const admin = require("firebase-admin");

admin.initializeApp({
  projectId: process.env.GCLOUD_PROJECT || "clicknow-4f0d3",
});

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const applyChanges = process.argv.includes("--apply");
const paidStatuses = new Set(["PAID", "FULLY_PAID", "PARTIALLY_PAID", "ADVANCE_PAID"]);
const hiddenStatuses = new Set([
  "UNPAID",
  "PENDING_PAYMENT",
  "CREATED",
  "FAILED",
  "PAYMENT_FAILED",
  "PAYMENT_ABANDONED",
  "ABANDONED_PAYMENT",
]);

async function main() {
  const bookings = await db.collection("bookings").get();
  const report = {
    mode: applyChanges ? "apply" : "dry-run",
    scanned: bookings.size,
    hiddenUnpaidBookings: [],
    activatedPaidBookings: [],
    missingBookingIds: [],
    duplicateInvoices: [],
    duplicatePayrolls: [],
    duplicateRefunds: [],
  };

  for (const bookingDoc of bookings.docs) {
    const booking = bookingDoc.data() || {};
    const paymentDoc = await db.collection("payments").doc(bookingDoc.id).get();
    const payment = paymentDoc.data() || {};
    const paymentStatus = clean(
      payment.paymentStatus || booking.paymentStatus || booking.payment?.status,
    ).toUpperCase();
    const hasCapturedPayment = paidStatuses.has(paymentStatus) &&
      positiveInt(payment.paidAmount || booking.paidAmount || booking.payment?.paidAmount) > 0;
    const batch = db.batch();
    let changed = false;

    if (!clean(booking.bookingCode)) {
      const bookingCode = await nextHumanId("booking", "BKG");
      report.missingBookingIds.push({ bookingId: bookingDoc.id, bookingCode });
      batch.set(bookingDoc.ref, { bookingCode, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      changed = true;
    }

    if (!hasCapturedPayment) {
      const nextPaymentStatus = hiddenStatuses.has(paymentStatus)
        ? paymentStatus || "PAYMENT_PENDING"
        : "PAYMENT_PENDING";
      report.hiddenUnpaidBookings.push({ bookingId: bookingDoc.id, paymentStatus: nextPaymentStatus });
      batch.set(bookingDoc.ref, {
        status: "DRAFT",
        lifecycleStatus: nextPaymentStatus.toLowerCase(),
        bookingStatus: nextPaymentStatus.toLowerCase(),
        bookingStage: nextPaymentStatus.toLowerCase(),
        paymentStatus: nextPaymentStatus,
        adminVisible: false,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      batch.delete(db.collection("customer_booking_requests").doc(bookingDoc.id));
      changed = true;
    } else if (booking.adminVisible !== true || clean(booking.status).toUpperCase() === "DRAFT") {
      report.activatedPaidBookings.push({ bookingId: bookingDoc.id, paymentStatus });
      batch.set(bookingDoc.ref, {
        status: clean(booking.status).toUpperCase() === "DRAFT" ? "REQUESTED" : booking.status,
        lifecycleStatus: clean(booking.status).toUpperCase() === "DRAFT"
          ? "requested"
          : booking.lifecycleStatus,
        bookingStatus: clean(booking.status).toUpperCase() === "DRAFT"
          ? "requested"
          : booking.bookingStatus,
        adminVisible: true,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      changed = true;
    }

    if (hasCapturedPayment) {
      const wasDraft = clean(booking.status).toUpperCase() === "DRAFT";
      const readModel = {
        ...booking,
        status: wasDraft ? "REQUESTED" : booking.status,
        lifecycleStatus: wasDraft ? "requested" : booking.lifecycleStatus,
        bookingStatus: wasDraft ? "requested" : booking.bookingStatus,
        adminVisible: true,
        sourceBookingId: bookingDoc.id,
        updatedAt: FieldValue.serverTimestamp(),
      };
      batch.set(db.collection("customer_booking_requests").doc(bookingDoc.id), readModel, { merge: true });
      const customerId = clean(booking.customerId || booking.userId || booking.customer?.id);
      if (customerId) {
        batch.set(
          db.collection("users").doc(customerId).collection("customer_bookings").doc(bookingDoc.id),
          readModel,
          { merge: true },
        );
      }
      const professionalId = clean(
        booking.assignedProfessionalId || booking.professionalId || booking.assignedToProfessionalId,
      );
      if (professionalId) {
        batch.set(
          db.collection("users").doc(professionalId).collection("booking_requests").doc(bookingDoc.id),
          professionalReadModel(readModel),
          { merge: true },
        );
      }
      changed = true;
    }

    if (applyChanges && changed) {
      await batch.commit();
    }
  }

  report.duplicateInvoices = await duplicateBookingLinks("invoices");
  report.duplicatePayrolls = await duplicateBookingLinks("payrolls");
  report.duplicateRefunds = await duplicateBookingLinks("refunds");
  console.log(JSON.stringify(report, null, 2));
}

async function duplicateBookingLinks(collectionName) {
  const snapshot = await db.collection(collectionName).get();
  const byBooking = new Map();
  for (const doc of snapshot.docs) {
    const bookingId = clean(doc.data()?.bookingId);
    if (!bookingId) continue;
    const ids = byBooking.get(bookingId) || [];
    ids.push(doc.id);
    byBooking.set(bookingId, ids);
  }
  return [...byBooking.entries()]
    .filter(([, ids]) => ids.length > 1)
    .map(([bookingId, documentIds]) => ({ bookingId, documentIds }));
}

async function nextHumanId(type, prefix) {
  const now = new Date();
  const date = `${now.getUTCFullYear()}${String(now.getUTCMonth() + 1).padStart(2, "0")}${String(now.getUTCDate()).padStart(2, "0")}`;
  const ref = db.collection("id_counters").doc(`${type}_${date}`);
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const sequence = positiveInt(snapshot.data()?.lastSequence) + 1;
    if (applyChanges) {
      transaction.set(ref, {
        type,
        date,
        lastSequence: sequence,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    return `${prefix}-${date}-${String(sequence).padStart(6, "0")}`;
  });
}

function clean(value) {
  return value == null ? "" : String(value).trim();
}

function positiveInt(value) {
  const parsed = Number.parseInt(clean(value).replace(/[^0-9-]/g, ""), 10);
  return Number.isFinite(parsed) ? Math.max(0, parsed) : 0;
}

function professionalReadModel(booking) {
  const result = { ...booking };
  for (const field of [
    "paidAmount",
    "remainingAmount",
    "totalAmount",
    "finalAmount",
    "discountAmount",
    "couponCode",
    "refundAmount",
    "refundEligibility",
    "refundPercentage",
    "financialBreakdown",
    "pricingSnapshot",
  ]) {
    delete result[field];
  }
  return result;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

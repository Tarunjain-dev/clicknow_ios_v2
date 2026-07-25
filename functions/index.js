const crypto = require("crypto");
const admin = require("firebase-admin");
const functions = require("firebase-functions");
const functionsV1 = require("firebase-functions/v1");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const Razorpay = require("razorpay");
const { calculatePricing, refundPolicy } = require("./business_logic");

admin.initializeApp();

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const COLLECTIONS = {
  bookings: "bookings",
  customerBookingRequests: "customer_booking_requests",
  payments: "payments",
  invoices: "invoices",
  refunds: "refunds",
  payrolls: "payrolls",
  stipendSlips: "stipend_slips",
  appSettings: "app_settings",
  financialAuditLogs: "financial_audit_logs",
  users: "users",
  customerBookings: "customer_bookings",
  customerCart: "customer_booking_cart",
  professionalBookingRequests: "booking_requests",
  coupons: "coupons",
  couponUsages: "coupon_usages",
  customerPaymentMarkers: "customer_payment_markers",
  paymentTransactions: "payment_transactions",
  financeLedger: "finance_ledger",
  professionalProfiles: "professional_profiles",
  adminActionLogs: "admin_action_logs",
  idCounters: "id_counters",
  reviews: "reviews",
  serviceStats: "service_stats",
  notificationCampaigns: "notification_campaigns",
};

function firebaseRuntimeConfig() {
  try {
    return functions.config ? functions.config() : {};
  } catch (error) {
    return {};
  }
}

function configuredRazorpayKeyId() {
  const config = firebaseRuntimeConfig();
  const razorpayConfig = config.razorpay || {};
  return clean(
    process.env.RAZORPAY_KEY_ID ||
      process.env.RAZORPAY_KEYID ||
      process.env.RAZORPAY_KEY ||
      razorpayConfig.key_id ||
      razorpayConfig.keyid ||
      razorpayConfig.key,
  );
}

function razorpaySecret() {
  const config = firebaseRuntimeConfig();
  const razorpayConfig = config.razorpay || {};
  const secret =
    clean(
      process.env.RAZORPAY_KEY_SECRET ||
        process.env.RAZORPAY_SECRET_KEY ||
        process.env.RAZORPAY_SECRET ||
        razorpayConfig.key_secret ||
        razorpayConfig.secret_key ||
        razorpayConfig.secret,
    );
  if (!secret) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Razorpay secret is not configured on backend.",
    );
  }
  return secret;
}

function razorpayClient() {
  const keyId = configuredRazorpayKeyId();
  if (!keyId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Razorpay key id is not configured on backend.",
    );
  }
  return new Razorpay({
    key_id: keyId,
    key_secret: razorpaySecret(),
  });
}

function maskedRazorpayKeyId() {
  const keyId = configuredRazorpayKeyId();
  if (!keyId) {
    return "";
  }
  return `${keyId.substring(0, Math.min(8, keyId.length))}...len=${keyId.length}`;
}

function razorpayProviderError(error, action) {
  const providerError = error?.error || {};
  const description = clean(
    providerError.description ||
      error?.description ||
      error?.message,
  );
  const code = clean(providerError.code || error?.code);
  const statusCode = positiveInt(error?.statusCode);
  console.error("Razorpay provider request failed", {
    action,
    statusCode,
    code,
    description,
    keyId: maskedRazorpayKeyId(),
  });
  const suffix = description
    ? `${description}.`
    : "Check backend Razorpay key id and secret.";
  throw new functions.https.HttpsError(
    "failed-precondition",
    `Razorpay ${action} failed: ${suffix}`,
  );
}

exports.createBookingDraft = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "customer");
    const draft = asObject(data.booking);
    const pricing = await resolveAuthoritativeServicePricing(draft);
    const userSnap = await db.collection(COLLECTIONS.users).doc(uid).get();
    const user = userSnap.data() || {};
    const bookingRef = db.collection(COLLECTIONS.bookings).doc();
    const bookingCode = await nextHumanId("booking", "BKG");
    const now = FieldValue.serverTimestamp();
    const eventDate = timestampFromInput(draft.eventDate);
    const booking = {
      requestId: bookingRef.id,
      bookingId: bookingRef.id,
      bookingCode,
      sourceBookingId: bookingRef.id,
      sourceVersion: 1,
      cartItemId: clean(draft.cartItemId),
      userId: uid,
      customerId: uid,
      customer: {
        id: uid,
        name: clean(user.name || user.fullName || user.customerName),
        phoneNumber: clean(user.phoneNumber || user.phone || user.mobileNumber),
        email: clean(user.email),
      },
      serviceCatalogId: pricing.serviceCatalogId,
      serviceTitle: pricing.serviceTitle,
      eventTypeId: pricing.eventTypeId,
      eventTypeName: pricing.eventTypeName,
      planKey: pricing.planKey,
      planName: pricing.planName,
      rateAmount: pricing.rateAmount,
      basePrice: pricing.serviceSubtotal,
      gstPercent: pricing.gstRate,
      gstAmount: pricing.gstAmount,
      totalAmount: pricing.originalCustomerPayable,
      originalCustomerPayable: pricing.originalCustomerPayable,
      finalAmount: pricing.originalCustomerPayable,
      pricingSnapshot: {
        ...pricing,
        paymentOption: "",
        couponId: null,
        couponCode: "",
        couponDiscountAmount: 0,
        discountedServiceSubtotal: pricing.serviceSubtotal,
        finalCustomerPayable: pricing.originalCustomerPayable,
        advanceRate: 20,
        advanceDue: Math.round(pricing.originalCustomerPayable * 0.2),
        remainingDue: pricing.originalCustomerPayable - Math.round(pricing.originalCustomerPayable * 0.2),
        commissionRate: 21,
        commissionAmount: Math.round(pricing.originalCustomerPayable * 0.21),
        expectedNetPayout: Math.max(
          0,
          pricing.originalCustomerPayable -
            pricing.gstAmount -
            Math.round(pricing.originalCustomerPayable * 0.21),
        ),
        pricingVersion: "v1",
        locked: false,
      },
      eventDate,
      scheduledDate: eventDate,
      eventTime: clean(draft.eventTime),
      eventDurationHours: clean(draft.eventDurationHours),
      guestCount: clean(draft.guestCount),
      venueName: clean(draft.venueName),
      venueHouseDetails: clean(draft.venueHouseDetails),
      venueLandmarkDetails: clean(draft.venueLandmarkDetails),
      fullAddress: clean(draft.fullAddress),
      state: clean(draft.state),
      city: clean(draft.city),
      pincode: clean(draft.pincode),
      latitude: finiteNumber(draft.latitude),
      longitude: finiteNumber(draft.longitude),
      specialRequirements: clean(draft.specialRequirements),
      urgentBooking: draft.urgentBooking === true,
      onsiteContactName: clean(draft.onsiteContactName),
      onsiteContactPhone: clean(draft.onsiteContactPhone),
      status: "DRAFT",
      lifecycleStatus: "draft",
      bookingStatus: "draft",
      bookingStage: "checkout_draft_created",
      paymentStatus: "UNPAID",
      paymentMode: "",
      paymentGateway: "razorpay",
      payment: {
        status: "UNPAID",
        mode: "",
        gateway: "razorpay",
        paidAmount: 0,
        remainingAmount: pricing.originalCustomerPayable,
        discountAmount: 0,
        currency: "INR",
      },
      adminVisible: false,
      assignedProfessionalId: "",
      assignedProfessionalIds: [],
      rejectedProfessionalIds: [],
      createdAt: now,
      updatedAt: now,
    };
    await bookingRef.set(booking);
    return {
      bookingId: bookingRef.id,
      bookingCode,
      pricingSnapshot: booking.pricingSnapshot,
    };
  }),
);

exports.createPaymentOrder = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
  await requireActiveAccount(uid, "customer");
  const bookingId = clean(data.bookingId);
  const paymentMode = normalizePaymentMode(data.paymentMode);
  const couponCode = clean(data.couponCode).toUpperCase();
  if (!bookingId) {
    throw new functions.https.HttpsError("invalid-argument", "Booking id is required.");
  }

  const bookingSnap = await db.collection(COLLECTIONS.bookings).doc(bookingId).get();
  const booking = requireBookingForCustomer(bookingSnap, uid);
  const paymentStatus = clean(booking.paymentStatus).toUpperCase();
  if (
    ["PAID", "FULLY_PAID"].includes(paymentStatus) ||
    ["PAID", "FULLY_PAID"].includes(clean(booking.payment?.status).toUpperCase())
  ) {
    throw new functions.https.HttpsError("failed-precondition", "Booking is already paid.");
  }
  if (paymentStatus === "PARTIALLY_PAID" || paymentStatus === "ADVANCE_PAID") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Please use remaining payment for this booking.",
    );
  }

  const pricingBase = pricingBaseForBooking(booking);
  if (pricingBase.serviceSubtotal <= 0) {
    throw new functions.https.HttpsError("failed-precondition", "Booking amount is invalid.");
  }

  const coupon = await resolveCoupon({
    couponCode,
    customerId: uid,
    booking,
    totalAmount: pricingBase.serviceSubtotal,
  });
  const quote = paymentQuote({
    totalAmount: pricingBase.originalCustomerPayable,
    serviceSubtotal: pricingBase.serviceSubtotal,
    rateAmount: pricingBase.rateAmount,
    quantityOrDuration: pricingBase.quantityOrDuration,
    paymentMode,
    discountAmount: coupon.discountAmount,
    couponCode: coupon.appliedCode,
  });
  const orderCode = await nextHumanId("order", "ORD");
  return createOrReuseOrder({
    bookingId,
    booking,
    customerId: uid,
    paymentMode,
    paymentPhase: "INITIAL",
    payableAmount: quote.payableAmount,
    remainingAmount: quote.remainingAmount,
    totalAmount: quote.originalCustomerPayable,
    discountAmount: coupon.discountAmount,
    couponCode: coupon.appliedCode,
    pricingSnapshot: quote,
    orderCode,
  });
  }),
);

exports.quoteCheckoutPayment = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "customer");
  const paymentMode = normalizePaymentMode(data.paymentMode);
  const couponCode = clean(data.couponCode).toUpperCase();
    const pricing = await resolveAuthoritativeServicePricing(data);
    const coupon = await resolveCoupon({
      couponCode,
      customerId: uid,
      booking: {
        serviceCatalogId: pricing.serviceCatalogId,
        serviceTitle: pricing.serviceTitle,
        eventTypeId: pricing.eventTypeId,
        eventTypeName: pricing.eventTypeName,
      },
      totalAmount: pricing.serviceSubtotal,
    });
    return paymentQuote({
      totalAmount: pricing.originalCustomerPayable,
      serviceSubtotal: pricing.serviceSubtotal,
      rateAmount: pricing.rateAmount,
      quantityOrDuration: pricing.quantityOrDuration,
      paymentMode,
      discountAmount: coupon.discountAmount,
      couponCode: coupon.appliedCode,
    });
  }),
);

exports.createRemainingPaymentOrder = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
  const bookingId = clean(data.bookingId);
  if (!bookingId) {
    throw new functions.https.HttpsError("invalid-argument", "Booking id is required.");
  }

  const bookingSnap = await db.collection(COLLECTIONS.bookings).doc(bookingId).get();
  const booking = requireBookingForCustomer(bookingSnap, uid);
  const payment = asObject(booking.payment);
  const paymentStatus = clean(booking.paymentStatus || payment.status).toUpperCase();
  if (!["PARTIALLY_PAID", "ADVANCE_PAID"].includes(paymentStatus)) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Remaining payment is available only after the advance is captured.",
    );
  }
  const remainingAmount = remainingDueForBooking(booking, payment);
  if (remainingAmount <= 0) {
    throw new functions.https.HttpsError("failed-precondition", "No remaining payment is due.");
  }

  return createOrReuseOrder({
    bookingId,
    booking,
    customerId: uid,
    paymentMode: "REMAINING",
    paymentPhase: "REMAINING",
    payableAmount: remainingAmount,
    remainingAmount: 0,
    totalAmount: positiveInt(booking.totalAmount),
    discountAmount: positiveInt(payment.discountAmount),
    couponCode: clean(payment.couponCode),
    pricingSnapshot: asObject(payment.financialBreakdown || booking.pricingSnapshot),
  });
  }),
);

exports.markPaymentAbandoned = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    const bookingId = clean(data.bookingId);
    if (!bookingId) {
      throw new functions.https.HttpsError("invalid-argument", "Booking id is required.");
    }
    const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
    const paymentRef = db.collection(COLLECTIONS.payments).doc(bookingId);
    const [bookingSnap, paymentSnap] = await Promise.all([
      bookingRef.get(),
      paymentRef.get(),
    ]);
    const booking = requireBookingForCustomer(bookingSnap, uid);
    const payment = paymentSnap.data() || {};
    const paidAmount = positiveInt(payment.paidAmount);
    const nextStatus = paidAmount > 0 ? "PARTIALLY_PAID" : "PAYMENT_ABANDONED";
    const now = FieldValue.serverTimestamp();
    const bookingPatch = {
      paymentStatus: nextStatus,
      "payment.status": nextStatus,
      "payment.activePaymentStatus": "ABANDONED",
      ...(paidAmount <= 0
        ? {
            status: "DRAFT",
            lifecycleStatus: "payment_abandoned",
            bookingStatus: "payment_abandoned",
            bookingStage: "payment_abandoned",
            adminVisible: false,
          }
        : {}),
      updatedAt: now,
    };
    const ledgerRef = db.collection(COLLECTIONS.financeLedger).doc(
      `${bookingId}_${clean(payment.activeRazorpayOrderId) || Date.now()}_PAYMENT_ABANDONED`,
    );
    const batch = db.batch();
    batch.set(bookingRef, bookingPatch, { merge: true });
    batch.set(paymentRef, {
      paymentStatus: nextStatus,
      activePaymentStatus: "ABANDONED",
      updatedAt: now,
    }, { merge: true });
    batch.set(ledgerRef, {
      ledgerId: ledgerRef.id,
      eventType: "PAYMENT_ABANDONED",
      bookingId,
      paymentId: clean(payment.paymentId) || bookingId,
      customerId: uid,
      amount: positiveInt(payment.activePayableAmount),
      currency: "INR",
      gatewayOrderId: clean(payment.activeRazorpayOrderId),
      status: "ABANDONED",
      createdAt: now,
    });
    await batch.commit();
    return { ok: true, bookingId };
  }),
);

exports.cancelUnacceptedBookingByAdmin = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "admin");
    const bookingId = clean(data.bookingId);
    const reason = clean(data.reason) || "Cancelled by admin";
    if (!bookingId) {
      throw new functions.https.HttpsError("invalid-argument", "Booking id is required.");
    }

    const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
    const paymentRef = db.collection(COLLECTIONS.payments).doc(bookingId);
    const refundRef = db.collection(COLLECTIONS.refunds).doc(`${bookingId}_ADMIN_CANCELLATION`);
    const refundBusinessId = await nextHumanId("refund", "REF");
    const completedRefundAmount = await completedRefundAmountForBooking(bookingId);
    let createdRefund = false;
    let refundAmount = 0;
    let paymentForRefund = {};
    await db.runTransaction(async (transaction) => {
      const bookingSnap = await transaction.get(bookingRef);
      const paymentSnap = await transaction.get(paymentRef);
      const refundSnap = await transaction.get(refundRef);
      const booking = bookingSnap.data();
      const payment = paymentSnap.data() || {};
      if (!booking) {
        throw new functions.https.HttpsError("not-found", "Booking not found.");
      }
      if (refundSnap.exists) {
        refundAmount = positiveInt(refundSnap.data()?.refundAmount);
        return;
      }
      const decision = clean(booking.professionalDecisionStatus).toLowerCase();
      const status = clean(booking.bookingStatus || booking.status).toLowerCase();
      if (
        decision === "accepted" ||
        ["confirmed", "accepted", "in_progress", "completed"].includes(status)
      ) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "This booking has already been accepted by a professional.",
        );
      }
      if (!["requested", "pending", "approved", "assigned"].includes(status)) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Only pending bookings can be cancelled by admin.",
        );
      }
      const paymentStatus = clean(payment.paymentStatus || booking.paymentStatus).toUpperCase();
      if (!["PAID", "FULLY_PAID", "PARTIALLY_PAID", "ADVANCE_PAID"].includes(paymentStatus)) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Cancellation requires a paid booking.",
        );
      }
      const paidAmount = collectedAmountForPayment(booking, payment);
      refundAmount = Math.max(0, paidAmount - completedRefundAmount);
      if (refundAmount <= 0) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "No paid amount available for refund.",
        );
      }

      const now = FieldValue.serverTimestamp();
      const refund = {
        refundId: refundBusinessId,
        refundDocumentId: refundRef.id,
        bookingId,
        paymentId: bookingId,
        customerId: clean(booking.customerId || booking.userId),
        refundAmount,
        refundReason: reason,
        refundType: refundAmount >= paidAmount ? "FULL" : "PARTIAL",
        refundStatus: "REQUESTED",
        refundMode: "PENDING_PROVIDER",
        refundEligibility: "Admin cancelled unaccepted booking",
        refundPercentage: 100,
        requestedBy: uid,
        requestedByRole: "admin",
        createdAt: now,
        updatedAt: now,
      };
      transaction.set(refundRef, refund);
      const bookingPatch = {
        bookingStatus: "cancelled_by_admin",
        lifecycleStatus: "cancelled_by_admin",
        status: "CANCELLED",
        bookingStage: "cancelled_by_admin",
        cancelledByAdminId: uid,
        cancelledReason: reason,
        cancelledAt: now,
        paymentStatus: "REFUND_PENDING",
        "payment.status": "REFUND_PENDING",
        refundAmount,
        adminVisible: true,
        updatedAt: now,
      };
      writeBookingCopies(transaction, bookingId, booking, bookingPatch);
      transaction.set(paymentRef, {
        paymentStatus: "REFUND_PENDING",
        refundStatus: "REQUESTED",
        refundAmount,
        refundEligibility: "Admin cancelled unaccepted booking",
        refundPercentage: 100,
        updatedAt: now,
      }, { merge: true });
      const ledgerRef = db.collection(COLLECTIONS.financeLedger).doc(`${refundRef.id}_REFUND_REQUESTED`);
      transaction.set(ledgerRef, {
        ledgerId: ledgerRef.id,
        eventType: "REFUND_REQUESTED",
        bookingId,
        paymentId: bookingId,
        refundId: refundBusinessId,
        customerId: clean(booking.customerId || booking.userId),
        amount: refundAmount,
        currency: "INR",
        status: "REQUESTED",
        createdAt: now,
      });
      paymentForRefund = payment;
      createdRefund = true;
    });

    if (createdRefund) {
      const paymentIds = Array.isArray(paymentForRefund.razorpayPaymentIds)
        ? paymentForRefund.razorpayPaymentIds.map(clean).filter(Boolean)
        : [];
      const gatewayPaymentId = clean(paymentForRefund.gatewayTransactionId) ||
        paymentIds[paymentIds.length - 1] ||
        "";
      if (gatewayPaymentId && paymentIds.length <= 1) {
        try {
          const providerRefund = await razorpayClient().payments.refund(gatewayPaymentId, {
            amount: rupeesToPaise(refundAmount),
            notes: { bookingId, reason, refundId: refundBusinessId },
          });
          await refundRef.set({
            refundStatus: "PROCESSING",
            refundMode: "RAZORPAY",
            razorpayRefundId: clean(providerRefund.id),
            processedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          }, { merge: true });
        } catch (error) {
          console.error("Admin cancellation refund provider request failed", error);
          await refundRef.set({
            refundStatus: "PROVIDER_FAILED",
            refundMode: "MANUAL_REVIEW",
            failureReason: clean(error.message),
            updatedAt: FieldValue.serverTimestamp(),
          }, { merge: true });
        }
      } else {
        await refundRef.set({
          refundStatus: "UNDER_REVIEW",
          refundMode: "MANUAL",
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
    }

    return { ok: true, bookingId, refundId: refundBusinessId, refundAmount };
  }),
);

exports.approveBookingByAdmin = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "admin");
    const bookingId = clean(data.bookingId);
    if (!bookingId) {
      throw new functions.https.HttpsError("invalid-argument", "Booking id is required.");
    }
    const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(bookingRef);
      const booking = snapshot.data();
      if (!booking) {
        throw new functions.https.HttpsError("not-found", "Booking not found.");
      }
      if (!hasSuccessfulPaymentStatus(booking.paymentStatus || asObject(booking.payment).status)) {
        throw new functions.https.HttpsError("failed-precondition", "Customer payment must be verified first.");
      }
      if (clean(booking.status).toUpperCase() !== "REQUESTED") {
        throw new functions.https.HttpsError("failed-precondition", "Only requested bookings can be approved.");
      }
      const now = FieldValue.serverTimestamp();
      writeBookingCopies(transaction, bookingId, booking, {
        status: "APPROVED",
        lifecycleStatus: "approved",
        bookingStatus: "approved",
        bookingStage: "booking_got_accepted_by_admin",
        approvedByAdminId: uid,
        approvedByAdminAt: now,
        "timeline.approvedAt": now,
        "statusTimeline.acceptedByAdminAt": now,
        updatedAt: now,
      });
      const auditRef = db.collection(COLLECTIONS.adminActionLogs).doc();
      transaction.set(auditRef, {
        logId: auditRef.id,
        bookingId,
        action: "BOOKING_APPROVED",
        performedByAdminId: uid,
        createdAt: now,
      });
    });
    const bookingSnap = await bookingRef.get();
    const booking = bookingSnap.data() || {};
    await safeCreateAndSendNotification({
      recipientIds: [clean(booking.customerId || booking.userId)],
      title: "Booking approved",
      body: `${clean(booking.serviceTitle) || "Your booking"} has been approved by admin.`,
      type: "booking_approved",
      source: "system",
      data: {
        bookingId,
        bookingCode: clean(booking.bookingCode),
        serviceTitle: clean(booking.serviceTitle),
      },
    });
    return { ok: true, bookingId };
  }),
);

exports.assignBookingByAdmin = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "admin");
    const bookingId = clean(data.bookingId);
    const professionalId = clean(data.professionalId);
    if (!bookingId || !professionalId) {
      throw new functions.https.HttpsError("invalid-argument", "Booking and professional ids are required.");
    }
    const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
    const profileRef = db.collection(COLLECTIONS.professionalProfiles).doc(professionalId);
    await db.runTransaction(async (transaction) => {
      const bookingSnap = await transaction.get(bookingRef);
      const profileSnap = await transaction.get(profileRef);
      const booking = bookingSnap.data();
      const profile = profileSnap.data();
      if (!booking) {
        throw new functions.https.HttpsError("not-found", "Booking not found.");
      }
      if (!profile) {
        throw new functions.https.HttpsError("not-found", "Professional profile not found.");
      }
      if (!hasSuccessfulPaymentStatus(booking.paymentStatus || asObject(booking.payment).status)) {
        throw new functions.https.HttpsError("failed-precondition", "Customer payment must be verified first.");
      }
      if (!["APPROVED", "ASSIGNED"].includes(clean(booking.status).toUpperCase())) {
        throw new functions.https.HttpsError("failed-precondition", "Booking is not ready for assignment.");
      }
      const rejectedProfessionalIds = Array.isArray(booking.rejectedProfessionalIds)
        ? booking.rejectedProfessionalIds.map(clean).filter(Boolean)
        : [];
      if (rejectedProfessionalIds.includes(professionalId)) {
        throw new functions.https.HttpsError("failed-precondition", "This professional has already rejected this booking.");
      }
      const profileStatus = clean(profile.accountStatus || profile.status).toLowerCase();
      if (["blocked", "suspended", "rejected"].includes(profileStatus)) {
        throw new functions.https.HttpsError("failed-precondition", "Professional is not available for assignment.");
      }
      const approvalStatus = clean(profile.approvalStatus || profile.professionalStatus || profile.status).toLowerCase();
      if (!["approved", "active", "verified", "online", "available"].includes(approvalStatus)) {
        throw new functions.https.HttpsError("failed-precondition", "Professional is not approved for assignment.");
      }
      const basicInfo = asObject(profile.basicInfo);
      const now = FieldValue.serverTimestamp();
      writeBookingCopies(transaction, bookingId, booking, {
        status: "ASSIGNED",
        lifecycleStatus: "assigned",
        bookingStatus: "assigned",
        bookingStage: "professional_assigned",
        assignedProfessionalId: professionalId,
        assignedProfessionalIds: FieldValue.arrayUnion(professionalId),
        professionalId,
        assignedToProfessionalId: professionalId,
        professional: {
          uid: professionalId,
          name: clean(basicInfo.fullName),
          phoneNumber: clean(profile.phoneNumber),
        },
        assignment: {
          professionalId,
          status: "pending_professional_response",
          assignedBy: uid,
          autoAssigned: data.autoAssigned === true,
          assignedAt: now,
          score: finiteNumber(data.score),
          scoreBreakdown: clean(data.scoreBreakdown),
        },
        professionalDecisionStatus: "pending",
        "timeline.assignedAt": now,
        "statusTimeline.professionalAssignedAt": now,
        updatedAt: now,
      });
      const auditRef = db.collection(COLLECTIONS.adminActionLogs).doc();
      transaction.set(auditRef, {
        logId: auditRef.id,
        bookingId,
        professionalId,
        action: data.autoAssigned === true ? "BOOKING_AUTO_ASSIGNED" : "BOOKING_ASSIGNED",
        performedByAdminId: uid,
        createdAt: now,
      });
    });
    const assignedBookingSnap = await bookingRef.get();
    const assignedBooking = assignedBookingSnap.data() || {};
    await safeCreateAndSendNotification({
      recipientIds: [clean(assignedBooking.customerId || assignedBooking.userId)],
      title: "Professional assigned",
      body: `${clean(asObject(assignedBooking.professional).name) || "A professional"} has been assigned to your booking.`,
      type: "booking_professional_assigned",
      source: "system",
      data: {
        bookingId,
        bookingCode: clean(assignedBooking.bookingCode),
        serviceTitle: clean(assignedBooking.serviceTitle),
      },
    });
    await safeCreateAndSendNotification({
      recipientIds: [professionalId],
      title: "New booking assigned",
      body: `${clean(assignedBooking.serviceTitle) || "A booking"} is waiting for your response.`,
      type: "booking_assigned",
      source: "system",
      data: {
        bookingId,
        bookingCode: clean(assignedBooking.bookingCode),
        serviceTitle: clean(assignedBooking.serviceTitle),
      },
    });
    return { ok: true, bookingId, professionalId };
  }),
);

exports.professionalRespondToBooking = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "professional");
    const bookingId = clean(data.bookingId);
    const accepted = data.accepted === true;
    const reason = clean(data.reason);
    if (!bookingId || (!accepted && !reason)) {
      throw new functions.https.HttpsError("invalid-argument", "Booking and rejection reason are required.");
    }
    const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(bookingRef);
      const booking = snapshot.data();
      if (!booking) {
        throw new functions.https.HttpsError("not-found", "Booking not found.");
      }
      if (clean(booking.assignedProfessionalId) !== uid) {
        throw new functions.https.HttpsError("permission-denied", "This booking is not assigned to you.");
      }
      if (clean(booking.status).toUpperCase() !== "ASSIGNED") {
        throw new functions.https.HttpsError("failed-precondition", "Booking is not awaiting a professional response.");
      }
      const now = FieldValue.serverTimestamp();
      if (accepted) {
        writeBookingCopies(transaction, bookingId, booking, {
          status: "CONFIRMED",
          lifecycleStatus: "confirmed",
          bookingStatus: "confirmed",
          bookingStage: "professional_confirmed",
          professionalDecisionStatus: "accepted",
          acceptedByProfessionalId: uid,
          acceptedAt: now,
          "statusTimeline.professionalAcceptedAt": now,
          updatedAt: now,
        });
      } else {
        writeBookingCopies(transaction, bookingId, booking, {
          status: "APPROVED",
          lifecycleStatus: "approved",
          bookingStatus: "approved",
          bookingStage: "booking_got_accepted_by_admin",
          assignedProfessionalId: "",
          assignedToProfessionalId: "",
          professionalId: "",
          professional: {},
          assignment: {},
          professionalDecisionStatus: "rejected",
          rejectedProfessionalIds: FieldValue.arrayUnion(uid),
          lastProfessionalRejection: {
            professionalId: uid,
            reason,
            rejectedAt: now,
          },
          updatedAt: now,
        });
        transaction.delete(
          db.collection(COLLECTIONS.users)
            .doc(uid)
            .collection(COLLECTIONS.professionalBookingRequests)
            .doc(bookingId),
        );
      }
    });
    const responseBookingSnap = await bookingRef.get();
    const responseBooking = responseBookingSnap.data() || {};
    await safeCreateAndSendNotification({
      recipientIds: [clean(responseBooking.customerId || responseBooking.userId)],
      title: accepted ? "Professional accepted booking" : "Professional declined booking",
      body: accepted
        ? `${clean(responseBooking.serviceTitle) || "Your booking"} is confirmed by the professional.`
        : "The assigned professional declined. Admin can assign another professional.",
      type: accepted ? "booking_professional_accepted" : "booking_professional_rejected",
      source: "system",
      data: {
        bookingId,
        bookingCode: clean(responseBooking.bookingCode),
        serviceTitle: clean(responseBooking.serviceTitle),
      },
    });
    return { ok: true, bookingId, accepted };
  }),
);

exports.requestBookingReschedule = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "customer");
    const bookingId = clean(data.bookingId);
    const newEventDate = timestampFromInput(data.newEventDate);
    const newEventTime = clean(data.newEventTime);
    const reason = clean(data.reason);
    if (!bookingId || !newEventDate || !newEventTime || !reason) {
      throw new functions.https.HttpsError("invalid-argument", "New date, time, and reason are required.");
    }
    const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(bookingRef);
      const booking = requireBookingForCustomer(snapshot, uid);
      if (["COMPLETED", "CANCELLED", "REJECTED"].includes(clean(booking.status).toUpperCase())) {
        throw new functions.https.HttpsError("failed-precondition", "This booking cannot be rescheduled.");
      }
      const now = FieldValue.serverTimestamp();
      writeBookingCopies(transaction, bookingId, booking, {
        bookingStage: "reschedule_requested",
        rescheduleRequest: {
          requestedBy: uid,
          requestedAt: now,
          newEventDate,
          newEventTime,
          reason,
          status: "pending",
        },
        "statusTimeline.rescheduleRequestedAt": now,
        updatedAt: now,
      });
    });
    return { ok: true, bookingId };
  }),
);

exports.cancelBookingByCustomer = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "customer");
    const bookingId = clean(data.bookingId);
    const reason = clean(data.reason) || "Cancelled by customer";
    if (!bookingId) {
      throw new functions.https.HttpsError("invalid-argument", "Booking id is required.");
    }
    if (reason.length < 5) {
      throw new functions.https.HttpsError("invalid-argument", "Cancellation reason is required.");
    }

    const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
    const paymentRef = db.collection(COLLECTIONS.payments).doc(bookingId);
    const refundRef = db.collection(COLLECTIONS.refunds).doc(`${bookingId}_CUSTOMER_CANCELLATION`);
    const refundBusinessId = await nextHumanId("refund", "REF");
    const completedRefundAmount = await completedRefundAmountForBooking(bookingId);
    let refundAmount = 0;
    let refundPercent = 0;
    let refundCreated = false;

    await db.runTransaction(async (transaction) => {
      const bookingSnap = await transaction.get(bookingRef);
      const booking = requireBookingForCustomer(bookingSnap, uid);
      const paymentSnap = await transaction.get(paymentRef);
      const payment = paymentSnap.data() || {};
      const refundSnap = await transaction.get(refundRef);
      if (refundSnap.exists) {
        refundAmount = positiveInt(refundSnap.data()?.refundAmount);
        return;
      }

      const status = clean(booking.status || booking.bookingStatus).toUpperCase();
      if (["IN_PROGRESS", "COMPLETED", "CANCELLED", "REJECTED"].includes(status)) {
        throw new functions.https.HttpsError("failed-precondition", "This booking cannot be cancelled.");
      }

      const now = FieldValue.serverTimestamp();
      const paidAmount = collectedAmountForPayment(booking, payment);
      const policy = refundPolicyForBooking(booking);
      refundPercent = policy.percent;
      refundAmount = calculateRefundAmount(booking, payment, completedRefundAmount);
      const paymentStatus = refundAmount > 0 ? "REFUND_PENDING" : "CANCELLED";
      const bookingPatch = {
        bookingStatus: "cancelled_by_customer",
        lifecycleStatus: "cancelled_by_customer",
        status: "CANCELLED",
        bookingStage: "cancelled_by_customer",
        cancelledByCustomerId: uid,
        cancelledByRole: "customer",
        cancelledReason: reason,
        cancellationReason: reason,
        cancellation: {
          cancelledBy: "customer",
          cancelledByUserId: uid,
          reason,
          cancelledAt: now,
        },
        "statusTimeline.cancelledAt": now,
        paymentStatus,
        "payment.status": paymentStatus,
        refundAmount,
        refundPercentage: refundPercent,
        refundEligibility: policy.label,
        adminVisible: true,
        updatedAt: now,
      };
      writeBookingCopies(transaction, bookingId, booking, bookingPatch);
      transaction.set(paymentRef, {
        paymentStatus,
        refundStatus: refundAmount > 0 ? "REQUESTED" : "",
        refundAmount,
        refundEligibility: policy.label,
        refundPercentage: refundPercent,
        updatedAt: now,
      }, { merge: true });

      if (refundAmount > 0) {
        const refund = {
          refundId: refundBusinessId,
          refundDocumentId: refundRef.id,
          bookingId,
          bookingCode: clean(booking.bookingCode),
          paymentId: bookingId,
          customerId: uid,
          refundAmount,
          refundReason: reason,
          refundType: refundAmount >= paidAmount ? "FULL" : "PARTIAL",
          refundStatus: "REQUESTED",
          refundMode: "PENDING_PROVIDER",
          refundEligibility: policy.label,
          refundPercentage: refundPercent,
          requestedBy: uid,
          requestedByRole: "customer",
          createdAt: now,
          updatedAt: now,
        };
        transaction.set(refundRef, refund);
        const ledgerRef = db.collection(COLLECTIONS.financeLedger).doc(`${refundRef.id}_REFUND_REQUESTED`);
        transaction.set(ledgerRef, {
          ledgerId: ledgerRef.id,
          eventType: "REFUND_REQUESTED",
          bookingId,
          bookingCode: clean(booking.bookingCode),
          paymentId: bookingId,
          refundId: refundBusinessId,
          customerId: uid,
          amount: refundAmount,
          currency: "INR",
          status: "REQUESTED",
          createdAt: now,
        });
        refundCreated = true;
      }
    });
    return { ok: true, bookingId, refundAmount, refundPercentage: refundPercent, refundCreated };
  }),
);

exports.adminReviewBookingReschedule = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "admin");
    const bookingId = clean(data.bookingId);
    const action = clean(data.action).toUpperCase();
    const reason = clean(data.reason);
    if (!bookingId || !["APPROVE", "REJECT"].includes(action) || (action === "REJECT" && !reason)) {
      throw new functions.https.HttpsError("invalid-argument", "A valid reschedule review is required.");
    }
    const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(bookingRef);
      const booking = snapshot.data();
      if (!booking) {
        throw new functions.https.HttpsError("not-found", "Booking not found.");
      }
      const request = asObject(booking.rescheduleRequest);
      if (clean(request.status).toLowerCase() !== "pending") {
        throw new functions.https.HttpsError("failed-precondition", "No pending reschedule request was found.");
      }
      const now = FieldValue.serverTimestamp();
      const oldProfessionalId = clean(booking.assignedProfessionalId);
      if (action === "APPROVE") {
        writeBookingCopies(transaction, bookingId, booking, {
          status: "APPROVED",
          lifecycleStatus: "approved",
          bookingStatus: "approved",
          bookingStage: "booking_got_accepted_by_admin",
          eventDate: request.newEventDate,
          scheduledDate: request.newEventDate,
          eventTime: clean(request.newEventTime),
          assignedProfessionalId: "",
          assignedToProfessionalId: "",
          professionalId: "",
          professional: {},
          assignment: {},
          professionalDecisionStatus: "pending",
          "rescheduleRequest.status": "approved",
          "rescheduleRequest.approvedBy": uid,
          "rescheduleRequest.approvedAt": now,
          updatedAt: now,
        });
        if (oldProfessionalId) {
          transaction.delete(
            db.collection(COLLECTIONS.users)
              .doc(oldProfessionalId)
              .collection(COLLECTIONS.professionalBookingRequests)
              .doc(bookingId),
          );
        }
      } else {
        writeBookingCopies(transaction, bookingId, booking, {
          "rescheduleRequest.status": "rejected",
          "rescheduleRequest.rejectedBy": uid,
          "rescheduleRequest.rejectedAt": now,
          "rescheduleRequest.rejectionReason": reason,
          updatedAt: now,
        });
      }
    });
    return { ok: true, bookingId, action };
  }),
);

exports.cancelAssignmentForReassignment = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "admin");
    const bookingId = clean(data.bookingId);
    const reason = clean(data.reason);
    if (!bookingId || !reason) {
      throw new functions.https.HttpsError("invalid-argument", "Booking and cancellation reason are required.");
    }
    const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(bookingRef);
      const booking = snapshot.data();
      if (!booking) {
        throw new functions.https.HttpsError("not-found", "Booking not found.");
      }
      const professionalId = clean(booking.assignedProfessionalId);
      const decision = clean(booking.professionalDecisionStatus).toLowerCase();
      if (clean(booking.status).toUpperCase() !== "ASSIGNED" || decision === "accepted" || !professionalId) {
        throw new functions.https.HttpsError("failed-precondition", "Only pending assignments can be cancelled.");
      }
      const now = FieldValue.serverTimestamp();
      writeBookingCopies(transaction, bookingId, booking, {
        status: "APPROVED",
        lifecycleStatus: "approved",
        bookingStatus: "approved",
        bookingStage: "booking_got_accepted_by_admin",
        assignedProfessionalId: "",
        assignedToProfessionalId: "",
        professionalId: "",
        professional: {},
        assignment: {
          cancelledByAdminId: uid,
          cancelledReason: reason,
          cancelledAt: now,
        },
        professionalDecisionStatus: "pending",
        adminAssignmentCancelled: true,
        adminAssignmentCancelReason: reason,
        adminAssignmentCancelledAt: now,
        updatedAt: now,
      });
      transaction.delete(
        db.collection(COLLECTIONS.users)
          .doc(professionalId)
          .collection(COLLECTIONS.professionalBookingRequests)
          .doc(bookingId),
      );
    });
    return { ok: true, bookingId };
  }),
);

exports.verifyPayment = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
  const bookingId = clean(data.bookingId);
  const paymentId = clean(data.paymentId) || bookingId;
  const razorpayPaymentId = clean(data.razorpayPaymentId);
  const razorpayOrderId = clean(data.razorpayOrderId);
  const razorpaySignature = clean(data.razorpaySignature);
  if (!bookingId || !razorpayPaymentId || !razorpayOrderId || !razorpaySignature) {
    throw new functions.https.HttpsError("invalid-argument", "Payment verification payload is incomplete.");
  }

  const expectedSignature = crypto
    .createHmac("sha256", razorpaySecret())
    .update(`${razorpayOrderId}|${razorpayPaymentId}`)
    .digest("hex");
  if (expectedSignature !== razorpaySignature) {
    throw new functions.https.HttpsError("permission-denied", "Payment signature verification failed.");
  }

  const gatewayPayment = await fetchAndValidateCapturedPayment({
    razorpayPaymentId,
    razorpayOrderId,
  });
  const paymentRef = db.collection(COLLECTIONS.payments).doc(paymentId);
  const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
  const existingBookingSnap = await bookingRef.get();
  const activationBookingCode = clean(existingBookingSnap.data()?.bookingCode) ||
    await nextHumanId("booking", "BKG");
  const transactionCode = await nextHumanId("transaction", "TXN");
  const paymentTransactionRef = db
    .collection(COLLECTIONS.paymentTransactions)
    .doc(`${bookingId}_${razorpayPaymentId}`);
  const ledgerRef = db
    .collection(COLLECTIONS.financeLedger)
    .doc(`${bookingId}_${razorpayPaymentId}_PAYMENT_CAPTURED`);
  await db.runTransaction(async (transaction) => {
    const bookingSnap = await transaction.get(bookingRef);
    const booking = requireBookingForCustomer(bookingSnap, uid);
    const paymentSnap = await transaction.get(paymentRef);
    const paymentTransactionSnap = await transaction.get(paymentTransactionRef);
    const payment = paymentSnap.data();
    if (!payment) {
      throw new functions.https.HttpsError("not-found", "Payment order not found.");
    }
    if (clean(payment.activeRazorpayOrderId) !== razorpayOrderId) {
      throw new functions.https.HttpsError("failed-precondition", "Payment order does not match active order.");
    }
    if (
      paymentTransactionSnap.exists ||
      (Array.isArray(payment.razorpayPaymentIds) &&
        payment.razorpayPaymentIds.includes(razorpayPaymentId))
    ) {
      return;
    }

    const capturedCouponCode = clean(payment.couponCode).toUpperCase();
    const isInitialCapture = positiveInt(payment.paidAmount) <= 0;
    const customerPaymentMarkerRef = db
      .collection(COLLECTIONS.customerPaymentMarkers)
      .doc(uid);
    const customerPaymentMarkerSnap = isInitialCapture
      ? await transaction.get(customerPaymentMarkerRef)
      : null;
    let couponUsageRef = capturedCouponCode
      ? db.collection(COLLECTIONS.couponUsages).doc(`${bookingId}_${capturedCouponCode}`)
      : null;
    if (
      isInitialCapture &&
      (capturedCouponCode === "CLICKNOW10" || capturedCouponCode === "STEALDEAL5")
    ) {
      const slotCount = capturedCouponCode === "CLICKNOW10" ? 1 : 2;
      const slotRefs = Array.from({ length: slotCount }, (_, index) =>
        db.collection(COLLECTIONS.couponUsages)
          .doc(`${capturedCouponCode}_${uid}_${index + 1}`));
      const slotSnaps = [];
      for (const slotRef of slotRefs) {
        slotSnaps.push(await transaction.get(slotRef));
      }
      const availableIndex = slotSnaps.findIndex((snapshot) => !snapshot.exists);
      if (availableIndex < 0) {
        const message = capturedCouponCode === "CLICKNOW10"
          ? "This coupon is valid only for first-time users."
          : "You have already used this coupon 2 times.";
        throw new functions.https.HttpsError("failed-precondition", message);
      }
      couponUsageRef = slotRefs[availableIndex];
    }
    if (
      isInitialCapture &&
      capturedCouponCode === "CLICKNOW10" &&
      customerPaymentMarkerSnap?.exists
    ) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "This coupon is valid only for first-time users.",
      );
    }

    const payableAmount = positiveInt(payment.activePayableAmount);
    if (positiveInt(gatewayPayment.amount) !== rupeesToPaise(payableAmount)) {
      throw new functions.https.HttpsError("failed-precondition", "Captured payment amount does not match the order.");
    }
    const previousPaidAmount = positiveInt(payment.paidAmount);
    const paidAmount = previousPaidAmount + payableAmount;
    const remainingAmount = positiveInt(payment.activeRemainingAmount);
    const isPaidInFull = remainingAmount <= 0 || clean(payment.paymentMode) === "FULL" || clean(payment.paymentPhase) === "REMAINING";
    const nextStatus = isPaidInFull ? "PAID" : "PARTIALLY_PAID";
    const now = FieldValue.serverTimestamp();
    const paymentPatch = {
      bookingCode: activationBookingCode,
      paymentStatus: nextStatus,
      paidAmount,
      remainingAmount: isPaidInFull ? 0 : remainingAmount,
      lastPaidAmount: payableAmount,
      gatewayTransactionId: razorpayPaymentId,
      transactionCode,
      razorpayPaymentIds: FieldValue.arrayUnion(razorpayPaymentId),
      razorpayOrderIds: FieldValue.arrayUnion(razorpayOrderId),
      activePaymentStatus: "",
      activeRazorpayOrderId: "",
      activePayableAmount: 0,
      activeRemainingAmount: isPaidInFull ? 0 : remainingAmount,
      paidAt: now,
      updatedAt: now,
    };
    const bookingPatch = paidBookingPatch({
      paymentStatus: nextStatus,
      payment,
      payableAmount,
      paidAmount,
      remainingAmount: isPaidInFull ? 0 : remainingAmount,
      razorpayPaymentId,
      razorpayOrderId,
      now,
      activateBooking: previousPaidAmount <= 0,
      bookingCode: activationBookingCode,
    });

    transaction.set(paymentRef, paymentPatch, { merge: true });
    transaction.set(
      paymentTransactionRef,
      {
        transactionId: razorpayPaymentId,
        transactionCode,
        bookingId,
        bookingCode: activationBookingCode,
        customerId: uid,
        paymentId,
        paymentPhase: clean(payment.paymentPhase) || (isPaidInFull ? "FULL" : "INITIAL"),
        paymentType: clean(payment.paymentMode) || "FULL",
        amount: payableAmount,
        gatewayOrderId: razorpayOrderId,
        gatewayPaymentId: razorpayPaymentId,
        status: "SUCCESS",
        currency: "INR",
        createdAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
    transaction.set(ledgerRef, {
      ledgerId: ledgerRef.id,
      eventType: "PAYMENT_CAPTURED",
      bookingId,
      bookingCode: activationBookingCode,
      paymentId,
      customerId: uid,
      amount: payableAmount,
      currency: "INR",
      gatewayOrderId: razorpayOrderId,
      gatewayPaymentId: razorpayPaymentId,
      transactionCode,
      status: "COMPLETED",
      createdAt: now,
    });
    if (previousPaidAmount <= 0) {
      transaction.set(customerPaymentMarkerRef, {
        customerId: uid,
        firstSuccessfulBookingId: bookingId,
        firstSuccessfulPaymentId: paymentId,
        firstSuccessfulPaymentAt: now,
        updatedAt: now,
      }, { merge: true });
    }
    if (previousPaidAmount <= 0 && capturedCouponCode && couponUsageRef) {
      const couponConfig = staticCoupon(capturedCouponCode) || {};
      const breakdown = asObject(payment.financialBreakdown);
      transaction.set(couponUsageRef, {
        usageId: couponUsageRef.id,
        userId: uid,
        customerId: uid,
        bookingId,
        orderId: razorpayOrderId,
        paymentId,
        couponCode: capturedCouponCode,
        discountType: clean(couponConfig.discountType),
        discountValue: positiveInt(couponConfig.discountValue),
        discountAmount: positiveInt(payment.discountAmount),
        cartSubtotal: positiveInt(payment.netAmount || breakdown.netAmount || breakdown.serviceSubtotal),
        finalPayableAmount: positiveInt(payment.finalAmount || breakdown.finalAmount),
        paymentStatus: nextStatus,
        transactionId: razorpayPaymentId,
        gatewayPaymentId: razorpayPaymentId,
        createdAt: now,
        usedAt: now,
      });
    }
    writeBookingCopies(transaction, bookingId, booking, bookingPatch);
    const cartItemId = clean(booking.cartItemId);
    if (previousPaidAmount <= 0 && cartItemId) {
      transaction.delete(
        db.collection(COLLECTIONS.users)
          .doc(uid)
          .collection(COLLECTIONS.customerCart)
          .doc(cartItemId),
      );
    }
  });

  const notifiedBookingSnap = await bookingRef.get();
  const notifiedBooking = notifiedBookingSnap.data() || {};
  await safeCreateAndSendNotification({
    recipientIds: [uid],
    title: "Payment successful",
    body: `${clean(notifiedBooking.serviceTitle) || "Your booking"} payment has been captured successfully.`,
    type: "booking_payment_success",
    source: "system",
    data: {
      bookingId,
      bookingCode: clean(notifiedBooking.bookingCode),
      serviceTitle: clean(notifiedBooking.serviceTitle),
      paymentId,
      transactionId: razorpayPaymentId,
    },
  });
  return { ok: true, bookingId, paymentId };
  }),
);

exports.processRefund = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
  const bookingId = clean(data.bookingId);
  const reason = clean(data.reason) || "Refund requested";
  if (!bookingId) {
    throw new functions.https.HttpsError("invalid-argument", "Booking id is required.");
  }

  const bookingSnap = await db.collection(COLLECTIONS.bookings).doc(bookingId).get();
  const booking = bookingSnap.data();
  if (!booking) {
    throw new functions.https.HttpsError("not-found", "Booking not found.");
  }
  const isOwner = clean(booking.customerId || booking.userId) === uid;
  const isAdmin = await isAdminUser(uid);
  if (!isOwner && !isAdmin) {
    throw new functions.https.HttpsError("permission-denied", "You cannot refund this booking.");
  }

  const paymentSnap = await db.collection(COLLECTIONS.payments).doc(bookingId).get();
  const payment = paymentSnap.data() || {};
  const paymentIds = Array.isArray(payment.razorpayPaymentIds)
    ? payment.razorpayPaymentIds.map((id) => clean(id)).filter((id) => id)
    : [];
  const gatewayPaymentId = clean(payment.gatewayTransactionId) ||
    paymentIds[paymentIds.length - 1] ||
    "";
  const requiresManualRefund = paymentIds.length > 1;
  const refundPolicy = refundPolicyForBooking(booking);
  const completedRefundAmount = await completedRefundAmountForBooking(bookingId);
  const refundableAmount = calculateRefundAmount(booking, payment, completedRefundAmount);
  if (refundableAmount <= 0) {
    throw new functions.https.HttpsError("failed-precondition", "No refundable amount is available.");
  }

  let razorpayRefund = {};
  if (gatewayPaymentId && !requiresManualRefund) {
    razorpayRefund = await razorpayClient().payments.refund(gatewayPaymentId, {
      amount: rupeesToPaise(refundableAmount),
      notes: { bookingId, reason },
    });
  }

  const now = FieldValue.serverTimestamp();
  const refundRef = db.collection(COLLECTIONS.refunds).doc(`${bookingId}_${Date.now()}`);
  const refundBusinessId = await nextHumanId("refund", "REF");
  const refundStatus = gatewayPaymentId && !requiresManualRefund
    ? "PROCESSING"
    : "UNDER_REVIEW";
  await refundRef.set({
    refundId: refundBusinessId,
    refundDocumentId: refundRef.id,
    bookingId,
    paymentId: bookingId,
    customerId: clean(booking.customerId || booking.userId),
    refundAmount: refundableAmount,
    refundReason: reason,
    refundEligibility: refundPolicy.label,
    refundPercentage: refundPolicy.percent,
    refundStatus,
    refundMode: gatewayPaymentId && !requiresManualRefund ? "RAZORPAY" : "MANUAL",
    requiresManualRefund,
    paymentTransactionCount: paymentIds.length,
    requestedBy: uid,
    requestedByRole: isAdmin ? "admin" : "customer",
    razorpayRefundId: clean(razorpayRefund.id),
    ...(refundStatus === "PROCESSING" ? { processedAt: now } : {}),
    createdAt: now,
    updatedAt: now,
  });

  const collectedAmount = collectedAmountForPayment(booking, payment);
  const nextPaymentStatus = refundableAmount >= collectedAmount - completedRefundAmount
    ? "REFUND_PENDING"
    : "PARTIAL_REFUND_PROCESSING";
  const batch = db.batch();
  batch.set(db.collection(COLLECTIONS.payments).doc(bookingId), {
    paymentStatus: nextPaymentStatus,
    refundEligibility: refundPolicy.label,
    refundPercentage: refundPolicy.percent,
    updatedAt: now,
  }, { merge: true });
  writeBookingCopies(batch, bookingId, booking, {
    paymentStatus: nextPaymentStatus,
    "payment.status": nextPaymentStatus,
    refundEligibility: refundPolicy.label,
    refundPercentage: refundPolicy.percent,
    updatedAt: now,
  });
  const ledgerRef = db.collection(COLLECTIONS.financeLedger).doc(`${refundRef.id}_REFUND_REQUESTED`);
  batch.set(ledgerRef, {
    ledgerId: ledgerRef.id,
    eventType: "REFUND_REQUESTED",
    bookingId,
    paymentId: bookingId,
    refundId: refundBusinessId,
    customerId: clean(booking.customerId || booking.userId),
    amount: refundableAmount,
    currency: "INR",
    status: refundStatus,
    createdAt: now,
  });
  await batch.commit();

  return { ok: true, refundId: refundBusinessId, refundAmount: refundableAmount };
  }),
);

exports.verifyBookingOtpAndStart = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "professional");
    const bookingId = clean(data.bookingId);
    const otp = clean(data.otp);
    if (!bookingId || !otp) {
      throw new functions.https.HttpsError("invalid-argument", "Booking id and OTP are required.");
    }

    const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(bookingRef);
      const booking = snapshot.data();
      if (!booking) {
        throw new functions.https.HttpsError("not-found", "Booking not found.");
      }
      if (clean(booking.assignedProfessionalId) !== uid) {
        throw new functions.https.HttpsError("permission-denied", "This booking is not assigned to you.");
      }
      if (!isBookingFullyPaid(booking)) {
        throw new functions.https.HttpsError("failed-precondition", "Booking can start only after full payment.");
      }
      if (clean(booking.otp || booking.bookingOtp) !== otp) {
        throw new functions.https.HttpsError("permission-denied", "Incorrect booking OTP.");
      }
      const durationMinutes = bookingDurationMinutes(booking);
      const now = admin.firestore.Timestamp.now();
      const endAt = admin.firestore.Timestamp.fromMillis(
        now.toMillis() + durationMinutes * 60 * 1000,
      );
      const patch = {
        status: "IN_PROGRESS",
        lifecycleStatus: "in_progress",
        bookingStatus: "in_progress",
        bookingStage: "event_started",
        otpVerified: true,
        otpVerifiedAt: FieldValue.serverTimestamp(),
        startedByProfessionalId: uid,
        startedAt: FieldValue.serverTimestamp(),
        bookingStartTime: now,
        bookingEndTime: endAt,
        bookingDuration: durationMinutes,
        timerStarted: true,
        timerCompleted: false,
        "timeline.startedAt": FieldValue.serverTimestamp(),
        "statusTimeline.professionalStartedAt": FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      };
      writeBookingCopies(transaction, bookingId, booking, patch);
    });
    return { ok: true, bookingId };
  }),
);

exports.endBooking = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "professional");
    const bookingId = clean(data.bookingId);
    if (!bookingId) {
      throw new functions.https.HttpsError("invalid-argument", "Booking id is required.");
    }
    await completeBookingById({
      bookingId,
      actorId: uid,
      actorRole: "professional",
      completionType: "manual",
    });
    return { ok: true, bookingId };
  }),
);

exports.adminManageUserAccount = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    if (!(await isAdminUser(uid))) {
      throw new functions.https.HttpsError("permission-denied", "Admin access is required.");
    }
    const targetUserId = clean(data.targetUserId);
    const targetUserRole = clean(data.targetUserRole).toLowerCase();
    const action = clean(data.action).toUpperCase();
    const reason = clean(data.reason);
    const requestedDocuments = Array.isArray(data.requestedDocuments)
      ? data.requestedDocuments.map(clean).filter(Boolean)
      : [];
    const validRoles = ["customer", "professional"];
    const validActions = {
      professional: [
        "SUSPEND_PROFESSIONAL", "REACTIVATE_PROFESSIONAL", "BLOCK_PROFESSIONAL",
        "UNBLOCK_PROFESSIONAL", "MARK_FEATURED", "REMOVE_FEATURED",
        "VERIFY_DOCUMENTS", "REQUEST_BANK_UPDATE",
      ],
      customer: [
        "SUSPEND_CUSTOMER", "REACTIVATE_CUSTOMER", "BLOCK_CUSTOMER",
        "UNBLOCK_CUSTOMER", "MARK_CUSTOMER_VERIFIED", "REMOVE_CUSTOMER_VERIFIED",
      ],
    };
    if (!targetUserId || !validRoles.includes(targetUserRole)) {
      throw new functions.https.HttpsError("invalid-argument", "A valid target user and role are required.");
    }
    if (!validActions[targetUserRole].includes(action)) {
      throw new functions.https.HttpsError("invalid-argument", "This action is not valid for the selected role.");
    }
    if ((action.startsWith("SUSPEND_") || action.startsWith("BLOCK_") || action === "REQUEST_BANK_UPDATE") && !reason) {
      throw new functions.https.HttpsError("invalid-argument", "A reason is required for this action.");
    }

    const adminSnap = await db.collection(COLLECTIONS.users).doc(uid).get();
    const adminData = adminSnap.data() || {};
    const adminName = clean(adminData.fullName || adminData.name || adminData.displayName || "Admin");
    const userRef = db.collection(COLLECTIONS.users).doc(targetUserId);
    const profileRef = db.collection(COLLECTIONS.professionalProfiles).doc(targetUserId);
    const auditRef = db.collection(COLLECTIONS.adminActionLogs).doc();

    await db.runTransaction(async (transaction) => {
      const userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw new functions.https.HttpsError("not-found", "Target user was not found.");
      }
      const userData = userSnap.data() || {};
      const storedRole = clean(userData.rbacRole || userData.role || userData.userRole).toLowerCase();
      if (
        (targetUserRole === "customer" && storedRole !== "customer") ||
        (targetUserRole === "professional" && !["professional", "professional_pending"].includes(storedRole))
      ) {
        throw new functions.https.HttpsError("failed-precondition", "Target user role does not match this action.");
      }
      let profileData = {};
      if (targetUserRole === "professional") {
        const profileSnap = await transaction.get(profileRef);
        if (!profileSnap.exists) {
          throw new functions.https.HttpsError("not-found", "Professional profile was not found.");
        }
        profileData = profileSnap.data() || {};
      }

      const currentStatus = clean(userData.accountStatus || profileData.accountStatus || "ACTIVE").toUpperCase();
      const userPatch = adminAccountActionPatch({ action, reason, uid, currentStatus, userData });
      const profilePatch = targetUserRole === "professional"
        ? adminProfessionalActionPatch({ action, reason, uid, currentStatus, profileData })
        : null;
      transaction.set(userRef, userPatch, { merge: true });
      if (profilePatch) {
        transaction.set(profileRef, profilePatch, { merge: true });
      }
      transaction.set(auditRef, {
        logId: auditRef.id,
        targetUserId,
        targetUserRole,
        action,
        reason: reason || null,
        metadata: { requestedDocuments },
        requestedDocuments,
        performedByAdminId: uid,
        performedByAdminName: adminName,
        oldValue: currentStatus,
        newValue: clean(userPatch.accountStatus || action),
        createdAt: FieldValue.serverTimestamp(),
      });
    });
    const actionTitles = {
      SUSPEND_PROFESSIONAL: "Account suspended",
      BLOCK_PROFESSIONAL: "Account blocked",
      REACTIVATE_PROFESSIONAL: "Account reactivated",
      UNBLOCK_PROFESSIONAL: "Account unblocked",
      REQUEST_BANK_UPDATE: "Bank details update requested",
      SUSPEND_CUSTOMER: "Account suspended",
      BLOCK_CUSTOMER: "Account blocked",
      REACTIVATE_CUSTOMER: "Account reactivated",
      UNBLOCK_CUSTOMER: "Account unblocked",
    };
    await safeCreateAndSendNotification({
      recipientIds: [targetUserId],
      title: actionTitles[action] || "Account update",
      body: reason || "Admin has updated your ClickNow account status.",
      type: "account_status_updated",
      source: "admin",
      sentByAdminId: uid,
      data: {
        action,
        targetUserRole,
        requestedDocuments,
        recipientRole: targetUserRole,
        deepLink: "",
      },
    });
    return { ok: true, action, targetUserId };
  }),
);

exports.sendAdminCustomNotification = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "admin");
    const title = clean(data.title);
    const body = clean(data.body);
    const recipientType = clean(data.recipientType || "all_customers").toLowerCase();
    const selectedUserIds = Array.isArray(data.selectedUserIds)
      ? data.selectedUserIds.map(clean).filter(Boolean)
      : [];
    if (!title || !body) {
      throw new functions.https.HttpsError("invalid-argument", "Title and message are required.");
    }
    if (!["all_customers", "all_professionals", "selected_users"].includes(recipientType)) {
      throw new functions.https.HttpsError("invalid-argument", "Recipient type is invalid.");
    }
    if (recipientType === "selected_users" && selectedUserIds.length === 0) {
      throw new functions.https.HttpsError("invalid-argument", "Select at least one user.");
    }

    const recipients = await resolveNotificationRecipients(recipientType, selectedUserIds);
    const campaignRef = db.collection(COLLECTIONS.notificationCampaigns).doc();
    await campaignRef.set({
      campaignId: campaignRef.id,
      title,
      body,
      recipientType,
      selectedUserIds,
      totalRecipients: recipients.length,
      totalTokens: 0,
      successCount: 0,
      failureCount: 0,
      status: "SENDING",
      createdByAdminId: uid,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    const result = await createAndSendNotification({
      recipientIds: recipients,
      title,
      body,
      type: "admin_custom",
      source: "admin",
      imageUrl: clean(data.imageUrl),
      deepLinkRoute: clean(data.deepLinkRoute),
      sentByAdminId: uid,
      campaignId: campaignRef.id,
      data: asObject(data.data),
    });
    await campaignRef.set({
      totalTokens: result.totalTokens,
      successCount: result.successCount,
      failureCount: result.failureCount,
      status: result.failureCount > 0 && result.successCount === 0 ? "FAILED" : "SENT",
      completedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return {
      ok: true,
      campaignId: campaignRef.id,
      totalRecipients: recipients.length,
      ...result,
    };
  }),
);

exports.submitRequestedDocumentReupload = functions.https.onRequest(
  paymentRequestHandler(async () => {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Document re-upload requests are no longer supported.",
    );
  }),
);

exports.adminUpdateRefund = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "admin");
    const refundDocumentId = clean(data.refundId);
    const action = clean(data.action).toUpperCase();
    const remarks = clean(data.remarks);
    if (!refundDocumentId || !["APPROVE", "REJECT", "COMPLETE"].includes(action)) {
      throw new functions.https.HttpsError("invalid-argument", "A valid refund action is required.");
    }
    if (!remarks) {
      throw new functions.https.HttpsError("invalid-argument", "Admin remarks are required.");
    }
    const refundRef = db.collection(COLLECTIONS.refunds).doc(refundDocumentId);
    await db.runTransaction(async (transaction) => {
      const refundSnap = await transaction.get(refundRef);
      const refund = refundSnap.data();
      if (!refund) {
        throw new functions.https.HttpsError("not-found", "Refund not found.");
      }
      if (action === "COMPLETE" && clean(refund.refundStatus).toUpperCase() === "COMPLETED") {
        return;
      }
      const now = FieldValue.serverTimestamp();
      const nextStatus = action === "APPROVE"
        ? "APPROVED"
        : action === "REJECT"
          ? "REJECTED"
          : "COMPLETED";
      const refundPatch = {
        refundStatus: nextStatus,
        approvedBy: uid,
        adminRemarks: remarks,
        ...(action === "APPROVE" ? { approvedAt: now } : {}),
        ...(action === "REJECT" ? { rejectedAt: now } : {}),
        ...(action === "COMPLETE" ? { completedAt: now } : {}),
        updatedAt: now,
      };
      if (action !== "COMPLETE") {
        transaction.set(refundRef, refundPatch, { merge: true });
        return;
      }
      const bookingId = clean(refund.bookingId);
      const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
      const paymentRef = db.collection(COLLECTIONS.payments).doc(clean(refund.paymentId) || bookingId);
      const bookingSnap = await transaction.get(bookingRef);
      const paymentSnap = await transaction.get(paymentRef);
      const booking = bookingSnap.data() || {};
      const payment = paymentSnap.data() || {};
      const paidAmount = collectedAmountForPayment(booking, payment);
      const completedRefundAmount = positiveInt(payment.completedRefundAmount) +
        positiveInt(refund.refundAmount);
      const paymentStatus = completedRefundAmount >= paidAmount
        ? "REFUNDED"
        : "PARTIALLY_REFUNDED";
      transaction.set(refundRef, refundPatch, { merge: true });
      transaction.set(paymentRef, {
        paymentStatus,
        completedRefundAmount,
        updatedAt: now,
      }, { merge: true });
      writeBookingCopies(transaction, bookingId, booking, {
        paymentStatus,
        "payment.status": paymentStatus,
        completedRefundAmount,
        updatedAt: now,
      });
      const ledgerRef = db.collection(COLLECTIONS.financeLedger).doc(`${refundDocumentId}_REFUND_COMPLETED`);
      transaction.set(ledgerRef, {
        ledgerId: ledgerRef.id,
        eventType: "REFUND_COMPLETED",
        bookingId,
        paymentId: clean(refund.paymentId) || bookingId,
        refundId: clean(refund.refundId) || refundDocumentId,
        customerId: clean(refund.customerId),
        amount: positiveInt(refund.refundAmount),
        currency: "INR",
        status: "COMPLETED",
        createdAt: now,
      });
    });
    const refundSnap = await refundRef.get();
    const refund = refundSnap.data() || {};
    if (["APPROVE", "COMPLETE"].includes(action)) {
      await safeCreateAndSendNotification({
        recipientIds: [clean(refund.customerId)],
        title: action === "COMPLETE" ? "Refund completed" : "Refund approved",
        body: `Refund of Rs.${positiveInt(refund.refundAmount)} has been ${action === "COMPLETE" ? "completed" : "approved"}.`,
        type: action === "COMPLETE" ? "refund_completed" : "refund_approved",
        source: "system",
        data: {
          bookingId: clean(refund.bookingId),
          refundId: clean(refund.refundId) || refundDocumentId,
          amount: positiveInt(refund.refundAmount),
        },
      });
    }
    return { ok: true, refundId: refundDocumentId, action };
  }),
);

exports.releaseProfessionalPayout = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "admin");
    const payrollDocumentId = clean(data.payrollDocumentId || data.payrollId);
    const transactionReference = clean(data.transactionReference);
    if (!payrollDocumentId || !transactionReference) {
      throw new functions.https.HttpsError("invalid-argument", "Payroll and transaction reference are required.");
    }
    const payrollRef = db.collection(COLLECTIONS.payrolls).doc(payrollDocumentId);
    const stipendRef = db.collection(COLLECTIONS.stipendSlips).doc(payrollDocumentId);
    await db.runTransaction(async (transaction) => {
      const payrollSnap = await transaction.get(payrollRef);
      const payroll = payrollSnap.data();
      if (!payroll) {
        throw new functions.https.HttpsError("not-found", "Payroll not found.");
      }
      if (clean(payroll.payoutStatus).toUpperCase() === "RELEASED") {
        return;
      }
      const bookingId = clean(payroll.bookingId);
      const bookingSnap = await transaction.get(db.collection(COLLECTIONS.bookings).doc(bookingId));
      const paymentSnap = await transaction.get(db.collection(COLLECTIONS.payments).doc(bookingId));
      const financeBooking = bookingWithAuthoritativePayment(
        bookingSnap.data() || {},
        paymentSnap.data() || {},
      );
      if (!isBookingFullyPaidForPayroll(financeBooking)) {
        throw new functions.https.HttpsError("failed-precondition", "Payout requires full customer payment.");
      }
      const now = FieldValue.serverTimestamp();
      const payrollBusinessId = clean(payroll.payrollId) || payrollDocumentId;
      transaction.set(payrollRef, {
        payoutStatus: "RELEASED",
        releasedAt: now,
        releasedBy: uid,
        transactionReference,
        stipendSlipId: payrollBusinessId,
        professionalConfirmationStatus: "PENDING",
        professionalConfirmationComment: "",
        professionalDisputeReason: "",
        professionalConfirmedAt: FieldValue.delete(),
        professionalDisputedAt: FieldValue.delete(),
        professionalConfirmationUpdatedAt: now,
      }, { merge: true });
      transaction.set(stipendRef, {
        stipendSlipId: payrollBusinessId,
        payrollId: payrollBusinessId,
        payrollDocumentId,
        professionalId: clean(payroll.professionalId),
        pdfUrl: "",
        pdfGenerationStatus: "PENDING_BACKEND",
        generatedAt: now,
      });
      const ledgerRef = db.collection(COLLECTIONS.financeLedger).doc(`${payrollDocumentId}_PAYOUT_RELEASED`);
      transaction.set(ledgerRef, {
        ledgerId: ledgerRef.id,
        eventType: "PAYOUT_RELEASED",
        bookingId,
        payrollId: clean(payroll.payrollId) || payrollDocumentId,
        professionalId: clean(payroll.professionalId),
        amount: positiveInt(payroll.netPayoutAmount),
        currency: "INR",
        transactionReference,
        status: "COMPLETED",
        createdAt: now,
      });
    });
    const payrollSnap = await payrollRef.get();
    const payroll = payrollSnap.data() || {};
    await safeCreateAndSendNotification({
      recipientIds: [clean(payroll.professionalId)],
      title: "Payroll released",
      body: `Your payout of Rs.${positiveInt(payroll.netPayoutAmount)} has been released.`,
      type: "payroll_released",
      source: "system",
      data: {
        payrollId: clean(payroll.payrollId) || payrollDocumentId,
        bookingId: clean(payroll.bookingId),
        amount: positiveInt(payroll.netPayoutAmount),
      },
    });
    return { ok: true, payrollId: payrollDocumentId };
  }),
);

exports.confirmProfessionalPayout = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "professional");
    const payrollDocumentId = clean(data.payrollDocumentId || data.payrollId);
    const action = clean(data.action).toUpperCase();
    const comment = clean(data.comment);
    const reason = clean(data.reason);
    if (!payrollDocumentId || !["CONFIRM", "DISPUTE"].includes(action)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid payroll confirmation action is required.",
      );
    }
    if (action === "DISPUTE" && !reason) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "A reason is required to report a payout issue.",
      );
    }

    const payrollRef = db.collection(COLLECTIONS.payrolls).doc(payrollDocumentId);
    await db.runTransaction(async (transaction) => {
      const payrollSnap = await transaction.get(payrollRef);
      const payroll = payrollSnap.data();
      if (!payroll) {
        throw new functions.https.HttpsError("not-found", "Payroll not found.");
      }
      if (clean(payroll.professionalId) !== uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "This payroll does not belong to the signed-in professional.",
        );
      }
      if (clean(payroll.payoutStatus).toUpperCase() !== "RELEASED") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Only a released payout can be confirmed or disputed.",
        );
      }
      if (clean(payroll.professionalConfirmationStatus).toUpperCase() === "CONFIRMED") {
        throw new functions.https.HttpsError(
          "already-exists",
          "This payout has already been confirmed.",
        );
      }

      const now = FieldValue.serverTimestamp();
      const nextStatus = action === "CONFIRM" ? "CONFIRMED" : "DISPUTED";
      const payrollPatch = action === "CONFIRM"
        ? {
            professionalConfirmationStatus: nextStatus,
            professionalConfirmationComment: comment,
            professionalConfirmedAt: now,
            professionalDisputeReason: "",
            professionalDisputedAt: FieldValue.delete(),
            professionalConfirmationUpdatedAt: now,
          }
        : {
            professionalConfirmationStatus: nextStatus,
            professionalDisputeReason: reason,
            professionalDisputedAt: now,
            professionalConfirmationUpdatedAt: now,
          };
      transaction.set(payrollRef, payrollPatch, { merge: true });

      const ledgerRef = db.collection(COLLECTIONS.financeLedger)
        .doc(`${payrollDocumentId}_PAYOUT_${nextStatus}`);
      transaction.set(ledgerRef, {
        ledgerId: ledgerRef.id,
        eventType: action === "CONFIRM" ? "PAYOUT_CONFIRMED" : "PAYOUT_DISPUTED",
        bookingId: clean(payroll.bookingId),
        payrollId: clean(payroll.payrollId) || payrollDocumentId,
        professionalId: uid,
        amount: positiveInt(payroll.netPayoutAmount),
        currency: "INR",
        status: nextStatus,
        comment: action === "CONFIRM" ? comment : reason,
        createdAt: now,
      });
    });

    return {
      ok: true,
      payrollId: payrollDocumentId,
      professionalConfirmationStatus: action === "CONFIRM" ? "CONFIRMED" : "DISPUTED",
    };
  }),
);

exports.reconcileCompletedBookingFinancials = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    await requireActiveAccount(uid, "admin");
    const bookingId = clean(data.bookingId);
    if (!bookingId) {
      throw new functions.https.HttpsError("invalid-argument", "Booking id is required.");
    }
    await completeBookingById({
      bookingId,
      actorId: uid,
      actorRole: "system",
      completionType: "financial_reconciliation",
    });
    return { ok: true, bookingId };
  }),
);

exports.markInvoiceDownloaded = functions.https.onRequest(
  paymentRequestHandler(async (data, uid) => {
    const invoiceId = clean(data.invoiceId);
    if (!invoiceId) {
      throw new functions.https.HttpsError("invalid-argument", "Invoice id is required.");
    }
    const invoiceRef = db.collection(COLLECTIONS.invoices).doc(invoiceId);
    const invoiceSnap = await invoiceRef.get();
    const invoice = invoiceSnap.data();
    if (!invoice) {
      throw new functions.https.HttpsError("not-found", "Invoice not found.");
    }
    const isOwner = clean(invoice.customerId) === uid;
    if (!isOwner && !(await isAdminUser(uid))) {
      throw new functions.https.HttpsError("permission-denied", "You cannot update this invoice.");
    }
    await invoiceRef.set({
      invoiceStatus: "DOWNLOADED",
      downloadedAt: FieldValue.serverTimestamp(),
      downloadedBy: uid,
    }, { merge: true });
    return { ok: true, invoiceId };
  }),
);

exports.autoCompleteExpiredBookings = onSchedule("every 5 minutes", async () => {
  const now = admin.firestore.Timestamp.now();
  const snapshot = await db.collection(COLLECTIONS.bookings)
    .where("status", "==", "IN_PROGRESS")
    .where("bookingEndTime", "<=", now)
    .limit(50)
    .get();
  for (const doc of snapshot.docs) {
    await completeBookingById({
      bookingId: doc.id,
      actorId: "system",
      actorRole: "system",
      completionType: "automatic",
    });
  }
});

exports.recalculateServiceStatsOnBookingWrite = functionsV1.firestore
  .document(`${COLLECTIONS.bookings}/{bookingId}`)
  .onWrite(async (change) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const serviceIds = new Set([
      clean(before.serviceCatalogId),
      clean(after.serviceCatalogId),
    ]);
    await Promise.all([...serviceIds].filter(Boolean).map(recalculateServiceStats));
  });

exports.recalculateServiceStatsOnReviewWrite = functionsV1.firestore
  .document(`${COLLECTIONS.reviews}/{reviewId}`)
  .onWrite(async (change) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const serviceIds = new Set([
      clean(before.serviceCatalogId),
      clean(after.serviceCatalogId),
    ]);
    await Promise.all([...serviceIds].filter(Boolean).map(recalculateServiceStats));
  });

exports.razorpayWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const webhookSecret =
      process.env.RAZORPAY_WEBHOOK_SECRET;
    if (!webhookSecret) {
      res.status(500).send("Webhook secret not configured");
      return;
    }
    const signature = req.get("x-razorpay-signature") || "";
    const body = JSON.stringify(req.body);
    const expected = crypto.createHmac("sha256", webhookSecret).update(body).digest("hex");
    if (signature !== expected) {
      res.status(401).send("Invalid signature");
      return;
    }

    const event = clean(req.body.event);
    const paymentEntity = req.body.payload?.payment?.entity || {};
    const orderId = clean(paymentEntity.order_id);
    if (event === "payment.failed" && orderId) {
      const snap = await db.collection(COLLECTIONS.payments)
        .where("activeRazorpayOrderId", "==", orderId)
        .limit(1)
        .get();
      for (const doc of snap.docs) {
        const payment = doc.data();
        const bookingId = clean(payment.bookingId || doc.id);
        const bookingSnap = await db.collection(COLLECTIONS.bookings).doc(bookingId).get();
        const booking = bookingSnap.data() || {};
        const currentStatus = clean(payment.paymentStatus).toUpperCase();
        const nextPaymentStatus = ["PAID", "FULLY_PAID"].includes(currentStatus)
          ? currentStatus
          : positiveInt(payment.paidAmount) > 0
            ? "PARTIALLY_PAID"
            : "PAYMENT_FAILED";
        const failurePatch = {
          paymentStatus: nextPaymentStatus,
          "payment.status": nextPaymentStatus,
          "payment.activePaymentStatus": "FAILED",
          "payment.failureReason": clean(
            paymentEntity.error_description || paymentEntity.error_reason,
          ),
          failureReason: clean(paymentEntity.error_description || paymentEntity.error_reason),
          ...(positiveInt(payment.paidAmount) <= 0
            ? {
                status: "DRAFT",
                lifecycleStatus: "payment_failed",
                bookingStatus: "payment_failed",
                bookingStage: "payment_failed",
                adminVisible: false,
              }
            : {}),
          updatedAt: FieldValue.serverTimestamp(),
        };
        if (positiveInt(payment.paidAmount) > 0) {
          await updateBookingCopies(bookingId, booking, failurePatch);
        } else {
          await db.collection(COLLECTIONS.bookings).doc(bookingId).set(
            failurePatch,
            { merge: true },
          );
        }
        const failureLedgerRef = db
          .collection(COLLECTIONS.financeLedger)
          .doc(`${bookingId}_${clean(paymentEntity.id) || orderId}_PAYMENT_FAILED`);
        const batch = db.batch();
        batch.set(doc.ref, {
          paymentStatus: nextPaymentStatus,
          activePaymentStatus: "FAILED",
          failureReason: clean(paymentEntity.error_description || paymentEntity.error_reason),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        batch.set(failureLedgerRef, {
          ledgerId: failureLedgerRef.id,
          eventType: "PAYMENT_FAILED",
          bookingId,
          paymentId: clean(payment.paymentId) || bookingId,
          customerId: clean(payment.customerId),
          amount: positiveInt(payment.activePayableAmount),
          currency: "INR",
          gatewayOrderId: orderId,
          gatewayPaymentId: clean(paymentEntity.id),
          status: "FAILED",
          failureReason: clean(paymentEntity.error_description || paymentEntity.error_reason),
          createdAt: FieldValue.serverTimestamp(),
        });
        await batch.commit();
      }
    }
    res.status(200).send("ok");
  } catch (error) {
    console.error(error);
    res.status(500).send("Webhook failed");
  }
});

async function createOrReuseOrder({
  bookingId,
  booking,
  customerId,
  paymentMode,
  paymentPhase,
  payableAmount,
  remainingAmount,
  totalAmount,
  discountAmount,
  couponCode,
  pricingSnapshot,
  orderCode,
}) {
  const paymentRef = db.collection(COLLECTIONS.payments).doc(bookingId);
  const paymentSnap = await paymentRef.get();
  const existing = paymentSnap.data();
  const existingOrderStatus = clean(existing?.activePaymentStatus || existing?.paymentStatus)
    .toUpperCase();
  if (
    existing &&
    existingOrderStatus === "CREATED" &&
    clean(existing.activeRazorpayOrderId) &&
    positiveInt(existing.activePayableAmount) === payableAmount &&
    clean(existing.paymentMode) === paymentMode &&
    clean(existing.couponCode).toUpperCase() === clean(couponCode).toUpperCase()
  ) {
    return orderResponse({ bookingId, booking, payment: existing });
  }

  let order;
  try {
    order = await razorpayClient().orders.create({
      amount: rupeesToPaise(payableAmount),
      currency: "INR",
      receipt: `${bookingId.substring(0, 24)}_${Date.now()}`,
      payment_capture: 1,
      notes: {
        bookingId,
        customerId,
        paymentMode,
        paymentPhase,
      },
    });
  } catch (error) {
    razorpayProviderError(error, "order creation");
  }
  const now = FieldValue.serverTimestamp();
  const bookingPayment = asObject(booking.payment);
  const normalizedPaymentMode = clean(paymentMode).toUpperCase();
  const suppliedPricing = asObject(pricingSnapshot);
  const breakdown = Object.keys(suppliedPricing).length > 0
    ? suppliedPricing
    : buildFinancialBreakdown({
        totalAmount,
        paymentMode: normalizedPaymentMode,
        discountAmount,
        couponCode,
      });
  const effectivePayableAmount =
    normalizedPaymentMode === "REMAINING" ? payableAmount : breakdown.payableAmount;
  const effectiveRemainingAmount =
    normalizedPaymentMode === "REMAINING" ? 0 : breakdown.remainingAmount;
  const existingPaymentStatus = clean(
    existing?.paymentStatus ||
      booking.paymentStatus ||
      bookingPayment.status,
  ).toUpperCase();
  const pendingBookingPaymentStatus =
    normalizedPaymentMode === "REMAINING" && existingPaymentStatus
      ? existingPaymentStatus
      : "PENDING_PAYMENT";
  const pendingPaymentDocumentStatus =
    normalizedPaymentMode === "REMAINING" && existingPaymentStatus
      ? existingPaymentStatus
      : "CREATED";
  const existingDepositAmount = positiveInt(
    existing?.depositAmount ||
      booking.depositAmount ||
      bookingPayment.depositAmount,
  );
  const preservedDepositAmount = normalizedPaymentMode === "ADVANCE_20"
    ? payableAmount
    : existingDepositAmount;
  const existingPaidAmount = positiveInt(
    existing?.paidAmount ||
      booking.paidAmount ||
      bookingPayment.paidAmount,
  );
  const hasDepositPaid = existingPaidAmount > 0 ||
    booking.depositPaid === true ||
    bookingPayment.depositPaid === true;
  const payment = {
    paymentId: bookingId,
    bookingId,
    bookingCode: clean(booking.bookingCode),
    orderCode: clean(orderCode),
    customerId,
    grossAmount: breakdown.grossAmount,
    netAmount: breakdown.netAmount,
    taxableAmount: breakdown.taxableAmount,
    gstPercent: breakdown.gstPercent,
    originalGstAmount: breakdown.originalGstAmount,
    gstAmount: breakdown.gstAmount,
    finalAmount: breakdown.finalAmount,
    totalAmount,
    discountAmount: breakdown.discountAmount,
    couponCode: breakdown.couponCode,
    payableAmount: effectivePayableAmount,
    paidAmount: existingPaidAmount,
    remainingAmount: effectiveRemainingAmount,
    depositAmount: preservedDepositAmount,
    finalPayableAmount: breakdown.finalAmount,
    paymentMode: normalizedPaymentMode,
    paymentPhase,
    paymentMethod: "online",
    paymentGateway: "razorpay",
    paymentStatus: pendingPaymentDocumentStatus,
    activePaymentStatus: "CREATED",
    activeRazorpayOrderId: order.id,
    activePayableAmount: effectivePayableAmount,
    activeRemainingAmount: effectiveRemainingAmount,
    currency: "INR",
    commissionPercent: breakdown.commissionPercent,
    commissionAmount: breakdown.commissionAmount,
    professionalPayoutAmount: breakdown.professionalPayoutAmount,
    financialBreakdown: breakdown,
    createdAt: existing?.createdAt || now,
    updatedAt: now,
  };
  const bookingRef = db.collection(COLLECTIONS.bookings).doc(bookingId);
  const orderLedgerRef = db
    .collection(COLLECTIONS.financeLedger)
    .doc(`${bookingId}_${order.id}_ORDER_CREATED`);
  const bookingPatch = {
    ...(existingPaidAmount <= 0
      ? {
          status: "DRAFT",
          lifecycleStatus: "payment_pending",
          bookingStatus: "payment_pending",
          bookingStage: "payment_order_created",
          adminVisible: false,
        }
      : {}),
    paymentStatus: pendingBookingPaymentStatus,
    paymentMode: normalizedPaymentMode,
    paymentGateway: "razorpay",
    couponCode: breakdown.couponCode,
    "payment.status": pendingBookingPaymentStatus,
    "payment.mode": normalizedPaymentMode,
    "payment.gateway": "razorpay",
    "payment.payableAmount": effectivePayableAmount,
    "payment.remainingAmount": effectiveRemainingAmount,
    "payment.discountAmount": breakdown.discountAmount,
    "payment.couponCode": breakdown.couponCode,
    "payment.financialBreakdown": breakdown,
    totalAmount,
    discountAmount: breakdown.discountAmount,
    finalAmount: breakdown.finalAmount,
    depositAmount: preservedDepositAmount,
    remainingAmount: effectiveRemainingAmount,
    depositPaid: hasDepositPaid,
    remainingPaid: false,
    netAmount: breakdown.netAmount,
    gstAmount: breakdown.gstAmount,
    commissionAmount: breakdown.commissionAmount,
    professionalPayoutAmount: breakdown.professionalPayoutAmount,
    financialBreakdown: breakdown,
    pricingSnapshot: {
      ...breakdown,
      paymentOption: normalizedPaymentMode,
      locked: true,
      lockedAt: now,
    },
    updatedAt: now,
  };
  const batch = db.batch();
  batch.set(paymentRef, payment, { merge: true });
  batch.set(bookingRef, bookingPatch, { merge: true });
  batch.set(orderLedgerRef, {
    ledgerId: orderLedgerRef.id,
    eventType: "ORDER_CREATED",
    bookingId,
    paymentId: bookingId,
    bookingCode: clean(booking.bookingCode),
    orderCode: clean(orderCode),
    customerId,
    amount: effectivePayableAmount,
    currency: "INR",
    gatewayOrderId: order.id,
    status: "CREATED",
    createdAt: now,
  });
  await batch.commit();
  return orderResponse({ bookingId, booking, payment });
}

function orderResponse({ bookingId, booking, payment }) {
  const customer = asObject(booking.customer);
  const breakdown = asObject(payment.financialBreakdown);
  return {
    paymentId: clean(payment.paymentId) || bookingId,
    bookingId,
    bookingCode: clean(booking.bookingCode),
    orderId: clean(payment.activeRazorpayOrderId),
    orderCode: clean(payment.orderCode),
    keyId: configuredRazorpayKeyId(),
    amountPaise: rupeesToPaise(positiveInt(payment.activePayableAmount)),
    currency: "INR",
    customerName: clean(customer.name || booking.customerName),
    customerEmail: clean(customer.email || booking.customerEmail),
    customerPhone: clean(customer.phoneNumber || customer.phone || booking.customerPhone),
    description: `${clean(booking.serviceTitle) || "ClickNow booking"} payment`,
    paymentMode: clean(payment.paymentMode),
    totalAmount: positiveInt(payment.totalAmount || payment.finalAmount),
    payableAmount: positiveInt(payment.activePayableAmount),
    remainingAmount: positiveInt(payment.activeRemainingAmount),
    discountAmount: positiveInt(payment.discountAmount),
    netAmount: positiveInt(payment.netAmount || breakdown.netAmount),
    gstAmount: positiveInt(payment.gstAmount || breakdown.gstAmount),
    commissionAmount: positiveInt(payment.commissionAmount || breakdown.commissionAmount),
    professionalPayoutAmount: positiveInt(
      payment.professionalPayoutAmount || breakdown.professionalPayoutAmount,
    ),
    financialBreakdown: breakdown,
  };
}

function paidBookingPatch({
  paymentStatus,
  payment,
  payableAmount,
  paidAmount,
  remainingAmount,
  razorpayPaymentId,
  razorpayOrderId,
  now,
  activateBooking,
  bookingCode,
}) {
  const mode = clean(payment.paymentMode);
  const isAdvance = mode === "ADVANCE_20";
  const isRemaining = mode === "REMAINING";
  const isFull = paymentStatus === "PAID";
  const breakdown = asObject(payment.financialBreakdown);
  const finalAmount = positiveInt(
    payment.finalPayableAmount || payment.finalAmount || breakdown.finalAmount,
  );
  const otp = isFull
    ? clean(payment.otp || payment.bookingOtp) || generateBookingOtp()
    : "";
  return {
    ...(activateBooking
      ? {
          status: "REQUESTED",
          lifecycleStatus: "requested",
          bookingStatus: "requested",
          bookingStage: "booking_request_submitted",
          adminVisible: true,
          bookingCode,
          "timeline.requestedAt": now,
          "statusTimeline.bookingRequestSubmittedAt": now,
        }
      : {}),
    paymentStatus,
    paymentMode: mode,
    paymentGateway: "razorpay",
    gatewayTransactionId: razorpayPaymentId,
    totalAmount: positiveInt(payment.totalAmount || payment.finalAmount),
    discountAmount: positiveInt(payment.discountAmount),
    finalAmount,
    depositAmount: isAdvance ? payableAmount : positiveInt(payment.depositAmount),
    remainingAmount,
    paidAmount,
    depositPaid: isAdvance || isFull || positiveInt(payment.paidAmount) > 0,
    remainingPaid: isFull || isRemaining,
    "payment.status": paymentStatus,
    "payment.mode": mode,
    "payment.gateway": "razorpay",
    "payment.paidAmount": paidAmount,
    "payment.lastPaidAmount": payableAmount,
    "payment.remainingAmount": remainingAmount,
    "payment.discountAmount": positiveInt(payment.discountAmount),
    "payment.couponCode": clean(payment.couponCode),
    "payment.financialBreakdown": breakdown,
    "payment.netAmount": breakdown.netAmount,
    "payment.gstAmount": breakdown.gstAmount,
    "payment.commissionPercent": breakdown.commissionPercent,
    "payment.commissionAmount": breakdown.commissionAmount,
    "payment.professionalPayoutAmount": breakdown.professionalPayoutAmount,
    "payment.depositPaid": isAdvance || isFull || positiveInt(payment.paidAmount) > 0,
    "payment.remainingPaid": isFull || isRemaining,
    "payment.finalAmount": finalAmount,
    "payment.depositAmount": isAdvance ? payableAmount : positiveInt(payment.depositAmount),
    "payment.razorpayPaymentIds": FieldValue.arrayUnion(razorpayPaymentId),
    "payment.razorpayOrderIds": FieldValue.arrayUnion(razorpayOrderId),
    "payment.paidAt": now,
    pricingSnapshot: {
      ...breakdown,
      locked: true,
      pricingVersion: clean(breakdown.pricingVersion) || "v1",
    },
    ...(isFull
      ? {
          otp,
          bookingOtp: otp,
          otpGeneratedAt: now,
          otpVerified: false,
          "payment.otpReady": true,
        }
      : {
          "payment.otpReady": false,
        }),
    updatedAt: now,
  };
}

async function resolveCoupon({ couponCode, customerId, booking, totalAmount }) {
  const existingCoupon = clean(
    booking.couponCode ||
      asObject(booking.payment).couponCode ||
      asObject(booking.pricingSnapshot).couponCode,
  );
  const pricingLocked = asObject(booking.pricingSnapshot).locked === true;
  if (!couponCode) {
    if (existingCoupon && pricingLocked) {
      throw new functions.https.HttpsError("failed-precondition", "Coupon is locked for this booking.");
    }
    return { appliedCode: "", discountAmount: 0 };
  }
  if (existingCoupon && existingCoupon !== couponCode) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Only one coupon can be applied per booking.",
    );
  }
  if (existingCoupon === couponCode && pricingLocked) {
    return {
      appliedCode: existingCoupon,
      discountAmount: positiveInt(
        asObject(booking.pricingSnapshot).couponDiscountAmount ||
          asObject(booking.pricingSnapshot).discountAmount ||
          asObject(booking.payment).discountAmount,
      ),
    };
  }
  const paymentStatus = clean(booking.paymentStatus || asObject(booking.payment).status).toUpperCase();
  if (existingCoupon && paymentStatus && paymentStatus !== "PENDING_PAYMENT") {
    throw new functions.https.HttpsError("failed-precondition", "Coupon is locked for this booking.");
  }
  const coupon = staticCoupon(couponCode);
  if (!coupon || coupon.active === false) {
    throw new functions.https.HttpsError("failed-precondition", "Invalid coupon code.");
  }
  const now = Date.now();
  const startsAt = toMillis(coupon.startsAt);
  const endsAt = toMillis(coupon.endsAt);
  if ((startsAt && now < startsAt) || (endsAt && now > endsAt)) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "This coupon has expired or is not active.",
    );
  }
  const minOrderAmount = positiveInt(coupon.minOrderAmount);
  if (minOrderAmount > 0 && totalAmount < minOrderAmount) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Minimum booking amount not reached.",
    );
  }
  const allowedServices = Array.isArray(coupon.serviceCatalogIds) ? coupon.serviceCatalogIds : [];
  if (allowedServices.length && !couponServiceMatches(booking, allowedServices)) {
    throw new functions.https.HttpsError("failed-precondition", "Invalid items for this code.");
  }
  const usageLimit = positiveInt(coupon.usageLimit);
  const usedCount = positiveInt(coupon.usedCount);
  if (usageLimit > 0 && usedCount >= usageLimit) {
    throw new functions.https.HttpsError("failed-precondition", "Coupon usage limit reached.");
  }
  if (coupon.firstTimeOnly === true) {
    const marker = await db.collection(COLLECTIONS.customerPaymentMarkers).doc(customerId).get();
    if (marker.exists) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "This coupon is valid only for first-time users.",
      );
    }
    const previousSuccess = await db
      .collection(COLLECTIONS.paymentTransactions)
      .where("customerId", "==", customerId)
      .where("status", "==", "SUCCESS")
      .limit(1)
      .get();
    if (!previousSuccess.empty) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "This coupon is valid only for first-time users.",
      );
    }
  }
  const customerUsage = asObject(coupon.customerUsage);
  const legacyUsageCount = positiveInt(customerUsage[customerId]);
  const perCustomerLimit = positiveInt(
    coupon.perCustomerLimit || (staticConfig ? 0 : 1),
  );
  if (perCustomerLimit > 0 && legacyUsageCount >= perCustomerLimit) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      `You have already used this coupon ${perCustomerLimit} times.`,
    );
  }
  if (perCustomerLimit > 0) {
    const usageSnap = await db
      .collection(COLLECTIONS.couponUsages)
      .where("customerId", "==", customerId)
      .where("couponCode", "==", couponCode)
      .get();
    if (legacyUsageCount + usageSnap.size >= perCustomerLimit) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `You have already used this coupon ${perCustomerLimit} times.`,
      );
    }
  }

  const discountType = clean(coupon.discountType).toUpperCase();
  const discountValue = positiveInt(coupon.discountValue);
  const maxDiscountAmount = positiveInt(coupon.maxDiscountAmount);
  let discountAmount = discountType === "PERCENT"
    ? Math.round(totalAmount * discountValue / 100)
    : discountValue;
  if (maxDiscountAmount > 0) {
    discountAmount = Math.min(discountAmount, maxDiscountAmount);
  }
  discountAmount = Math.max(0, Math.min(Math.max(0, totalAmount - 1), discountAmount));
  return { appliedCode: couponCode, discountAmount };
}

function staticCoupon(couponCode) {
  const coupons = {
    CLICKNOW10: {
      active: true,
      discountType: "PERCENT",
      discountValue: 10,
      maxDiscountAmount: 1500,
      minOrderAmount: 0,
      serviceCatalogIds: [],
      firstTimeOnly: true,
      perCustomerLimit: 1,
      showOnUi: true,
    },
    STEALDEAL5: {
      active: true,
      discountType: "PERCENT",
      discountValue: 5,
      maxDiscountAmount: 0,
      minOrderAmount: 0,
      serviceCatalogIds: [],
      perCustomerLimit: 2,
      showOnUi: true,
    },
    ACT500: {
      active: true,
      discountType: "FLAT",
      discountValue: 500,
      minOrderAmount: 2000,
      serviceCatalogIds: ["magician", "anchor", "musician"],
      showOnUi: true,
    },
    TALENT1000: {
      active: true,
      discountType: "FLAT",
      discountValue: 1000,
      minOrderAmount: 8000,
      serviceCatalogIds: ["live_painter"],
      showOnUi: true,
    },
    MOH1000: {
      active: true,
      discountType: "FLAT",
      discountValue: 1000,
      minOrderAmount: 5000,
      serviceCatalogIds: [],
      showOnUi: false,
    },
  };
  return coupons[couponCode] || null;
}

function couponServiceMatches(booking, allowedServices) {
  const searchable = [
    booking.serviceCatalogId,
    booking.serviceTitle,
    booking.eventTypeId,
    booking.eventTypeName,
  ]
    .map((value) => clean(value).toLowerCase().replace(/[\s-]+/g, "_"))
    .join("|");
  const aliases = {
    musician: ["musician", "music", "live_performance"],
    live_painter: ["live_painter", "painter", "painting"],
  };
  return allowedServices.some((service) => {
    const normalized = clean(service).toLowerCase();
    return (aliases[normalized] || [normalized]).some((value) => searchable.includes(value));
  });
}

function paymentQuote({
  totalAmount,
  serviceSubtotal,
  rateAmount,
  quantityOrDuration,
  paymentMode,
  discountAmount,
  couponCode,
}) {
  return buildFinancialBreakdown({
    totalAmount,
    serviceSubtotal,
    rateAmount,
    quantityOrDuration,
    paymentMode,
    discountAmount,
    couponCode,
  });
}

function buildFinancialBreakdown({
  totalAmount,
  serviceSubtotal = 0,
  rateAmount = 0,
  quantityOrDuration = 0,
  paymentMode,
  discountAmount = 0,
  couponCode = "",
  gstPercent = 18,
  commissionPercent = 21,
}) {
  return calculatePricing({
    totalAmount,
    serviceSubtotal,
    rateAmount,
    quantityOrDuration,
    paymentMode,
    discountAmount,
    couponCode,
    gstPercent,
    commissionPercent,
  });
}

async function completeBookingById({
  bookingId,
  actorId,
  actorRole,
  completionType,
}) {
  const ref = db.collection(COLLECTIONS.bookings).doc(bookingId);
  const [invoiceBusinessId, payrollBusinessId] = await Promise.all([
    nextHumanId("customer_invoice", "INV-CUS"),
    nextHumanId("professional_payroll", "PAY-PRO"),
  ]);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const booking = snapshot.data();
    if (!booking) {
      throw new functions.https.HttpsError("not-found", "Booking not found.");
    }
    const invoiceRef = db.collection(COLLECTIONS.invoices).doc(bookingId);
    const payrollRef = db.collection(COLLECTIONS.payrolls).doc(bookingId);
    const paymentRef = db.collection(COLLECTIONS.payments).doc(bookingId);
    const financeSettingsRef = db.collection(COLLECTIONS.appSettings).doc("finance");
    const invoiceSnap = await transaction.get(invoiceRef);
    const payrollSnap = await transaction.get(payrollRef);
    const paymentSnap = await transaction.get(paymentRef);
    const financeSettingsSnap = await transaction.get(financeSettingsRef);
    const financeBooking = bookingWithAuthoritativePayment(
      booking,
      paymentSnap.data() || {},
    );
    if (actorRole === "professional" && clean(booking.assignedProfessionalId) !== actorId) {
      throw new functions.https.HttpsError("permission-denied", "This booking is not assigned to you.");
    }
    const currentStatus = clean(booking.status).toUpperCase();
    if (currentStatus === "COMPLETED") {
      writeCompletionFinancialRecords(transaction, {
        bookingId,
        booking: financeBooking,
        actorId,
        invoiceRef,
        invoiceSnap,
        payrollRef,
        payrollSnap,
        financeSettings: financeSettingsSnap.data() || {},
        invoiceBusinessId,
        payrollBusinessId,
      });
      return;
    }
    if (currentStatus !== "IN_PROGRESS" && actorRole !== "system") {
      throw new functions.https.HttpsError("failed-precondition", "Only in-progress bookings can be completed.");
    }
    const patch = {
      status: "COMPLETED",
      lifecycleStatus: "completed",
      bookingStatus: "completed",
      bookingStage: "completed",
      completedByProfessionalId: actorRole === "professional" ? actorId : clean(booking.assignedProfessionalId),
      completedBy: actorId,
      completionType,
      completedAt: FieldValue.serverTimestamp(),
      bookingCompletedAt: FieldValue.serverTimestamp(),
      timerStarted: false,
      timerCompleted: true,
      "timeline.completedAt": FieldValue.serverTimestamp(),
      "statusTimeline.completedAt": FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };
    writeBookingCopies(transaction, bookingId, booking, patch);
    writeCompletionFinancialRecords(transaction, {
      bookingId,
      booking: { ...financeBooking, ...patch, bookingId },
      actorId,
      invoiceRef,
      invoiceSnap,
      payrollRef,
      payrollSnap,
      financeSettings: financeSettingsSnap.data() || {},
      invoiceBusinessId,
      payrollBusinessId,
    });
  });
}

function bookingWithAuthoritativePayment(booking, paymentDocument) {
  if (!paymentDocument || Object.keys(paymentDocument).length === 0) {
    return booking;
  }
  const bookingPayment = asObject(booking.payment);
  const breakdown = asObject(paymentDocument.financialBreakdown || bookingPayment.financialBreakdown);
  const paymentStatus = clean(
    paymentDocument.paymentStatus ||
      paymentDocument.status ||
      booking.paymentStatus ||
      bookingPayment.status,
  );
  return {
    ...booking,
    paymentStatus,
    paidAmount: positiveInt(
      paymentDocument.paidAmount ||
        booking.paidAmount ||
        bookingPayment.paidAmount,
    ),
    remainingAmount: positiveInt(
      paymentDocument.remainingAmount ||
        booking.remainingAmount ||
        bookingPayment.remainingAmount,
    ),
    remainingPaid:
      paymentDocument.remainingPaid === true ||
      booking.remainingPaid === true ||
      bookingPayment.remainingPaid === true ||
      paymentStatus.toUpperCase() === "PAID",
    finalAmount: positiveInt(
      paymentDocument.finalAmount ||
        breakdown.finalAmount ||
      paymentDocument.finalPayableAmount ||
        booking.finalAmount ||
        bookingPayment.finalAmount,
    ),
    payment: {
      ...bookingPayment,
      ...paymentDocument,
      financialBreakdown: breakdown,
      status: paymentStatus,
    },
  };
}

function writeCompletionFinancialRecords(transaction, {
  bookingId,
  booking,
  actorId,
  invoiceRef,
  invoiceSnap,
  payrollRef,
  payrollSnap,
  financeSettings,
  invoiceBusinessId,
  payrollBusinessId,
}) {
  const customerId = clean(booking.customerId || booking.userId || asObject(booking.customer).id);
  const professionalId = clean(booking.assignedProfessionalId || booking.completedByProfessionalId);
  const now = FieldValue.serverTimestamp();

  if (customerId && !invoiceSnap.exists) {
    const invoice = {
      invoiceId: invoiceBusinessId,
      invoiceDocumentId: invoiceRef.id,
      bookingId,
      bookingCode: clean(booking.bookingCode),
      customerId,
      invoiceNumber: invoiceBusinessId,
      pdfUrl: "",
      pdfGenerationStatus: "PENDING_BACKEND",
      invoiceStatus: "GENERATED",
      serviceName: clean(booking.serviceTitle || booking.serviceName),
      eventTypeName: clean(booking.eventTypeName),
      invoiceAmount: finalAmountForBooking(booking),
      generatedAt: now,
    };
    transaction.set(invoiceRef, invoice);
    transaction.set(db.collection(COLLECTIONS.financialAuditLogs).doc(), auditPayload({
      entityType: "invoice",
      entityId: invoiceRef.id,
      action: "generated",
      oldState: {},
      newState: invoice,
      actorId,
      actorRole: "system",
    }));
  }

  if (professionalId && !payrollSnap.exists && isBookingFullyPaidForPayroll(booking)) {
    const bookingAmount = finalAmountForBooking(booking);
    const gstAmount = positiveInt(booking.gstAmount);
    const commissionPercent = positiveNumber(financeSettings.commissionPercent, 21);
    const commissionAmount = Math.round((bookingAmount * commissionPercent) / 100);
    const netPayoutAmount = Math.max(0, bookingAmount - gstAmount - commissionAmount);
    const payroll = {
      payrollId: payrollBusinessId,
      payrollDocumentId: payrollRef.id,
      bookingId,
      bookingCode: clean(booking.bookingCode),
      professionalId,
      bookingAmount,
      commissionPercent,
      commissionAmount,
      gstAmount,
      otherCharges: positiveInt(financeSettings.professionalCharges),
      netPayoutAmount,
      financialBreakdown: {
        grossAmount: bookingAmount,
        gstAmount,
        commissionPercent,
        commissionAmount,
        professionalPayoutAmount: netPayoutAmount,
      },
      payoutStatus: "PENDING",
      createdAt: now,
      releasedAt: null,
      releasedBy: "",
      transactionReference: "",
      serviceName: clean(booking.serviceTitle || booking.serviceName),
      eventDate: booking.eventDate || null,
    };
    transaction.set(payrollRef, payroll);
    transaction.set(db.collection(COLLECTIONS.financialAuditLogs).doc(), auditPayload({
      entityType: "payroll",
      entityId: payrollRef.id,
      action: "created",
      oldState: {},
      newState: payroll,
      actorId,
      actorRole: "system",
    }));
  }
}

function isBookingFullyPaid(booking) {
  const payment = asObject(booking.payment);
  const status = clean(booking.paymentStatus || payment.status).toUpperCase();
  return ["PAID", "FULLY_PAID"].includes(status) ||
    booking.remainingPaid === true ||
    payment.remainingPaid === true;
}

function finalAmountForBooking(booking) {
  const payment = asObject(booking.payment);
  const breakdown = asObject(payment.financialBreakdown);
  return positiveInt(
    breakdown.finalAmount ||
    booking.finalAmount ||
      payment.finalAmount ||
      payment.finalPayableAmount ||
      booking.totalAmount ||
      payment.totalAmount,
  );
}

function paidAmountForBooking(booking) {
  const payment = asObject(booking.payment);
  return positiveInt(booking.paidAmount || payment.paidAmount);
}

function isBookingFullyPaidForPayroll(booking) {
  const finalAmount = finalAmountForBooking(booking);
  if (finalAmount <= 0) {
    return false;
  }
  if (!isBookingFullyPaid(booking)) {
    return false;
  }
  const payment = asObject(booking.payment);
  const remainingAmount = positiveInt(
    booking.remainingAmount || payment.remainingAmount,
  );
  return paidAmountForBooking(booking) >= finalAmount || remainingAmount <= 0;
}

function remainingDueForBooking(booking, payment) {
  const storedRemaining = positiveInt(payment.remainingAmount || booking.remainingAmount);
  let paidAmount = positiveInt(payment.paidAmount || booking.paidAmount);
  const depositAmount = positiveInt(payment.depositAmount || booking.depositAmount);
  const paymentMode = clean(booking.paymentMode || payment.mode || payment.paymentMode).toUpperCase();
  const paymentStatus = clean(booking.paymentStatus || payment.status).toUpperCase();
  const finalAmount = positiveInt(
    booking.finalAmount ||
    payment.finalAmount ||
    payment.finalPayableAmount ||
    booking.totalAmount ||
    payment.totalAmount,
  );
  if (paidAmount <= 0 && depositAmount > 0) {
    paidAmount = depositAmount;
  }
  if (
    paidAmount <= 0 &&
    finalAmount > 0 &&
    (paymentStatus === "PARTIALLY_PAID" ||
      paymentStatus === "ADVANCE_PAID" ||
      paymentMode === "ADVANCE_20")
  ) {
    paidAmount = Math.round(finalAmount * 0.2);
  }
  if (paidAmount > 0 && finalAmount > 0) {
    return Math.max(0, finalAmount - paidAmount);
  }
  return storedRemaining;
}

function bookingDurationMinutes(booking) {
  const direct = positiveInt(booking.bookingDuration);
  if (direct > 0) {
    return direct;
  }
  const hours = Number.parseFloat(clean(booking.eventDurationHours || booking.durationHours));
  if (Number.isFinite(hours) && hours > 0) {
    return Math.max(1, Math.round(hours * 60));
  }
  return 60;
}

function generateBookingOtp() {
  return String(Math.floor(1000 + Math.random() * 9000));
}

function collectedAmountForPayment(booking, payment) {
  const bookingPayment = asObject(booking.payment);
  return positiveInt(payment.paidAmount || booking.paidAmount || bookingPayment.paidAmount);
}

function calculateRefundAmount(booking, payment, completedRefundAmount = 0) {
  const paidAmount = collectedAmountForPayment(booking, payment);
  const eligiblePaidAmount = Math.max(0, paidAmount - positiveInt(completedRefundAmount));
  if (eligiblePaidAmount <= 0) {
    return 0;
  }
  const policy = refundPolicyForBooking(booking);
  return Math.round((eligiblePaidAmount * policy.percent) / 100);
}

async function completedRefundAmountForBooking(bookingId) {
  const snapshot = await db.collection(COLLECTIONS.refunds)
    .where("bookingId", "==", bookingId)
    .get();
  return snapshot.docs.reduce((total, doc) => {
    const refund = doc.data() || {};
    const status = clean(refund.refundStatus).toUpperCase();
    if (!["COMPLETED", "REFUNDED", "PROCESSED"].includes(status)) {
      return total;
    }
    return total + positiveInt(refund.refundAmount);
  }, 0);
}

function refundPolicyForBooking(booking) {
  const decision = clean(booking.professionalDecisionStatus).toLowerCase();
  return refundPolicy({
    professionalAccepted:
      decision === "accepted" ||
      ["confirmed", "accepted", "in_progress", "completed"].includes(
        clean(booking.bookingStatus || booking.status).toLowerCase(),
      ),
    eventMillis: toMillis(booking.eventDate || booking.scheduledDate),
  });
}

function paymentRequestHandler(handler) {
  return async (req, res) => {
    try {
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
      res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }
      if (req.method !== "POST") {
        res.status(405).json({
          error: { status: "INVALID_ARGUMENT", message: "POST is required." },
        });
        return;
      }
      const uid = await requireBearerAuth(req);
      const result = await handler(asObject(req.body.data), uid);
      res.status(200).json({ result });
    } catch (error) {
      const statusCode = error.httpErrorCode?.status || 500;
      const code = error.code || "internal";
      const message = error.message || "Payment request failed.";
      console.error(error);
      res.status(statusCode).json({
        error: {
          status: code.toUpperCase().replace(/-/g, "_"),
          message,
        },
      });
    }
  };
}

async function requireBearerAuth(req) {
  const header = clean(req.get("authorization") || req.get("Authorization"));
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    throw new functions.https.HttpsError("unauthenticated", "Login is required.");
  }
  try {
    const decoded = await admin.auth().verifyIdToken(match[1]);
    if (!decoded.uid) {
      throw new Error("Missing uid");
    }
    return decoded.uid;
  } catch (error) {
    throw new functions.https.HttpsError("unauthenticated", "Login is required.");
  }
}

function requireBookingForCustomer(snapshot, uid) {
  const booking = snapshot.data();
  if (!booking) {
    throw new functions.https.HttpsError("not-found", "Booking not found.");
  }
  const ownerId = clean(booking.customerId || booking.userId || asObject(booking.customer).id);
  if (ownerId !== uid) {
    throw new functions.https.HttpsError("permission-denied", "You cannot access this booking.");
  }
  return booking;
}

async function isAdminUser(uid) {
  const userRecord = await admin.auth().getUser(uid);
  const claims = userRecord.customClaims || {};
  if (claims.admin === true || clean(claims.role).toLowerCase() === "admin") {
    return true;
  }
  const userSnap = await db.collection(COLLECTIONS.users).doc(uid).get();
  const user = userSnap.data() || {};
  return [
    clean(user.role).toLowerCase(),
    clean(user.rbacRole).toLowerCase(),
    clean(user.userRole).toLowerCase(),
  ].includes("admin");
}

async function requireActiveAccount(uid, expectedRole) {
  const userSnap = await db.collection(COLLECTIONS.users).doc(uid).get();
  const user = userSnap.data();
  if (!user) {
    throw new functions.https.HttpsError("not-found", "User account was not found.");
  }
  const role = clean(user.rbacRole || user.role || user.userRole).toLowerCase();
  if (expectedRole && role && role !== expectedRole && !(expectedRole === "professional" && role === "professional_pending")) {
    throw new functions.https.HttpsError("permission-denied", "This action is not available for your account role.");
  }
  const status = clean(user.accountStatus || "ACTIVE").toUpperCase();
  if (status === "SUSPENDED") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Your account is currently suspended. Please contact support.",
    );
  }
  if (status === "BLOCKED") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Your account has been blocked. Please contact admin support.",
    );
  }
}

function adminAccountActionPatch({ action, reason, uid, currentStatus, userData }) {
  const now = FieldValue.serverTimestamp();
  const patch = { updatedAt: now };
  if (action.startsWith("SUSPEND_")) {
    if (currentStatus === "BLOCKED") {
      throw new functions.https.HttpsError("failed-precondition", "Unblock the account before suspending it.");
    }
    Object.assign(patch, {
      accountStatus: "SUSPENDED",
      suspensionReason: reason,
      suspendedAt: now,
      suspendedBy: uid,
      professionalAvailableForBooking: false,
      professionalAvailabilityStatus: "offline",
    });
  } else if (action.startsWith("BLOCK_")) {
    Object.assign(patch, {
      accountStatus: "BLOCKED",
      blockedReason: reason,
      blockedAt: now,
      blockedBy: uid,
      professionalAvailableForBooking: false,
      professionalAvailabilityStatus: "offline",
    });
  } else if (action.startsWith("REACTIVATE_") || action.startsWith("UNBLOCK_")) {
    Object.assign(patch, {
      accountStatus: "ACTIVE",
      suspensionReason: null,
      blockedReason: null,
      reactivatedAt: now,
      reactivatedBy: uid,
    });
    if (action.endsWith("_PROFESSIONAL")) {
      Object.assign(patch, {
        professionalAvailableForBooking: false,
        professionalAvailabilityStatus: "offline",
      });
    }
  } else if (action === "MARK_FEATURED") {
    if (currentStatus !== "ACTIVE" || clean(userData.approvalStatus).toLowerCase() !== "approved") {
      throw new functions.https.HttpsError("failed-precondition", "Only active, approved professionals can be featured.");
    }
    patch.isFeatured = true;
  } else if (action === "REMOVE_FEATURED") {
    patch.isFeatured = false;
  } else if (action === "VERIFY_DOCUMENTS") {
    Object.assign(patch, {
      documentsVerified: true,
      approvalStatus: "approved",
      professionalStatus: "approved",
    });
  } else if (action === "REQUEST_BANK_UPDATE") {
    Object.assign(patch, {
      bankDetailsUpdateRequired: true,
      bankDetailsUpdateReason: reason,
    });
  } else if (action === "MARK_CUSTOMER_VERIFIED") {
    patch.isVerifiedCustomer = true;
  } else if (action === "REMOVE_CUSTOMER_VERIFIED") {
    patch.isVerifiedCustomer = false;
  }
  return patch;
}

function adminProfessionalActionPatch({ action, reason, uid, currentStatus, profileData }) {
  const patch = adminAccountActionPatch({
    action,
    reason,
    uid,
    currentStatus,
    userData: {
      approvalStatus: profileData.approvalStatus || profileData.status,
    },
  });
  if (action.startsWith("SUSPEND_")) {
    patch.status = "suspended";
  } else if (action.startsWith("BLOCK_")) {
    patch.status = "blocked";
  } else if (action.startsWith("REACTIVATE_") || action.startsWith("UNBLOCK_")) {
    const approval = clean(profileData.approvalStatus || profileData.status).toLowerCase();
    patch.status = ["approved", "verified", "active", "suspended", "blocked"].includes(approval)
      ? "approved"
      : approval || "pending";
  } else if (action === "VERIFY_DOCUMENTS") {
    patch.status = "approved";
    patch.approvalStatus = "approved";
  }
  return patch;
}

function normalizePaymentMode(raw) {
  const mode = clean(raw).toUpperCase();
  if (mode === "FULL") {
    return "FULL";
  }
  if (mode === "ADVANCE_20" || mode === "ADVANCE") {
    return "ADVANCE_20";
  }
  throw new functions.https.HttpsError("invalid-argument", "Payment mode is invalid.");
}

function hasSuccessfulPaymentStatus(value) {
  return ["PAID", "FULLY_PAID", "PARTIALLY_PAID", "ADVANCE_PAID"].includes(
    clean(value).toUpperCase(),
  );
}

async function resolveAuthoritativeServicePricing(raw) {
  const serviceCatalogId = clean(raw.serviceCatalogId);
  const eventTypeId = clean(raw.eventTypeId);
  const planKey = clean(raw.planKey).toLowerCase();
  const quantityOrDuration = positiveNumber(raw.eventDurationHours);
  if (!serviceCatalogId || !eventTypeId || !planKey || quantityOrDuration <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Service, event type, plan, and duration are required.",
    );
  }
  if (quantityOrDuration < 1 || quantityOrDuration > 10) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Booking duration must be between 1 and 10 hours.",
    );
  }

  const serviceRef = db.collection("service_catalog").doc(serviceCatalogId);
  const eventRef = serviceRef.collection("event_types").doc(eventTypeId);
  const settingsRef = db.collection(COLLECTIONS.appSettings).doc("service_management");
  const [serviceSnap, eventSnap, settingsSnap] = await Promise.all([
    serviceRef.get(),
    eventRef.get(),
    settingsRef.get(),
  ]);
  if (!serviceSnap.exists || !eventSnap.exists) {
    throw new functions.https.HttpsError("failed-precondition", "Selected service pricing is unavailable.");
  }
  const service = serviceSnap.data() || {};
  const event = eventSnap.data() || {};
  if (service.isActive === false || event.isActive === false) {
    throw new functions.https.HttpsError("failed-precondition", "Selected service is not active.");
  }
  const plans = asObject(event.pricingPlans);
  const plan = asObject(plans[planKey]);
  const rateAmount = positiveInt(plan.price);
  if (rateAmount <= 0) {
    throw new functions.https.HttpsError("failed-precondition", "Selected plan price is unavailable.");
  }
  const gstRate = positiveNumber((settingsSnap.data() || {}).gstPercent, 18);
  const serviceSubtotal = Math.round(rateAmount * quantityOrDuration);
  const gstAmount = Math.round((serviceSubtotal * gstRate) / 100);
  return {
    currency: "INR",
    serviceCatalogId,
    serviceTitle: clean(service.name || service.title || raw.serviceTitle) || "Service",
    eventTypeId,
    eventTypeName: clean(event.name || raw.eventTypeName) || "Event",
    planKey,
    planName: clean(plan.label || raw.planName) || planKey,
    rateAmount,
    quantityOrDuration,
    serviceSubtotal,
    gstRate,
    gstPercent: gstRate,
    gstAmount,
    originalCustomerPayable: serviceSubtotal + gstAmount,
  };
}

async function resolveNotificationRecipients(recipientType, selectedUserIds = []) {
  if (recipientType === "selected_users") {
    return [...new Set(selectedUserIds.map(clean).filter(Boolean))];
  }
  const targetRole = recipientType === "all_professionals" ? "professional" : "customer";
  const byRbac = await db.collection(COLLECTIONS.users)
    .where("rbacRole", "==", targetRole)
    .limit(1000)
    .get();
  const ids = new Set(byRbac.docs.map((doc) => doc.id));
  if (targetRole === "customer") {
    const byRole = await db.collection(COLLECTIONS.users)
      .where("role", "==", "customer")
      .limit(1000)
      .get();
    byRole.docs.forEach((doc) => ids.add(doc.id));
  } else {
    const byRole = await db.collection(COLLECTIONS.users)
      .where("role", "in", ["professional", "professional_pending"])
      .limit(1000)
      .get();
    byRole.docs.forEach((doc) => ids.add(doc.id));
  }
  return [...ids];
}

async function safeCreateAndSendNotification(options) {
  try {
    return await createAndSendNotification(options);
  } catch (error) {
    console.error("Notification delivery failed", error);
    return { totalTokens: 0, successCount: 0, failureCount: 0 };
  }
}

async function adminNotificationRecipients() {
  const ids = new Set();
  const byRbac = await db.collection(COLLECTIONS.users)
    .where("rbacRole", "==", "admin")
    .limit(1000)
    .get();
  byRbac.docs.forEach((doc) => ids.add(doc.id));
  const byRole = await db.collection(COLLECTIONS.users)
    .where("role", "==", "admin")
    .limit(1000)
    .get();
  byRole.docs.forEach((doc) => ids.add(doc.id));
  return [...ids];
}

async function createAndSendNotification({
  recipientIds,
  title,
  body,
  type = "system",
  source = "system",
  data = {},
  imageUrl = "",
  deepLinkRoute = "",
  sentByAdminId = "",
  campaignId = "",
}) {
  const recipients = [...new Set((recipientIds || []).map(clean).filter(Boolean))];
  if (recipients.length === 0) {
    return { totalTokens: 0, successCount: 0, failureCount: 0 };
  }
  const notificationPayload = {
    title: clean(title),
    body: clean(body),
    type: clean(type),
    source: clean(source),
    imageUrl: clean(imageUrl),
    deepLinkRoute: clean(deepLinkRoute),
    sentByAdminId: clean(sentByAdminId),
    campaignId: clean(campaignId),
    data: sanitizeFcmData(data),
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  };
  const batches = [];
  let batch = db.batch();
  let writeCount = 0;
  const tokenRefs = [];
  const tokens = [];
  for (const uid of recipients) {
    const userRef = db.collection(COLLECTIONS.users).doc(uid);
    batch.set(userRef.collection("notifications").doc(), {
      ...notificationPayload,
      recipientId: uid,
      recipientRole: clean(data.recipientRole),
    });
    writeCount += 1;
    if (writeCount >= 450) {
      batches.push(batch.commit());
      batch = db.batch();
      writeCount = 0;
    }
    const tokenSnap = await userRef.collection("fcm_tokens")
      .where("isActive", "==", true)
      .limit(20)
      .get();
    tokenSnap.docs.forEach((doc) => {
      const token = clean(doc.data().token);
      if (token) {
        tokens.push(token);
        tokenRefs.push(doc.ref);
      }
    });
  }
  if (writeCount > 0) {
    batches.push(batch.commit());
  }
  await Promise.all(batches);

  let successCount = 0;
  let failureCount = 0;
  for (let index = 0; index < tokens.length; index += 500) {
    const chunk = tokens.slice(index, index + 500);
    const response = await admin.messaging().sendEachForMulticast({
      tokens: chunk,
      notification: { title: clean(title), body: clean(body) },
      data: sanitizeFcmData({
        ...data,
        title,
        body,
        type,
        source,
        imageUrl,
        deepLinkRoute,
        campaignId,
      }),
      android: {
        priority: "high",
        notification: {
          channelId: "clicknow_default",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });
    successCount += response.successCount;
    failureCount += response.failureCount;
    const invalidWrites = [];
    response.responses.forEach((item, offset) => {
      if (!item.success && isInvalidFcmTokenError(item.error)) {
        invalidWrites.push(tokenRefs[index + offset].set({
          isActive: false,
          disabledAt: FieldValue.serverTimestamp(),
          disabledReason: clean(item.error?.code || "invalid_fcm_token"),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true }));
      }
    });
    await Promise.all(invalidWrites);
  }
  return { totalTokens: tokens.length, successCount, failureCount };
}

function sanitizeFcmData(data = {}) {
  const source = asObject(data);
  return Object.fromEntries(
    Object.entries(source)
      .filter(([key, value]) => clean(key) && value !== undefined && value !== null)
      .map(([key, value]) => [clean(key), typeof value === "string" ? value : JSON.stringify(value)]),
  );
}

function isInvalidFcmTokenError(error) {
  const code = clean(error?.code).toLowerCase();
  return [
    "messaging/registration-token-not-registered",
    "messaging/invalid-registration-token",
    "messaging/invalid-argument",
  ].includes(code);
}

function pricingBaseForBooking(booking) {
  const snapshot = asObject(booking.pricingSnapshot);
  const gstRate = positiveNumber(snapshot.gstRate || snapshot.gstPercent || booking.gstPercent, 18);
  const originalCustomerPayable = positiveInt(
    snapshot.originalCustomerPayable ||
      booking.originalCustomerPayable ||
      booking.totalAmount,
  );
  const serviceSubtotal = positiveInt(
    snapshot.serviceSubtotal ||
      booking.basePrice ||
      Math.round((originalCustomerPayable * 100) / (100 + gstRate)),
  );
  return {
    serviceSubtotal,
    originalCustomerPayable: originalCustomerPayable ||
      serviceSubtotal + Math.round((serviceSubtotal * gstRate) / 100),
    rateAmount: positiveInt(snapshot.rateAmount || booking.rateAmount),
    quantityOrDuration: positiveNumber(
      snapshot.quantityOrDuration || booking.eventDurationHours,
    ),
  };
}

async function fetchAndValidateCapturedPayment({ razorpayPaymentId, razorpayOrderId }) {
  let payment;
  try {
    payment = await razorpayClient().payments.fetch(razorpayPaymentId);
  } catch (error) {
    console.error("Unable to fetch Razorpay payment", error);
    throw new functions.https.HttpsError("unavailable", "Unable to verify captured payment.");
  }
  if (clean(payment.order_id) !== razorpayOrderId) {
    throw new functions.https.HttpsError("failed-precondition", "Captured payment order does not match.");
  }
  if (clean(payment.currency).toUpperCase() !== "INR") {
    throw new functions.https.HttpsError("failed-precondition", "Captured payment currency is invalid.");
  }
  if (payment.captured !== true && clean(payment.status).toLowerCase() !== "captured") {
    throw new functions.https.HttpsError("failed-precondition", "Payment has not been captured.");
  }
  return payment;
}

async function nextHumanId(type, prefix) {
  const now = new Date();
  const date = [
    now.getUTCFullYear(),
    String(now.getUTCMonth() + 1).padStart(2, "0"),
    String(now.getUTCDate()).padStart(2, "0"),
  ].join("");
  const counterRef = db.collection(COLLECTIONS.idCounters).doc(`${clean(type).toLowerCase()}_${date}`);
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(counterRef);
    const sequence = positiveInt(snapshot.data()?.lastSequence) + 1;
    transaction.set(counterRef, {
      type: clean(type).toLowerCase(),
      date,
      lastSequence: sequence,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return `${clean(prefix).toUpperCase()}-${date}-${String(sequence).padStart(6, "0")}`;
  });
}

async function updateBookingCopies(bookingId, booking, patch) {
  const batch = db.batch();
  writeBookingCopies(batch, bookingId, booking, patch);
  await batch.commit();
}

function writeBookingCopies(batchOrTransaction, bookingId, booking, patch) {
  const customerId = clean(booking.customerId || booking.userId || asObject(booking.customer).id);
  const professionalId = Object.prototype.hasOwnProperty.call(patch, "assignedProfessionalId")
    ? clean(patch.assignedProfessionalId)
    : clean(
        booking.assignedProfessionalId ||
          booking.professionalId ||
          booking.assignedToProfessionalId,
      );
  const mirror = materializePatch(booking, patch);
  mirror.sourceBookingId = bookingId;
  mirror.sourceVersion = positiveInt(booking.sourceVersion) + 1;
  batchOrTransaction.set(db.collection(COLLECTIONS.bookings).doc(bookingId), patch, { merge: true });
  batchOrTransaction.set(db.collection(COLLECTIONS.customerBookingRequests).doc(bookingId), mirror, { merge: true });
  if (customerId) {
    batchOrTransaction.set(
      db.collection(COLLECTIONS.users).doc(customerId).collection(COLLECTIONS.customerBookings).doc(bookingId),
      mirror,
      { merge: true },
    );
  }
  if (professionalId) {
    const professionalMirror = professionalReadModel(mirror);
    batchOrTransaction.set(
      db.collection(COLLECTIONS.users)
        .doc(professionalId)
        .collection(COLLECTIONS.professionalBookingRequests)
        .doc(bookingId),
      professionalMirror,
      { merge: true },
    );
  }
}

function professionalReadModel(booking) {
  const result = { ...booking };
  for (const field of [
    "paidAmount",
    "remainingAmount",
    "totalAmount",
    "finalAmount",
    "originalCustomerPayable",
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
  const payment = asObject(result.payment);
  result.payment = {
    status: clean(payment.status || result.paymentStatus),
    commissionPercent: positiveNumber(payment.commissionPercent),
    commissionAmount: positiveInt(payment.commissionAmount || result.commissionAmount),
    professionalPayoutAmount: positiveInt(
      payment.professionalPayoutAmount || result.professionalPayoutAmount,
    ),
    gstAmount: positiveInt(payment.gstAmount || result.gstAmount),
  };
  return result;
}

function materializePatch(base, patch) {
  const result = { ...asObject(base) };
  for (const [path, value] of Object.entries(asObject(patch))) {
    const parts = path.split(".");
    if (parts.length === 1) {
      result[path] = value;
      continue;
    }
    let cursor = result;
    for (let index = 0; index < parts.length - 1; index++) {
      const part = parts[index];
      cursor[part] = { ...asObject(cursor[part]) };
      cursor = cursor[part];
    }
    cursor[parts[parts.length - 1]] = value;
  }
  canonicalizeCustomerFinancialFields(result);
  return result;
}

function canonicalizeCustomerFinancialFields(booking) {
  const payment = asObject(booking.payment);
  const breakdown = asObject(
    booking.financialBreakdown ||
      booking.pricingSnapshot ||
      payment.financialBreakdown,
  );
  const paymentStatus = clean(
    booking.paymentStatus ||
      payment.status ||
      payment.paymentStatus,
  );
  const totalAmount = positiveInt(
    booking.finalAmount ||
      booking.finalCustomerPayable ||
      breakdown.finalAmount ||
      breakdown.finalCustomerPayable ||
      booking.totalAmount ||
      breakdown.totalAmount,
  );
  const paidAmount = positiveInt(booking.paidAmount || payment.paidAmount);
  const remainingAmount = paymentStatus === "PAID" || paymentStatus === "FULLY_PAID"
    ? 0
    : paidAmount > 0 && totalAmount > 0
      ? Math.max(0, totalAmount - paidAmount)
      : positiveInt(
          booking.remainingAmount ||
            payment.remainingAmount ||
            Math.max(0, totalAmount - paidAmount),
        );
  const paymentMode = clean(booking.paymentMode || payment.mode || payment.paymentMode);

  if (paymentStatus) {
    booking.paymentStatus = paymentStatus;
  }
  booking.totalAmount = positiveInt(booking.totalAmount || breakdown.totalAmount || totalAmount);
  booking.finalAmount = totalAmount || booking.totalAmount;
  booking.paidAmount = paidAmount;
  booking.remainingAmount = remainingAmount;
  booking.payment = {
    ...payment,
    status: paymentStatus,
    paymentStatus,
    mode: paymentMode,
    paymentMode,
    totalAmount: booking.totalAmount,
    finalAmount: booking.finalAmount,
    paidAmount,
    remainingAmount,
    financialBreakdown: asObject(payment.financialBreakdown).finalAmount
      ? payment.financialBreakdown
      : breakdown,
  };
}

function clean(value) {
  return value == null ? "" : String(value).trim();
}

function asObject(value) {
  return value && typeof value === "object" && !Array.isArray(value) ? value : {};
}

function positiveInt(value) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.max(0, Math.round(value));
  }
  const parsed = Number.parseInt(clean(value).replace(/[^0-9-]/g, ""), 10);
  return Number.isFinite(parsed) ? Math.max(0, parsed) : 0;
}

function positiveNumber(value, fallback = 0) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.max(0, value);
  }
  const parsed = Number.parseFloat(clean(value).replace(/[^0-9.-]/g, ""));
  return Number.isFinite(parsed) ? Math.max(0, parsed) : fallback;
}

async function recalculateServiceStats(serviceCatalogId) {
  const [bookingSnapshot, reviewSnapshot] = await Promise.all([
    db.collection(COLLECTIONS.bookings)
      .where("serviceCatalogId", "==", serviceCatalogId)
      .get(),
    db.collection(COLLECTIONS.reviews)
      .where("serviceCatalogId", "==", serviceCatalogId)
      .get(),
  ]);
  const completedBookingIds = new Set(
    bookingSnapshot.docs
      .filter((doc) => clean(doc.data().status).toUpperCase() === "COMPLETED")
      .map((doc) => doc.id),
  );
  const validRatings = reviewSnapshot.docs
    .map((doc) => doc.data())
    .filter((review) => {
      const rating = finiteNumber(review.rating);
      return review.visible !== false &&
        completedBookingIds.has(clean(review.bookingId)) &&
        rating >= 1 &&
        rating <= 5;
    })
    .map((review) => finiteNumber(review.rating));
  const averageRating = validRatings.length === 0
    ? 0
    : validRatings.reduce((sum, rating) => sum + rating, 0) / validRatings.length;
  await db.collection(COLLECTIONS.serviceStats).doc(serviceCatalogId).set({
    serviceId: serviceCatalogId,
    averageRating: Math.round(averageRating * 10) / 10,
    ratingCount: validRatings.length,
    totalReviews: validRatings.length,
    totalCompletedBookings: completedBookingIds.size,
    lastUpdatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}

function finiteNumber(value, fallback = 0) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  const parsed = Number.parseFloat(clean(value));
  return Number.isFinite(parsed) ? parsed : fallback;
}

function timestampFromInput(value) {
  if (!value) {
    return null;
  }
  if (typeof value.toDate === "function") {
    return admin.firestore.Timestamp.fromDate(value.toDate());
  }
  const millis = Date.parse(clean(value));
  if (!Number.isFinite(millis)) {
    throw new functions.https.HttpsError("invalid-argument", "Event date is invalid.");
  }
  return admin.firestore.Timestamp.fromMillis(millis);
}

function invoiceNumber(bookingId) {
  const value = clean(bookingId).toUpperCase();
  const suffix = value.length <= 8 ? value : value.substring(value.length - 8);
  return `CN-INV-${suffix || Date.now()}`;
}

function auditPayload({
  entityType,
  entityId,
  action,
  oldState,
  newState,
  actorId,
  actorRole,
}) {
  return {
    entityType,
    entityId,
    action,
    oldState,
    newState,
    actorId,
    actorRole,
    timestamp: FieldValue.serverTimestamp(),
    metadata: {},
  };
}

function rupeesToPaise(value) {
  return Math.max(100, positiveInt(value) * 100);
}

function toMillis(value) {
  if (!value) {
    return 0;
  }
  if (typeof value.toMillis === "function") {
    return value.toMillis();
  }
  if (value._seconds) {
    return value._seconds * 1000;
  }
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

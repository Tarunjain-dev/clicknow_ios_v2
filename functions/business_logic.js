"use strict";

function calculatePricing({
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
  const suppliedSubtotal = positiveInt(serviceSubtotal);
  const computedNetAmount = suppliedSubtotal > 0
    ? suppliedSubtotal
    : Math.round((positiveInt(totalAmount) * 100) / (100 + gstPercent));
  const originalGstAmount = Math.round((computedNetAmount * gstPercent) / 100);
  const grossAmount = computedNetAmount + originalGstAmount;
  const cappedDiscountAmount = Math.max(
    0,
    Math.min(Math.max(0, computedNetAmount - 1), positiveInt(discountAmount)),
  );
  const taxableAmount = Math.max(0, computedNetAmount - cappedDiscountAmount);
  const gstAmount = Math.round((taxableAmount * gstPercent) / 100);
  const finalAmount = taxableAmount + gstAmount;
  const commissionAmount = Math.round((finalAmount * commissionPercent) / 100);
  const professionalPayoutAmount = Math.max(
    0,
    finalAmount - gstAmount - commissionAmount,
  );
  const normalizedPaymentMode = clean(paymentMode).toUpperCase();
  const payableAmount = normalizedPaymentMode === "ADVANCE_20"
    ? Math.max(1, Math.round(finalAmount * 0.2))
    : finalAmount;
  return {
    totalAmount: grossAmount,
    originalAmount: grossAmount,
    grossAmount,
    currency: "INR",
    rateAmount: positiveInt(rateAmount),
    quantityOrDuration: positiveNumber(quantityOrDuration),
    serviceSubtotal: computedNetAmount,
    netAmount: computedNetAmount,
    taxableAmount,
    discountedServiceSubtotal: taxableAmount,
    discountAmount: cappedDiscountAmount,
    couponDiscountAmount: cappedDiscountAmount,
    couponCode: clean(couponCode),
    couponApplied: clean(couponCode).length > 0 && cappedDiscountAmount > 0,
    paymentMode: normalizedPaymentMode || "FULL",
    gstPercent,
    originalGstAmount,
    gstAmount,
    finalAmount,
    originalCustomerPayable: grossAmount,
    finalCustomerPayable: finalAmount,
    payableAmount,
    advanceAmount: normalizedPaymentMode === "ADVANCE_20" ? payableAmount : 0,
    advanceRate: 20,
    advanceDue: normalizedPaymentMode === "ADVANCE_20" ? payableAmount : 0,
    remainingAmount: Math.max(0, finalAmount - payableAmount),
    remainingDue: Math.max(0, finalAmount - payableAmount),
    commissionPercent,
    commissionRate: commissionPercent,
    commissionAmount,
    professionalPayoutAmount,
    expectedNetPayout: professionalPayoutAmount,
    pricingVersion: "v1",
    locked: false,
  };
}

function refundPolicy({ professionalAccepted, eventMillis, nowMillis = Date.now() }) {
  if (!professionalAccepted) {
    return { percent: 100, label: "No professional assigned" };
  }
  if (!eventMillis) {
    return { percent: 100, label: "Event date unavailable" };
  }
  const hoursUntilEvent = (eventMillis - nowMillis) / (1000 * 60 * 60);
  if (hoursUntilEvent > 72) return { percent: 100, label: "More than 72 hours" };
  if (hoursUntilEvent > 48) return { percent: 80, label: "48-72 hours" };
  if (hoursUntilEvent > 24) return { percent: 50, label: "24-48 hours" };
  return { percent: 0, label: "Less than 24 hours" };
}

function isAdminVisibleBooking({ status, paymentStatus, adminVisible }) {
  if (adminVisible === false) {
    return false;
  }
  const allowedStatuses = new Set([
    "REQUESTED",
    "APPROVED",
    "ASSIGNED",
    "CONFIRMED",
    "ACCEPTED",
    "IN_PROGRESS",
    "COMPLETED",
    "CANCELLED",
    "REJECTED",
  ]);
  const allowedPayments = new Set([
    "PAID",
    "FULLY_PAID",
    "PARTIALLY_PAID",
    "ADVANCE_PAID",
    "REFUND_PENDING",
    "REFUND_PROCESSING",
    "PARTIALLY_REFUNDED",
    "REFUNDED",
  ]);
  return allowedStatuses.has(clean(status).toUpperCase()) &&
    allowedPayments.has(clean(paymentStatus).toUpperCase());
}

function clean(value) {
  return value == null ? "" : String(value).trim();
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

module.exports = {
  calculatePricing,
  isAdminVisibleBooking,
  refundPolicy,
};

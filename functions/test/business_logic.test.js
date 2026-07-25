"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const {
  calculatePricing,
  isAdminVisibleBooking,
  refundPolicy,
} = require("../business_logic");

test("full payment without coupon", () => {
  const quote = calculatePricing({
    serviceSubtotal: 5000,
    rateAmount: 2500,
    quantityOrDuration: 2,
    paymentMode: "FULL",
  });
  assert.equal(quote.gstAmount, 900);
  assert.equal(quote.finalCustomerPayable, 5900);
  assert.equal(quote.payableAmount, 5900);
  assert.equal(quote.expectedNetPayout, 3761);
});

test("full payment with coupon", () => {
  const quote = calculatePricing({
    serviceSubtotal: 5000,
    paymentMode: "FULL",
    discountAmount: 1000,
    couponCode: "TALENT1000",
  });
  assert.equal(quote.discountedServiceSubtotal, 4000);
  assert.equal(quote.gstAmount, 720);
  assert.equal(quote.finalCustomerPayable, 4720);
});

test("advance payment calculations", () => {
  const withoutCoupon = calculatePricing({
    serviceSubtotal: 5000,
    paymentMode: "ADVANCE_20",
  });
  const withCoupon = calculatePricing({
    serviceSubtotal: 5000,
    paymentMode: "ADVANCE_20",
    discountAmount: 1000,
    couponCode: "TALENT1000",
  });
  assert.equal(withoutCoupon.payableAmount, 1180);
  assert.equal(withoutCoupon.remainingDue, 4720);
  assert.equal(withCoupon.payableAmount, 944);
  assert.equal(withCoupon.remainingDue, 3776);
});

test("coupon discount never reduces final payable below one rupee", () => {
  const quote = calculatePricing({
    serviceSubtotal: 500,
    paymentMode: "FULL",
    discountAmount: 5000,
    couponCode: "MOH1000",
  });
  assert.equal(quote.discountAmount, 499);
  assert.equal(quote.finalCustomerPayable, 1);
  assert.equal(quote.payableAmount, 1);
});

test("refund windows use eligible paid amount percentages", () => {
  const now = Date.UTC(2026, 5, 13);
  assert.equal(refundPolicy({ professionalAccepted: false, nowMillis: now }).percent, 100);
  assert.equal(refundPolicy({
    professionalAccepted: true,
    eventMillis: now + 73 * 60 * 60 * 1000,
    nowMillis: now,
  }).percent, 100);
  assert.equal(refundPolicy({
    professionalAccepted: true,
    eventMillis: now + 60 * 60 * 60 * 1000,
    nowMillis: now,
  }).percent, 80);
  assert.equal(refundPolicy({
    professionalAccepted: true,
    eventMillis: now + 36 * 60 * 60 * 1000,
    nowMillis: now,
  }).percent, 50);
  assert.equal(refundPolicy({
    professionalAccepted: true,
    eventMillis: now + 12 * 60 * 60 * 1000,
    nowMillis: now,
  }).percent, 0);
});

test("admin visibility requires a verified captured payment", () => {
  for (const paymentStatus of [
    "UNPAID",
    "PENDING_PAYMENT",
    "CREATED",
    "PAYMENT_FAILED",
    "PAYMENT_ABANDONED",
  ]) {
    assert.equal(isAdminVisibleBooking({
      status: "REQUESTED",
      paymentStatus,
      adminVisible: true,
    }), false);
  }
  assert.equal(isAdminVisibleBooking({
    status: "REQUESTED",
    paymentStatus: "PARTIALLY_PAID",
    adminVisible: true,
  }), true);
  assert.equal(isAdminVisibleBooking({
    status: "REQUESTED",
    paymentStatus: "PAID",
    adminVisible: true,
  }), true);
});

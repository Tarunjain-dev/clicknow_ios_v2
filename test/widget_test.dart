import 'package:clicknow_version2/app/services/booking/booking_service.dart';
import 'package:clicknow_version2/app/services/payments/razorpay_payment_service.dart';
import 'package:clicknow_version2/app/screens/common/support/models/support_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('booking status codes remain stable for Firestore compatibility', () {
    expect(BookingStatusCode.requested.code, 'REQUESTED');
    expect(BookingStatusCode.confirmed.code, 'CONFIRMED');
    expect(BookingStatusCode.inProgress.code, 'IN_PROGRESS');
    expect(BookingStatusCode.completed.code, 'COMPLETED');
    expect(BookingStatusCode.rejected.code, 'REJECTED');
  });

  test('Razorpay quote preserves advance and remaining payment amounts', () {
    final quote = RazorpayPaymentQuote.fromMap(<String, dynamic>{
      'totalAmount': 5900,
      'originalAmount': 5900,
      'discountAmount': 0,
      'finalAmount': 5900,
      'payableAmount': 1180,
      'advanceAmount': 1180,
      'remainingAmount': 4720,
      'paymentMode': 'ADVANCE_20',
      'couponCode': '',
      'couponApplied': false,
    });

    expect(quote.payableAmount, 1180);
    expect(quote.remainingAmount, 4720);
    expect(quote.payableAmount + quote.remainingAmount, quote.finalAmount);
  });

  test('support priority mapping follows dispute urgency rules', () {
    expect(SupportValues.priorityFor('PROFESSIONAL_NOT_ARRIVED'), 'URGENT');
    expect(SupportValues.priorityFor('PAYMENT_ISSUE'), 'HIGH');
    expect(SupportValues.priorityFor('TECHNICAL_ISSUE'), 'MEDIUM');
    expect(SupportValues.priorityFor('OTHER'), 'LOW');
  });

  test('support ticket model safely handles missing optional fields', () {
    final ticket = SupportTicketModel.fromMap(<String, dynamic>{
      'ticketId': 'ticket-1',
      'raisedByUserId': 'user-1',
      'raisedByRole': 'customer',
      'raisedByName': 'Customer',
      'category': 'BOOKING_ISSUE',
      'subject': 'Booking problem',
      'description': 'A sufficiently detailed booking issue.',
      'createdAt': DateTime(2026, 6, 11),
      'updatedAt': DateTime(2026, 6, 11),
    });

    expect(ticket.status, 'OPEN');
    expect(ticket.priority, 'MEDIUM');
    expect(ticket.relatedBookingId, isNull);
    expect(ticket.adminUnreadCount, 0);
  });
}

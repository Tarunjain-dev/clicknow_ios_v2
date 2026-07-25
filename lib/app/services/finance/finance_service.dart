import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

class FinanceService {
  FinanceService._();

  static final FinanceService instance = FinanceService._();

  Future<void> createPaymentForBooking({
    required Map<String, dynamic> bookingData,
    String paymentMethod = 'online',
    String paymentGateway = 'pending_gateway',
    String gatewayTransactionId = '',
  }) async {
    throw StateError(
      'Payments can only be created by the backend after gateway verification.',
    );
  }

  Future<void> generateInvoiceForCompletedBooking({
    required Map<String, dynamic> bookingData,
    required String actorId,
  }) async {
    await _reconcileCompletedBooking(bookingData);
  }

  Future<void> generatePayrollForCompletedBooking({
    required Map<String, dynamic> bookingData,
    required String actorId,
  }) async {
    await _reconcileCompletedBooking(bookingData);
  }

  Future<void> createRefundForBooking({
    required Map<String, dynamic> bookingData,
    required String requestedBy,
    required String requestedByRole,
    required String reason,
    required bool fullRefund,
  }) async {
    await _callBackend('processRefund', <String, dynamic>{
      'bookingId': _bookingId(bookingData),
      'reason': reason.trim(),
    });
  }

  Future<void> approveRefund({
    required String refundId,
    required String adminId,
    required String remarks,
  }) async {
    await _updateRefund(
      refundId: refundId,
      action: 'APPROVE',
      remarks: remarks,
    );
  }

  Future<void> rejectRefund({
    required String refundId,
    required String adminId,
    required String remarks,
  }) async {
    await _updateRefund(refundId: refundId, action: 'REJECT', remarks: remarks);
  }

  Future<void> completeRefund({
    required String refundId,
    required String adminId,
    required String remarks,
  }) async {
    await _updateRefund(
      refundId: refundId,
      action: 'COMPLETE',
      remarks: remarks,
    );
  }

  Future<void> releasePayout({
    required String payrollId,
    required String adminId,
    required String transactionReference,
  }) async {
    await _callBackend('releaseProfessionalPayout', <String, dynamic>{
      'payrollId': payrollId,
      'transactionReference': transactionReference.trim(),
    });
  }

  Future<void> markInvoiceDownloaded({
    required String invoiceId,
    required String actorId,
  }) async {
    await _callBackend('markInvoiceDownloaded', <String, dynamic>{
      'invoiceId': invoiceId,
    });
  }

  Future<void> _reconcileCompletedBooking(
    Map<String, dynamic> bookingData,
  ) async {
    final bookingId = _bookingId(bookingData);
    if (bookingId.isEmpty) {
      throw StateError('Booking reference is required.');
    }
    await _callBackend('reconcileCompletedBookingFinancials', <String, dynamic>{
      'bookingId': bookingId,
    });
  }

  Future<void> _updateRefund({
    required String refundId,
    required String action,
    required String remarks,
  }) async {
    await _callBackend('adminUpdateRefund', <String, dynamic>{
      'refundId': refundId,
      'action': action,
      'remarks': remarks.trim(),
    });
  }

  Future<Map<String, dynamic>> _callBackend(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please login to continue.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Unable to verify login.');
    }
    final projectId = Firebase.app().options.projectId;
    final response = await http.post(
      Uri.parse(
        'https://us-central1-$projectId.cloudfunctions.net/$functionName',
      ),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{'data': payload}),
    );
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = Map<String, dynamic>.from(
        (decoded['error'] as Map?) ?? const <String, dynamic>{},
      );
      final message = _string(error['message']);
      throw StateError(
        message.isEmpty ? 'Finance server request failed.' : message,
      );
    }
    return Map<String, dynamic>.from(
      (decoded['result'] as Map?) ?? const <String, dynamic>{},
    );
  }

  String _bookingId(Map<String, dynamic> data) {
    final bookingId = _string(data['bookingId']);
    return bookingId.isNotEmpty ? bookingId : _string(data['requestId']);
  }
}

String _string(dynamic value) => value?.toString().trim() ?? '';

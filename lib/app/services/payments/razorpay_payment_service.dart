import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

enum CustomerPaymentMode { advance, full }

extension CustomerPaymentModeX on CustomerPaymentMode {
  String get code {
    switch (this) {
      case CustomerPaymentMode.advance:
        return 'ADVANCE_20';
      case CustomerPaymentMode.full:
        return 'FULL';
    }
  }

  String get label {
    switch (this) {
      case CustomerPaymentMode.advance:
        return '20% Advance';
      case CustomerPaymentMode.full:
        return 'Full Payment';
    }
  }
}

class RazorpayOrderInfo {
  const RazorpayOrderInfo({
    required this.paymentId,
    required this.bookingId,
    required this.orderId,
    required this.keyId,
    required this.amountPaise,
    required this.currency,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.description,
    required this.paymentMode,
    required this.totalAmount,
    required this.payableAmount,
    required this.remainingAmount,
    required this.discountAmount,
    required this.netAmount,
    required this.gstAmount,
    required this.commissionAmount,
    required this.professionalPayoutAmount,
    required this.financialBreakdown,
  });

  final String paymentId;
  final String bookingId;
  final String orderId;
  final String keyId;
  final int amountPaise;
  final String currency;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String description;
  final String paymentMode;
  final int totalAmount;
  final int payableAmount;
  final int remainingAmount;
  final int discountAmount;
  final int netAmount;
  final int gstAmount;
  final int commissionAmount;
  final int professionalPayoutAmount;
  final Map<String, dynamic> financialBreakdown;

  factory RazorpayOrderInfo.fromMap(Map<String, dynamic> data) {
    return RazorpayOrderInfo(
      paymentId: _string(data['paymentId']),
      bookingId: _string(data['bookingId']),
      orderId: _string(data['orderId']),
      keyId: _string(data['keyId']),
      amountPaise: _asInt(data['amountPaise']),
      currency: _string(data['currency']).isEmpty
          ? 'INR'
          : _string(data['currency']),
      customerName: _string(data['customerName']),
      customerEmail: _string(data['customerEmail']),
      customerPhone: _string(data['customerPhone']),
      description: _string(data['description']),
      paymentMode: _string(data['paymentMode']),
      totalAmount: _asInt(data['totalAmount']),
      payableAmount: _asInt(data['payableAmount']),
      remainingAmount: _asInt(data['remainingAmount']),
      discountAmount: _asInt(data['discountAmount']),
      netAmount: _asInt(data['netAmount']),
      gstAmount: _asInt(data['gstAmount']),
      commissionAmount: _asInt(data['commissionAmount']),
      professionalPayoutAmount: _asInt(data['professionalPayoutAmount']),
      financialBreakdown: _asMap(data['financialBreakdown']),
    );
  }
}

class RazorpayPaymentQuote {
  const RazorpayPaymentQuote({
    required this.totalAmount,
    required this.originalAmount,
    required this.grossAmount,
    required this.netAmount,
    required this.taxableAmount,
    required this.discountAmount,
    required this.gstPercent,
    required this.gstAmount,
    required this.finalAmount,
    required this.payableAmount,
    required this.advanceAmount,
    required this.remainingAmount,
    required this.commissionPercent,
    required this.commissionAmount,
    required this.professionalPayoutAmount,
    required this.paymentMode,
    required this.couponCode,
    required this.couponApplied,
  });

  final int totalAmount;
  final int originalAmount;
  final int grossAmount;
  final int netAmount;
  final int taxableAmount;
  final int discountAmount;
  final num gstPercent;
  final int gstAmount;
  final int finalAmount;
  final int payableAmount;
  final int advanceAmount;
  final int remainingAmount;
  final num commissionPercent;
  final int commissionAmount;
  final int professionalPayoutAmount;
  final String paymentMode;
  final String couponCode;
  final bool couponApplied;

  factory RazorpayPaymentQuote.fromMap(Map<String, dynamic> data) {
    return RazorpayPaymentQuote(
      totalAmount: _asInt(data['totalAmount']),
      originalAmount: _asInt(data['originalAmount']),
      grossAmount: _asInt(data['grossAmount']),
      netAmount: _asInt(data['netAmount']),
      taxableAmount: _asInt(data['taxableAmount']),
      discountAmount: _asInt(data['discountAmount']),
      gstPercent: _asNum(data['gstPercent']),
      gstAmount: _asInt(data['gstAmount']),
      finalAmount: _asInt(data['finalAmount']),
      payableAmount: _asInt(data['payableAmount']),
      advanceAmount: _asInt(data['advanceAmount']),
      remainingAmount: _asInt(data['remainingAmount']),
      commissionPercent: _asNum(data['commissionPercent']),
      commissionAmount: _asInt(data['commissionAmount']),
      professionalPayoutAmount: _asInt(data['professionalPayoutAmount']),
      paymentMode: _string(data['paymentMode']),
      couponCode: _string(data['couponCode']),
      couponApplied: data['couponApplied'] == true,
    );
  }
}

class RazorpayCheckoutResult {
  const RazorpayCheckoutResult({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });

  final String paymentId;
  final String orderId;
  final String signature;
}

class RazorpayPaymentService {
  RazorpayPaymentService._() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  static final RazorpayPaymentService instance = RazorpayPaymentService._();

  final Razorpay _razorpay = Razorpay();
  Completer<RazorpayCheckoutResult>? _activeCheckout;

  Future<RazorpayPaymentQuote> quoteCheckoutPayment({
    required CustomerPaymentMode paymentMode,
    required String serviceCatalogId,
    required String eventTypeId,
    required String planKey,
    required String eventDurationHours,
    String couponCode = '',
  }) async {
    final data = await _callFunction('quoteCheckoutPayment', <String, dynamic>{
      'paymentMode': paymentMode.code,
      'couponCode': couponCode.trim(),
      'serviceCatalogId': serviceCatalogId.trim(),
      'eventTypeId': eventTypeId.trim(),
      'planKey': planKey.trim(),
      'eventDurationHours': eventDurationHours.trim(),
    });
    return RazorpayPaymentQuote.fromMap(data);
  }

  Future<RazorpayOrderInfo> createPaymentOrder({
    required String bookingId,
    required CustomerPaymentMode paymentMode,
    String couponCode = '',
  }) async {
    final data = await _callFunction('createPaymentOrder', <String, dynamic>{
      'bookingId': bookingId,
      'paymentMode': paymentMode.code,
      'couponCode': couponCode.trim(),
    });
    return RazorpayOrderInfo.fromMap(data);
  }

  Future<RazorpayOrderInfo> createRemainingPaymentOrder({
    required String bookingId,
  }) async {
    final data = await _callFunction(
      'createRemainingPaymentOrder',
      <String, dynamic>{'bookingId': bookingId},
    );
    return RazorpayOrderInfo.fromMap(data);
  }

  Future<void> verifyPayment({
    required String bookingId,
    required String paymentId,
    required RazorpayCheckoutResult result,
  }) async {
    await _callFunction('verifyPayment', <String, dynamic>{
      'bookingId': bookingId,
      'paymentId': paymentId,
      'razorpayPaymentId': result.paymentId,
      'razorpayOrderId': result.orderId,
      'razorpaySignature': result.signature,
    });
  }

  Future<void> markPaymentAbandoned({required String bookingId}) async {
    await _callFunction('markPaymentAbandoned', <String, dynamic>{
      'bookingId': bookingId,
    });
  }

  Future<void> verifyBookingOtpAndStart({
    required String bookingId,
    required String otp,
  }) async {
    await _callFunction('verifyBookingOtpAndStart', <String, dynamic>{
      'bookingId': bookingId,
      'otp': otp.trim(),
    });
  }

  Future<void> endBooking({required String bookingId}) async {
    await _callFunction('endBooking', <String, dynamic>{
      'bookingId': bookingId,
    });
  }

  Future<void> adminUpdateRefund({
    required String refundId,
    required String action,
    required String remarks,
  }) async {
    await _callFunction('adminUpdateRefund', <String, dynamic>{
      'refundId': refundId,
      'action': action,
      'remarks': remarks.trim(),
    });
  }

  Future<void> releaseProfessionalPayout({
    required String payrollId,
    required String transactionReference,
  }) async {
    await _callFunction('releaseProfessionalPayout', <String, dynamic>{
      'payrollId': payrollId,
      'transactionReference': transactionReference.trim(),
    });
  }

  Future<void> confirmProfessionalPayout({
    required String payrollId,
    required String action,
    String comment = '',
    String reason = '',
  }) async {
    await _callFunction('confirmProfessionalPayout', <String, dynamic>{
      'payrollDocumentId': payrollId,
      'action': action,
      'comment': comment.trim(),
      'reason': reason.trim(),
    });
  }

  Future<void> reconcileCompletedBookingFinancials({
    required String bookingId,
  }) async {
    await _callFunction(
      'reconcileCompletedBookingFinancials',
      <String, dynamic>{'bookingId': bookingId},
    );
  }

  Future<RazorpayCheckoutResult> openCheckout(RazorpayOrderInfo order) async {
    if (_activeCheckout != null && !_activeCheckout!.isCompleted) {
      throw StateError('A payment is already in progress.');
    }

    final completer = Completer<RazorpayCheckoutResult>();
    _activeCheckout = completer;
    final user = FirebaseAuth.instance.currentUser;
    final options = <String, Object?>{
      'key': order.keyId,
      'amount': order.amountPaise,
      'currency': order.currency,
      'name': 'ClickNow',
      'description': order.description.isEmpty
          ? 'Booking payment'
          : order.description,
      'order_id': order.orderId,
      'prefill': <String, String>{
        'contact': order.customerPhone,
        'email': order.customerEmail.isNotEmpty
            ? order.customerEmail
            : (user?.email ?? ''),
        'name': order.customerName,
      },
      'theme': <String, String>{'color': '#3E015E'},
      'notes': <String, String>{
        'bookingId': order.bookingId,
        'paymentId': order.paymentId,
        'paymentMode': order.paymentMode,
      },
    };

    _razorpay.open(options);
    return completer.future.whenComplete(() {
      _activeCheckout = null;
    });
  }

  void dispose() {
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final completer = _activeCheckout;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.complete(
      RazorpayCheckoutResult(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        signature: response.signature ?? '',
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final completer = _activeCheckout;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.completeError(
      StateError(response.message ?? 'Payment was not completed.'),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    final completer = _activeCheckout;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.completeError(
      StateError(
        'External wallet ${response.walletName ?? ''} is not supported yet.',
      ),
    );
  }

  Future<Map<String, dynamic>> _callFunction(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please login to continue payment.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Unable to verify login for payment.');
    }
    final projectId = Firebase.app().options.projectId;
    if (projectId.isEmpty) {
      throw StateError('Firebase project id is missing.');
    }

    final response = await http
        .post(
          Uri.parse(
            'https://us-central1-$projectId.cloudfunctions.net/$functionName',
          ),
          headers: <String, String>{
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{'data': payload}),
        )
        .timeout(
          const Duration(seconds: 25),
          onTimeout: () => throw StateError(
            'Payment server timed out. Check your connection and retry.',
          ),
        );
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = Map<String, dynamic>.from(
        (decoded['error'] as Map?) ?? const <String, dynamic>{},
      );
      throw StateError(
        _string(error['message']).isEmpty
            ? 'Payment server request failed.'
            : _string(error['message']),
      );
    }
    if (decoded.containsKey('error')) {
      final error = Map<String, dynamic>.from(decoded['error'] as Map);
      throw StateError(
        _string(error['message']).isEmpty
            ? 'Payment server request failed.'
            : _string(error['message']),
      );
    }
    return Map<String, dynamic>.from(
      (decoded['result'] as Map?) ?? const <String, dynamic>{},
    );
  }
}

String _string(dynamic value) => value?.toString().trim() ?? '';

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(_string(value).replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
}

num _asNum(dynamic value) {
  if (value is num) {
    return value;
  }
  return num.tryParse(_string(value).replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

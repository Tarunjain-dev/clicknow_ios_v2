class ClickNowIdUtils {
  const ClickNowIdUtils._();

  static String firstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String? lastString(dynamic value) {
    if (value is Iterable && value.isNotEmpty) {
      return firstNonEmpty(<dynamic>[value.last]);
    }
    return null;
  }

  static String bookingDisplayId(
    Map<String, dynamic> data, {
    String fallbackDocumentId = '',
  }) {
    return firstNonEmpty(<dynamic>[
      data['bookingCode'],
      data['bookingDisplayId'],
      data['bookingBusinessId'],
      data['bookingId'],
      fallbackDocumentId,
    ]);
  }

  static String paymentDisplayId(
    Map<String, dynamic> data, {
    String fallbackDocumentId = '',
  }) {
    return firstNonEmpty(<dynamic>[
      data['paymentId'],
      data['paymentDocumentId'],
      fallbackDocumentId,
    ]);
  }

  static String paymentOrderDisplayId(Map<String, dynamic> data) {
    return firstNonEmpty(<dynamic>[
      data['orderCode'],
      data['paymentOrderId'],
      data['activeOrderCode'],
      data['activeRazorpayOrderId'],
      lastString(data['razorpayOrderIds']),
      data['razorpayOrderId'],
      data['orderId'],
    ]);
  }

  static String transactionDisplayId(Map<String, dynamic> data) {
    return firstNonEmpty(<dynamic>[
      data['transactionCode'],
      data['paymentTransactionCode'],
      data['transactionId'],
      data['gatewayTransactionId'],
      lastString(data['razorpayPaymentIds']),
      data['razorpayPaymentId'],
      data['gatewayPaymentId'],
    ]);
  }

  static String customerInvoiceDisplayId(
    Map<String, dynamic> data, {
    String fallbackDocumentId = '',
  }) {
    return firstNonEmpty(<dynamic>[
      data['invoiceNumber'],
      data['invoiceId'],
      data['customerInvoiceId'],
      fallbackDocumentId,
    ]);
  }

  static String professionalPayrollDisplayId(
    Map<String, dynamic> data, {
    String fallbackDocumentId = '',
  }) {
    return firstNonEmpty(<dynamic>[
      data['payrollId'],
      data['stipendSlipId'],
      data['professionalPayrollSlipId'],
      fallbackDocumentId,
    ]);
  }
}

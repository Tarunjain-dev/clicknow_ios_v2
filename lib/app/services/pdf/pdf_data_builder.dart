import 'package:clicknow_version2/app/services/pdf/models/customer_invoice_pdf_data.dart';
import 'package:clicknow_version2/app/services/pdf/models/pdf_line_item.dart';
import 'package:clicknow_version2/app/services/pdf/models/professional_payroll_pdf_data.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/id_utils/clicknow_id_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PdfDataBuilder {
  PdfDataBuilder._();

  static final PdfDataBuilder instance = PdfDataBuilder._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<CustomerInvoicePdfData> customerInvoiceForBooking({
    required String bookingId,
    Map<String, dynamic> fallbackBookingData = const <String, dynamic>{},
  }) async {
    final bookingSnap = await _db
        .collection(ServiceCatalogPaths.bookingsCollection)
        .doc(bookingId)
        .get();
    final paymentSnap = await _db
        .collection(ServiceCatalogPaths.paymentsCollection)
        .doc(bookingId)
        .get();
    final invoiceSnap = await _db
        .collection(ServiceCatalogPaths.invoicesCollection)
        .doc(bookingId)
        .get();
    final booking = <String, dynamic>{
      ...fallbackBookingData,
      ...(bookingSnap.data() ?? const <String, dynamic>{}),
    };
    final payment = paymentSnap.data() ?? const <String, dynamic>{};
    final invoice = invoiceSnap.data() ?? const <String, dynamic>{};
    final customer = _asMap(booking['customer']);
    final bookingPayment = _asMap(booking['payment']);
    final customerId = _first(<dynamic>[
      booking['customerId'],
      booking['userId'],
      customer['id'],
      _auth.currentUser?.uid,
    ]);
    final userSnap = customerId.isEmpty
        ? null
        : await _db
            .collection(ServiceCatalogPaths.usersCollection)
            .doc(customerId)
            .get();
    final user = userSnap?.data() ?? const <String, dynamic>{};
    final pricing = _asMap(booking['pricingSnapshot']);
    final subtotal = _num(_firstValue(<dynamic>[
      pricing['serviceSubtotal'],
      booking['basePrice'],
      booking['rateAmount'],
    ]));
    final discount = _num(_firstValue(<dynamic>[
      payment['discountAmount'],
      pricing['couponDiscountAmount'],
      booking['couponDiscountAmount'],
    ]));
    final gstAmount = _num(_firstValue(<dynamic>[
      booking['gstAmount'],
      pricing['gstAmount'],
      payment['gstAmount'],
    ]));
    final taxable = _num(_firstValue(<dynamic>[
      pricing['taxableAmount'],
      pricing['discountedServiceSubtotal'],
      subtotal - discount,
    ]));
    final total = _num(_firstValue(<dynamic>[
      booking['finalAmount'],
      booking['totalAmount'],
      booking['originalCustomerPayable'],
      payment['finalAmount'],
      invoice['invoiceAmount'],
    ]));
    final paid = _num(_firstValue(<dynamic>[
      payment['paidAmount'],
      bookingPayment['paidAmount'],
      booking['paidAmount'],
      booking['collectedAmount'],
    ]));
    final remaining = _num(_firstValue(<dynamic>[
      payment['activeRemainingAmount'],
      payment['remainingAmount'],
      bookingPayment['remainingAmount'],
      booking['remainingAmount'],
      total - paid,
    ]));
    final duration = _num(_firstValue(<dynamic>[
      booking['eventDurationHours'],
      booking['durationHours'],
      pricing['durationHours'],
      1,
    ]));
    final serviceName = _first(<dynamic>[
      booking['serviceTitle'],
      booking['serviceName'],
      invoice['serviceName'],
      'ClickNow Service',
    ]);
    final unitPrice = subtotal <= 0 ? total - gstAmount : subtotal;
    return CustomerInvoicePdfData(
      invoiceNumber: _first(<dynamic>[
        ClickNowIdUtils.customerInvoiceDisplayId(invoice),
        'INV-CUS-${_safeId(bookingId)}',
      ]),
      invoiceDate: _date(invoice['generatedAt']) ?? DateTime.now(),
      dueDate: null,
      bookingId: _first(<dynamic>[booking['bookingCode'], bookingId]),
      paymentId: ClickNowIdUtils.paymentDisplayId(
        payment,
        fallbackDocumentId: bookingId,
      ),
      orderId: _first(<dynamic>[
        ClickNowIdUtils.paymentOrderDisplayId(payment),
        bookingPayment['razorpayOrderId'],
      ]),
      transactionId: _first(<dynamic>[
        ClickNowIdUtils.transactionDisplayId(payment),
        bookingPayment['transactionId'],
      ]),
      companyName: _companyName,
      companyAddress: _companyAddress,
      companyEmail: _companyEmail,
      companyPhone: _companyPhone,
      companyWebsite: _companyWebsite,
      companyGstin: _companyGstin,
      placeOfSupply: _first(<dynamic>[
        invoice['placeOfSupply'],
        booking['placeOfSupply'],
        'Haryana (06)',
      ]),
      customerName: _first(<dynamic>[
        customer['name'],
        user['fullName'],
        user['name'],
        user['customerName'],
        'Customer',
      ]),
      customerBusinessName: _first(<dynamic>[
        user['businessName'],
        customer['businessName'],
        booking['customerBusinessName'],
      ]),
      customerPhone: _first(<dynamic>[
        customer['phoneNumber'],
        user['phoneNumber'],
        user['phone'],
      ]),
      customerEmail: _first(<dynamic>[customer['email'], user['email']]),
      customerAddress: _first(<dynamic>[booking['fullAddress'], user['address']]),
      customerGstin: _first(<dynamic>[
        user['gstin'],
        user['gstNumber'],
        customer['gstin'],
      ]),
      serviceName: serviceName,
      eventType: _first(<dynamic>[booking['eventTypeName'], invoice['eventTypeName']]),
      planName: _first(<dynamic>[booking['planName'], booking['planKey']]),
      eventDateTime: _date(booking['eventDate'] ?? booking['scheduledDate']),
      eventDurationHours: duration,
      venueName: _first(<dynamic>[booking['venueName']]),
      venueHouseOrHallDetails: _first(<dynamic>[booking['venueHouseDetails']]),
      venueLandmarkOrDirections:
          _first(<dynamic>[booking['venueLandmarkDetails']]),
      venueAddress: _first(<dynamic>[booking['fullAddress']]),
      items: <PdfLineItem>[
        PdfLineItem(
          itemName: serviceName,
          description: _first(<dynamic>[
            booking['eventTypeName'],
            booking['planName'],
            'Booking service',
          ]),
          sacCode: _first(<dynamic>[
            booking['sacCode'],
            pricing['sacCode'],
            '9983',
          ]),
          unitPrice: unitPrice,
          quantity: 1,
          discountPercent: subtotal <= 0 ? 0 : (discount / subtotal) * 100,
          taxPercent: _num(_firstValue(<dynamic>[
            booking['gstPercent'],
            pricing['gstRate'],
            18,
          ])),
          amount: total,
        ),
      ],
      subtotal: subtotal,
      discountAmount: discount,
      couponCode: _first(<dynamic>[payment['couponCode'], pricing['couponCode']]),
      taxableAmount: taxable,
      gstPercent: _num(_firstValue(<dynamic>[
        booking['gstPercent'],
        pricing['gstRate'],
        18,
      ])),
      gstAmount: gstAmount,
      cgstAmount: gstAmount / 2,
      sgstAmount: gstAmount / 2,
      igstAmount: 0,
      totalAmount: total,
      paymentOption: _first(<dynamic>[
        payment['paymentMode'],
        bookingPayment['paymentMode'],
        booking['paymentOption'],
        pricing['paymentOption'],
      ]),
      paymentMode: _first(<dynamic>[
        payment['paymentMethod'],
        payment['paymentGateway'],
        bookingPayment['gateway'],
        'Online',
      ]),
      paidAmount: paid,
      remainingAmount: remaining < 0 ? 0 : remaining,
      paymentStatus: _first(<dynamic>[
        payment['paymentStatus'],
        booking['paymentStatus'],
        bookingPayment['status'],
        'PENDING',
      ]),
      paymentDate: _date(payment['paidAt'] ?? bookingPayment['paidAt']),
      upiId: _first(<dynamic>[invoice['upiId'], booking['upiId']]),
      bankDetails: _first(<dynamic>[invoice['bankDetails'], _companyBankDetails]),
      notes: 'Booking invoice generated from ClickNow records.',
    );
  }

  Future<ProfessionalPayrollPdfData> professionalPayrollForPayroll({
    required String payrollId,
  }) async {
    final payrollSnap = await _db
        .collection(ServiceCatalogPaths.payrollsCollection)
        .doc(payrollId)
        .get();
    final payroll = payrollSnap.data() ?? const <String, dynamic>{};
    final bookingId = _first(<dynamic>[payroll['bookingId'], payrollId]);
    final bookingSnap = await _db
        .collection(ServiceCatalogPaths.bookingsCollection)
        .doc(bookingId)
        .get();
    final booking = bookingSnap.data() ?? const <String, dynamic>{};
    final professionalId = _first(<dynamic>[payroll['professionalId']]);
    final userSnap = professionalId.isEmpty
        ? null
        : await _db
            .collection(ServiceCatalogPaths.usersCollection)
            .doc(professionalId)
            .get();
    final profileSnap = professionalId.isEmpty
        ? null
        : await _db
            .collection('professional_profiles')
            .doc(professionalId)
            .get();
    final user = userSnap?.data() ?? const <String, dynamic>{};
    final profile = profileSnap?.data() ?? const <String, dynamic>{};
    final basic = _asMap(profile['basicInfo']);
    final customer = _asMap(booking['customer']);
    return ProfessionalPayrollPdfData(
      payrollId: ClickNowIdUtils.professionalPayrollDisplayId(
        payroll,
        fallbackDocumentId: payrollId,
      ),
      payrollDocumentId: _first(<dynamic>[payroll['payrollDocumentId'], payrollId]),
      generatedAt: _date(payroll['createdAt']) ?? DateTime.now(),
      bookingId: _first(<dynamic>[booking['bookingCode'], bookingId]),
      professionalId: professionalId,
      professionalName: _first(<dynamic>[
        basic['fullName'],
        user['fullName'],
        user['name'],
        'Professional',
      ]),
      professionalPhone: _first(<dynamic>[
        user['phoneNumber'],
        profile['phoneNumber'],
        basic['phoneNumber'],
      ]),
      professionalEmail: _first(<dynamic>[user['email'], basic['email']]),
      serviceName: _first(<dynamic>[
        payroll['serviceName'],
        booking['serviceTitle'],
        booking['serviceName'],
      ]),
      eventType: _first(<dynamic>[booking['eventTypeName']]),
      planName: _first(<dynamic>[booking['planName'], booking['planKey']]),
      eventDateTime: _date(payroll['eventDate'] ?? booking['eventDate']),
      eventDurationHours: _num(_firstValue(<dynamic>[
        booking['eventDurationHours'],
        booking['durationHours'],
        1,
      ])),
      customerName: _first(<dynamic>[customer['name'], booking['customerName']]),
      venueName: _first(<dynamic>[booking['venueName']]),
      venueAddress: _first(<dynamic>[booking['fullAddress']]),
      grossBookingAmount: _num(payroll['bookingAmount']),
      gstAmount: _num(payroll['gstAmount']),
      platformCommissionPercent: _num(payroll['commissionPercent']),
      platformCommissionAmount: _num(payroll['commissionAmount']),
      netPayoutAmount: _num(payroll['netPayoutAmount']),
      payoutStatus: _first(<dynamic>[payroll['payoutStatus'], 'PENDING']),
      paymentMode: _first(<dynamic>[
        payroll['paymentMode'],
        payroll['payoutMode'],
        'Bank Transfer',
      ]),
      gstStatus: _first(<dynamic>[
        payroll['gstStatus'],
        payroll['taxStatus'],
        'Not applicable',
      ]),
      releasedAt: _date(payroll['releasedAt']),
      releasedBy: _first(<dynamic>[payroll['releasedBy']]),
      transactionReference: _first(<dynamic>[payroll['transactionReference']]),
      professionalConfirmationStatus:
          _first(<dynamic>[payroll['professionalConfirmationStatus']]),
      companyName: _companyName,
      companyAddress: _companyAddress,
      companyEmail: _companyEmail,
      companyPhone: _companyPhone,
      companyGstin: _companyGstin,
      bankDetails: _companyBankDetails,
      notes: 'This payroll slip uses backend-generated payout values.',
    );
  }

  static const String _companyName = 'ClickNow';
  static const String _companyAddress =
      '494/18 Vijay Nagar, Hisar, Haryana - 125001';
  static const String _companyEmail = 'support@clicknow.co.in';
  static const String _companyPhone = '+91 9253842526';
  static const String _companyWebsite = 'www.clicknow.co.in';
  static const String _companyGstin = '06AAWFC4094J1ZV';
  static const String _companyBankDetails =
      'Bank Name: HDFC Bank\n'
      'Account Number: 50200121579841\n'
      'Account Name: ClickNow\n'
      'IFSC Code: HDFC0000155';

  String _safeId(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return cleaned.length > 8 ? cleaned.substring(cleaned.length - 8) : cleaned;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  dynamic _firstValue(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      return value;
    }
    return null;
  }

  String _first(List<dynamic> values) => _string(_firstValue(values));

  String _string(dynamic value) => value?.toString().trim() ?? '';

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_string(value)) ?? 0;
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

import 'pdf_line_item.dart';

class CustomerInvoicePdfData {
  const CustomerInvoicePdfData({
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.bookingId,
    required this.paymentId,
    required this.orderId,
    required this.transactionId,
    required this.companyName,
    required this.companyAddress,
    required this.companyEmail,
    required this.companyPhone,
    this.companyWebsite,
    this.companyGstin,
    this.companyLogoAssetPath,
    this.placeOfSupply,
    required this.customerName,
    this.customerBusinessName,
    required this.customerPhone,
    this.customerEmail,
    this.customerAddress,
    this.customerGstin,
    required this.serviceName,
    required this.eventType,
    required this.planName,
    this.eventDateTime,
    required this.eventDurationHours,
    this.venueName,
    this.venueHouseOrHallDetails,
    this.venueLandmarkOrDirections,
    this.venueAddress,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    this.couponCode,
    required this.taxableAmount,
    required this.gstPercent,
    required this.gstAmount,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
    required this.totalAmount,
    required this.paymentOption,
    this.paymentMode,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    this.paymentDate,
    this.upiId,
    this.bankDetails,
    this.notes,
    this.termsAndConditions,
  });

  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String bookingId;
  final String paymentId;
  final String orderId;
  final String transactionId;
  final String companyName;
  final String companyAddress;
  final String companyEmail;
  final String companyPhone;
  final String? companyWebsite;
  final String? companyGstin;
  final String? companyLogoAssetPath;
  final String? placeOfSupply;
  final String customerName;
  final String? customerBusinessName;
  final String customerPhone;
  final String? customerEmail;
  final String? customerAddress;
  final String? customerGstin;
  final String serviceName;
  final String eventType;
  final String planName;
  final DateTime? eventDateTime;
  final double eventDurationHours;
  final String? venueName;
  final String? venueHouseOrHallDetails;
  final String? venueLandmarkOrDirections;
  final String? venueAddress;
  final List<PdfLineItem> items;
  final double subtotal;
  final double discountAmount;
  final String? couponCode;
  final double taxableAmount;
  final double gstPercent;
  final double gstAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalAmount;
  final String paymentOption;
  final String? paymentMode;
  final double paidAmount;
  final double remainingAmount;
  final String paymentStatus;
  final DateTime? paymentDate;
  final String? upiId;
  final String? bankDetails;
  final String? notes;
  final String? termsAndConditions;
}

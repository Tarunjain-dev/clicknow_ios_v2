class ProfessionalPayrollPdfData {
  const ProfessionalPayrollPdfData({
    required this.payrollId,
    required this.payrollDocumentId,
    required this.generatedAt,
    required this.bookingId,
    required this.professionalId,
    required this.professionalName,
    required this.professionalPhone,
    this.professionalEmail,
    required this.serviceName,
    required this.eventType,
    required this.planName,
    this.eventDateTime,
    required this.eventDurationHours,
    this.customerName,
    this.venueName,
    this.venueAddress,
    required this.grossBookingAmount,
    required this.gstAmount,
    required this.platformCommissionPercent,
    required this.platformCommissionAmount,
    this.deductionsAmount = 0,
    required this.netPayoutAmount,
    required this.payoutStatus,
    this.paymentMode,
    this.gstStatus,
    this.releasedAt,
    this.releasedBy,
    this.transactionReference,
    this.professionalConfirmationStatus,
    required this.companyName,
    required this.companyAddress,
    required this.companyEmail,
    required this.companyPhone,
    this.companyGstin,
    this.bankDetails,
    this.companyLogoAssetPath,
    this.notes,
  });

  final String payrollId;
  final String payrollDocumentId;
  final DateTime generatedAt;
  final String bookingId;
  final String professionalId;
  final String professionalName;
  final String professionalPhone;
  final String? professionalEmail;
  final String serviceName;
  final String eventType;
  final String planName;
  final DateTime? eventDateTime;
  final double eventDurationHours;
  final String? customerName;
  final String? venueName;
  final String? venueAddress;
  final double grossBookingAmount;
  final double gstAmount;
  final double platformCommissionPercent;
  final double platformCommissionAmount;
  final double deductionsAmount;
  final double netPayoutAmount;
  final String payoutStatus;
  final String? paymentMode;
  final String? gstStatus;
  final DateTime? releasedAt;
  final String? releasedBy;
  final String? transactionReference;
  final String? professionalConfirmationStatus;
  final String companyName;
  final String companyAddress;
  final String companyEmail;
  final String companyPhone;
  final String? companyGstin;
  final String? bankDetails;
  final String? companyLogoAssetPath;
  final String? notes;
}

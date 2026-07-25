import 'package:clicknow_version2/app/screens/professional/professionalDashboard/earnings/getx/professionalEarnings_Controller.dart';
import 'package:clicknow_version2/app/screens/common/pdf/pdf_preview_screen.dart';
import 'package:clicknow_version2/app/services/pdf/pdf_data_builder.dart';
import 'package:clicknow_version2/app/services/pdf/pdf_formatters.dart';
import 'package:clicknow_version2/app/services/pdf/professional_payroll_pdf_service.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ProfessionalPaymentDetailsScreen extends StatefulWidget {
  const ProfessionalPaymentDetailsScreen({required this.item, super.key});

  final ProfessionalPaymentHistoryItem item;

  @override
  State<ProfessionalPaymentDetailsScreen> createState() =>
      _ProfessionalPaymentDetailsScreenState();
}

class _ProfessionalPaymentDetailsScreenState
    extends State<ProfessionalPaymentDetailsScreen> {
  final ProfessionalEarningsController _controller =
      ProfessionalEarningsController.instance;

  late String _confirmationStatus;
  String _confirmationComment = '';
  String _disputeReason = '';
  DateTime? _confirmedAt;
  DateTime? _disputedAt;

  ProfessionalPaymentHistoryItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    _confirmationStatus = item.professionalConfirmationStatus;
    _confirmationComment = item.professionalConfirmationComment;
    _disputeReason = item.professionalDisputeReason;
    _confirmedAt = item.professionalConfirmedAt;
    _disputedAt = item.professionalDisputedAt;
  }

  @override
  Widget build(BuildContext context) {
    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling utility
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    final isReleased = item.status.toUpperCase() == 'RELEASED';

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveUtility.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// -- Header
                Row(
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : Colors.black,
                        size: 24,
                      ),
                    ),
                    Text(
                      'Payment Details',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: ResponsiveUtility.fontSize(18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtility.height(8)),

                /// -- Payment status section
                Container(
                  width: double.infinity,
                  padding: ResponsiveUtility.all(12),
                  decoration: BoxDecoration(
                    color: isReleased
                        ? (isDark
                              ? Color(0xFF1C324A).withValues(alpha: 0.4)
                              : Color(0xffF7FFFA).withValues(alpha: 0.6))
                        : (isDark
                              ? Color(0xFF3A2A10).withValues(alpha: 0.5)
                              : Color(0xffFFF7E6)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isReleased
                          ? (isDark ? Color(0xFF05DF72) : Color(0xFF00712A))
                          : Color(0xffD28A00),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isReleased
                                ? Icons.check_circle_outline_rounded
                                : Icons.pending_actions_rounded,
                            color: isReleased
                                ? (isDark
                                      ? Color(0xFF05DF72)
                                      : Color(0xFF00712A))
                                : Color(0xffD28A00),
                            size: 26,
                          ),
                          SizedBox(width: scale.getScaledWidth(8)),
                          Text(
                            isReleased ? 'Payment Completed' : 'Payment Pending',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : isReleased
                                  ? Color(0xFF00712A)
                                  : Color(0xff8A5A00),
                              fontSize: ResponsiveUtility.fontSize(16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveUtility.height(8)),
                      Padding(
                        padding: EdgeInsets.only(
                          left: scale.getScaledWidth(34),
                        ),
                        child: Text(
                          'Booking ID: ${item.bookingId}',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.6),
                            fontSize: ResponsiveUtility.fontSize(14),
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtility.height(8)),
                      Container(
                        width: double.infinity,
                        padding: ResponsiveUtility.only(
                          bottom: 8,
                          top: 8,
                          right: 12,
                          left: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white.withValues(alpha: 1.0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isReleased ? 'Released Payout' : 'Pending Payout',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.62)
                                    : Colors.black.withValues(alpha: 0.62),
                                fontSize: ResponsiveUtility.fontSize(14),
                              ),
                            ),
                            SizedBox(height: ResponsiveUtility.height(8)),
                            Text(
                              'Rs.${_formatAmount(item.netAmount)}',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveUtility.fontSize(18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: scale.getScaledHeight(10)),
                _dataCard(
                  scale: scale,
                  title: 'Transaction Details',
                  isDark: isDark,
                  children: [
                    _line(scale, "Admin Review", item.transactionId, isDark),
                    _line(
                      scale,
                      'Event Date',
                      _formatDate(item.eventDate),
                      isDark,
                    ),
                    _line(
                      scale,
                      'Payout Date',
                      _formatDate(item.payoutDate),
                      isDark,
                    ),
                  ],
                ),
                if (isReleased) ...[
                  SizedBox(height: scale.getScaledHeight(10)),
                  _payoutConfirmationCard(scale, isDark),
                ],
                SizedBox(height: scale.getScaledHeight(16)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isReleased ? () => _openStipendSlip(item) : null,
                    icon: const Icon(Icons.download_outlined),
                    label: Text(
                      'Download Stipend Slip',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: scale.getScaledFont(17),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white
                          : AppColors.primaryColor,
                      foregroundColor: isDark
                          ? Color(0xFF4D186F)
                          : Colors.white,
                      minimumSize: Size.fromHeight(
                        ResponsiveUtility.height(44),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _payoutConfirmationCard(ScalingUtility scale, bool isDark) {
    final status = _confirmationStatus.isEmpty ? 'PENDING' : _confirmationStatus.toUpperCase();
    return _dataCard(
      scale: scale,
      title: 'Payout Receipt Confirmation',
      isDark: isDark,
      children: [
        _line(scale, 'Status', _friendlyStatus(status), isDark, isStrong: true),
        if (status == 'CONFIRMED') ...[
          _line(scale, 'Confirmed On', _formatDate(_confirmedAt), isDark),
          if (_confirmationComment.isNotEmpty)
            _line(scale, 'Comment', _confirmationComment, isDark),
        ],
        if (status == 'DISPUTED') ...[
          _line(scale, 'Reported On', _formatDate(_disputedAt), isDark),
          _line(scale, 'Issue', _disputeReason, isDark),
          Padding(
            padding: EdgeInsets.only(top: scale.getScaledHeight(4)),
            child: Text(
              'Admin has been notified and will review this payout.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: scale.getScaledFont(13),
              ),
            ),
          ),
        ],
        if (status == 'PENDING') ...[
          Text(
            'Please confirm after the released amount reaches your account.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: scale.getScaledFont(13),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(10)),
          Obx(() {
            final loading = _controller.payoutActionsInProgress.contains(
              item.payrollId,
            );
            return Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () => _submitConfirmation('CONFIRM'),
                    child: Text(loading ? 'Updating...' : 'Confirm Received'),
                  ),
                ),
                SizedBox(width: scale.getScaledWidth(8)),
                Expanded(
                  child: OutlinedButton(
                    onPressed: loading
                        ? null
                        : () => _submitConfirmation('DISPUTE'),
                    child: const Text('Report Issue'),
                  ),
                ),
              ],
            );
          }),
        ],
      ],
    );
  }

  Future<void> _submitConfirmation(String action) async {
    final inputController = TextEditingController();
    final isDispute = action == 'DISPUTE';
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isDispute ? 'Report Payout Issue' : 'Confirm Payout'),
        content: TextField(
          controller: inputController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: isDispute
                ? 'Describe the issue (required)'
                : 'Add an optional comment',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = inputController.text.trim();
              if (isDispute && value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            child: Text(isDispute ? 'Report Issue' : 'Confirm Received'),
          ),
        ],
      ),
    );
    inputController.dispose();
    if (message == null || !mounted) return;

    final success = await _controller.submitPayoutConfirmation(
      payrollId: item.payrollId,
      action: action,
      message: message,
    );
    if (!success || !mounted) return;
    setState(() {
      if (isDispute) {
        _confirmationStatus = 'DISPUTED';
        _disputeReason = message;
        _disputedAt = DateTime.now();
      } else {
        _confirmationStatus = 'CONFIRMED';
        _confirmationComment = message;
        _confirmedAt = DateTime.now();
      }
    });
  }

  Widget _dataCard({
    required ScalingUtility scale,
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtility.all(10),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1435) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Color(0xFF2A3363) : Color(0xffD9D9D9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtility.fontSize(14),
            ),
          ),
          SizedBox(height: ResponsiveUtility.height(4)),
          ...children,
        ],
      ),
    );
  }

  Widget _line(
    ScalingUtility scale,
    String label,
    String value,
    bool isDark, {
    bool isStrong = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: scale.getScaledHeight(4)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: isStrong ? 1 : 0.62)
                    : Colors.black.withValues(alpha: isStrong ? 1 : 0.62),
                fontWeight: isStrong ? FontWeight.w600 : FontWeight.w400,
                fontSize: ResponsiveUtility.fontSize(12),
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: isStrong ? 1 : 0.72)
                  : Colors.black.withValues(alpha: isStrong ? 1 : 0.72),
              fontWeight: isStrong ? FontWeight.w600 : FontWeight.w400,
              fontSize: scale.getScaledFont(12),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('MMM d, yyyy').format(value);
  }

  static String _formatAmount(int value) {
    return NumberFormat.decimalPattern('en_IN').format(value);
  }

  static String _friendlyStatus(String status) {
    switch (status) {
      case 'CONFIRMED':
        return 'Received and confirmed';
      case 'DISPUTED':
        return 'Issue reported';
      default:
        return 'Awaiting your confirmation';
    }
  }

  Future<void> _openStipendSlip(ProfessionalPaymentHistoryItem item) async {
    try {
      final slip = await PdfDataBuilder.instance.professionalPayrollForPayroll(
        payrollId: item.payrollId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfPreviewScreen(
            title: 'Payroll Slip ${slip.payrollId}',
            fileName:
                'ClickNow_Payroll_${PdfFormatters.safeFileName(slip.payrollId)}.pdf',
            buildPdf: () => ProfessionalPayrollPdfService.generate(slip),
          ),
        ),
      );
    } catch (_) {
      Get.snackbar(
        'Slip Failed',
        'Unable to generate stipend slip.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1A1435),
        colorText: Colors.white,
      );
    }
  }
}

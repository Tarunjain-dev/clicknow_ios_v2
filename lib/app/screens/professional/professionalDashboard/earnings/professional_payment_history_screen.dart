import 'package:clicknow_version2/app/screens/professional/professionalDashboard/earnings/getx/professionalEarnings_Controller.dart';
import 'package:clicknow_version2/app/screens/professional/professionalDashboard/earnings/professional_payment_details_screen.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ProfessionalPaymentHistoryScreen extends StatelessWidget {
  const ProfessionalPaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    /// -- Dark Mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling Utility
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    final controller = ProfessionalEarningsController.instance;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: ResponsiveUtility.only(
                  bottom: 10,
                  top: 10,
                  right: 12,
                  left: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : Colors.black,
                        size: 20,
                      ),
                    ),
                    Text(
                      'Payment History',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: ResponsiveUtility.fontSize(18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: ResponsiveUtility.height(1),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.paymentHistory.isEmpty) {
                    return Center(
                      child: Text(
                        'No payroll records yet.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: ResponsiveUtility.fontSize(14),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: ResponsiveUtility.only(
                      bottom: 10,
                      top: 10,
                      right: 12,
                      left: 12,
                    ),
                    itemCount: controller.paymentHistory.length,
                    separatorBuilder: (context, separatorIndex) =>
                        SizedBox(height: ResponsiveUtility.height(10)),
                    itemBuilder: (context, index) {
                      final item = controller.paymentHistory[index];
                      return InkWell(
                        onTap: () {
                          Get.to(
                            () => ProfessionalPaymentDetailsScreen(item: item),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Color(0xFF1A1435)
                                : Color(0xffFCFBFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Color(0xFF2A3363)
                                  : Color(0xffD9D9D9),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: ResponsiveUtility.only(
                                  bottom: 10,
                                  top: 10,
                                  right: 12,
                                  left: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Booking ID: ${item.bookingId}',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: ResponsiveUtility.fontSize(
                                            14,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: ResponsiveUtility.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.status == 'RELEASED' ?
                                        isDark ?  Color(0xFF16C658).withValues(alpha: 0.15) : Color(0xFF16C658).withValues(alpha: 0.15): 
                                        isDark ? Color(0xffFFF7E6).withValues(alpha: 1.0) : Color(0xffFFF7E6).withValues(alpha: 1.0),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: item.status == 'RELEASED' ? Color(0xFF00A63E) : Color(0xffD28A00),
                                        ),
                                      ),
                                      child: Text(
                                        item.status,
                                        style: TextStyle(
                                          color: item.status == 'RELEASED' ? Color(0xFF00A63E) : Color(0xffD28A00),
                                          fontSize: ResponsiveUtility.fontSize(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _lineItem(
                                scale: scale,
                                label: 'Event Date',
                                value: _formatDate(item.eventDate),
                                isDark: isDark,
                              ),
                              if (item.status.toUpperCase() == 'RELEASED')
                                _lineItem(
                                  scale: scale,
                                  label: 'Receipt Confirmation',
                                  value: _confirmationLabel(
                                    item.professionalConfirmationStatus,
                                  ),
                                  isDark: isDark,
                                ),
                              Container(
                                margin: ResponsiveUtility.only(top: 6),
                                padding: ResponsiveUtility.only(
                                  top: 8,
                                  bottom: 10,
                                  left: 12,
                                  right: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      item.status.toUpperCase() == 'RELEASED'
                                          ? 'Released Payout'
                                          : 'Pending Payout',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.72,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.72,
                                              ),
                                        fontSize: ResponsiveUtility.fontSize(
                                          14,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Rs.${_formatAmount(item.netAmount)}',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.72,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.72,
                                              ),
                                        fontSize: ResponsiveUtility.fontSize(
                                          14,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lineItem({
    required ScalingUtility scale,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: ResponsiveUtility.only(bottom: 0, top: 4, right: 12, left: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.58)
                  : Colors.black.withValues(alpha: 0.58),
              fontSize: ResponsiveUtility.fontSize(12),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.58)
                  : Colors.black.withValues(alpha: 0.58),
              fontSize: ResponsiveUtility.fontSize(12),
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

  static String _confirmationLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return 'Confirmed';
      case 'DISPUTED':
        return 'Issue Reported';
      default:
        return 'Awaiting Confirmation';
    }
  }
}

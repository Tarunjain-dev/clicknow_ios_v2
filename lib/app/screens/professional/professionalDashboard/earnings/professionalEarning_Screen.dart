// ignore_for_file: file_names

import 'package:clicknow_version2/app/screens/professional/professionalDashboard/earnings/getx/professionalEarnings_Controller.dart';
import 'package:clicknow_version2/app/screens/professional/professionalDashboard/earnings/professional_payment_history_screen.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ProfessionalEarningsScreen extends StatelessWidget {
  const ProfessionalEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling utility instance
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
               padding: ResponsiveUtility.only(bottom: 10, top: 12, right: 12, left: 12),
                child: Text(
                  'My Earnings',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtility.fontSize(18),
                  ),
                ),
              ),
              Container(
                height: 1,
                color: isDark ? Colors.white.withValues(alpha: 0.2) : Color(0xffD9D9D9),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: ResponsiveUtility.only(bottom: 10, top: 12, right: 12, left: 12),
                  child: Column(
                    children: [
                      Obx(
                        () => GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: ResponsiveUtility.width(8),
                          mainAxisSpacing: ResponsiveUtility.height(8),
                          childAspectRatio: 2.2,
                          children: [
                            _summaryCard(scale: scale, title: 'Total Revenue.', value: controller.totalRevenue.value, isDark: isDark),
                            _summaryCard(scale: scale, title: 'This Monthly Revenue.', value: controller.monthlyRevenue.value, isDark: isDark),
                            _summaryCard(scale: scale, title: 'Pending Payout.', value: controller.pendingPayout.value, isDark: isDark),
                            _summaryCard(scale: scale, title: 'Settled Amount.', value: controller.settledAmount.value, isDark: isDark),
                          ],
                        ),
                      ),
                      SizedBox(height: ResponsiveUtility.height(10)),
                      Obx(() => _monthlyChartCard(scale, controller, isDark)),
                      SizedBox(height: ResponsiveUtility.height(10)),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.to(() => const ProfessionalPaymentHistoryScreen());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
                            foregroundColor: isDark ? Color(0xFF4D186F) : Colors.white,
                            minimumSize:
                                Size.fromHeight(scale.getScaledHeight(46)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'View Payment History',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: scale.getScaledFont(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({
    required ScalingUtility scale,
    required String title,
    required int value,
    required bool isDark,
  }) {
    return Container(
      padding: ResponsiveUtility.only(bottom: 8, top: 8, right:10, left: 10),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1435) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Color(0xFF2A3363) : Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.currency_rupee_rounded,
                color: isDark ? Color(0xFFD000FF) : Colors.black.withValues(alpha: 0.6),
                size: 16,
              ),
              SizedBox(width: ResponsiveUtility.width(6)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: ResponsiveUtility.fontSize(14),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                _formatCurrency(value),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtility.fontSize(22),
                ),
              ),
              SizedBox(width: scale.getScaledWidth(4)),
              Text(
                'Rs.',
                style: TextStyle(
                  color: isDark ? Color(0xFFD000FF) : Colors.black.withValues(alpha: 0.6),
                  fontSize: ResponsiveUtility.fontSize(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthlyChartCard(
    ScalingUtility scale,
    ProfessionalEarningsController controller,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtility.only(bottom: 10, top: 10, right:10, left: 10),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1435) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Color(0xFF2A3363) : Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(4)),
            child: Text(
              'Monthly Overview',
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.86) : Colors.black.withValues(alpha: 1),
                fontSize: ResponsiveUtility.fontSize(16),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtility.height(8)),
          SizedBox(
            height: ResponsiveUtility.height(230),
            child: SfCartesianChart(
              margin: ResponsiveUtility.only(left: 8, top: 8, bottom: 0, right:8),
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                iconHeight: ResponsiveUtility.height(10),
                iconWidth: ResponsiveUtility.width(10),
                itemPadding: 10,
                textStyle: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6),
                  fontSize: ResponsiveUtility.fontSize(10),
                ),
              ),
              primaryXAxis: CategoryAxis(
                majorGridLines: MajorGridLines(
                  width: ResponsiveUtility.width(1),
                  dashArray: const <double>[4, 4],
                  color: isDark ? Colors.white.withValues(alpha: 0.24) : Colors.black.withValues(alpha: 0.24),
                ),
                majorTickLines: MajorTickLines(size: ResponsiveUtility.width(1)),
                axisLine: AxisLine(width: ResponsiveUtility.width(1), color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.4)),
                labelStyle: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.72) : Colors.black.withValues(alpha: 0.72),
                  fontSize: scale.getScaledFont(11),
                ),
              ),
              primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: 100,
                interval: 20,
                axisLine: AxisLine(width: ResponsiveUtility.width(1), color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.4)),
                majorTickLines: MajorTickLines(size: ResponsiveUtility.width(1)),
                majorGridLines: MajorGridLines(
                  width: ResponsiveUtility.width(1),
                  dashArray: const <double>[4, 4],
                  color: isDark ? Colors.white.withValues(alpha: 0.24) : Colors.black.withValues(alpha: 0.24),
                ),
                labelStyle: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.72) : Colors.black.withValues(alpha: 0.72),
                  fontSize: scale.getScaledFont(11),
                ),
              ),
              series: <CartesianSeries<ProfessionalEarningsMonthlyOverview, String>>[
                ColumnSeries<ProfessionalEarningsMonthlyOverview, String>(
                  name: 'Revenue',
                  dataSource: controller.monthlyOverview.toList(),
                  xValueMapper: (item, _) => item.month,
                  yValueMapper: (item, _) => item.revenue,
                  color: isDark ? Color(0xFF6C7CFF) : Color(0xff0029FF),
                  width: 0.28,
                  spacing: 0.2,
                ),
                ColumnSeries<ProfessionalEarningsMonthlyOverview, String>(
                  name: 'Payout',
                  dataSource: controller.monthlyOverview.toList(),
                  xValueMapper: (item, _) => item.month,
                  yValueMapper: (item, _) => item.payout,
                  color: isDark ? Color(0xFF79CAA3) : Color(0xff00E458),
                  width: 0.28,
                  spacing: 0.2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int value) {
    return NumberFormat.decimalPattern('en_IN').format(value);
  }
}

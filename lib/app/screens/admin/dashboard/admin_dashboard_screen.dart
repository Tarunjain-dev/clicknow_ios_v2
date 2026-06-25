import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/admin/dashboard/getx/admin_dashboard_controller.dart';
import 'package:clicknow_version2/app/screens/admin/widgets/admin_drawer.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    final controller = Get.isRegistered<AdminDashboardController>() ? Get.find<AdminDashboardController>() : Get.put(AdminDashboardController());

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AdminDrawer(
        scale: scale,
        activeRoute: AppRoutes.adminDashboardRoute,
      ),
      body: SafeArea(
        child: Obx(() {
          final data = controller.dashboard.value;
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: Column(
              children: [
                /// -- app bar
                _header(context, scale, controller),

                /// -- Body
                Expanded(
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: ResponsiveUtility.symmetric(horizontal: 10),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (controller.errorMessage.value.isNotEmpty)
                              _errorBanner(context, controller.errorMessage.value, scale,),
                            if (controller.isLoading.value)
                              const LinearProgressIndicator(minHeight: 2),
                            SizedBox(height: ResponsiveUtility.height(10)),
                            _sectionHeading(context, 'Business overview', 'Live operational and financial totals', scale,),
                            SizedBox(height: ResponsiveUtility.height(10)),
                            _metricGrid(context, scale, [
                              _Metric('Professionals', '${data.totalProfessionals}', Icons.groups_2_outlined, const Color(0xff6B4EFF),),
                              _Metric('Pending approvals', '${data.pendingApprovals}', Icons.fact_check_outlined, const Color(0xffF59E0B),),
                              _Metric('Customers', '${data.totalCustomers}', Icons.people_alt_outlined, const Color(0xff0EA5E9),),
                              _Metric('Active bookings', '${data.activeBookings}', Icons.calendar_month_rounded, const Color(0xff10B981),),
                              _Metric('Total revenue', _money(data.totalRevenue), Icons.payments_outlined, const Color(0xff7C3AED),),
                              _Metric('Pending payout', _money(data.pendingPayout), Icons.account_balance_wallet_outlined, const Color(0xffEF4444),),
                            ]),
                            SizedBox(height: ResponsiveUtility.height(10)),
                            _sectionHeading(context, 'Booking health', 'Current distribution across the booking lifecycle', scale,),
                            SizedBox(height: ResponsiveUtility.height(10)),
                            _metricGrid(context, scale, [
                              _Metric('Completed', '${data.completedBookings}', Icons.task_alt_rounded, const Color(0xff10B981),),
                              _Metric('In progress', '${data.inProgressBookings}', Icons.timelapse_rounded, const Color(0xffF59E0B),),
                              _Metric('Confirmed', '${data.confirmedBookings}', Icons.verified_outlined, const Color(0xff3B82F6),),
                              _Metric('Rejected', '${data.rejectedBookings}', Icons.block_outlined, const Color(0xffEF4444),),
                              _Metric('Open support', '${data.openSupportTickets}', Icons.support_agent_rounded, const Color(0xffEC4899),),
                            ]),
                            SizedBox(height: ResponsiveUtility.height(10)),
                            _chartCard(context, scale, data.monthlyOverview, controller),
                            SizedBox(height: ResponsiveUtility.height(20)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _header(BuildContext context, ScalingUtility scale, AdminDashboardController controller,) {
    return Container(
      padding: ResponsiveUtility.only(left: 8,top: 10, right: 14, bottom: 14),
      color: Color(0xff6F18A8),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin dashboard', style: TextStyle(color: Colors.white, fontSize: ResponsiveUtility.fontSize(18), fontWeight: FontWeight.w800,),),
                Text('ClickNow operations at a glance', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: ResponsiveUtility.fontSize(12),),),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(BuildContext context, String title, String subtitle, ScalingUtility scale,){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.black, fontSize: ResponsiveUtility.fontSize(14), fontWeight: FontWeight.bold,),),
        Text(subtitle, style: TextStyle(color: Colors.black, fontSize: ResponsiveUtility.fontSize(10),),),
      ],
    );
  }

  Widget _metricGrid(BuildContext context, ScalingUtility scale, List<_Metric> metrics,) {
    return GridView.builder(
      itemCount: metrics.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: ResponsiveUtility.height(10),
        crossAxisSpacing: ResponsiveUtility.width(10),
        childAspectRatio:  1.42,
      ),
      itemBuilder: (_, index) => _metricCard(context, scale, metrics[index]),
    );
  }

  Widget _metricCard(BuildContext context, ScalingUtility scale, _Metric metric,) {
    return Container(
      padding: EdgeInsets.all(scale.getScaledWidth(12)),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffD9D9D9),),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: ResponsiveUtility.all(12),
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(metric.icon, color: metric.color, size: 19),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              style: TextStyle(
                color: Colors.black,
                fontSize: ResponsiveUtility.fontSize(18),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtility.height(3)),
          Text(
            metric.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.6),
              fontSize: ResponsiveUtility.fontSize(11),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(BuildContext context, ScalingUtility scale, List<AdminMonthlyOverview> data, AdminDashboardController controller,){
    final maxValue = data.fold<double>(0, (current, item) => [current, item.revenue, item.payout].reduce((a, b) => a > b ? a : b),);
    final axisMax = _niceAxisMax(maxValue);
    final axisInterval = _niceAxisInterval(axisMax);
    return Container(
      padding: ResponsiveUtility.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color:const Color(0xffD9D9D9),),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionHeading(context, '12-month financial overview', 'Revenue & Payroll trends', scale,),
              ),
              IconButton(
                tooltip: 'Previous months',
                onPressed: controller.showPreviousChartMonths,
                icon: Icon(Icons.chevron_left_rounded, color: Colors.black),
              ),
              IconButton(
                tooltip: 'Next months',
                onPressed: controller.canShowNextChartMonths ? controller.showNextChartMonths : null,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: controller.canShowNextChartMonths ? Colors.black : Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtility.height(10)),
          SizedBox(
            height: ResponsiveUtility.height(260),
            child: maxValue == 0
                ? Center(
                    child: Text('Financial activity will appear here.', style: TextStyle(color: Colors.black),),
                  )
                : SfCartesianChart(
                    margin: EdgeInsets.zero,
                    plotAreaBorderWidth: 0,
                    tooltipBehavior: TooltipBehavior(enable: true),
                    legend: Legend(
                      isVisible: true,
                      position: LegendPosition.bottom,
                      textStyle: TextStyle(color: Colors.black),
                    ),
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      axisLine: AxisLine(color: Colors.black.withValues(alpha: 0.6)),
                      labelStyle: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                    ),
                    primaryYAxis: NumericAxis(
                      minimum: 0,
                      maximum: axisMax,
                      interval: axisInterval,
                      axisLine: AxisLine(color: Colors.black.withValues(alpha: 0.6)),
                      majorTickLines: const MajorTickLines(size: 0),
                      numberFormat: null,
                      labelFormat: 'Rs.{value}',
                      majorGridLines: MajorGridLines(
                        color: Colors.black.withValues(alpha: 0.55),
                        dashArray: const [4, 4],
                      ),
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    series: <CartesianSeries<AdminMonthlyOverview, String>>[
                      ColumnSeries<AdminMonthlyOverview, String>(
                        name: 'Revenue',
                        dataSource: data,
                        xValueMapper: (item, _) => item.label,
                        yValueMapper: (item, _) => item.revenue,
                        color: const Color(0xff6B4EFF),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5),),
                      ),
                      ColumnSeries<AdminMonthlyOverview, String>(
                        name: 'Payout',
                        dataSource: data,
                        xValueMapper: (item, _) => item.label,
                        yValueMapper: (item, _) => item.payout,
                        color: const Color(0xff10B981),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5),),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(BuildContext context, String message, ScalingUtility scale,) {
    return Container(
      margin: EdgeInsets.only(bottom: scale.getScaledHeight(8)),
      padding: EdgeInsets.all(scale.getScaledWidth(10)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _money(double value) {
    final rounded = value.round();
    final raw = rounded.toString();
    final chars = raw.split('').reversed.toList();
    final out = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i != 0 && i % 3 == 0) out.add(',');
      out.add(chars[i]);
    }
    return 'Rs.${out.reversed.join()}';
  }

  double _niceAxisMax(double value) {
    if (value <= 0) return 1000;
    final roughMax = value * 1.15;
    final magnitude = _pow10(roughMax);
    final normalized = roughMax / magnitude;
    final rounded = normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10;
    return (rounded * magnitude).toDouble();
  }

  double _niceAxisInterval(double axisMax) {
    if (axisMax <= 0) return 200;
    return axisMax / 5;
  }

  double _pow10(double value) {
    var magnitude = 1.0;
    while (magnitude * 10 <= value) {
      magnitude *= 10;
    }
    while (value < magnitude && magnitude > 1) {
      magnitude /= 10;
    }
    return magnitude;
  }
}

class _Metric {
  const _Metric(this.title, this.value, this.icon, this.color);
  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

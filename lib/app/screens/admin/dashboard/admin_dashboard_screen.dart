import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/admin/dashboard/getx/admin_dashboard_controller.dart';
import 'package:clicknow_version2/app/screens/admin/widgets/admin_drawer.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    final controller = Get.isRegistered<AdminDashboardController>()
        ? Get.find<AdminDashboardController>()
        : Get.put(AdminDashboardController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xff0C0714)
        : const Color(0xffF5F6FA);

    return Scaffold(
      backgroundColor: background,
      drawer: AdminDrawer(
        scale: scale,
        activeRoute: AppRoutes.adminDashboardRoute,
      ),
      body: SafeArea(
        child: Obx(() {
          final data = controller.dashboard.value;
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _header(context, scale, controller)),
                SliverPadding(
                  padding: EdgeInsets.all(scale.getScaledWidth(14)),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (controller.errorMessage.value.isNotEmpty)
                        _errorBanner(
                          context,
                          controller.errorMessage.value,
                          scale,
                        ),
                      if (controller.isLoading.value)
                        const LinearProgressIndicator(minHeight: 2),
                      SizedBox(height: scale.getScaledHeight(12)),
                      _sectionHeading(
                        context,
                        'Business overview',
                        'Live operational and financial totals',
                        scale,
                      ),
                      SizedBox(height: scale.getScaledHeight(10)),
                      _metricGrid(context, scale, [
                        _Metric(
                          'Professionals',
                          '${data.totalProfessionals}',
                          Icons.groups_2_outlined,
                          const Color(0xff6B4EFF),
                        ),
                        _Metric(
                          'Pending approvals',
                          '${data.pendingApprovals}',
                          Icons.fact_check_outlined,
                          const Color(0xffF59E0B),
                        ),
                        _Metric(
                          'Customers',
                          '${data.totalCustomers}',
                          Icons.people_alt_outlined,
                          const Color(0xff0EA5E9),
                        ),
                        _Metric(
                          'Active bookings',
                          '${data.activeBookings}',
                          Icons.calendar_month_rounded,
                          const Color(0xff10B981),
                        ),
                        _Metric(
                          'Total revenue',
                          _money(data.totalRevenue),
                          Icons.payments_outlined,
                          const Color(0xff7C3AED),
                        ),
                        _Metric(
                          'Pending payout',
                          _money(data.pendingPayout),
                          Icons.account_balance_wallet_outlined,
                          const Color(0xffEF4444),
                        ),
                      ]),
                      SizedBox(height: scale.getScaledHeight(18)),
                      _sectionHeading(
                        context,
                        'Booking health',
                        'Current distribution across the booking lifecycle',
                        scale,
                      ),
                      SizedBox(height: scale.getScaledHeight(10)),
                      _metricGrid(context, scale, [
                        _Metric(
                          'Completed',
                          '${data.completedBookings}',
                          Icons.task_alt_rounded,
                          const Color(0xff10B981),
                        ),
                        _Metric(
                          'In progress',
                          '${data.inProgressBookings}',
                          Icons.timelapse_rounded,
                          const Color(0xffF59E0B),
                        ),
                        _Metric(
                          'Confirmed',
                          '${data.confirmedBookings}',
                          Icons.verified_outlined,
                          const Color(0xff3B82F6),
                        ),
                        _Metric(
                          'Rejected',
                          '${data.rejectedBookings}',
                          Icons.block_outlined,
                          const Color(0xffEF4444),
                        ),
                        _Metric(
                          'Open support',
                          '${data.openSupportTickets}',
                          Icons.support_agent_rounded,
                          const Color(0xffEC4899),
                        ),
                      ]),
                      SizedBox(height: scale.getScaledHeight(18)),
                      _chartCard(context, scale, data.monthlyOverview),
                      SizedBox(height: scale.getScaledHeight(24)),
                    ]),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    ScalingUtility scale,
    AdminDashboardController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        scale.getScaledWidth(8),
        scale.getScaledHeight(10),
        scale.getScaledWidth(14),
        scale.getScaledHeight(14),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xff16052C), Color(0xff231044)]
              : const [Color(0xff3A075F), Color(0xff6F18A8)],
        ),
      ),
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
                Text(
                  'Admin dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: scale.getScaledFont(20),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'ClickNow operations at a glance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: scale.getScaledFont(11),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: controller.isRefreshing.value
                ? null
                : controller.refresh,
            icon: controller.isRefreshing.value
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(
    BuildContext context,
    String title,
    String subtitle,
    ScalingUtility scale,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: scale.getScaledFont(16),
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: scale.getScaledFont(11),
          ),
        ),
      ],
    );
  }

  Widget _metricGrid(
    BuildContext context,
    ScalingUtility scale,
    List<_Metric> metrics,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100
        ? 4
        : width >= 700
        ? 3
        : 2;
    return GridView.builder(
      itemCount: metrics.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: scale.getScaledHeight(10),
        crossAxisSpacing: scale.getScaledWidth(10),
        childAspectRatio: width < 420 ? 1.42 : 1.65,
      ),
      itemBuilder: (_, index) => _metricCard(context, scale, metrics[index]),
    );
  }

  Widget _metricCard(
    BuildContext context,
    ScalingUtility scale,
    _Metric metric,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(scale.getScaledWidth(12)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff181128) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xff332746) : const Color(0xffE5E7EB),
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D111827),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
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
                color: scheme.onSurface,
                fontSize: scale.getScaledFont(20),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(3)),
          Text(
            metric.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: scale.getScaledFont(11),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(
    BuildContext context,
    ScalingUtility scale,
    List<AdminMonthlyOverview> data,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final maxValue = data.fold<double>(
      0,
      (current, item) =>
          [current, item.revenue, item.payout].reduce((a, b) => a > b ? a : b),
    );
    return Container(
      padding: EdgeInsets.all(scale.getScaledWidth(14)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff181128) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xff332746) : const Color(0xffE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            context,
            'Six-month financial overview',
            'Successful payments compared with professional payouts',
            scale,
          ),
          SizedBox(height: scale.getScaledHeight(12)),
          SizedBox(
            height: scale.getScaledHeight(260),
            child: maxValue == 0
                ? Center(
                    child: Text(
                      'Financial activity will appear here.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  )
                : SfCartesianChart(
                    margin: EdgeInsets.zero,
                    plotAreaBorderWidth: 0,
                    tooltipBehavior: TooltipBehavior(enable: true),
                    legend: Legend(
                      isVisible: true,
                      position: LegendPosition.bottom,
                      textStyle: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      axisLine: AxisLine(color: scheme.outlineVariant),
                      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    primaryYAxis: NumericAxis(
                      axisLine: const AxisLine(width: 0),
                      majorTickLines: const MajorTickLines(size: 0),
                      numberFormat: null,
                      labelFormat: '₹{value}',
                      majorGridLines: MajorGridLines(
                        color: scheme.outlineVariant.withValues(alpha: 0.55),
                        dashArray: const [4, 4],
                      ),
                      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    series: <CartesianSeries<AdminMonthlyOverview, String>>[
                      ColumnSeries<AdminMonthlyOverview, String>(
                        name: 'Revenue',
                        dataSource: data,
                        xValueMapper: (item, _) => item.label,
                        yValueMapper: (item, _) => item.revenue,
                        color: const Color(0xff6B4EFF),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                      ColumnSeries<AdminMonthlyOverview, String>(
                        name: 'Payout',
                        dataSource: data,
                        xValueMapper: (item, _) => item.label,
                        yValueMapper: (item, _) => item.payout,
                        color: const Color(0xff10B981),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(
    BuildContext context,
    String message,
    ScalingUtility scale,
  ) {
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
    return '₹${out.reversed.join()}';
  }
}

class _Metric {
  const _Metric(this.title, this.value, this.icon, this.color);

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

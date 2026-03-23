import 'package:clicknow_version2/app/screens/admin/widgets/admin_drawer.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff0A0713),
            Color(0xff1A0D2C),
            Color(0xff12091F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AdminDrawer(scale: scale),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: scale.getScaledWidth(16),
              vertical: scale.getScaledHeight(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, scale),
                SizedBox(height: scale.getScaledHeight(16)),
                _buildStatsGrid(scale),
                SizedBox(height: scale.getScaledHeight(18)),
                _buildSectionTitle("Booking Status Distribution", scale),
                SizedBox(height: scale.getScaledHeight(10)),
                _buildBookingStatusGrid(scale),
                SizedBox(height: scale.getScaledHeight(18)),
                _buildSectionTitle("Monthly Overview", scale),
                SizedBox(height: scale.getScaledHeight(10)),
                _buildChartCard(scale),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ScalingUtility scale) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) => GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              height: scale.getScaledHeight(36),
              width: scale.getScaledWidth(36),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                Icons.menu,
                color: Colors.white.withValues(alpha: 0.9),
                size: scale.getScaledWidth(18),
              ),
            ),
          ),
        ),
        SizedBox(width: scale.getScaledWidth(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ClickNow Admin’s Dashboard",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: scale.getScaledFont(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: scale.getScaledHeight(2)),
              Text(
                "Overview of your booking performance",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: scale.getScaledFont(11),
                ),
              ),
            ],
          ),
        ),
        _buildNotificationBadge(scale),
      ],
    );
  }

  Widget _buildNotificationBadge(ScalingUtility scale) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: scale.getScaledHeight(36),
          width: scale.getScaledWidth(36),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(
            Icons.notifications_none,
            color: Colors.white,
            size: scale.getScaledWidth(18),
          ),
        ),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            height: scale.getScaledHeight(16),
            width: scale.getScaledWidth(16),
            decoration: BoxDecoration(
              color: const Color(0xff6C3DFF),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.2),
            ),
            child: Center(
              child: Text(
                "6",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: scale.getScaledFont(8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ScalingUtility scale) {
    final cards = [
      _StatCardData(
        title: "Total Professionals",
        value: "127",
        delta: "+12%",
        icon: Icons.badge,
        iconColor: const Color(0xff9F62FF),
      ),
      _StatCardData(
        title: "Pending Approvals",
        value: "8",
        delta: "+12%",
        icon: Icons.pending_actions,
        iconColor: const Color(0xffFF9E2C),
      ),
      _StatCardData(
        title: "Total Customer",
        value: "127",
        delta: "+12%",
        icon: Icons.groups,
        iconColor: const Color(0xff5FD6FF),
      ),
      _StatCardData(
        title: "Active Bookings",
        value: "8",
        delta: "+12%",
        icon: Icons.event_available,
        iconColor: const Color(0xff3DFFB2),
      ),
      _StatCardData(
        title: "Monthly Revenue",
        value: "127",
        delta: "+12%",
        icon: Icons.attach_money,
        iconColor: const Color(0xff7C7CFF),
      ),
      _StatCardData(
        title: "Pending Payout",
        value: "8",
        delta: "+12%",
        icon: Icons.account_balance_wallet,
        iconColor: const Color(0xffFF4D4D),
      ),
    ];

    return GridView.builder(
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: scale.getScaledHeight(12),
        crossAxisSpacing: scale.getScaledWidth(12),
        childAspectRatio: 1.28,
      ),
      itemBuilder: (context, index) => _StatCard(
        data: cards[index],
        scale: scale,
      ),
    );
  }

  Widget _buildSectionTitle(String title, ScalingUtility scale) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: scale.getScaledFont(13),
      ),
    );
  }

  Widget _buildBookingStatusGrid(ScalingUtility scale) {
    final items = [
      _StatCardData(
        title: "Completed Booking",
        value: "127",
        delta: "+12%",
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xff8E5CFF),
      ),
      _StatCardData(
        title: "In-Progress Booking",
        value: "8",
        delta: "+12%",
        icon: Icons.work_history_outlined,
        iconColor: const Color(0xffFF9E2C),
      ),
      _StatCardData(
        title: "Canceled Booking",
        value: "127",
        delta: "+12%",
        icon: Icons.cancel_outlined,
        iconColor: const Color(0xffFF4D4D),
      ),
      _StatCardData(
        title: "Confirmed Booking",
        value: "8",
        delta: "+12%",
        icon: Icons.event_available_outlined,
        iconColor: const Color(0xff3DFFB2),
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: scale.getScaledHeight(12),
        crossAxisSpacing: scale.getScaledWidth(12),
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) => _StatCard(
        data: items[index],
        scale: scale,
        compact: true,
      ),
    );
  }

  Widget _buildChartCard(ScalingUtility scale) {
    final data = [
      _MonthlyData('Jan', 58, 40),
      _MonthlyData('Feb', 70, 55),
      _MonthlyData('Mar', 78, 20),
      _MonthlyData('Apr', 82, 18),
      _MonthlyData('May', 74, 62),
      _MonthlyData('Jun', 40, 22),
    ];

    return Container(
      padding: EdgeInsets.all(scale.getScaledWidth(12)),
      decoration: BoxDecoration(
        color: const Color(0xff161025),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          textStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: scale.getScaledFont(10),
          ),
        ),
        primaryXAxis: CategoryAxis(
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: scale.getScaledFont(9),
          ),
        ),
        primaryYAxis: NumericAxis(
          axisLine: const AxisLine(width: 0),
          majorGridLines: MajorGridLines(
            color: Colors.white.withValues(alpha: 0.08),
          ),
          labelStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: scale.getScaledFont(9),
          ),
        ),
        series: <CartesianSeries<_MonthlyData, String>>[
          ColumnSeries<_MonthlyData, String>(
            name: 'Revenue',
            dataSource: data,
            xValueMapper: (item, _) => item.month,
            yValueMapper: (item, _) => item.revenue,
            color: const Color(0xff8E5CFF),
            width: 0.5,
          ),
          ColumnSeries<_MonthlyData, String>(
            name: 'Payout',
            dataSource: data,
            xValueMapper: (item, _) => item.month,
            yValueMapper: (item, _) => item.payout,
            color: const Color(0xff6CFFB2),
            width: 0.5,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.data,
    required this.scale,
    this.compact = false,
  });

  final _StatCardData data;
  final ScalingUtility scale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(scale.getScaledWidth(compact ? 10 : 12)),
      decoration: BoxDecoration(
        color: const Color(0xff151022),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: scale.getScaledHeight(26),
            width: scale.getScaledWidth(26),
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              data.icon,
              color: data.iconColor,
              size: scale.getScaledWidth(14),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(8)),
          Text(
            data.title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: scale.getScaledFont(compact ? 10 : 11),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(4)),
          Row(
            children: [
              Text(
                data.value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: scale.getScaledFont(compact ? 16 : 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: scale.getScaledHeight(4)),
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: const Color(0xff31FF89),
                size: scale.getScaledWidth(12),
              ),
              SizedBox(width: scale.getScaledWidth(4)),
              Text(
                "${data.delta} vs last month",
                style: TextStyle(
                  color: const Color(0xff31FF89),
                  fontSize: scale.getScaledFont(9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.title,
    required this.value,
    required this.delta,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String delta;
  final IconData icon;
  final Color iconColor;
}

class _MonthlyData {
  const _MonthlyData(this.month, this.revenue, this.payout);

  final String month;
  final double revenue;
  final double payout;
}

import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key, required this.scale, this.activeRoute});

  final ScalingUtility scale;
  final String? activeRoute;

  @override
  Widget build(BuildContext context) {
    final items = _drawerItems();
    final drawerWidth = MediaQuery.of(context).size.width * 0.78;

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff1A0A2F), Color(0xff120621), Color(0xff0B0616)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale.getScaledWidth(16),
                    vertical: scale.getScaledHeight(8),
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isActive =
                        item.route != null && item.route == activeRoute;
                    return ListTile(
                      onTap: () {
                        Get.back();
                        final route = item.route;
                        if (route == null || route == Get.currentRoute) {
                          return;
                        }
                        Future.microtask(() => Get.offNamed(route));
                      },
                      tileColor: isActive
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: scale.getScaledWidth(6),
                      ),
                      leading: Icon(
                        item.icon,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.85),
                        size: scale.getScaledWidth(18),
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.9),
                          fontSize: scale.getScaledFont(13),
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        size: scale.getScaledWidth(18),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => Divider(
                    height: scale.getScaledHeight(8),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  itemCount: items.length,
                ),
              ),
              SizedBox(height: scale.getScaledHeight(12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: scale.getScaledWidth(16),
        vertical: scale.getScaledHeight(16),
      ),
      child: Row(
        children: [
          Container(
            height: scale.getScaledHeight(46),
            width: scale.getScaledWidth(46),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "CN",
                style: TextStyle(
                  color: AppColors.purple3,
                  fontWeight: FontWeight.bold,
                  fontSize: scale.getScaledFont(18),
                ),
              ),
            ),
          ),
          SizedBox(width: scale.getScaledWidth(12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ClickNow",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: scale.getScaledFont(18),
                ),
              ),
              SizedBox(height: scale.getScaledHeight(2)),
              Text(
                "Admins",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: scale.getScaledFont(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_DrawerItem> _drawerItems() {
    return const [
      _DrawerItem(
        label: "Dashboard",
        icon: Icons.grid_view_rounded,
        route: AppRoutes.adminDashboardRoute,
      ),
      _DrawerItem(
        label: "Professionals",
        icon: Icons.badge_outlined,
        route: AppRoutes.adminProfessionalsRoute,
      ),
      _DrawerItem(
        label: "Customers",
        icon: Icons.groups_outlined,
        route: AppRoutes.adminCustomersRoute,
      ),
      _DrawerItem(
        label: "Bookings",
        icon: Icons.calendar_month_outlined,
        route: AppRoutes.adminBookingsRoute,
      ),
      _DrawerItem(
        label: "Services",
        icon: Icons.work_outline,
        route: AppRoutes.adminServicesRoute,
      ),
      _DrawerItem(
        label: "Payments",
        icon: Icons.payments_outlined,
        route: AppRoutes.adminPaymentsRoute,
      ),
      _DrawerItem(
        label: "Support & Disputes",
        icon: Icons.support_agent,
        route: AppRoutes.adminSupportDisputesRoute,
      ),
      _DrawerItem(label: "Reports & Analytics", icon: Icons.query_stats),
      _DrawerItem(
        label: "Content & Portfolio",
        icon: Icons.photo_library_outlined,
        route: AppRoutes.adminContentPortfolioRoute,
      ),
      _DrawerItem(
        label: "Settings",
        icon: Icons.settings_outlined,
        route: AppRoutes.adminSettingsRoute,
      ),
    ];
  }
}

class _DrawerItem {
  const _DrawerItem({required this.label, required this.icon, this.route});

  final String label;
  final IconData icon;
  final String? route;
}

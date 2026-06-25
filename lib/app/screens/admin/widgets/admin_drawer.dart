import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
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

    return Drawer(
      width: ResponsiveUtility.width(300),
      backgroundColor: Colors.transparent,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtility.width(16),
                    vertical: ResponsiveUtility.height(8),
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isActive = item.route != null && item.route == activeRoute;
                    return ListTile(
                      onTap: () {
                        Get.back();
                        final route = item.route;
                        if (route == null || route == Get.currentRoute) {
                          return;
                        }
                        Future.microtask(() => Get.offNamed(route));
                      },
                      tileColor: isActive ? Colors.black.withValues(alpha: 0.08) : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: ResponsiveUtility.symmetric(horizontal: 10),
                      leading: Icon(
                        item.icon,
                        color: isActive ? AppColors.primaryColor : Colors.black.withValues(alpha: 0.4),
                        size: ResponsiveUtility.height(18),
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isActive ? AppColors.primaryColor : Colors.black.withValues(alpha: 0.4),
                          fontSize: ResponsiveUtility.fontSize(14),
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: isActive ? AppColors.primaryColor : Colors.black.withValues(alpha: 0.4),
                        size: ResponsiveUtility.height(18),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => Divider(
                    height: ResponsiveUtility.height(10),
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                  itemCount: items.length,
                ),
              ),
              SizedBox(height: ResponsiveUtility.height(10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: ResponsiveUtility.all(16),
      child: Row(
        children: [
          Container(
            height: ResponsiveUtility.height(46),
            width: ResponsiveUtility.width(46),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "CN",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtility.fontSize(18),
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtility.width(12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ClickNow",
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtility.height(18),
                ),
              ),
              SizedBox(height: ResponsiveUtility.height(2)),
              Text(
                "Admins",
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.7),
                  fontSize: ResponsiveUtility.fontSize(12),
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
      _DrawerItem(
        label: "Notifications",
        icon: Icons.notifications_active_outlined,
        route: AppRoutes.adminNotificationsRoute,
      ),
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

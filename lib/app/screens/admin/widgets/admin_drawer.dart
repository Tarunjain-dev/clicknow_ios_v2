import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key, required this.scale});

  final ScalingUtility scale;

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
            colors: [
              Color(0xff1A0A2F),
              Color(0xff120621),
              Color(0xff0B0616),
            ],
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
                    return ListTile(
                      onTap: () => Get.back(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: scale.getScaledWidth(6),
                      ),
                      leading: Icon(
                        item.icon,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: scale.getScaledWidth(18),
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: scale.getScaledFont(13),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: scale.getScaledWidth(18),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => Divider(
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
      _DrawerItem(label: "Dashboard", icon: Icons.grid_view_rounded),
      _DrawerItem(label: "Professionals", icon: Icons.badge_outlined),
      _DrawerItem(label: "Customers", icon: Icons.groups_outlined),
      _DrawerItem(label: "Bookings", icon: Icons.calendar_month_outlined),
      _DrawerItem(label: "Services", icon: Icons.work_outline),
      _DrawerItem(label: "Payments", icon: Icons.payments_outlined),
      _DrawerItem(label: "Support & Disputes", icon: Icons.support_agent),
      _DrawerItem(label: "Reports & Analytics", icon: Icons.query_stats),
      _DrawerItem(label: "Content & Portfolio", icon: Icons.photo_library_outlined),
      _DrawerItem(label: "Settings", icon: Icons.settings_outlined),
    ];
  }
}

class _DrawerItem {
  const _DrawerItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

import 'package:clicknow_version2/app/screens/admin/settings/getx/admin_settings_controller.dart';
import 'package:clicknow_version2/app/screens/admin/widgets/admin_drawer.dart';
import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();
    final controller = Get.isRegistered<AdminSettingsController>() ? Get.find<AdminSettingsController>() : Get.put(AdminSettingsController());

    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AdminDrawer(scale: scale, activeRoute: AppRoutes.adminSettingsRoute),
        body: Column(
          children: <Widget>[
            _buildHeader(scale),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  scale.getScaledWidth(14),
                  scale.getScaledHeight(14),
                  scale.getScaledWidth(14),
                  scale.getScaledHeight(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildSectionTitle(scale),
                    SizedBox(height: scale.getScaledHeight(12)),
                    _buildLogoutCard(scale, controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ScalingUtility scale) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        scale.getScaledWidth(10),
        scale.getScaledHeight(60),
        scale.getScaledWidth(12),
        scale.getScaledHeight(12),
      ),
      decoration: const BoxDecoration(
        color: Color(0xff6F18A8),
        border: Border(bottom: BorderSide(color: Color(0xffD9D9D9), width: 1)),
      ),
      child: Row(
        children: <Widget>[
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              splashRadius: 22,
              icon: Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: scale.getScaledWidth(28),
              ),
            ),
          ),
          SizedBox(width: scale.getScaledWidth(6)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: scale.getScaledFont(18),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Manage admin session and app preferences',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: scale.getScaledFont(11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ScalingUtility scale) {
    return Text(
      'Account Settings',
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: scale.getScaledFont(15),
      ),
    );
  }

  Widget _buildLogoutCard(
    ScalingUtility scale,
    AdminSettingsController controller,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xffF6F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Padding(
        padding: EdgeInsets.all(scale.getScaledWidth(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  height: scale.getScaledHeight(36),
                  width: scale.getScaledWidth(36),
                  decoration: BoxDecoration(
                    color: const Color(0xffFFE5E5).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: const Color(0xffFF0000),
                    size: scale.getScaledWidth(18),
                  ),
                ),
                SizedBox(width: scale.getScaledWidth(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: scale.getScaledFont(14),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Securely sign out from admin account',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.62),
                          fontSize: scale.getScaledFont(11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: scale.getScaledHeight(12)),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLogoutInProgress.value
                      ? null
                      : () => _showLogoutConfirmation(controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4B176F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: controller.isLogoutInProgress.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: scale.getScaledFont(13),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation(AdminSettingsController controller) async {
    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.black),
        ),
        content: const Text(
          'Are you sure you want to logout from admin account?',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: Get.back,
            child: Text('Cancel', style: TextStyle(color: const Color(0xff171230))),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}

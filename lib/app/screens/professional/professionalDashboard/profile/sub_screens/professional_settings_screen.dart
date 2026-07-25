import 'package:clicknow_version2/app/screens/professional/professionalDashboard/profile/getx/professionalProfile_Controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalSettingsScreen extends StatelessWidget {
  const ProfessionalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling Utility instance
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();
    final controller = ProfessionalProfileController.instance;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              /// -- Header section
              _header(scale, isDark),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    scale.getScaledWidth(14),
                    scale.getScaledHeight(12),
                    scale.getScaledWidth(14),
                    scale.getScaledHeight(16),
                  ),
                  children: [
                    Obx(
                      () => _settingTile(
                        scale: scale,
                        title: 'Logout',
                        subtitle: 'Sign out of your account.',
                        icon: Icons.logout_rounded,
                        iconColor: isDark ? Color(0xffFFB300) : Color(0xffFF9F2B),
                        borderColor: isDark ? Color(0xffFFB300) : Color(0xffFF9F2B),
                        background: isDark ? Color(0xff2E1E14) : Color(0xffFFF8F3),
                        isLoading: controller.isLogoutInProgress.value,
                        onTap: () => _confirmLogout(controller, isDark),
                        isDark : isDark,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtility.height(10)),
                    Obx(
                      () => _settingTile(
                        scale: scale,
                        title: 'Delete Account',
                        subtitle: 'Request delete your account.',
                        icon: Icons.delete_outline_rounded,
                        iconColor: isDark ? Color(0xffFF5B66) : Color(0xffFF0000),
                        borderColor: isDark ? Color(0xffFF5B66) : Color(0xffFF0000),
                        background: isDark ? Color(0xff2B1734) : Color(0xffFFE5E5).withValues(alpha: 0.4),
                        isLoading: controller.isDeleteRequestInProgress.value,
                        onTap: () => _confirmDelete(controller, isDark),
                        isDark: isDark
                      ),
                    ),
                    SizedBox(height: ResponsiveUtility.height(10)),
                    Container(
                      width: double.infinity,
                      padding: ResponsiveUtility.only(left: 12, top: 10, right: 10, bottom: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xff1A1436) : Color(0xffFCFBFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: Color(0xffB629FF), size: 18,),
                              SizedBox(width: ResponsiveUtility.width(8)),
                              Text(
                                'Account Security',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: ResponsiveUtility.fontSize(16),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveUtility.fontSize(6)),
                          Text(
                            'Keep your account secure by using a strong password and logging out from shared devices.',
                            style: TextStyle(
                              color: isDark ? Colors.white.withValues(alpha: 0.58) : Colors.black.withValues(alpha: 0.58),
                              fontSize: ResponsiveUtility.fontSize(12),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ScalingUtility scale, bool isDark) {
    return Container(
      padding: ResponsiveUtility.only(left: 8, top: 8, right: 12, bottom: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          ),
          Expanded(
            child: Text(
              'Settings',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveUtility.fontSize(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingTile({
    required ScalingUtility scale,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required Color background,
    required bool isLoading,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: ResponsiveUtility.only(left: 12, top: 10, right: 12, bottom: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            SizedBox(width: scale.getScaledWidth(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: borderColor,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtility.fontSize(16),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.85),
                      fontSize: ResponsiveUtility.fontSize(14),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                height: ResponsiveUtility.height(20),
                width: ResponsiveUtility.width(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.85),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white.withValues(alpha: 1) : Colors.black.withValues(alpha: 1),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(ProfessionalProfileController controller, bool isDark) async {
    final confirmed = await _showActionDialog(
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      accentColor: const Color(0xffFFB300),
      icon: Icons.logout_rounded,
      isDark: isDark,
    );
    if (confirmed == true) {
      await controller.logout();
    }
  }

  Future<void> _confirmDelete(ProfessionalProfileController controller, bool isDark) async {
    final confirmed = await _showActionDialog(
      title: 'Delete Account',
      message: 'Are you sure you want to request account deletion? This action will be reviewed by support.',
      confirmLabel: 'Request Delete',
      accentColor: const Color(0xffFF5B66),
      icon: Icons.warning_amber_rounded,
      isDark: isDark
    );
    if (confirmed == true) {
      await controller.requestDeleteAccount();
    }
  }

  Future<bool?> _showActionDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color accentColor,
    required IconData icon,
    required bool isDark,
  }) {
    final dialogContext = Get.overlayContext ?? Get.context;
    if (dialogContext == null) {
      return Future<bool?>.value(false);
    }
    return Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: ResponsiveUtility.all(16),
          decoration: BoxDecoration(
            color: isDark ? Color(0xff1A1436) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Color(0xff2A3363) : Colors.white),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: ResponsiveUtility.height(46),
                width: ResponsiveUtility.width(46),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              SizedBox(height: ResponsiveUtility.height(10)),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveUtility.fontSize(18),
                ),
              ),
              SizedBox(height: ResponsiveUtility.height(6)),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.72) : Colors.black.withValues(alpha: 0.72),
                  fontSize: ResponsiveUtility.fontSize(14),
                  height: 1.35,
                ),
              ),
              SizedBox(height: ResponsiveUtility.fontSize(14)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9)),
                        foregroundColor: isDark ? Colors.white70 : Colors.black54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtility.width(8)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

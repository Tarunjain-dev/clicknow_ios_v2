import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'getx/professionalProfile_Controller.dart';
import 'sub_screens/availability_schedule_screen.dart';
import 'sub_screens/bank_details_screen.dart';
import 'sub_screens/document_status_screen.dart';
import 'sub_screens/edit_professional_information_screen.dart';
import 'sub_screens/professional_settings_screen.dart';

class ProfessionalProfileScreen extends StatelessWidget {
  const ProfessionalProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    /// -- Dark Mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling Utility instance
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    /// -- Prof. Profile Controller instance
    final controller = ProfessionalProfileController.instance;

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xffB629FF)),
              );
            }
            return RefreshIndicator(
              onRefresh: () => controller.refreshProfile(showMessage: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: ResponsiveUtility.only(
                  left: 14,
                  top: 12,
                  right: 14,
                  bottom: 16,
                ),
                children: [
                  Text(
                    "My Profile",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: ResponsiveUtility.fontSize(18),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "Manage your account and preferences",
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.62)
                          : Colors.black.withValues(alpha: 0.62),
                      fontSize: ResponsiveUtility.fontSize(12),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtility.height(12)),
                  _profileCard(scale, controller, isDark),
                  SizedBox(height: ResponsiveUtility.height(10)),
                  _sectionCard(
                    scale: scale,
                    isDark: isDark,
                    title: "General Settings",
                    children: [
                      _menuTile(
                        scale: scale,
                        isDark: isDark,
                        title: 'Edit Professional Information',
                        subtitle: 'Update profile, work days and locations',
                        icon: Icons.person_outline,
                        onTap: () => Get.to(
                          () => const EditProfessionalInformationScreen(),
                        ),
                      ),
                      _menuTile(
                        scale: scale,
                        isDark: isDark,
                        title: 'Availability & Schedule',
                        subtitle: 'Manage working calendar',
                        icon: Icons.calendar_month_outlined,
                        onTap: () =>
                            Get.to(() => const AvailabilityScheduleScreen()),
                      ),
                    ],
                  ),

                  /// -- Document & Banking
                  SizedBox(height: ResponsiveUtility.height(10)),
                  _sectionCard(
                    scale: scale,
                    isDark: isDark,
                    title: "Document & Banking",
                    children: [
                      _menuTile(
                        scale: scale,
                        isDark: isDark,
                        title: 'Document Status',
                        subtitle: 'Aadhaar and PAN verification status',
                        icon: Icons.description_outlined,
                        onTap: () => Get.to(() => const DocumentStatusScreen()),
                      ),
                      _menuTile(
                        scale: scale,
                        isDark: isDark,
                        title: 'Bank Details',
                        subtitle: 'View linked account and payout details',
                        icon: Icons.account_balance_outlined,
                        onTap: () => Get.to(() => const BankDetailsScreen()),
                      ),
                    ],
                  ),

                  /// -- General Settings
                  SizedBox(height: ResponsiveUtility.height(10)),
                  _sectionCard(
                    scale: scale,
                    isDark: isDark,
                    title: "General Settings",
                    children: [
                      _menuTile(
                        scale: scale,
                        isDark: isDark,
                        title: 'Help & Support',
                        subtitle: 'Contact Us.',
                        icon: Icons.help_outline,
                        onTap: () => Get.toNamed(
                          AppRoutes.helpSupportRoute,
                          arguments: <String, dynamic>{'role': 'professional'},
                        ),
                      ),
                      // _menuTile(
                      //   scale: scale,
                      //   isDark: isDark,
                      //   title: 'Privacy Policy',
                      //   subtitle: 'How we use your data',
                      //   icon: Icons.privacy_tip_outlined,
                      //   onTap: () => {},
                      // ),
                      // _menuTile(
                      //   scale: scale,
                      //   isDark: isDark,
                      //   title: 'Rate the app',
                      //   subtitle: 'Help us improve',
                      //   icon: Icons.star_rate,
                      //   onTap: () => {},
                      // ),
                      _menuTile(
                        scale: scale,
                        isDark: isDark,
                        title: 'Account Settings',
                        subtitle: 'Logout and account settings',
                        icon: Icons.settings_outlined,
                        onTap: () =>
                            Get.to(() => const ProfessionalSettingsScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _profileCard(
    ScalingUtility scale,
    ProfessionalProfileController controller,
    bool isDark,
  ) {
    final data = controller.profile.value;
    return Container(
      width: double.infinity,
      padding: ResponsiveUtility.only(left: 12, top: 12, right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xff17122F) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Color(0xff2C2750) : Color(0xffD9D9D9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: ResponsiveUtility.width(48),
                height: ResponsiveUtility.height(48),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF5C86A),
                    width: ResponsiveUtility.width(2),
                  ),
                ),
                child: ClipOval(
                  child: _profileImageWidget(
                    scale: scale,
                    imageUrl: data.profileImageUrl,
                  ),
                ),
              ),
              Positioned(
                right: -ResponsiveUtility.width(2),
                bottom: -ResponsiveUtility.height(2),
                child: InkWell(
                  onTap: controller.onProfileImageTap,
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    width: ResponsiveUtility.width(18),
                    height: ResponsiveUtility.height(18),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF20334F) : Color(0xffFCFBFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Color(0xFF2F5A8A) : Color(0xffD9D9D9),
                      ),
                    ),
                    child: controller.isUploadingProfileImage.value
                        ? Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 1.6,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.all(3),
                            child: Image.asset(
                              AppImages.camera,
                              width: ResponsiveUtility.width(12),
                              height: ResponsiveUtility.height(12),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: ResponsiveUtility.width(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.fullName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtility.fontSize(16),
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(2)),
                Text(
                  data.phoneNumber.isEmpty ? '-' : data.phoneNumber,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.72)
                        : Colors.black.withValues(alpha: 0.72),
                    fontSize: ResponsiveUtility.fontSize(12),
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(6)),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Color(0xffD000FF),
                      size: 14,
                    ),
                    SizedBox(width: ResponsiveUtility.width(4)),
                    Expanded(
                      child: Text(
                        data.locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.76)
                              : Colors.black.withValues(alpha: 0.76),
                          fontSize: ResponsiveUtility.fontSize(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required ScalingUtility scale,
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xff17122F) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Color(0xff2C2750) : Color(0xffD9D9D9),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: ResponsiveUtility.only(
              left: 12,
              top: 10,
              right: 12,
              bottom: 8,
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtility.fontSize(16),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: isDark ? Color(0xff2C2750) : Color(0xffD9D9D9),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _menuTile({
    required ScalingUtility scale,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: ResponsiveUtility.only(
          left: 12,
          top: 10,
          right: 12,
          bottom: 8,
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xffD000FF), size: 16),
            SizedBox(width: ResponsiveUtility.width(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveUtility.fontSize(14),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtility.height(2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.6),
                      fontSize: ResponsiveUtility.fontSize(12),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.62)
                  : Colors.black.withValues(alpha: 0.62),
              size: ResponsiveUtility.width(24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileImageWidget({
    required ScalingUtility scale,
    required String imageUrl,
  }) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return Image.asset(AppImages.avtar2, fit: BoxFit.cover);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: Color(0xFF191C39),
          alignment: Alignment.center,
          child: SizedBox(
            width: scale.getScaledWidth(14),
            height: scale.getScaledHeight(14),
            child: const CircularProgressIndicator(
              strokeWidth: 1.8,
              color: Colors.white,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) {
        return Image.asset(AppImages.avtar2, fit: BoxFit.cover);
      },
    );
  }
}

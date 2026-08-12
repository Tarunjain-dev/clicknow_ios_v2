import 'package:clicknow_version2/app/screens/customer/profile/getx/customer_profile_controller.dart';
import 'package:clicknow_version2/app/screens/customer/profile/sub_screens/edit_personal_information_screen.dart';
import 'package:clicknow_version2/app/screens/customer/profile/sub_screens/invoice_history_screen.dart';
import 'package:clicknow_version2/app/screens/customer/profile/sub_screens/saved_address_screen.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Scaling Utility instance
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    /// -- Customer profile controller
    final controller = CustomerProfileController.instance;

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color:  isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: ResponsiveUtility.only(left: 14, top: 14,right: 14, bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Profile',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveUtility.fontSize(18),
                            ),
                          ),
                          SizedBox(height: scale.getScaledHeight(2)),
                          Text(
                            'Manage your account and preferences',
                            style: TextStyle(
                              color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                              fontSize: ResponsiveUtility.fontSize(14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: isDark ? Color(0xFF28305F) : Color(0xFFD9D9D9)),
              Expanded(
                child: SingleChildScrollView(
                  padding: ResponsiveUtility.only(left: 12, top: 10,right: 12, bottom: 16),
                  child: Column(
                    children: [
                      _profileCard(scale, controller, isDark),
                      SizedBox(height: ResponsiveUtility.height(10)),
                      Obx(() => _settingsCard(scale, controller, isDark)),
                      SizedBox(height: ResponsiveUtility.height(10)),
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          height: scale.getScaledHeight(44),
                          child: OutlinedButton(
                            onPressed: controller.isGuestUser.value
                                ? () async {
                                    await controller.ensureLoggedInForRestrictedAction();
                                  }
                                : () async {
                                    await controller.onLogout();
                                  },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: controller.isGuestUser.value
                                    ? const Color(0xFF4A5AA2)
                                    : const Color(0xFFFF2A37),
                              ),
                              foregroundColor: controller.isGuestUser.value
                                  ? Colors.white
                                  : const Color(0xFFFF3E4A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              controller.isGuestUser.value
                                  ? 'Login with Phone'
                                  : 'Logout',
                              style: TextStyle(
                                color: isDark ? Color(0xFFD9D9D9) : Color.fromARGB(255, 33, 39, 77),
                                fontWeight: FontWeight.w600,
                                fontSize: scale.getScaledFont(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: scale.getScaledHeight(10)),
                      Text(
                        'ClickNow | v2.0.1+2',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                          fontSize: ResponsiveUtility.fontSize(10),
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

  Widget _profileCard(ScalingUtility scale, CustomerProfileController controller, bool isDark) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtility.only(left: 10, top: 10,right: 10, bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF0F1030).withValues(alpha: 0.95) : Color(0xFFFCFBFF).withValues(alpha: 1.0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Color(0xFF2A3363) : Color(0xFFD9D9D9)),
      ),
      child: Obx(
        () => Column(
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: ResponsiveUtility.width(44),
                      height: ResponsiveUtility.height(44),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF5C86A), width: 2),
                      ),
                      child: ClipOval(
                        child: _profileImageWidget(
                          scale: scale,
                          imageUrl: controller.profileImageUrl.value,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: InkWell(
                        onTap: controller.onProfileImageTap,
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          width: ResponsiveUtility.width(18),
                          height: ResponsiveUtility.height(18),
                          decoration: BoxDecoration(
                            color: isDark ? Color(0xFF20334F) : Color(0xFFFCFBFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? Color(0xFF2F5A8A) : Color(0xFFD9D9D9)),
                          ),
                          child: controller.isUploadingProfileImage.value
                              ? Padding(
                                  padding: ResponsiveUtility.all(4),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.6,
                                    color: Colors.white,
                                  ),
                                )
                              : Padding(
                                  padding: ResponsiveUtility.all(3),
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
                SizedBox(width: ResponsiveUtility.height(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.fullName.value,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.black,
                          fontSize: ResponsiveUtility.fontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtility.height(2)),
                      Text(
                        controller.phone.value,
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.68) : Colors.black.withValues(alpha: 0.68),
                          fontSize: ResponsiveUtility.fontSize(12),
                        ),
                      ),
                      if (controller.isGuestUser.value) ...[
                        SizedBox(height: ResponsiveUtility.height(4)),
                        Container(
                          padding: ResponsiveUtility.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Color(0xFF2A2F66) : Color(0xFFFCFBFF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Guest Mode',
                            style: TextStyle(
                              color: isDark ? Color(0xFFC8D0FF) : Color(0xFFD9D9D9),
                              fontSize: ResponsiveUtility.fontSize(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtility.height(10)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: const Color(0xFFD100FF),
                  size: ResponsiveUtility.width(18),
                ),
                SizedBox(width: ResponsiveUtility.width(8)),
                Expanded(
                  child: Text(
                    controller.location.value,
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                      fontSize: ResponsiveUtility.fontSize(14),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtility.height(6)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: const Color(0xFFD100FF),
                  size: ResponsiveUtility.width(16),
                ),
                SizedBox(width: ResponsiveUtility.width(8)),
                Expanded(
                  child: Text(
                    'Member since ${controller.memberSince.value}',
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                      fontSize: ResponsiveUtility.fontSize(14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard(ScalingUtility scale, CustomerProfileController controller, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF151233).withValues(alpha: 0.95) : Color(0xFFFCFBFF).withValues(alpha: 1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Color(0xFF2A3363) : Color(0xFFD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(12),
              scale.getScaledHeight(10),
              scale.getScaledWidth(12),
              scale.getScaledHeight(8),
            ),
            child: Text(
              'General Settings',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.black,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtility.fontSize(14),
              ),
            ),
          ),
          Container(height: 1, color: isDark ? Color(0xFF2A3363).withValues(alpha: 0.9) : Color(0xFFD9D9D9).withValues(alpha: 0.9)),
          _settingItem(
            scale: scale,
            isDark: isDark,
            icon: Icons.person_outline,
            title: 'Edit Personal Information',
            subtitle: 'Update name, email & other information.',
            onTap: () async {
              final allowed = await controller.ensureLoggedInForRestrictedAction(
                message: 'Please login to update personal information',
              );
              if (!allowed) {
                return;
              }
              Get.to(() => const EditPersonalInformationScreen());
            },
          ),
          _settingItem(
            scale: scale,
            isDark: isDark,
            icon: Icons.receipt_long_outlined,
            title: 'Invoice History',
            subtitle:
                '${controller.invoices.length} invoices. Rs.${_formatAmount(controller.totalInvoiceAmount)} total',
            onTap: () async {
              final allowed = await controller.ensureLoggedInForRestrictedAction(
                message: 'Please login to view invoice history',
              );
              if (!allowed) {
                return;
              }
              Get.to(() => const InvoiceHistoryScreen());
            },
          ),
          _settingItem(
            scale: scale,
            isDark: isDark,
            icon: Icons.location_on_outlined,
            title: 'Saved address',
            subtitle: '${controller.savedAddresses.length} saved address',
            onTap: () async {
              final allowed = await controller.ensureLoggedInForRestrictedAction(
                message: 'Please login to manage saved addresses',
              );
              if (!allowed) {
                return;
              }
              Get.to(() => const SavedAddressScreen());
            },
          ),
          _settingItem(
            scale: scale,
            isDark: isDark,
            icon: Icons.support_agent_outlined,
            title: 'Help & Support',
            subtitle: 'FAQs & contact us',
            onTap: controller.onSupport,
          ),
          // _settingItem(
          //   scale: scale,
          //   isDark: isDark,
          //   icon: Icons.privacy_tip_outlined,
          //   title: 'Privacy policy',
          //   subtitle: 'How we use your data',
          //   onTap: controller.onPrivacyPolicy,
          // ),
          // _settingItem(
          //   scale: scale,
          //   isDark: isDark,
          //   icon: Icons.star_border_rounded,
          //   title: 'Rate the app',
          //   subtitle: 'Help us improve',
          //   onTap: controller.onRateApp,
          //   showDivider: false,
          // ),
        ],
      ),
    );
  }

  Widget _settingItem({
    required ScalingUtility scale,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(12),
              scale.getScaledHeight(9),
              scale.getScaledWidth(10),
              scale.getScaledHeight(9),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFFD100FF),
                  size: 16,
                ),
                SizedBox(width: ResponsiveUtility.width(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black.withValues(alpha: 0.92),
                          fontSize: ResponsiveUtility.fontSize(14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: scale.getScaledHeight(1)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                          fontSize: ResponsiveUtility.fontSize(12),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? Colors.white.withValues(alpha: 0.82) : Colors.black.withValues(alpha: 0.82),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            margin: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(12)),
            height: 0.5,
            color: isDark ? Color(0xFF2A3363).withValues(alpha: 0.6) : Color(0xFFD9D9D9).withValues(alpha: 0.6),
          ),
      ],
    );
  }

  Widget _profileImageWidget({
    required ScalingUtility scale,
    required String imageUrl,
  }) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return Image.asset(
        AppImages.avtar2,
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: const Color(0xFF191C39),
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
        return Image.asset(
          AppImages.avtar2,
          fit: BoxFit.cover,
        );
      },
    );
  }

  String _formatAmount(int amount) {
    final text = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final indexFromEnd = text.length - i;
      buffer.write(text[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}


import 'package:clicknow_version2/app/screens/professional/getx/professionalBottomNavBarController.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalBottomNavBar extends StatelessWidget {
  ProfessionalBottomNavBar({super.key});

  /// -- Professional Bottom Navigation Controller
  final ProfessionalBottomNavController professionalBottomNavController = Get.put(ProfessionalBottomNavController());

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,

        /// BODY
        body: Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 2),
            child: professionalBottomNavController.screens[professionalBottomNavController.index.value],
          ),
        ),

        /// BOTTOM NAVIGATION
        bottomNavigationBar: Obx(
          () => Container(
            height: ResponsiveUtility.height(72),
            padding: ResponsiveUtility.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Color(0xffFCFCFC).withValues(alpha: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildNavItem(isDark: isDark, index: 0, icon: Icons.home_outlined, activeIcon: Icons.home, label: "Dashboard",),
                buildNavItem(isDark: isDark, index: 1, icon: Icons.currency_rupee_rounded, activeIcon: Icons.currency_rupee_rounded, label: "Earnings",),
                buildNavItem(isDark: isDark, index: 2, icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory, label: "Bookings",),
                buildNavItem(isDark: isDark, index: 3, icon: Icons.person_outline, activeIcon: Icons.person, label: "Profile",),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNavItem({

    required bool isDark,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = professionalBottomNavController.index.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => professionalBottomNavController.changeTab(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(microseconds: 2),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: ResponsiveUtility.height(8)),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? Colors.deepPurple.withValues(alpha: 0.15) : const Color(0xffBF00FF).withValues(alpha: 0.06))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(ResponsiveUtility.radius(16)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isActive ? activeIcon : icon,
                  key: ValueKey(isActive),
                  size: 26,
                  color: isActive ? Colors.deepPurple : (isDark ? Colors.grey : Colors.black54),
                ),
              ),
              SizedBox(height: ResponsiveUtility.height(4)),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 2),
                style: TextStyle(
                  fontSize: ResponsiveUtility.fontSize(10),
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.deepPurple : (isDark ? Colors.grey : Colors.black54),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

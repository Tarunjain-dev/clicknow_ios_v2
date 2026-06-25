import 'package:clicknow_version2/app/screens/customer/getx/customerBottomNavController.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerBottomNavBar extends StatelessWidget {
  const CustomerBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Controller instance
    final CustomerBottomNavController bottomNavController = Get.isRegistered<CustomerBottomNavController>() ? Get.find<CustomerBottomNavController>() : Get.put(CustomerBottomNavController());

    /// -- Scaling utility
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 2),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: bottomNavController.screens[bottomNavController.index.value],
          ),
        ),
        bottomNavigationBar: Obx(
          () => Container(
            height: ResponsiveUtility.height(72),
            padding: ResponsiveUtility.symmetric(horizontal: 10, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  bottomNavController: bottomNavController,
                  scale: scale,
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isDark: isDark,
                ),
                _buildNavItem(
                  bottomNavController: bottomNavController,
                  scale: scale,
                  index: 1,
                  icon: Icons.image_outlined,
                  activeIcon: Icons.image,
                  label: 'Portfolio',
                  isDark: isDark,
                ),
                _buildNavItem(
                  bottomNavController: bottomNavController,
                  scale: scale,
                  index: 2,
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory,
                  label: 'Bookings',
                  isDark: isDark,
                ),
                _buildNavItem(
                  bottomNavController: bottomNavController,
                  scale: scale,
                  index: 3,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required CustomerBottomNavController bottomNavController,
    required ScalingUtility scale,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final bool isActive = bottomNavController.index.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => bottomNavController.changeTab(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 2),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: ResponsiveUtility.height(8)),
          decoration: BoxDecoration(
            color: isDark?
                    isActive ? Color(0xff10091B) : Colors.black:
                    isActive ? Color(0xffBF00FF).withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 2),
                child: Icon(
                  isActive ? activeIcon : icon,
                  key: ValueKey(isActive),
                  size: 24,
                  color: isActive ? Color(0xff700095) : Colors.grey,
                ),
              ),
              SizedBox(height: ResponsiveUtility.height(2)),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: ResponsiveUtility.fontSize(10),
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.deepPurple : Colors.grey,
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

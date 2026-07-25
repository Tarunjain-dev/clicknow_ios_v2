import 'package:clicknow_version2/app/screens/common/splash/getx/splash_Controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    Get.put(SplashController());
  }

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return SafeArea(
      child: Container(
        height: double.maxFinite,
        width: double.maxFinite,
        decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color:  isDark ? null : Colors.white,
      ),
        child: Scaffold(
          backgroundColor: AppColors.transparent,
          resizeToAvoidBottomInset: true,

          /// -- The Logo
          body: Center(
            child: SizedBox(
              height: ResponsiveUtility.height(70),
              width: double.maxFinite,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// -- "CN" in a box.
                  Container(
                    height: ResponsiveUtility.height(70),
                    width: ResponsiveUtility.width(70),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(ResponsiveUtility.radius(10)),
                      color: isDark ? AppColors.white : AppColors.primaryColor,
                    ),
                    child: Center(
                      child: Padding(
                        padding: ResponsiveUtility.all(8),
                        child: Text(
                          "CN",
                          style: TextStyle(
                            fontSize: ResponsiveUtility.fontSize(32),
                            color: isDark ? AppColors.purple3 : AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  /// -- ClickNow
                  SizedBox(width: ResponsiveUtility.width(8)),
                  Text(
                    'Click',
                    style: TextStyle(
                      fontSize: ResponsiveUtility.fontSize(38),
                      fontWeight: FontWeight.bold, color: isDark ? AppColors.white : AppColors.primaryColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Now',
                    style: TextStyle(
                      fontSize: ResponsiveUtility.fontSize(38),
                      fontWeight: FontWeight.normal,
                      color: isDark ? AppColors.white : AppColors.primaryColor,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

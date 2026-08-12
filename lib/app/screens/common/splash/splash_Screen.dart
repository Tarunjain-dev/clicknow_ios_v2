import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/common/splash/getx/splash_Controller.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
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
    debugPrint(
      '[SplashScreen] initState — pendingOtp=${AuthController.hasPendingOtp}',
    );
    // If a pending OTP exists (iOS reCAPTCHA return), skip the splash timer
    // entirely and go straight to the correct screen. Do NOT create a
    // SplashController — that would start a navigation timer that could
    // interrupt the OTP screen.
    if (ProfessionalRegistrationController.hasPendingOtp) {
      debugPrint(
        '[SplashScreen] initState — professional pending OTP detected, routing to registration',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.professionalRegistrationRoute);
      });
      return;
    }
    if (AuthController.hasPendingOtp) {
      debugPrint(
        '[SplashScreen] initState — pending OTP detected, routing to login immediately',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Ensure AuthController is alive so it restores OTP state.
        AuthController.instance;
        Get.offAllNamed(AppRoutes.loginRoute);
      });
      return;
    }
    // If a SplashController is already registered (e.g. GetX replayed the
    // initial route after returning from iOS reCAPTCHA), do not create a
    // second one — that would start a duplicate timer and navigate away from
    // the OTP screen.
    if (!Get.isRegistered<SplashController>()) {
      Get.put(SplashController());
    }
  }

  @override
  void dispose() {
    debugPrint('[SplashScreen] dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

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
    );
  }
}

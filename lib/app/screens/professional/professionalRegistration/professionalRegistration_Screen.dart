import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/stepper_controller.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/horizontal_stepper.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/stepperBody/stepFiveBody_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/stepperBody/stepFourBody_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/stepperBody/stepOneBody_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/stepperBody/stepThreeBody_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/stepperBody/stepTwoBody_Screen.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalRegistrationScreen extends StatelessWidget {
  const ProfessionalRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    /// -- Stepper Controller Instance
    final StepperController controller = Get.put(StepperController());

    /// -- Professional Registration Controller Instance
    final professionalRegController = Get.put(
      ProfessionalRegistrationController(),
    );

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Obx(() {
      final isStepOne = controller.currentStep.value == 0;
      final isLockedByPhoneFlow =
          professionalRegController.isPhoneVerified.value ||
          professionalRegController.isOtpSent.value;
      final canPop =
          !professionalRegController.isSubmittingProfile.value &&
          !(isStepOne && isLockedByPhoneFlow);

      return PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop && isStepOne && !isLockedByPhoneFlow) {
            AuthController.instance
                .restoreProfessionalStarterSectionBeforeVerification();
          }
        },
        child: Container(
          height: double.maxFinite,
          width: double.maxFinite,
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.primaryGradient : null,
            color: isDark ? null : Colors.white,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// -- Horizontal stepper
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: HorizontalStepper(),
                    ),

                    /// -- Divider
                    Divider(
                      color: isDark ? Color(0xff1E2939) : Color(0xffDDDDDD),
                      thickness: 1,
                    ),

                    /// -- Progress Indicator
                    Padding(
                      padding: ResponsiveUtility.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Obx(() {
                        final progress =
                            (controller.currentStep.value + 1) /
                            controller.steps.length;
                        final percent = (progress * 100).round();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Step ${controller.currentStep.value + 1} of ${controller.steps.length}",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: ResponsiveUtility.height(2)),
                            Text(
                              "Progress $percent%",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: ResponsiveUtility.fontSize(10),
                              ),
                            ),
                            SizedBox(height: ResponsiveUtility.height(6)),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: isDark
                                    ? Color(0xff1E2939)
                                    : AppColors.grey.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xff9235B1),
                                ),
                                borderRadius: BorderRadiusGeometry.circular(50),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),

                    /// BODY SCREENS
                    Obx(() {
                      if (!controller.isProgressLoaded.value ||
                          !professionalRegController.isDraftLoaded.value) {
                        return const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                      return Expanded(
                        child: PageView(
                          controller: controller.pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            StepOneBodyScreen(),
                            StepTwoBodyScreen(),
                            StepThreeBodyScreen(),
                            StepFourBodyScreen(),
                            StepFiveBodyScreen(),
                          ],
                        ),
                      );
                    }),

                    /// -- Support email of clicknow
                    Padding(
                      padding: ResponsiveUtility.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: Text.rich(
                        TextSpan(
                          text: "Need help? Contact support at ",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.black.withValues(alpha: 0.8),
                            fontSize: ResponsiveUtility.fontSize(14),
                          ),
                          children: const [
                            TextSpan(
                              text: "support@clicknow.co.in",
                              style: TextStyle(color: Color(0xff9235B1)),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtility.height(4)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

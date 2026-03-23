import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/stepper_controller.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/horizontal_stepper.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/stepperBody/stepFiveBody_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/stepperBody/stepFourBody_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/stepperBody/stepOneBody_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/stepperBody/stepThreeBody_Screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/stepperBody/stepTwoBody_Screen.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfessionalRegistrationScreen extends StatelessWidget {
  const ProfessionalRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Scaling Utility Instance
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    /// -- Stepper Controller Instance
    final StepperController controller = Get.put(StepperController());

    /// -- Professional Registration Controller Instance
    Get.put(ProfessionalRegistrationController());

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: HorizontalStepper(),
                ),

                const Divider(
                  color: Color(0xff1E2939),
                  thickness: 2,
                ),

                /// -- Progress Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Obx(() {
                    final progress =
                        (controller.currentStep.value + 1) / controller.steps.length;
                    final percent = (progress * 100).round();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Progress $percent%",
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: const Color(0xff1E2939),
                            valueColor: const AlwaysStoppedAnimation(Color(0xff9235B1)),
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                /// BODY SCREENS
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    children: [
                      StepOneBodyScreen(),
                      StepTwoBodyScreen(),
                      StepThreeBodyScreen(),
                      StepFourBodyScreen(),
                      StepFiveBodyScreen(),
                    ],
                  ),
                ),

                /// ACTION BUTTONS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text.rich(
                    TextSpan(
                      text: "Need help? Contact support at ",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      children: const [
                        TextSpan(
                          text: "support@example.com",
                          style: TextStyle(color: Color(0xff9235B1)),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

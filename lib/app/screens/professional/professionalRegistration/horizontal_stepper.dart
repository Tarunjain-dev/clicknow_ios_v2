import 'package:clicknow_version2/app/screens/professional/getx/stepper_controller.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HorizontalStepper extends StatelessWidget {
  HorizontalStepper({super.key});

  final StepperController controller = Get.find();

  // Base icon list (can be fewer than steps — safe handled)
  final List<IconData> _baseIcons = const [
    Icons.person_outline,
    Icons.location_on_outlined,
    Icons.payment_outlined,
    Icons.check_circle_outline,
    Icons.currency_rupee_rounded
  ];

  IconData _getStepIcon(int index) {
    if (index < _baseIcons.length) {
      return _baseIcons[index];
    }
    return Icons.circle_outlined; // fallback (prevents crash)
  }

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Align(
      alignment: Alignment.topCenter,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Obx(() {
            final stepsCount = controller.steps.length;
            final stepWidth = ResponsiveUtility.width(52.0);
            final remainingWidth = constraints.maxWidth - (stepsCount * stepWidth);
            final connectorWidth = stepsCount > 1 ? (remainingWidth / (stepsCount - 1)).clamp(8.0, 60.0) : 0.0;

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(stepsCount, (index) {
                final isActive = index == controller.currentStep.value;
                final isCompleted = index < controller.currentStep.value;
                final isEnabled = isActive || isCompleted;

                return Row(
                  children: [
                    SizedBox(
                      width: stepWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          // ICON CIRCLE
                          Container(
                            height: ResponsiveUtility.height(34),
                            width: ResponsiveUtility.width(34),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isEnabled ?
                              Color(0xff9A00CF):
                              isDark ? Color(0xff363636) : Color(0xffABABAB),
                            ),
                            child: Icon(_getStepIcon(index), size: 18, color: isEnabled ? Colors.white : isDark ? Color(0xff888888) : Colors.white,),
                          ),
                          SizedBox(height: ResponsiveUtility.height(6)),
                          Text('Step ${index + 1}', textAlign: TextAlign.center, style: TextStyle(fontSize: ResponsiveUtility.fontSize(10), color: isEnabled ? Color(0xff9A00CF) : Colors.grey.shade400,),),
                          SizedBox(height: ResponsiveUtility.height(2)),
                          Text(controller.steps[index], textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: ResponsiveUtility.fontSize(8), color: isEnabled ? isDark ? Colors.white : Colors.black : Colors.grey.shade400,),),
                        ],
                      ),
                    ),

                    // CONNECTOR
                    if (index != stepsCount - 1)
                      Container(
                        width: connectorWidth,
                        height: ResponsiveUtility.height(2.0),
                        margin: EdgeInsets.only(bottom: ResponsiveUtility.height(32)),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isCompleted ? Color(0xff9A00CF) : isDark ? Colors.grey.shade700 : Color(0xffDDDDDD),
                        ),
                      ),
                  ],
                );
              }),
            );
          });
        },
      ),
    );
  }
}

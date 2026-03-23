import 'package:clicknow_version2/app/screens/common/onboarding/getx/onboardingController.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/utils/device_constants/appStrings.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Initialize "ScalingUtility" class in EachScreen.
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    /// -- Onboarding Controller Instance
    final onBoardingController = Get.put(OnBoardingController());

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: Stack(
          children: [

            /// Horizontal scrollable pages
            PageView(
              controller: onBoardingController.pageController,
              onPageChanged: onBoardingController.updatePageIndicator,
              children: [
                OnBoardingPage(image: AppImages.onboarding1, title: AppStrings.onboardingTitle1, subtitle: AppStrings.onboardingDescription1,),
                OnBoardingPage(image: AppImages.onboarding2, title: AppStrings.onboardingTitle2, subtitle: AppStrings.onboardingDescription2,),
                OnBoardingPage(image: AppImages.onboarding3, title: AppStrings.onboardingTitle3, subtitle: AppStrings.onboardingDescription3,),
                OnBoardingPage(image: AppImages.onboarding4, title: AppStrings.onboardingTitle4, subtitle: AppStrings.onboardingDescription4,),
              ],
            ),

            /// Skip Button
            SkipButton(),

            /// Dot Navigation : SmoothPage Indicator
            Positioned(
                bottom: scale.getScaledHeight(40),
                left: scale.getScaledWidth(14),
                child: OnBoardingDotIndicator(),
            ),

            /// -- Next Button
            Positioned(
              bottom: scale.getScaledHeight(20),
              right: scale.getScaledWidth(14),
              child: OnBoardingNextButton(onBoardingController: onBoardingController, scale: scale),
            ),
          ],
        ),
      ),
    );
  }
}

class OnBoardingNextButton extends StatelessWidget {
  const OnBoardingNextButton({
    super.key,
    required this.onBoardingController,
    required this.scale,
  });

  final OnBoardingController onBoardingController;
  final ScalingUtility scale;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = onBoardingController.currentPageIndex.value;
      return GestureDetector(
        onTap: ()=> onBoardingController.nextPage(),
        child: Container(
          height: scale.getScaledWidth(60),
          width: scale.getScaledWidth(60),
          decoration: BoxDecoration(
            color: AppColors.buttonBackground,
            shape: BoxShape.circle
          ),
          child: Center(
            child: Text(
              index == 3 ? "Start" : "Next",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: scale.getScaledFont(14), color: AppColors.buttonForeground),
            ),
          ),
        ),
      );
      },
    );
  }
}

class OnBoardingDotIndicator extends StatelessWidget {
  const OnBoardingDotIndicator({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Initialize "ScalingUtility" class in EachScreen.
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    /// -- Onboarding Controller Instance
    final onBoardingController = OnBoardingController.instance;

    return Align(
      alignment: Alignment.center,
      child: SmoothPageIndicator(
        controller: onBoardingController.pageController,
        onDotClicked: onBoardingController.dotNavigationClick,
        effect: ExpandingDotsEffect(
          activeDotColor: AppColors.purple3,
          dotColor: AppColors.lightGrey,
          dotHeight: scale.getScaledHeight(6),
          dotWidth: scale.getScaledWidth(14),
        ),
        count: 4,
      ),
    );
  }
}

class SkipButton extends StatelessWidget {
  const SkipButton({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Initialize "ScalingUtility" class in EachScreen.
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    /// -- Onboarding Controller instance
    final onBoardingController = OnBoardingController.instance;

    return Obx(() {
      final index = onBoardingController.currentPageIndex.value;
      return Positioned(
        top: scale.getScaledHeight(50),
        right: scale.getScaledWidth(12),
        child: SizedBox(
          height: scale.getScaledHeight(30),
          width: scale.getScaledWidth(60),
          child: ElevatedButton(
            onPressed: () => index != 3 ? onBoardingController.skipPage(): onBoardingController.authPage(),
            style: ButtonStyle(
              padding: WidgetStatePropertyAll(scale.getPadding(all: 0)),
              side: WidgetStatePropertyAll(
                BorderSide(
                    width: index !=3 ? scale.getScaledWidth(1) : scale.getScaledWidth(1.5) ,
                    color: index !=3 ? AppColors.black : AppColors.white),
              ),
              backgroundColor: WidgetStatePropertyAll(AppColors.transparent),
            ),
            child:Text(
              index != 3 ? "Skip" : "Start",
              style: TextStyle(
                color: AppColors.white,
                fontSize: index !=3 ? scale.getScaledFont(13) : scale.getScaledFont(14),
                fontWeight: index !=3 ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      },
    );
  }
}

class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  final String image, title, subtitle;

  @override
  Widget build(BuildContext context) {

    /// -- Initialize "ScalingUtility" class in EachScreen.
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: scale.getScaledHeight(90)),

        /// -- Onboarding Title
        SizedBox(width: double.infinity, height: scale.getScaledHeight(0)),
        Padding(
          padding: scale.getPadding(left: 10, right: 10, top: 10),
          child: Text(title, style: TextStyle(fontSize: scale.getScaledFont(20), fontWeight: FontWeight.bold, color: AppColors.white,), textAlign: TextAlign.center,),
        ),
        SizedBox(height: scale.getScaledHeight(8)),

        /// -- Onboarding Sub-Title
        Padding(
          padding: scale.getPadding(left: 10, right: 16),
          child: Text(subtitle, style: TextStyle(fontSize: scale.getScaledFont(13), fontWeight: FontWeight.normal, color: AppColors.descriptionColor), textAlign: TextAlign.start,),
        ),

        SizedBox(height: scale.getScaledHeight(36)),

        /// -- Onboarding Image
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: scale.getPadding(left: 10, right: 10),
            child: SizedBox(
              height: scale.getScaledHeight(350),
              width: scale.getScaledWidth(350),
              child: Image(image: AssetImage(image), fit: BoxFit.contain,),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:clicknow_version2/app/screens/common/onboarding/getx/onboardingController.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/utils/device_constants/appStrings.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Onboarding Controller Instance
    final onBoardingController = Get.put(OnBoardingController());

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
              SkipButton(),//

              /// Dot Navigation : SmoothPage Indicator
              Positioned(
                  bottom: ResponsiveUtility.height(46),
                  left: ResponsiveUtility.width(14),
                  child: OnBoardingDotIndicator(),
              ),

              /// -- Next Button
              Positioned(
                bottom: ResponsiveUtility.height(26),
                right: ResponsiveUtility.width(18),
                child: OnBoardingNextButton(onBoardingController: onBoardingController,),
              ),
            ],
          ),
        ),
    );
  }
}

/// -- Next Button
class OnBoardingNextButton extends StatelessWidget {
  const OnBoardingNextButton({super.key, required this.onBoardingController,});

  final OnBoardingController onBoardingController;

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Obx(() {
      final index = onBoardingController.currentPageIndex.value;
      return GestureDetector(
        onTap: ()=> onBoardingController.nextPage(),
        child: Container(
          height: ResponsiveUtility.height(60),
          width: ResponsiveUtility.width(60),
          decoration: BoxDecoration(
            color: isDark ? AppColors.buttonBackground : AppColors.primaryColor,
            shape: BoxShape.circle
          ),
          child: Center(
            child: Text(
              index == 3 ? "START" : "NEXT",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtility.fontSize(14),
                  color: isDark ? AppColors.primaryColor : AppColors.white,
              ),
            ),
          ),
        ),
      );
      },
    );
  }
}

/// -- Dot Indicators
class OnBoardingDotIndicator extends StatelessWidget {
  const OnBoardingDotIndicator({super.key});

  @override
  Widget build(BuildContext context) {

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
          dotHeight: ResponsiveUtility.height(6),
          dotWidth: ResponsiveUtility.width(16),
        ),
        count: 4,
      ),
    );
  }
}

/// -- Skip Button
class SkipButton extends StatelessWidget {
  const SkipButton({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Onboarding Controller instance
    final onBoardingController = OnBoardingController.instance;

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Obx(() {
      final index = onBoardingController.currentPageIndex.value;
      return Positioned(
        top: ResponsiveUtility.height(60),
        right: ResponsiveUtility.width(12),
        child: SizedBox(
          height: ResponsiveUtility.height(30),
          width: ResponsiveUtility.width(60),
          child: ElevatedButton(
            onPressed: () => index != 3 ? onBoardingController.skipPage(): onBoardingController.authPage(),
            style: ButtonStyle(
              padding: WidgetStatePropertyAll(ResponsiveUtility.all(0)),
              side: WidgetStatePropertyAll(
                BorderSide(
                    color: index !=3
                        ? isDark ? AppColors.black : AppColors.lightGrey
                        : isDark ? AppColors.white : AppColors.lightGrey,
                ),
              ),
              backgroundColor: WidgetStatePropertyAll(isDark ? AppColors.black : AppColors.white),
            ),
            child:Text(
              index != 3 ? "Skip" : "Start",
              style: TextStyle(
                color: isDark ? AppColors.white : AppColors.black,
                fontSize: index !=3 ? ResponsiveUtility.fontSize(12) : ResponsiveUtility.fontSize(14),
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

/// -- Onboarding page
class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({super.key, required this.image, required this.title, required this.subtitle,});

  final String image, title, subtitle;

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ResponsiveUtility.height(100),),

        /// -- Onboarding Title
        SizedBox(
          width: double.infinity,
          height: ResponsiveUtility.height(0),
        ),
        Padding(
          padding: ResponsiveUtility.only(left: 10, right: 10, top: 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtility.fontSize(18),
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.black,
            ),
            textAlign: TextAlign.start,
          ),
        ),
        SizedBox(height: ResponsiveUtility.height(8),),

        /// -- Onboarding Sub-Title
        Padding(
          padding: ResponsiveUtility.only(left: 10, right: 16),
          child: Text(
            subtitle,
            style: TextStyle(
                fontSize: ResponsiveUtility.fontSize(12),
                fontWeight: FontWeight.normal,
                color: isDark ? AppColors.descriptionColor : AppColors.grey
            ),
            textAlign: TextAlign.start,
          ),
        ),

        Expanded(
          child: SizedBox(height: ResponsiveUtility.height(36),),
        ),

        /// -- Onboarding Image
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: ResponsiveUtility.only(right: 10, left: 10),
            child: SizedBox(
              height: ResponsiveUtility.height(280),
              width: ResponsiveUtility.width(390),
              child: Image(image: AssetImage(image), fit: BoxFit.contain,),
            ),
          ),
        ),

        SizedBox(height: ResponsiveUtility.height(200),),
      ],
    );
  }
}

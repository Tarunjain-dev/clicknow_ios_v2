import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class OnBoardingController extends GetxController {

  /// -- Show onboarding Screen Only once through out the life time of the application.
  final storage = GetStorage();
  bool get hasSeenOnboarding => storage.read('hasSeenOnboarding') ?? false;
  void completeOnboarding() {
    storage.write('hasSeenOnboarding', true);
    debugPrint("DEBUG - hasSeenOnboarding = ${hasSeenOnboarding.toString()}");
  }

  /// -- Getter Function for onboarding controller object
  static OnBoardingController get instance => Get.find();

  /// --- Member variables
  final pageController = PageController();
  var currentPageIndex = 0.obs;

  /// --- Member Functions

  // Update current Index when Page Scroll
  void updatePageIndicator(int index) => currentPageIndex.value = index;

  // Jump to specific dot selected page
  void dotNavigationClick(int index) {
    currentPageIndex.value = index;
    pageController.jumpToPage(index);
  }

  // Update current Index & Jump to next page
  void nextPage() {
    if (currentPageIndex.value == 3) {
      // last page appeared
      authPage();
    } else {
      int page = currentPageIndex.value + 1; // move to next page
      pageController.jumpToPage(page);
    }
  }

  // Update current Index & Jump to last page
  void skipPage() {
    currentPageIndex.value = 3; // 0 index based pages (total 4 pages)
    pageController.jumpToPage(3);

    /// -- Skip Onboarding & Navigate to login screen
    authPage();
  }

  void authPage() {
    completeOnboarding();
    Get.offAllNamed(AppRoutes.loginRoute);
  }
}

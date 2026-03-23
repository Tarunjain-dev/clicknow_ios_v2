import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StepperController extends GetxController {
  final currentStep = 0.obs;

  final steps = [
    "Verify Phone",
    "About You",
    "Professional",
    "Legal",
    "Services",
  ];

  late PageController pageController;

  @override
  void onInit() {
    pageController = PageController();
    super.onInit();
  }

  void nextStep() {
    if (currentStep.value < steps.length - 1) {
      currentStep.value++;
      pageController.animateToPage(
        currentStep.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      pageController.animateToPage(
        currentStep.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToStep(int index) {
    currentStep.value = index;
    pageController.jumpToPage(index);
  }
}

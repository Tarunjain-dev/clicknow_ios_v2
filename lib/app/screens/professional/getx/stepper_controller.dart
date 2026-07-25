import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:clicknow_version2/app/screens/professional/getx/professional_onboarding_storage.dart';

class StepperController extends GetxController {
  final currentStep = 0.obs;
  final isProgressLoaded = false.obs;
  final stepCompletion =
      List<bool>.filled(ProfessionalOnboardingStorage.totalSteps, false).obs;
  final onboardingCompleted = false.obs;

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
    _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    final savedFlags = await ProfessionalOnboardingStorage.readStepFlags();
    stepCompletion.assignAll(savedFlags);
    onboardingCompleted.value =
        await ProfessionalOnboardingStorage.readOnboardingCompleted();

    currentStep.value =
        ProfessionalOnboardingStorage.firstIncompleteStepIndex(savedFlags);
    _syncPageWithCurrentStep();
    isProgressLoaded.value = true;
  }

  void _syncPageWithCurrentStep() {
    if (pageController.hasClients) {
      pageController.jumpToPage(currentStep.value);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed && pageController.hasClients) {
        pageController.jumpToPage(currentStep.value);
      }
    });
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
    final target = index.clamp(0, steps.length - 1).toInt();
    currentStep.value = target;
    pageController.jumpToPage(target);
  }

  Future<void> markStepCompleted(int stepIndex) async {
    if (stepIndex < 0 || stepIndex >= steps.length) return;
    stepCompletion[stepIndex] = true;
    stepCompletion.refresh();
    await ProfessionalOnboardingStorage.writeStepFlag(stepIndex, true);
  }

  Future<void> completeStepAndContinue(int stepIndex) async {
    await markStepCompleted(stepIndex);
    nextStep();
  }

  Future<void> markOnboardingCompleted() async {
    onboardingCompleted.value = true;
    await ProfessionalOnboardingStorage.writeOnboardingCompleted(true);
  }

  Future<void> resetProgress() async {
    await ProfessionalOnboardingStorage.clearProgress();
    stepCompletion.assignAll(
      List<bool>.filled(ProfessionalOnboardingStorage.totalSteps, false),
    );
    onboardingCompleted.value = false;
    currentStep.value = 0;
    _syncPageWithCurrentStep();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

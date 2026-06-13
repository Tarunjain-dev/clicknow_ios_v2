import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/stepper_controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:clicknow_version2/app/widgets/searchable_multi_selection_bottom_sheet.dart';
import 'package:clicknow_version2/app/widgets/searchable_selection_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class StepFiveBodyScreen extends StatefulWidget {
  const StepFiveBodyScreen({super.key});

  @override
  State<StepFiveBodyScreen> createState() => _StepFiveBodyScreenState();
}

class _StepFiveBodyScreenState extends State<StepFiveBodyScreen> {

  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<ProfessionalRegistrationController>();
  final stepperController = Get.find<StepperController>();
  bool get _isDark => HelperFunctions.isDarkMode(context);
  Color get _textPrimary => _isDark ? Colors.white : Colors.black;
  Color get _textSecondary => _isDark ? Colors.white60 : Colors.black.withValues(alpha: 0.6);

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling Utility
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    return Obx(() {

      final isSubmitting = controller.isSubmittingProfile.value;

      return Stack(
        children: [
          AbsorbPointer(
            absorbing: isSubmitting,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: ResponsiveUtility.only(left: 16, top: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16,),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      decoration: _mainDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: ResponsiveUtility.only(bottom: 4, right: 10, top: 10, left: 10),
                            child: Text("Professional Services & Finances", style: TextStyle(color: _textPrimary, fontSize: ResponsiveUtility.fontSize(16), fontWeight: FontWeight.bold,),),
                          ),
                          Padding(
                            padding: ResponsiveUtility.symmetric(horizontal: 10),
                            child: Text("Select your service details and complete finance setup.", style: TextStyle(color: _textSecondary, fontSize: ResponsiveUtility.fontSize(12),),),
                          ),
                          Divider(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9)),
                          Padding(
                            padding: ResponsiveUtility.all(8),
                            child: Column(
                              children: [
                                _buildExpandable(
                                  title: "Professional Services",
                                  isExpanded: controller.isPricingExpanded,
                                  onTap: controller.togglePricing,
                                  child: _professionalServicesSection(),
                                  isDark: isDark,
                                ),
                                SizedBox(height: ResponsiveUtility.height(10)),
                                _buildExpandable(
                                  title: "Bank Information",
                                  isExpanded: controller.isBankExpanded,
                                  onTap: controller.toggleBank,
                                  child: _bankSection(),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),

                          /// --  Back and Continue button
                          Divider(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9), height: 2),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              color: _isDark ? const Color(0xff101425) : const Color(0xffF6F6F6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0,),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: scale.getScaledHeight(40),
                                      child: ElevatedButton(
                                        onPressed: isSubmitting ? null : () => stepperController.previousStep(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark ? const Color(0xff13182C) : Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadiusGeometry.circular(10,),
                                            side: BorderSide(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.arrow_back,
                                              color: isDark ? Colors.white : Colors.black54,
                                              size: 22,
                                            ),
                                            SizedBox(
                                              width: scale.getScaledWidth(8),
                                            ),
                                            Text(
                                              "Back",
                                              style: TextStyle(
                                                color: isDark ? Colors.white : Colors.black54,
                                                fontWeight: FontWeight.bold,
                                                fontSize: scale.getScaledFont(
                                                  14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: scale.getScaledWidth(8)),
                                  Expanded(
                                    child: SizedBox(
                                      height: scale.getScaledHeight(40),
                                      child: ElevatedButton(
                                        onPressed: isSubmitting
                                            ? null
                                            : () async {
                                                if (controller.validateStep5()) {
                                                  await controller.saveDraftForStep(4);
                                                  final success = await controller.submitProfessionalProfile();
                                                  if (success) {
                                                    await stepperController.markStepCompleted(4);
                                                    await stepperController.markOnboardingCompleted();
                                                    await controller.clearOnboardingDraft();
                                                    Get.offAllNamed(AppRoutes.adminApprovalScreen,);
                                                  }
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadiusGeometry.circular(10,),
                                          ),
                                        ),
                                        child: Text(
                                          isSubmitting ? "Uploading..." : "Continue",
                                          style: TextStyle(
                                            color: isDark ? AppColors.purple3 : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: scale.getScaledFont(14),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isSubmitting)
            Positioned.fill(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveUtility.width(360),
                  ),
                  child: Card(
                    elevation: 4,
                    shadowColor: Colors.black,
                    color: isDark ? const Color(0xff150A26) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: ResponsiveUtility.symmetric(horizontal: 16),
                    child: Padding(
                      padding: ResponsiveUtility.only(bottom: 20, left: 20, right: 20, top: 20,),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "uploading aadhaar document",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: ResponsiveUtility.fontSize(18),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtility.height(4)),
                          Text(
                            "Please wait while we securely upload your documents.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6),
                              fontSize: ResponsiveUtility.fontSize(14),
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtility.height(20)),
                          LinearProgressIndicator(
                            backgroundColor: const Color(0xffEDEDF3),
                            color: const Color(0xff8A14FF),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          SizedBox(height: ResponsiveUtility.height(10)),
                          Text(
                            "${controller.uploadProgress.value * 100}% Uploaded...",
                            style: TextStyle(
                              color: const Color(0xffFB9F00),
                              fontSize: ResponsiveUtility.fontSize(14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _professionalServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Service Type", style: TextStyle(color: _textPrimary)),
        SizedBox(height: ResponsiveUtility.height(8)),
        Theme(
          data: Theme.of(context).copyWith(hintColor: _isDark ? Color(0xff5B6274) : Colors.black.withValues(alpha: 0.6)),
          child: Obx(() {
            final selected = controller.serviceTypeOptions.contains(controller.selectedServiceType.value,) ? controller.selectedServiceType.value : null;
            return DropdownButtonFormField<String>(
              initialValue: selected,
              dropdownColor: _isDark ? Color(0xff1C1736) : Colors.white,
              style: TextStyle(color: Colors.white, fontSize: ResponsiveUtility.fontSize(12)),
              items: controller.serviceTypeOptions
                  .map(
                    (service) => DropdownMenuItem(
                      value: service,
                      child: Text(service, style: TextStyle(color: _textPrimary),),
                    ),
                  )
                  .toList(),
              onChanged: controller.onServiceTypeChanged,
              decoration: _dropdownDecoration("Select a service"),
            );
          }),
        ),
        SizedBox(height: ResponsiveUtility.height(10)),
        Text("Speciality or Event type", style: TextStyle(color: _textPrimary),),
        SizedBox(height: ResponsiveUtility.height(8)),
        Obx(() {
          final specialities = controller.currentServiceSpecialityOptions;
          final selectedSpecialities = controller.selectedServiceSpecialities.toList(growable: false);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _multiSelectorField(
                hint: "Choose your speciality",
                values: selectedSpecialities,
                enabled: specialities.isNotEmpty,
                onTap: () async {
                  if (specialities.isEmpty) {
                    return;
                  }
                  final picked = await SearchableMultiSelectionBottomSheet.show(
                    context: context,
                    title: 'Select Speciality / Event Type',
                    options: specialities,
                    initialValues: selectedSpecialities,
                    searchHint: 'Search speciality',
                  );
                  if (picked == null) {
                    return;
                  }
                  controller.onServiceSpecialitySelection(picked);
                },
              ),
              if (selectedSpecialities.isNotEmpty) ...[
                SizedBox(height: ResponsiveUtility.height(4)),
                Wrap(
                  spacing: ResponsiveUtility.width(2),
                  runSpacing: ResponsiveUtility.width(0),
                  children: selectedSpecialities
                      .map(
                        (value) => Chip(
                          backgroundColor: Color(0xff9810FA),
                          side: BorderSide(color: _isDark ? Colors.white24 : const Color(0xffD9D9D9),),
                          label: Text(value, style: TextStyle(color: _isDark ? Colors.white : Colors.white,),),
                          onDeleted: () {
                            final updated = selectedSpecialities.where((item) => item != value).toList(growable: false);
                            controller.onServiceSpecialitySelection(updated);
                          },
                          deleteIcon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.white,),
                        ),
                      ).toList(growable: false),
                ),
              ],
              if (controller.selectedServiceType.value.isNotEmpty && specialities.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "No active event types available for this service right now.",
                    style: TextStyle(
                      color: _isDark ? Colors.white54 : Colors.black54,
                      fontSize: ResponsiveUtility.fontSize(12),
                    ),
                  ),
                ),
            ],
          );
        }),
        SizedBox(height: ResponsiveUtility.height(10)),
        Obx(() {
          if (controller.selectedServiceType.value.isEmpty) {
            return const SizedBox();
          }
          final questions = controller.activeServiceQuestions;
          return Column(
            children: questions.map((question) => _serviceQuestionField(question)).toList(),
          );
        }),
        _toggleTile(
          "Available for urgent bookings",
          controller.urgentAvailable,
        ),
        _toggleTile(
          "Willing to travel outside city",
          controller.willingToTravel,
        ),
        Obx(() {
          if (!controller.willingToTravel.value) {
            return const SizedBox();
          }
          return Column(
            children: [
              const SizedBox(height: 12),
              _secondaryWorkingLocationSection(),
            ],
          );
        }),
        _toggleTile(
          "Cancellation Policy",
          controller.cancellationAccepted,
          subtitle: "I agree to platform cancellation policy.",
          onReadMore: () => _showAgreementDialog(
            title: "Cancellation Policy",
            content: "By accepting this policy, you agree to follow platform cancellation terms for assigned bookings, timelines, communication, and refund handling rules.",
            googleDocURL: "https://docs.google.com/document/d/14DFXyV-YwYRBBuoBB05JQVMy7rBj257NkiBA5nTVZxg/edit?usp=drivesdk "
          ),
        ),
        _toggleTile(
          "Platform Commission Agreement",
          controller.commissionAccepted,
          subtitle: "I agree to platform commission rules.",
          onReadMore: () => _showAgreementDialog(
            title: "Platform Commission Agreement",
            content: "By accepting this agreement, you authorize platform commission deduction as per applicable service/category rates for successful booking payouts.",
            googleDocURL: "https://docs.google.com/document/d/1T5Ti4EywOrqJCxjBTIPwxcB4uNtYuM6dgUE6C-3cT8w/edit?usp=drivesdk"
          ),
        ),
      ],
    );
  }

  Widget _serviceQuestionField(ServiceQuestionConfiguration question) {
    switch (question.inputType) {
      case ServiceQuestionInputType.radio:
        return _radioQuestion(question);
      case ServiceQuestionInputType.dropdown:
        return _dropdownQuestion(question);
      case ServiceQuestionInputType.number:
        return _textQuestion(
          question,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );
      case ServiceQuestionInputType.text:
        return _textQuestion(question);
    }
  }

  Widget _radioQuestion(ServiceQuestionConfiguration question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.label, style: TextStyle(color: _textPrimary)),
          const SizedBox(height: 8),
          Obx(() {
            final selected = controller.getServiceQuestionAnswer(question.id);
            return RadioGroup<String>(
              groupValue: selected,
              onChanged: (value) {
                controller.setServiceQuestionAnswer(question.id, value ?? "");
              },
              child: Row(
                children: question.options
                    .map(
                      (option) => Expanded(
                        child: Row(
                          children: [
                            Radio<String>(
                              value: option,
                              fillColor: const WidgetStatePropertyAll(
                                Color(0xff9235B1),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  color: _isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _dropdownQuestion(ServiceQuestionConfiguration question) {
    return Padding(
      padding: ResponsiveUtility.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.label, style: TextStyle(color: _textPrimary)),
          SizedBox(height: ResponsiveUtility.height(8)),
          Theme(
            data: Theme.of(context).copyWith(hintColor: const Color(0xff5B6274)),
            child: Obx(() {
              final answer = controller.getServiceQuestionAnswer(question.id);
              final selected = answer.isNotEmpty && question.options.contains(answer) ? answer : null;
              return DropdownButtonFormField<String>(
                initialValue: selected,
                dropdownColor: _isDark ? Color(0xff1C1736) : Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: question.options
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          style: TextStyle(color: _textPrimary),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  controller.setServiceQuestionAnswer(question.id, value ?? "");
                },
                decoration: _dropdownDecoration(question.hint),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _textQuestion(
    ServiceQuestionConfiguration question, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter> inputFormatters = const [],
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.label, style: TextStyle(color: _textPrimary)),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey(
              "${controller.selectedServiceType.value}-${question.id}",
            ),
            initialValue: controller.getServiceQuestionAnswer(question.id),
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLength: question.inputType == ServiceQuestionInputType.text
                ? question.maxLength
                : null,
            style: TextStyle(color: _textPrimary),
            decoration: _inputDecoration(question.hint),
            onChanged: (value) {
              controller.setServiceQuestionAnswer(question.id, value);
            },
          ),
        ],
      ),
    );
  }

  Widget _secondaryWorkingLocationSection() {
    return Container(
      decoration: _innerDecoration(),
      child: Padding(
        padding: ResponsiveUtility.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: Color(0xff9235B1)),
                SizedBox(width: ResponsiveUtility.width(8)),
                Text("Secondary Working Locations", style: TextStyle(color: _textPrimary),),
              ],
            ),
            SizedBox(height: ResponsiveUtility.height(10)),
            Text("Working State", style: TextStyle(color: _textPrimary)),
            SizedBox(height: ResponsiveUtility.height(6)),
            Obx(
              () => _selectorField(
                hint: "Select working state",
                value: controller.selectedSecondaryWorkingState.value,
                onTap: () async {
                  final selected = await SearchableSelectionBottomSheet.show(
                    context: context,
                    title: 'Select Working State',
                    options: controller.stateOptions,
                    initialValue: controller.selectedSecondaryWorkingState.value,
                    searchHint: 'Search state',
                  );
                  if (selected == null) {
                    return;
                  }
                  controller.onSecondaryWorkingStateChanged(selected);
                },
              ),
            ),
            const SizedBox(height: 12),
            Text("Working City", style: TextStyle(color: _textPrimary)),
            const SizedBox(height: 6),
            Obx(() {
              final cities = controller.currentSecondaryWorkingCityOptions;
              final selectedCities = controller.selectedSecondaryWorkingCities.toList(growable: false);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _multiSelectorField(
                    hint: "Select working city",
                    values: selectedCities,
                    enabled: cities.isNotEmpty,
                    onTap: () async {
                      if (cities.isEmpty) {
                        return;
                      }
                      final picked = await SearchableMultiSelectionBottomSheet.show(
                        context: context,
                        title: 'Select Working City',
                        options: cities,
                        initialValues: selectedCities,
                        searchHint: 'Search city',
                      );
                      if (picked == null) {
                        return;
                      }
                      controller.selectedSecondaryWorkingCities.assignAll(
                        picked,
                      );
                    },
                  ),
                  if (selectedCities.isNotEmpty) ...[
                    SizedBox(height: ResponsiveUtility.height(8)),
                    Wrap(
                      spacing: ResponsiveUtility.width(2),
                      runSpacing: ResponsiveUtility.width(0),
                      children: selectedCities
                          .map(
                            (city) => Chip(
                              backgroundColor: Color(0xff9810FA),
                              label: Text(city, style: TextStyle(color: _isDark ? _textPrimary : Colors.white),),
                              onDeleted: () => controller.selectedSecondaryWorkingCities.remove(city),
                              deleteIcon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.white,),
                            ),
                          ).toList(growable: false),
                    ),
                  ],
                ],
              );
            }),
            SizedBox(height: ResponsiveUtility.height(10)),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.saveSecondaryWorkingLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDark ? Colors.white : AppColors.primaryColor,
                      foregroundColor: _isDark ? AppColors.primaryColor : Colors.white,
                      padding: ResponsiveUtility.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Save Location", style: TextStyle(fontWeight: FontWeight.bold),),
                  ),
                ),
                SizedBox(width: ResponsiveUtility.width(8)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.addMoreSecondaryWorkingLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDark ? Colors.white : AppColors.primaryColor,
                      foregroundColor: _isDark ? AppColors.primaryColor : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Add More", style: TextStyle(fontWeight: FontWeight.bold),),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtility.height(8)),
            Obx(() {
              if (controller.secondaryWorkingLocations.isEmpty) {
                return const SizedBox();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selected Secondary Working Locations:",
                    style: TextStyle(color: _isDark ? Colors.white54 : Colors.black54, fontSize: ResponsiveUtility.fontSize(12)),
                  ),
                  SizedBox(height: ResponsiveUtility.height(6)),
                  ...controller.secondaryWorkingLocations.map((loc) {
                    return Padding(
                      padding: ResponsiveUtility.only(bottom: 4),
                      child: Text(
                        "- ${loc.state} : ${loc.cities.join(", ")}",
                        style: TextStyle(
                          color: _isDark ? Colors.white70 : Colors.black54,
                          fontSize: ResponsiveUtility.fontSize(12),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _bankSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Account Number", style: TextStyle(color: _textPrimary)),
        SizedBox(height: ResponsiveUtility.height(8)),
        _textField(controller.accountNumberController, "Enter account number"),
        SizedBox(height: ResponsiveUtility.height(12)),
        Text("Upload Bank Passbook", style: TextStyle(color: _textPrimary),),
        SizedBox(height: ResponsiveUtility.height(8)),
        Obx(
          () => GestureDetector(
            onTap: controller.pickBankPassbook,
            child: Container(
              height: ResponsiveUtility.height(120),
              decoration: _uploadDecoration(),
              child: Center(
                child: controller.bankPassbookFileName.value.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, color: _isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.6)),
                          SizedBox(height: ResponsiveUtility.height(8)),
                          Text(
                            "Tap to upload",
                            style: TextStyle(
                              color: _isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtility.height(4)),
                          Text(
                            "Upload Front & back in single PDF",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _isDark ? Colors.white54 : Colors.black54),
                          ),
                          SizedBox(height: ResponsiveUtility.height(4)),
                          Text(
                            "PDF only, max 5 MB",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isDark ? Colors.white54 : Colors.black54,
                              fontSize: ResponsiveUtility.fontSize(11),
                            ),
                          ),
                        ],
                      )
                    : Text(controller.bankPassbookFileName.value, style: const TextStyle(color: Colors.purpleAccent),),
              ),
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtility.height(10)),
        Text("UPI ID", style: TextStyle(color: _textPrimary)),
        SizedBox(height: ResponsiveUtility.height(8)),
        _textField(controller.upiController, "Enter UPI ID"),
        SizedBox(height: ResponsiveUtility.height(10)),
        Text("Bank Name", style: TextStyle(color: _textPrimary)),
        SizedBox(height: ResponsiveUtility.height(8)),
        _textField(controller.bankNameController, "Enter bank name"),
        SizedBox(height: ResponsiveUtility.height(10)),
        Text("Branch Name", style: TextStyle(color: _textPrimary)),
        SizedBox(height: ResponsiveUtility.height(8)),
        _textField(controller.branchNameController, "Enter branch name"),
        SizedBox(height: ResponsiveUtility.height(10)),
        Text("IFSC Code", style: TextStyle(color: _textPrimary)),
        SizedBox(height: ResponsiveUtility.height(8)),
        _textField(controller.ifscController, "Enter IFSC code"),
      ],
    );
  }

  Widget _buildExpandable({
    required String title,
    required RxBool isExpanded,
    required VoidCallback onTap,
    required Widget child,
    required bool isDark
  }) {
    return Obx(
      () => Container(
        decoration: _innerDecoration(),
        child: Column(
          children: [
            ListTile(
              onTap: onTap,
              title: Text(title, style: TextStyle(color: _textPrimary)),
              trailing: Icon(
                isExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            if (isExpanded.value)
              Padding(padding: ResponsiveUtility.only(bottom: 12, top: 0, right: 10, left: 10), child: child),
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: _textPrimary),
      decoration: _inputDecoration(hint),
    );
  }

  Widget _toggleTile(
    String title,
    RxBool value, {
    String? subtitle,
    VoidCallback? onReadMore,
  }) {
    return Obx(
      () => SwitchListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: _textPrimary)),
            if (subtitle != null)
              Text(subtitle, style: TextStyle(color: _isDark ? Colors.white54 : _textSecondary, fontSize: ResponsiveUtility.fontSize(11),),),
            if (onReadMore != null)
              GestureDetector(
                onTap: onReadMore,
                child: Text(
                  "Read more",
                  style: TextStyle(
                    color: Color(0xff9810FA),
                    fontSize: ResponsiveUtility.fontSize(11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        value: value.value,
        activeThumbColor: _isDark ? Color(0xff7CFC00) : Color(0xff00C950),
        activeTrackColor: _isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
        inactiveThumbColor: _isDark ? Color(0xff9F9F9F) : Color(0xff8E8E8E),
        inactiveTrackColor: _isDark ? Color(0xff2A2A2A).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1),
        onChanged: (val) => value.value = val,
      ),
    );
  }

  void _showAgreementDialog({required String title, required String content, required String googleDocURL}) {
    final isDark = HelperFunctions.isDarkMode(context);
    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xff1C1736) : Colors.white,
        title: Text(
          title,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          content,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text("Close", style: TextStyle(color: isDark ? Colors.white : AppColors.primaryColor)),
          ),
          ElevatedButton(
            onPressed: ()=> HelperFunctions.launchURL(googleDocURL),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
            ),
            child: Text("Read Policy", style: TextStyle(color: isDark ? AppColors.primaryColor : Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _selectorField({
    required String hint,
    required String value,
    required Future<void> Function() onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.8) : const Color(0xffF6F4FF).withValues(alpha: 0.8),
          border: Border.all(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.trim().isEmpty ? hint : value.trim(),
                style: TextStyle(
                  color: value.trim().isEmpty ? const Color(0xff5B6274) : _isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xff69729A)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.8) : const Color(0xffF6F4FF).withValues(alpha: 0.8),
      hintText: hint,
      hintStyle: TextStyle(color: _isDark ? const Color(0xff5B6274) : Colors.black54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? AppColors.primaryColor : Color(0xffD9D9D9))),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Colors.red : Color(0xffD9D9D9))),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9))),
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.8) : const Color(0xffF6F4FF).withValues(alpha: 0.8),
      labelStyle: TextStyle(color: _textPrimary, fontSize: 14),
      hintText: hint,
      hintStyle: TextStyle(color: _isDark ? const Color(0xff5B6274) : Colors.black54),
      helperStyle: TextStyle(color: _textPrimary, fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? AppColors.primaryColor : Color(0xffD9D9D9))),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Colors.red : Color(0xffD9D9D9))),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9))),
    );
  }

  BoxDecoration _multiFieldContainerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
    );
  }

  Widget _multiSelectorField({
    required String hint,
    required List<String> values,
    required Future<void> Function() onTap,
    bool enabled = true,
  }) {
    final label = values.isEmpty ? hint : values.join(', ');
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: ResponsiveUtility.symmetric(horizontal: 14, vertical: 12),
        decoration: _multiFieldContainerDecoration().copyWith(
          color: _isDark ? Color(0xff1C1736).withValues(alpha: 0.85) : const Color(0xffF6F4FF).withValues(alpha: 0.8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: values.isEmpty ?
                  const Color(0xff5B6274) :
                  _isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),
                  fontSize: ResponsiveUtility.fontSize(12),
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: _isDark ? Color(0xff69729A): Colors.black.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  BoxDecoration _mainDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.5) : const Color(0xffFCFBFF),
      border: Border.all(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9)),
    );
  }

  BoxDecoration _innerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.8) : const Color(0xffF6F4FF).withValues(alpha: 0.8),
      border: Border.all(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9)),
    );
  }

  BoxDecoration _uploadDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9)),
      color: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.6) : Colors.white,
    );
  }
}

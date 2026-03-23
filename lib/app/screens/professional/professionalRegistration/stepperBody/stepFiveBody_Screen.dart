import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/stepper_controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

class StepFiveBodyScreen extends StatefulWidget {
  const StepFiveBodyScreen({super.key});

  @override
  State<StepFiveBodyScreen> createState() => _StepFiveBodyScreenState();
}

class _StepFiveBodyScreenState extends State<StepFiveBodyScreen> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<ProfessionalRegistrationController>();
  final stepperController = Get.find<StepperController>();

  @override
  Widget build(BuildContext context) {
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              decoration: _mainDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 4),
                    child: Text(
                      "Professional Services & Finances",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "Select your service details and complete finance setup.",
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                  const Divider(color: Color(0xff1E2939)),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        _buildExpandable(
                          title: "Professional Services",
                          isExpanded: controller.isPricingExpanded,
                          onTap: controller.togglePricing,
                          child: _professionalServicesSection(),
                        ),
                        const SizedBox(height: 16),
                        _buildExpandable(
                          title: "Bank Information",
                          isExpanded: controller.isBankExpanded,
                          onTap: controller.toggleBank,
                          child: _bankSection(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xff1E2939), height: 2),
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      color: Color(0xff101425),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 20.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: scale.getScaledHeight(40),
                              child: ElevatedButton(
                                onPressed: () =>
                                    stepperController.previousStep(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff13182C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.circular(
                                      10,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xff1E2939),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    SizedBox(width: scale.getScaledWidth(8)),
                                    Text(
                                      "Back",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: scale.getScaledFont(14),
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
                              child: Obx(
                                () => ElevatedButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () async {
                                          if (controller.validateStep5()) {
                                            final success =
                                                await controller
                                                    .submitProfessionalProfile();
                                            if (success) {
                                              Get.offAllNamed(
                                                AppRoutes.adminApprovalScreen,
                                              );
                                            }
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadiusGeometry.circular(
                                        10,
                                      ),
                                    ),
                                  ),
                                  child: controller.isLoading.value
                                      ? SizedBox(
                                          height: scale.getScaledHeight(18),
                                          width: scale.getScaledWidth(18),
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              AppColors.purple3,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          "Continue",
                                          style: TextStyle(
                                            color: AppColors.purple3,
                                            fontWeight: FontWeight.bold,
                                            fontSize: scale.getScaledFont(14),
                                          ),
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
    );
  }

  Widget _professionalServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Service Type", style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(hintColor: const Color(0xff5B6274)),
          child: Obx(() {
            final selected = controller.serviceTypeOptions.contains(
              controller.selectedServiceType.value,
            )
                ? controller.selectedServiceType.value
                : null;
            return DropdownButtonFormField<String>(
              initialValue: selected,
              dropdownColor: const Color(0xff1C1736),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: controller.serviceTypeOptions
                  .map(
                    (service) => DropdownMenuItem(
                      value: service,
                      child: Text(
                        service,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: controller.onServiceTypeChanged,
              decoration: _dropdownDecoration("Select a service"),
            );
          }),
        ),
        const SizedBox(height: 12),
        const Text(
          "Speciality or Event type",
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final specialities = controller.currentServiceSpecialityOptions;
          return Container(
            decoration: _multiFieldContainerDecoration(),
            child: MultiDropdown<String>(
              key: ValueKey(controller.selectedServiceType.value),
              items: specialities
                  .map(
                    (value) => DropdownItem(
                      label: value,
                      value: value,
                      selected: controller.selectedServiceSpecialities.contains(
                        value,
                      ),
                    ),
                  )
                  .toList(),
              onSelectionChange: controller.onServiceSpecialitySelection,
              fieldDecoration: _multiFieldDecoration(
                "Choose your speciality",
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.selectedServiceType.value.isEmpty) {
            return const SizedBox();
          }
          final questions = controller.activeServiceQuestions;
          return Column(
            children: questions
                .map((question) => _serviceQuestionField(question))
                .toList(),
          );
        }),
        _toggleTile("Available for urgent bookings", controller.urgentAvailable),
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
        _toggleTile("Cancellation Policy", controller.cancellationAccepted),
        _toggleTile(
          "Platform Commission Agreement",
          controller.commissionAccepted,
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
          Text(question.label, style: const TextStyle(color: Colors.white)),
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
                                  color: Colors.white.withValues(alpha: 0.75),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.label, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(hintColor: const Color(0xff5B6274)),
            child: Obx(() {
              final answer = controller.getServiceQuestionAnswer(question.id);
              final selected =
                  answer.isNotEmpty && question.options.contains(answer)
                  ? answer
                  : null;
              return DropdownButtonFormField<String>(
                initialValue: selected,
                dropdownColor: const Color(0xff1C1736),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: question.options
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          style: const TextStyle(color: Colors.white),
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
          Text(question.label, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey("${controller.selectedServiceType.value}-${question.id}"),
            initialValue: controller.getServiceQuestionAnswer(question.id),
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLength: question.inputType == ServiceQuestionInputType.text
                ? question.maxLength
                : null,
            style: const TextStyle(color: Colors.white),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on_outlined, color: Color(0xff9235B1)),
                SizedBox(width: 8),
                Text(
                  "Secondary Working Locations",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text("Working State", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            Theme(
              data: Theme.of(context).copyWith(hintColor: const Color(0xff5B6274)),
              child: Obx(
                () => DropdownButtonFormField<String>(
                  initialValue:
                      controller.selectedSecondaryWorkingState.value.isEmpty
                      ? null
                      : controller.selectedSecondaryWorkingState.value,
                  dropdownColor: const Color(0xff1C1736),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: controller.stateOptions
                      .map(
                        (state) => DropdownMenuItem(
                          value: state,
                          child: Text(
                            state,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: controller.onSecondaryWorkingStateChanged,
                  decoration: _dropdownDecoration("Select working state"),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text("Working City", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            Obx(() {
              final cities = controller.currentSecondaryWorkingCityOptions;
              return Container(
                decoration: _multiFieldContainerDecoration(),
                child: MultiDropdown<String>(
                  key: ValueKey(controller.selectedSecondaryWorkingState.value),
                  items: cities
                      .map((city) => DropdownItem(label: city, value: city))
                      .toList(),
                  onSelectionChange: (selectedItems) {
                    controller.selectedSecondaryWorkingCities.assignAll(
                      selectedItems,
                    );
                  },
                  fieldDecoration: _multiFieldDecoration("Select working city"),
                ),
              );
            }),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.saveSecondaryWorkingLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xff360248),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Save Location",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.addMoreSecondaryWorkingLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xff360248),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Add More",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.secondaryWorkingLocations.isEmpty) {
                return const SizedBox();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selected Secondary Working Locations:",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  ...controller.secondaryWorkingLocations.map((loc) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "- ${loc.state} : ${loc.cities.join(", ")}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
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
        const Text("Account Number", style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        _textField(controller.accountNumberController, "Enter account number"),
        const SizedBox(height: 12),
        const Text(
          "Upload Bank Passbook",
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Obx(
          () => GestureDetector(
            onTap: controller.pickBankPassbook,
            child: Container(
              height: 120,
              decoration: _uploadDecoration(),
              child: Center(
                child: controller.bankPassbookFileName.value.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, color: Colors.white54),
                          SizedBox(height: 8),
                          Text(
                            "Tap to upload",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Upload Front & back in single PDF",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      )
                    : Text(
                        controller.bankPassbookFileName.value,
                        style: const TextStyle(color: Colors.purpleAccent),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text("UPI ID", style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        _textField(controller.upiController, "Enter UPI ID"),
        const SizedBox(height: 12),
        const Text("Bank Name", style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        _textField(controller.bankNameController, "Enter bank name"),
        const SizedBox(height: 12),
        const Text("Branch Name", style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        _textField(controller.branchNameController, "Enter branch name"),
        const SizedBox(height: 12),
        const Text("IFSC Code", style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        _textField(controller.ifscController, "Enter IFSC code"),
      ],
    );
  }

  Widget _buildExpandable({
    required String title,
    required RxBool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Obx(
      () => Container(
        decoration: _innerDecoration(),
        child: Column(
          children: [
            ListTile(
              onTap: onTap,
              title: Text(title, style: const TextStyle(color: Colors.white)),
              trailing: Icon(
                isExpanded.value
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white,
              ),
            ),
            if (isExpanded.value)
              Padding(padding: const EdgeInsets.all(12), child: child),
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint),
    );
  }

  Widget _toggleTile(String title, RxBool value) {
    return Obx(
      () => SwitchListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        value: value.value,
        activeThumbColor: const Color(0xff7CFC00),
        onChanged: (val) => value.value = val,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xff1C1736).withValues(alpha: 0.8),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xff5B6274)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xff1C1736).withValues(alpha: 0.8),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 14),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xff5B6274)),
      helperStyle: const TextStyle(color: Colors.white, fontSize: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  BoxDecoration _multiFieldContainerDecoration() {
    return BoxDecoration(
      color: const Color(0xff1C1736).withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xff1E2939)),
    );
  }

  FieldDecoration _multiFieldDecoration(String hint) {
    return FieldDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xff5B6274)),
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      suffixIcon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      showClearIcon: false,
    );
  }

  BoxDecoration _mainDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: const Color(0xff1C1736).withValues(alpha: 0.5),
      border: Border.all(color: const Color(0xff1E2939)),
    );
  }

  BoxDecoration _innerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: const Color(0xff1C1736).withValues(alpha: 0.8),
      border: Border.all(color: const Color(0xff1E2939)),
    );
  }

  BoxDecoration _uploadDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xff1E2939)),
      color: const Color(0xff1C1736).withValues(alpha: 0.6),
    );
  }
}

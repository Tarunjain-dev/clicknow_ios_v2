import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/stepper_controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_dropdown/multi_dropdown.dart';

class StepThreeBodyScreen extends StatefulWidget {
  const StepThreeBodyScreen({super.key});

  @override
  State<StepThreeBodyScreen> createState() => _StepThreeBodyScreenState();
}

class _StepThreeBodyScreenState extends State<StepThreeBodyScreen> {

  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<ProfessionalRegistrationController>();
  final stepperController = Get.find<StepperController>();

  @override
  Widget build(BuildContext context) {

    /// -- Scaling Utility Instance
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
              decoration: _mainContainer(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Step 3 Title and description
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 4),
                    child: Text(
                      "Build Your Professional Profile",
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
                      "This information will be visible to clicknow customers and helpful for us to deliver booking orders.",
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                  const Divider(color: Color(0xff1E2939)),

                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        /// --  Work Information Section
                        _buildExpandable(
                          title: "Work Information",
                          icon: Icons.work_outline,
                          isExpanded: controller.isWorkExpanded,
                          onTap: controller.toggleWork,
                          child: _workSection(),
                        ),
                        const SizedBox(height: 12),

                        /// -- Working Locations Section
                        _buildExpandable(
                          title: "Working Locations",
                          icon: Icons.location_on_outlined,
                          isExpanded: controller.isWorkingLocationExpanded,
                          onTap: controller.toggleWorkingLocation,
                          child: _workingLocationSection(),
                        ),
                        const SizedBox(height: 12),

                        /// -- Profile & Online Presence Section
                        _buildExpandable(
                          title: "Profile & Online Presence",
                          icon: Icons.link,
                          isExpanded: controller.isProfileExpanded,
                          onTap: controller.toggleProfile,
                          child: _profileSection(),
                        ),
                        const SizedBox(height: 12),

                        /// -- Additional Details
                        _buildExpandable(
                          title: "Additional Details",
                          icon: Icons.info_outline,
                          isExpanded: controller.isAdditionalExpanded,
                          onTap: controller.toggleAdditional,
                          child: _additionalSection(),
                        ),
                      ],
                    ),
                  ),

                  /// -- back and Continue Buttons
                  const Divider(color: Color(0xff1E2939), height: 2),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      color: const Color(0xff101425),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 20.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          /// -- Back Button
                          Expanded(
                            child: SizedBox(
                              height: scale.getScaledHeight(40),
                              child: ElevatedButton(
                                onPressed: () =>
                                    stepperController.previousStep(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xff13182C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.circular(
                                      10,
                                    ),
                                    side: BorderSide(color: Color(0xff1E2939)),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
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

                          /// -- Continue Button
                          SizedBox(width: scale.getScaledWidth(8)),
                          Expanded(
                            child: SizedBox(
                              height: scale.getScaledHeight(40),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (controller.validateStep3()) {
                                    stepperController.nextStep();
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
                                child: Text(
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

  /// -- Expandable Container Widget
  Widget _buildExpandable({
    required String title,
    IconData icon = Icons.phone,
    required RxBool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Obx(
      () => Container(
        decoration: _innerContainer(),
        child: Column(
          children: [
            ListTile(
              onTap: onTap,
              leading: Icon(icon, color: const Color(0xff9235B1)),
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

  /// -- Work Information Section
  Widget _workSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Experience Dropdown
        _fieldLabel("Years of Experience"),
        const SizedBox(height: 6),
        Theme(
          data: Theme.of(context).copyWith(hintColor: Color(0xff5B6274)),
          child: Obx(
            () => DropdownButtonFormField(
              initialValue: controller.selectedExperience.value.isEmpty
                  ? null
                  : controller.selectedExperience.value,
              dropdownColor: const Color(0xff1C1736),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: controller.experienceOptions
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) =>
                  controller.selectedExperience.value = val ?? "",
              decoration: _dropdownDecoration("Enter Years"),
            ),
          ),
        ),

        const SizedBox(height: 16),

        /// Working Days Chips
        _fieldLabel("Available Working Days"),
        const SizedBox(height: 6),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.workingDaysOptions
              .map(
                (day) => Obx(() {
                  bool selected = controller.selectedWorkingDays.contains(day);
                  return GestureDetector(
                    onTap: () => controller.toggleWorkingDay(day),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xff360248)
                            : const Color(0xff2A2E3F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        day,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }),
              )
              .toList(),
        ),

        const SizedBox(height: 16),

        /// Short Bio
        _fieldLabel("Short Bio"),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller.shortBioController,
          maxLength: 300,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            "Tell Customers about yourself and your expertise...",
          ),
        ),
      ],
    );
  }

  /// -- Working Locations Section
  Widget _workingLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Working State"),
        const SizedBox(height: 6),
        Theme(
          data: Theme.of(context).copyWith(hintColor: Color(0xff5B6274)),
          child: Obx(
            () => DropdownButtonFormField<String>(
              initialValue: controller.selectedWorkingState.value.isEmpty
                  ? null
                  : controller.selectedWorkingState.value,
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
              onChanged: controller.onWorkingStateChanged,
              decoration: _dropdownDecoration("Select working state"),
            ),
          ),
        ),

        const SizedBox(height: 12),
        _fieldLabel("Working City"),
        const SizedBox(height: 6),
        Obx(() {
          final cities = controller.currentWorkingCityOptions;
          return Container(
            decoration: _multiFieldContainerDecoration(),
            child: MultiDropdown<String>(
              key: ValueKey(controller.selectedWorkingState.value),
              items: cities
                  .map((city) => DropdownItem(label: city, value: city))
                  .toList(),
              onSelectionChange: (selectedItems) {
                controller.selectedWorkingCities.assignAll(selectedItems);
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
                onPressed: controller.saveWorkingLocation,
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
                onPressed: controller.addMoreWorkingLocation,
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
          if (controller.workingLocations.isEmpty) {
            return const SizedBox();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Selected Working Locations :",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 6),
              ...controller.workingLocations.map((loc) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "- ${loc.state} : ${loc.cities.join(", ")}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                );
              }),
              const SizedBox(height: 8),
              const Text(
                "Note : These are the locations you are willingly wanted to work.",
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// -- Profile & Online Presence Section
  Widget _profileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Google Work Drive URL"),
        const SizedBox(height: 8),
        _textField(controller.googleDriveController, "Google Work Drive URL"),
        const SizedBox(height: 12),

        _fieldLabel("Instagram Profile URL"),
        const SizedBox(height: 8),
        _textField(controller.instagramController, "Instagram Profile URL"),
        const SizedBox(height: 12),

        _fieldLabel("Website URL", optional: true),
        const SizedBox(height: 8),
        _textField(controller.websiteController, "Website URL"),
      ],
    );
  }

  Widget _additionalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel("Company/Brand Name", optional: true),
        const SizedBox(height: 8),
        _textField(controller.companyNameController, "Company/Brand Name"),
        const SizedBox(height: 12),

        _fieldLabel("Past Client Experience", optional: true),
        const SizedBox(height: 8),
        _textField(
          controller.clientExperienceController,
          "Past Client Experience",
        ),
        const SizedBox(height: 12),

        _fieldLabel("Awards & Achievements", optional: true),
        const SizedBox(height: 8),
        _textField(controller.awardsController, "Awards & Achievements"),
      ],
    );
  }

  Widget _fieldLabel(String text, {bool optional = false}) {
    return Row(
      children: [
        Text(text, style: const TextStyle(color: Colors.white)),
        if (optional) const SizedBox(width: 6),
        if (optional)
          const Text(
            "[optional]",
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
      ],
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

  // ------------------------------------------------

  Widget _textField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint),
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

  BoxDecoration _mainContainer() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: const Color(0xff1C1736).withValues(alpha: 0.5),
      border: Border.all(color: const Color(0xff1E2939)),
    );
  }

  BoxDecoration _innerContainer() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: const Color(0xff1C1736).withValues(alpha: 0.8),
      border: Border.all(color: const Color(0xff1E2939)),
    );
  }
}

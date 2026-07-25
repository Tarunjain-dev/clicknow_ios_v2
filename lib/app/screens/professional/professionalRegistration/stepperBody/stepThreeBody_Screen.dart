import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/stepper_controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:clicknow_version2/app/widgets/searchable_multi_selection_bottom_sheet.dart';
import 'package:clicknow_version2/app/widgets/searchable_selection_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StepThreeBodyScreen extends StatefulWidget {
  const StepThreeBodyScreen({super.key});

  @override
  State<StepThreeBodyScreen> createState() => _StepThreeBodyScreenState();
}

class _StepThreeBodyScreenState extends State<StepThreeBodyScreen> {

  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<ProfessionalRegistrationController>();
  final stepperController = Get.find<StepperController>();
  bool get _isDark => HelperFunctions.isDarkMode(context);
  Color get _textPrimary => _isDark ? Colors.white : Colors.black;
  Color get _textSecondary => _isDark ? Colors.white60 : Colors.black.withValues(alpha: 0.6);

  @override
  Widget build(BuildContext context) {

    /// -- Dark Mode Utility
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling Utility Instance
    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: ResponsiveUtility.only(left: 16, top: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16,),
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
                  Padding(
                    padding: ResponsiveUtility.only(bottom:4, left: 10, right: 10,  top: 10),
                    child: Text(
                      "Build Your Professional Profile",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: ResponsiveUtility.fontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: ResponsiveUtility.symmetric(horizontal: 10),
                    child: Text(
                      "This information will be visible to clicknow customers and helpful for us to deliver booking orders.",
                      style: TextStyle(color: _textSecondary, fontSize: ResponsiveUtility.fontSize(12)),
                    ),
                  ),
                  Divider(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9)),

                  Padding(
                    padding: ResponsiveUtility.all(10),
                    child: Column(
                      children: [
                        // --  Work Information Section
                        _buildExpandable(
                          title: "Work Information",
                          icon: Icons.work_outline,
                          isExpanded: controller.isWorkExpanded,
                          onTap: controller.toggleWork,
                          child: _workSection(),
                        ),
                        SizedBox(height: ResponsiveUtility.height(10)),

                        /// -- Working Locations Section
                        _buildExpandable(
                          title: "Working Locations",
                          icon: Icons.location_on_outlined,
                          isExpanded: controller.isWorkingLocationExpanded,
                          onTap: controller.toggleWorkingLocation,
                          child: _workingLocationSection(),
                        ),
                        SizedBox(height: ResponsiveUtility.height(10)),

                        /// -- Profile & Online Presence Section
                        _buildExpandable(
                          title: "Profile & Online Presence",
                          icon: Icons.link,
                          isExpanded: controller.isProfileExpanded,
                          onTap: controller.toggleProfile,
                          child: _profileSection(),
                        ),
                        SizedBox(height: ResponsiveUtility.height(10)),

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
                  Divider(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9), height: 2),
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
                                onPressed: () => stepperController.previousStep(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xff13182C) : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.circular(
                                      10,
                                    ),
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
                                    SizedBox(width: scale.getScaledWidth(8)),
                                    Text(
                                      "Back",
                                      style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black54,
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
                                onPressed: () async {
                                  if (controller.validateStep3()) {
                                    await controller.saveDraftForStep(2);
                                    await stepperController.completeStepAndContinue(2);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.circular(
                                      10,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "Continue",
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
              title: Text(title, style: TextStyle(color: _textPrimary)),
              trailing: Icon(
                isExpanded.value
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: _textPrimary,
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
        SizedBox(height: ResponsiveUtility.height(6)),
        Theme(
          data: Theme.of(context).copyWith(hintColor: Color(0xff5B6274)),
          child: Obx(
            () => DropdownButtonFormField(
              initialValue: controller.selectedExperience.value.isEmpty ? null : controller.selectedExperience.value,
              dropdownColor: _isDark ? const Color(0xff1C1736) : Colors.white,
              style: TextStyle(color: _textPrimary, fontSize: ResponsiveUtility.fontSize(14)),
              items: controller.experienceOptions
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: TextStyle(color: _textPrimary),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => controller.selectedExperience.value = val ?? "",
              decoration: _dropdownDecoration("Enter Years"),
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtility.height(10)),

        /// Working Days Chips
        _fieldLabel("Available Working Days"),
        SizedBox(height: ResponsiveUtility.height(6)),

        Wrap(
          spacing: ResponsiveUtility.width(8),
          runSpacing: ResponsiveUtility.width(8),
          children: controller.workingDaysOptions
              .map(
                (day) => Obx(() {
                  bool selected = controller.selectedWorkingDays.contains(day);
                  return GestureDetector(
                    onTap: () => controller.toggleWorkingDay(day),
                    child: Container(
                      padding: ResponsiveUtility.symmetric(vertical: 8, horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected ?
                               _isDark ? AppColors.purple3 : Color(0xff9810FA) :
                               _isDark ? Color(0xff2A2E3F) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        day,
                        style: TextStyle(
                          color: selected ? Colors.white : (_isDark ? Colors.white70 : Colors.black54),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              )
              .toList(),
        ),
        SizedBox(height: ResponsiveUtility.height(10)),

        /// Short Bio
        _fieldLabel("Short Bio"),
        SizedBox(height: ResponsiveUtility.height(6)),
        TextFormField(
          controller: controller.shortBioController,
          maxLength: 300,
          maxLines: 4,
          style: TextStyle(color: _textPrimary),
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
        SizedBox(height: ResponsiveUtility.height(6)),
        Obx(
          () => _selectorField(
            hint: "Select working state",
            value: controller.selectedWorkingState.value,
            onTap: () async {
              final selected = await SearchableSelectionBottomSheet.show(
                context: context,
                title: 'Select Working State',
                options: controller.stateOptions,
                initialValue: controller.selectedWorkingState.value,
                searchHint: 'Search state',
              );
              if (selected == null) {
                return;
              }
              controller.onWorkingStateChanged(selected);
            },
          ),
        ),
        SizedBox(height: ResponsiveUtility.height(10)),

        /// -- Working City
        _fieldLabel("Working City"),
        SizedBox(height: ResponsiveUtility.height(6)),
        Obx(() {
          final cities = controller.currentWorkingCityOptions;
          final selectedCities = controller.selectedWorkingCities.toList(growable: false);
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
                  controller.selectedWorkingCities.assignAll(picked);
                },
              ),
              if (selectedCities.isNotEmpty) ...[
                SizedBox(height: ResponsiveUtility.height(8)),
                Wrap(
                  spacing: ResponsiveUtility.width(8),
                  runSpacing: ResponsiveUtility.width(8),
                  children: selectedCities
                      .map(
                        (city) => Chip(
                          backgroundColor: Color(0xff9810FA) ,
                          side: BorderSide(color: Colors.white),
                          label: Text(city, style: TextStyle(color: Colors.white),),
                          onDeleted: () {
                            controller.selectedWorkingCities.remove(city);
                          },
                          deleteIcon: Icon(Icons.cancel_outlined, size: 16, color: Colors.white,),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ],
          );
        }),

        SizedBox(height: ResponsiveUtility.height(6)),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => controller.saveWorkingLocation(clearAfter: true),
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
                onPressed: controller.addMoreWorkingLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDark ? Colors.white : AppColors.primaryColor,
                  foregroundColor: _isDark ? AppColors.primaryColor : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),),
                ),
                child: const Text("Add More", style: TextStyle(fontWeight: FontWeight.bold),),
              ),
            ),
          ],
        ),

        SizedBox(height: ResponsiveUtility.height(10)),
        Obx(() {
          if (controller.workingLocations.isEmpty) {
            return const SizedBox();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Selected Working Locations :",
                style: TextStyle(color: _isDark ? Colors.white54 : Colors.black54, fontSize: ResponsiveUtility.fontSize(12)),
              ),
              SizedBox(height: ResponsiveUtility.height(6)),
              ...controller.workingLocations.map((loc) {
                return Padding(
                  padding: ResponsiveUtility.only(bottom: 2),
                  child: Text(
                    "- ${loc.state} : ${loc.cities.join(", ")}",
                    style: TextStyle(color: _isDark ? Colors.white70 : Colors.black54, fontSize: ResponsiveUtility.fontSize(12)),
                  ),
                );
              }),
              SizedBox(height: ResponsiveUtility.height(6)),
              Text(
                "Note : These are the locations you are willingly wanted to work.",
                style: TextStyle(color: _isDark ? Colors.white54 : Colors.black54, fontSize: ResponsiveUtility.fontSize(10)),
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
        Text(text, style: TextStyle(color: _textPrimary)),
        if (optional) const SizedBox(width: 6),
        if (optional)
          Text(
            "[optional]",
            style: TextStyle(color: _isDark ? Colors.white54 : Colors.black54, fontSize: 11),
          ),
      ],
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
          color: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.85) : const Color(0xffF6F4FF).withValues(alpha: 0.9),
          border: Border.all(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.trim().isEmpty ? hint : value.trim(),
                style: TextStyle(
                  color: value.trim().isEmpty
                      ? const Color(0xff5B6274)
                      : _textPrimary,
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

  BoxDecoration _multiFieldContainerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Color(0xff1E2939)),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: _multiFieldContainerDecoration().copyWith(
          color: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.85) : const Color(0xffF6F4FF).withValues(alpha: 0.9),
          border: Border.all(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: values.isEmpty
                      ? const Color(0xff5B6274)
                      : _textPrimary,
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

  // ------------------------------------------------

  Widget _textField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: _textPrimary),
      decoration: _inputDecoration(hint),
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
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.8) : const Color(0xffF6F4FF).withValues(alpha: 0.8),
      labelStyle: TextStyle(color: _textPrimary, fontSize: ResponsiveUtility.fontSize(12)),
      hintText: hint,
      hintStyle: TextStyle(color: _isDark ? const Color(0xff5B6274) : Colors.black54),
      helperStyle: TextStyle(color: _textPrimary, fontSize: ResponsiveUtility.fontSize(12)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? AppColors.primaryColor : Color(0xffD9D9D9))),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Colors.red : Color(0xffD9D9D9))),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _isDark ? Color(0xff1E2939) : Color(0xffD9D9D9))),
    );
  }

  BoxDecoration _mainContainer() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.5) : const Color(0xffFCFBFF),
      border: Border.all(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9)),
    );
  }

  BoxDecoration _innerContainer() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: _isDark ? const Color(0xff1C1736).withValues(alpha: 0.8) : const Color(0xffF6F4FF).withValues(alpha: 0.8),
      border: Border.all(color: _isDark ? const Color(0xff1E2939) : const Color(0xffD9D9D9)),
    );
  }
}

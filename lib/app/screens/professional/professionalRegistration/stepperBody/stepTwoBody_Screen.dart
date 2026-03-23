import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/stepper_controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class StepTwoBodyScreen extends StatefulWidget {
  const StepTwoBodyScreen({super.key});

  @override
  State<StepTwoBodyScreen> createState() => _StepTwoBodyScreenState();
}

class _StepTwoBodyScreenState extends State<StepTwoBodyScreen> {
  final _formKey = GlobalKey<FormState>();
  final professionalRegController = Get.find<ProfessionalRegistrationController>();
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xff1C1736).withValues(alpha: 0.5),
                border: Border.all(color: const Color(0xff1E2939)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Step 2 Title and Description
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 4),
                    child: Text(
                      "Tell Us About Yourself",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: scale.getScaledFont(20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "Help us Know you better with some basic information.",
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                  const Divider(color: Color(0xff1E2939), thickness: 2),

                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// FULL NAME
                        const Text(
                          "Full Name",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: professionalRegController.nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration("Enter your full name"),
                        ),

                        const SizedBox(height: 16),

                        /// GENDER DROPDOWN
                        const Text(
                          "Gender",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),

                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(hintColor: Color(0xff5B6274)),
                          child: Obx(
                            () => DropdownButtonFormField<String>(
                              initialValue:
                                  professionalRegController
                                      .selectedGender
                                      .value
                                      .isEmpty
                                  ? null
                                  : professionalRegController
                                        .selectedGender
                                        .value,
                              dropdownColor: const Color(0xff1C1736),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              items: professionalRegController.genderOptions
                                  .map(
                                    (gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(
                                        gender,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                professionalRegController.selectedGender.value =
                                    value ?? "";
                              },
                              decoration: _dropdownDecoration("Select gender"),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// DATE OF BIRTH
                        const Text(
                          "Date of Birth",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),

                        Obx(
                          () => InkWell(
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                professionalRegController.selectedDob.value =
                                    picked;
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: _containerDecoration(),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month,
                                    color: Colors.white54,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    professionalRegController
                                                .selectedDob
                                                .value ==
                                            null
                                        ? "Select date of birth"
                                        : DateFormat("dd MMM yyyy").format(
                                            professionalRegController
                                                .selectedDob
                                                .value!,
                                          ),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// PERMANENT ADDRESS
                        const Text(
                          "Permanent Address",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: professionalRegController
                              .permanentAddressController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            "Enter your complete address",
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// STATE
                        const Text(
                          "State",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(hintColor: Color(0xff5B6274)),
                          child: Obx(
                            () => DropdownButtonFormField<String>(
                              initialValue:
                                  professionalRegController
                                      .selectedState
                                      .value
                                      .isEmpty
                                  ? null
                                  : professionalRegController
                                        .selectedState
                                        .value,
                              dropdownColor: const Color(0xff1C1736),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              items: professionalRegController.stateOptions
                                  .map(
                                    (state) => DropdownMenuItem(
                                      value: state,
                                      child: Text(
                                        state,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged:
                                  professionalRegController.onStateChanged,
                              decoration: _dropdownDecoration("Select state"),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// CITY
                        const Text(
                          "City",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(hintColor: Color(0xff5B6274)),
                          child: Obx(() {
                            final cities =
                                professionalRegController.currentCityOptions;
                            return DropdownButtonFormField<String>(
                              initialValue:
                                  professionalRegController
                                      .selectedCity
                                      .value
                                      .isEmpty
                                  ? null
                                  : professionalRegController
                                        .selectedCity
                                        .value,
                              dropdownColor: const Color(0xff1C1736),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              items: cities
                                  .map(
                                    (city) => DropdownMenuItem(
                                      value: city,
                                      child: Text(
                                        city,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: cities.isEmpty
                                  ? null
                                  : professionalRegController.onCityChanged,
                              decoration: _dropdownDecoration("Select City"),
                            );
                          }),
                        ),

                        const SizedBox(height: 16),

                        /// PINCODE
                        const Text(
                          "Pincode",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(hintColor: Color(0xff5B6274)),
                          child: Obx(() {
                            final pincodes =
                                professionalRegController.currentPincodeOptions;
                            return DropdownButtonFormField<String>(
                              initialValue:
                                  professionalRegController
                                      .selectedPincode
                                      .value
                                      .isEmpty
                                  ? null
                                  : professionalRegController
                                        .selectedPincode
                                        .value,
                              dropdownColor: const Color(0xff1C1736),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              items: pincodes
                                  .map(
                                    (pin) => DropdownMenuItem(
                                      value: pin,
                                      child: Text(
                                        pin,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: pincodes.isEmpty
                                  ? null
                                  : (val) {
                                      professionalRegController
                                              .selectedPincode
                                              .value =
                                          val ?? "";
                                    },
                              decoration: _dropdownDecoration("Select pincode"),
                            );
                          }),
                        ),

                        const SizedBox(height: 16),

                        /// LANGUAGES
                        const Text(
                          "Languages Known",
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: _containerDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: professionalRegController
                                    .languageOptions
                                    .map((lang) {
                                      return Obx(() {
                                        bool isSelected =
                                            professionalRegController
                                                .selectedLanguages
                                                .contains(lang);

                                        return GestureDetector(
                                          onTap: () => professionalRegController
                                              .toggleLanguage(lang),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xff360248)
                                                  : const Color(0xff2A2E3F),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              lang,
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        );
                                      });
                                    })
                                    .toList(),
                              ),

                              /// Divider + Selected Text
                              Obx(() {
                                if (professionalRegController
                                    .selectedLanguages
                                    .isEmpty) {
                                  return const SizedBox();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    const Divider(color: Color(0xff1E2939)),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Selected : ",
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            professionalRegController
                                                .selectedLanguages
                                                .join(", "),
                                            maxLines: 3,
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.purpleAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
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
                                  if (professionalRegController
                                      .validateStep2()) {
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xff1C1736).withValues(alpha: 0.8),
      labelStyle: TextStyle(color: Colors.white, fontSize: 14),
      hintText: hint,
      // helperStyle: TextStyle(color: Colors.white, fontSize: ),
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

  BoxDecoration _containerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: const Color(0xff1C1736).withValues(alpha: 0.8),
      border: Border.all(color: const Color(0xff1E2939)),
    );
  }
}

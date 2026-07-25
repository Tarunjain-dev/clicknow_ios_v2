import 'package:clicknow_version2/app/screens/professional/getx/professionalRegistrationController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/stepper_controller.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/professional_location_picker_screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/widgets/address_preview_card.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/widgets/location_search_field.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/widgets/map_picker_widget.dart';
import 'package:clicknow_version2/app/services/maps_service.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      professionalRegController.initializeStep2Location();
    });
  }

  Future<void> _openLargeMapPicker() async {
    if (!professionalRegController.isMapApiConfigured) {
      return;
    }

    final selectedLatitude = professionalRegController.selectedLatitude.value;
    final selectedLongitude = professionalRegController.selectedLongitude.value;
    AddressSelection? initialSelection;

    if (selectedLatitude != null && selectedLongitude != null) {
      initialSelection = AddressSelection(
        formattedAddress: professionalRegController.permanentAddressController.text.trim(),
        state: professionalRegController.selectedState.value,
        city: professionalRegController.selectedCity.value,
        pincode: professionalRegController.selectedPincode.value,
        latitude: selectedLatitude,
        longitude: selectedLongitude,
      );
    }

    final pickedLocation = await Get.to<AddressSelection>(
      () => ProfessionalLocationPickerScreen(
        initialCenterLatitude: professionalRegController.mapCenterLatitude.value,
        initialCenterLongitude: professionalRegController.mapCenterLongitude.value,
        initialSelection: initialSelection,
      ),
      fullscreenDialog: true,
    );

    if (pickedLocation == null) {
      return;
    }

    await professionalRegController.applyAddressSelectionFromPicker(
      pickedLocation,
    );
  }

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: ResponsiveUtility.only(top: 16, right: 16, left: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveUtility.radius(10)),
                color: isDark ? Color(0xff1C1736).withValues(alpha: 0.5) : Color(0xffFCFBFF),
                border:Border.all(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Step 2 Title and Description
                  Padding(
                    padding: ResponsiveUtility.only(top: 10, right: 10, left: 10, bottom: 4),
                    child: Text(
                      "Tell Us About Yourself",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: ResponsiveUtility.fontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: ResponsiveUtility.symmetric(horizontal: 10),
                    child: Text(
                      "Help us Know you better with some basic information.",
                      style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6), fontSize: ResponsiveUtility.fontSize(12),),
                    ),
                  ),
                  Divider(color:  isDark ? Color(0xff1E2939) : Color(0xffD9D9D9), thickness: 1),

                  Padding(
                    padding: ResponsiveUtility.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// FULL NAME
                        Text("Full Name", style: TextStyle(color: isDark ? Colors.white : Colors.black,),),
                        SizedBox(height: ResponsiveUtility.height(2)),
                        TextFormField(
                          controller: professionalRegController.nameController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black,),
                          decoration: _inputDecoration("Enter your full name", isDark),
                        ),
                        SizedBox(height: ResponsiveUtility.height(10)),

                        /// GENDER DROPDOWN
                        Text("Gender", style: TextStyle(color: isDark ? Colors.white : Colors.black),),
                        SizedBox(height: ResponsiveUtility.height(2)),
                        Theme(
                          data: Theme.of(context,).copyWith(hintColor: isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.6)),
                          child: Obx(
                            () => DropdownButtonFormField<String>(
                              initialValue: professionalRegController.selectedGender.value.isEmpty ? null : professionalRegController.selectedGender.value,
                              dropdownColor: isDark ? Color(0xff1C1736) : Colors.white,
                              style: TextStyle(fontSize: ResponsiveUtility.fontSize(14),),
                              items: professionalRegController.genderOptions
                                  .map(
                                    (gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(gender, style: TextStyle(color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),),),
                                    ),
                                  ).toList(),
                              onChanged: (value) {
                                professionalRegController.selectedGender.value = value ?? "";
                              },
                              decoration: _inputDecoration("Select gender", isDark),
                            ),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtility.height(16)),

                        /// DATE OF BIRTH
                        Text("Date of Birth", style: TextStyle(color: isDark ? Colors.white : Colors.black,),),
                        SizedBox(height: ResponsiveUtility.height(6)),
                        Obx(
                          () => InkWell(
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                                barrierColor: Colors.black.withValues(alpha: 0.6),
                              );
                              if (picked != null) {
                                professionalRegController.selectedDob.value = picked;
                              }
                            },
                            child: Container(
                              padding: ResponsiveUtility.symmetric(horizontal: 14, vertical: 12),
                              decoration: _containerDecoration(isDark),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    color: isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.6),
                                  ),
                                  SizedBox(width: ResponsiveUtility.width(10)),
                                  Text(
                                    professionalRegController.selectedDob.value == null
                                    ? "Select date of birth"
                                    : DateFormat("dd MMM yyyy").format(professionalRegController.selectedDob.value!,),
                                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.6),),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtility.height(16)),

                        /// PERMANENT ADDRESS
                        Text("Permanent Address", style: TextStyle(color: isDark ? Colors.white : Colors.black),),
                        SizedBox(height: ResponsiveUtility.height(6)),
                        Obx(
                          () => LocationSearchField(
                            controller: professionalRegController.permanentAddressController,
                            onChanged: professionalRegController.onAddressSearchChanged,
                            onSuggestionTap: professionalRegController.selectAddressSuggestion,
                            suggestions: professionalRegController.placeSuggestions,
                            isSearching: professionalRegController.isSearchingPlaces.value,
                            onUseCurrentLocation: professionalRegController.useCurrentLocationForAddress,
                            isFetchingCurrentLocation: professionalRegController.isFetchingCurrentLocation.value,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtility.height(16)),

                        Obx(
                          () => AddressPreviewCard(
                            formattedAddress: professionalRegController.permanentAddressController.text,
                            city: professionalRegController.selectedCity.value,
                            state: professionalRegController.selectedState.value,
                            country: professionalRegController.selectedCountry.value,
                            pincode: professionalRegController.selectedPincode.value,
                            latitude: professionalRegController.selectedLatitude.value,
                            longitude: professionalRegController.selectedLongitude.value,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtility.height(16)),

                        Obx(
                          () => MapPickerWidget(
                            centerLatitude: professionalRegController.mapCenterLatitude.value,
                            centerLongitude: professionalRegController.mapCenterLongitude.value,
                            selectedLatitude: professionalRegController.selectedLatitude.value,
                            selectedLongitude: professionalRegController.selectedLongitude.value,
                            isResolvingAddress: professionalRegController.isResolvingAddressFromMap.value,
                            onLocationChanged: (double latitude, double longitude,) {
                              return professionalRegController.onMapLocationChanged(latitude: latitude, longitude: longitude,);
                            },
                            onConfirmLocation: professionalRegController.confirmSelectedLocation,
                            canConfirmLocation: professionalRegController.hasSelectedLocation,
                            showMap: professionalRegController.isMapApiConfigured,
                            fallbackMessage:
                                "Google Maps API key is missing.\n"
                                "Please set ApiConstants.googleMapsApiKey.",
                            onOpenExpandedMap: professionalRegController.isMapApiConfigured ? _openLargeMapPicker : null,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtility.height(16)),

                        /// LANGUAGES
                        Text("Languages Known", style: TextStyle(color: isDark ? AppColors.white : Colors.black),),
                        SizedBox(height: ResponsiveUtility.height(6)),

                        Container(
                          padding: ResponsiveUtility.all(10),
                          width: double.infinity,
                          decoration: _containerDecoration(isDark),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: ResponsiveUtility.width(8),
                                runSpacing: ResponsiveUtility.width(8),
                                children: professionalRegController
                                    .languageOptions
                                    .map((lang) {
                                      return Obx(() {
                                        bool isSelected = professionalRegController.selectedLanguages.contains(lang);
                                        return GestureDetector(
                                          onTap: () => professionalRegController.toggleLanguage(lang),
                                          child: Container(
                                            padding: ResponsiveUtility.symmetric(horizontal: 14, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isSelected ?
                                              isDark ? AppColors.purple3 : Color(0xff9810FA) :
                                              isDark ? Color(0xff2A2E3F) : Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              lang,
                                              style: TextStyle(
                                                color: isSelected ?
                                                Colors.white :
                                                isDark ? Colors.white70 : Color(0xff6F5F5F),
                                                fontWeight: FontWeight.w600,
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
                                if (professionalRegController.selectedLanguages.isEmpty) {
                                  return const SizedBox();
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: ResponsiveUtility.height(10)),
                                    Divider(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
                                    SizedBox(height: ResponsiveUtility.height(8)),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Selected : ", style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.8,) : Colors.black.withValues(alpha: 0.6),),),
                                        Expanded(
                                          child: Text(
                                            professionalRegController.selectedLanguages.join(", "),
                                            maxLines: 3,
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: AppColors.primaryColor,),
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
                  Divider(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9), height: 2),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      color: isDark ? Color(0xff101425) : Color(0xffF6F6F6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [

                          /// -- Back Button
                          Expanded(
                            child: SizedBox(
                              height: ResponsiveUtility.height(40),
                              child: ElevatedButton(
                                onPressed: () => stepperController.previousStep(),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: isDark ? Color(0xff13182C) : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.circular(10),
                                    side: BorderSide(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),
                                      size: 16,
                                    ),
                                    SizedBox(width: ResponsiveUtility.width(8)),
                                    Text(
                                      "Back",
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveUtility.fontSize(14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          /// -- Continue Button
                          SizedBox(width: ResponsiveUtility.width(8)),
                          Expanded(
                            child: SizedBox(
                              height: ResponsiveUtility.height(40),
                              child: Obx(() {
                                final canContinue = professionalRegController.hasSelectedLocation && !professionalRegController.isResolvingAddressFromMap.value;

                                return ElevatedButton(
                                  onPressed: !canContinue
                                      ? null
                                      : () async {
                                          if (professionalRegController.validateStep2()) {
                                            await professionalRegController.saveDraftForStep(1);
                                            await professionalRegController.saveStep2ProfileToFirestore();
                                            await stepperController.completeStepAndContinue(1);
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadiusGeometry.circular(10,),
                                    ),
                                  ),
                                  child: Text(
                                    "Continue",
                                    style: TextStyle(
                                      color: isDark ? AppColors.purple3 : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: ResponsiveUtility.fontSize(14),
                                    ),
                                  ),
                                );
                              }),
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

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? Color(0xff1C1736).withValues(alpha: 0.5) : Color(0xffF6F4FF).withValues(alpha: 0.8),
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.6),
        fontSize: ResponsiveUtility.fontSize(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
          width: 1.2,
        ),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),),
    );
  }

  BoxDecoration _containerDecoration(bool isDark) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(ResponsiveUtility.radius(10)),
      color: isDark ? Color(0xff1C1736).withValues(alpha: 0.8) : Color(0xffF6F4FF).withValues(alpha: 0.8),
      border: Border.all(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
    );
  }
}

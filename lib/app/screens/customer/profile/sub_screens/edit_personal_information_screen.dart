import 'dart:async';
import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/customer/profile/getx/customer_profile_controller.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/professional_location_picker_screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/widgets/address_preview_card.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/widgets/location_search_field.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/widgets/map_picker_widget.dart';
import 'package:clicknow_version2/app/services/location_service.dart';
import 'package:clicknow_version2/app/services/maps_service.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class EditPersonalInformationController extends GetxController {
  EditPersonalInformationController(
    this.profileController, {
    required this.forceCompletion,
  });

  final CustomerProfileController profileController;
  final bool forceCompletion;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController gstNumberController = TextEditingController();

  final RxString selectedState = ''.obs;
  final RxString selectedCity = ''.obs;
  final RxString selectedCountry = ''.obs;
  static const double _defaultIndiaLatitude = 22.9734;
  static const double _defaultIndiaLongitude = 78.6569;

  final MapsService _mapsService = MapsService.instance;
  final LocationService _locationService = LocationService.instance;
  Timer? _placeSearchDebounceTimer;
  int _placeSearchRequestId = 0;
  bool _locationInitialized = false;

  final RxDouble mapCenterLatitude = _defaultIndiaLatitude.obs;
  final RxDouble mapCenterLongitude = _defaultIndiaLongitude.obs;
  final RxnDouble selectedLatitude = RxnDouble();
  final RxnDouble selectedLongitude = RxnDouble();
  final RxList<PlaceSuggestion> placeSuggestions = <PlaceSuggestion>[].obs;
  final RxBool isSearchingPlaces = false.obs;
  final RxBool isResolvingAddressFromMap = false.obs;
  final RxBool isFetchingCurrentLocation = false.obs;

  bool get isMapApiConfigured => _mapsService.isApiKeyConfigured;
  bool get hasSelectedLocation =>
      selectedLatitude.value != null &&
      selectedLongitude.value != null &&
      addressController.text.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    fullNameController.text = profileController.fullName.value == 'Guest User'
        ? ''
        : profileController.fullName.value;
    landmarkController.text = profileController.landmark.value;
    addressController.text = profileController.address.value;
    stateController.text = profileController.state.value;
    cityController.text = profileController.city.value;
    pincodeController.text = profileController.pincode.value;
    gstNumberController.text = profileController.gstNumber.value;
    selectedState.value = stateController.text.trim();
    selectedCity.value = cityController.text.trim();

    if (profileController.latitude.value != null &&
        profileController.longitude.value != null) {
      selectedLatitude.value = profileController.latitude.value;
      selectedLongitude.value = profileController.longitude.value;
      mapCenterLatitude.value = profileController.latitude.value!;
      mapCenterLongitude.value = profileController.longitude.value!;
    }
  }

  Future<void> initializeLocation() async {
    if (_locationInitialized) {
      return;
    }
    _locationInitialized = true;

    _syncAddressControllersToRx();

    if (selectedLatitude.value != null && selectedLongitude.value != null) {
      mapCenterLatitude.value = selectedLatitude.value!;
      mapCenterLongitude.value = selectedLongitude.value!;
      return;
    }

    final fallbackHasAddress = addressController.text.trim().isNotEmpty;
    if (fallbackHasAddress) {
      return;
    }

    await useCurrentLocationForAddress(showSuccessSnackbar: false);
  }

  void onAddressSearchChanged(String input) {
    _placeSearchDebounceTimer?.cancel();
    final query = input.trim();

    if (query.isEmpty) {
      _placeSearchRequestId++;
      placeSuggestions.clear();
      isSearchingPlaces.value = false;
      return;
    }

    _placeSearchDebounceTimer = Timer(
      const Duration(milliseconds: 400),
      () async {
        final requestId = ++_placeSearchRequestId;
        isSearchingPlaces.value = true;
        try {
          final suggestions = await _mapsService.fetchPlaceSuggestions(query);
          if (requestId != _placeSearchRequestId) {
            return;
          }
          placeSuggestions.assignAll(suggestions);
        } catch (_) {
          if (requestId != _placeSearchRequestId) {
            return;
          }
          placeSuggestions.clear();
          AppSnackbar.error(
            "Search Failed",
            "Unable to fetch location suggestions right now.",
          );
        } finally {
          if (requestId == _placeSearchRequestId) {
            isSearchingPlaces.value = false;
          }
        }
      },
    );
  }

  Future<void> selectAddressSuggestion(PlaceSuggestion suggestion) async {
    placeSuggestions.clear();
    isResolvingAddressFromMap.value = true;
    try {
      final details = await _mapsService.getPlaceDetails(suggestion.placeId);
      if (details == null) {
        AppSnackbar.error(
          "Location Error",
          "Could not resolve selected place details.",
        );
        return;
      }
      _applyAddressSelection(details);
    } catch (_) {
      AppSnackbar.error(
        "Location Error",
        "Unable to fetch selected place details.",
      );
    } finally {
      isResolvingAddressFromMap.value = false;
    }
  }

  Future<void> onMapLocationChanged({
    required double latitude,
    required double longitude,
  }) async {
    isResolvingAddressFromMap.value = true;
    try {
      final result = await _mapsService.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );
      if (result != null) {
        _applyAddressSelection(result);
      } else {
        selectedLatitude.value = latitude;
        selectedLongitude.value = longitude;
        mapCenterLatitude.value = latitude;
        mapCenterLongitude.value = longitude;
        addressController.text =
            'Pinned location (${latitude.toStringAsFixed(6)}, '
            '${longitude.toStringAsFixed(6)})';
        selectedState.value = '';
        selectedCity.value = '';
        selectedCountry.value = '';
        stateController.clear();
        cityController.clear();
        pincodeController.clear();
      }
    } catch (_) {
      AppSnackbar.error(
        "Location Error",
        "Unable to resolve address for selected map pin.",
      );
    } finally {
      isResolvingAddressFromMap.value = false;
    }
  }

  Future<void> useCurrentLocationForAddress({
    bool showSuccessSnackbar = true,
  }) async {
    if (isFetchingCurrentLocation.value) {
      return;
    }

    isFetchingCurrentLocation.value = true;
    try {
      final permission = await _locationService.ensurePermission();
      if (permission == LocationPermissionState.serviceDisabled) {
        AppSnackbar.error(
          "Location Disabled",
          "Please enable location services and try again.",
        );
        return;
      }
      if (permission == LocationPermissionState.denied) {
        AppSnackbar.error(
          "Permission Required",
          "Location permission is required to fetch current location.",
        );
        return;
      }
      if (permission == LocationPermissionState.deniedForever) {
        AppSnackbar.error(
          "Permission Denied",
          "Enable location permission from app settings.",
        );
        return;
      }

      final coordinate = await _locationService.getCurrentLocation();
      if (coordinate == null) {
        AppSnackbar.error(
          "Location Error",
          "Unable to fetch current location coordinates.",
        );
        return;
      }

      await onMapLocationChanged(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
      );

      if (showSuccessSnackbar) {
        AppSnackbar.success(
          "Location Selected",
          "Current location has been applied.",
        );
      }
    } on TimeoutException {
      AppSnackbar.error(
        "Location Timeout",
        "Location lookup timed out. Please try again.",
      );
    } catch (_) {
      AppSnackbar.error(
        "Location Error",
        "Unable to fetch your current location.",
      );
    } finally {
      isFetchingCurrentLocation.value = false;
    }
  }

  void confirmSelectedLocation() {
    if (!hasSelectedLocation) {
      AppSnackbar.error(
        "Location Required",
        "Please select a valid map location first.",
      );
      return;
    }
    AppSnackbar.success(
      "Location Confirmed",
      "Selected location has been confirmed.",
    );
  }

  Future<void> applyAddressSelectionFromPicker(
    AddressSelection selection, {
    bool showSuccessSnackbar = true,
  }) async {
    isResolvingAddressFromMap.value = true;
    try {
      _applyAddressSelection(selection);
      if (showSuccessSnackbar) {
        AppSnackbar.success(
          "Location Saved",
          "Selected map location has been applied.",
        );
      }
    } finally {
      isResolvingAddressFromMap.value = false;
    }
  }

  void _applyAddressSelection(AddressSelection selection) {
    selectedLatitude.value = selection.latitude;
    selectedLongitude.value = selection.longitude;
    mapCenterLatitude.value = selection.latitude;
    mapCenterLongitude.value = selection.longitude;

    addressController.text = selection.formattedAddress;
    selectedState.value = selection.state.trim();
    selectedCity.value = selection.city.trim();
    selectedCountry.value = selection.country.trim();

    stateController.text = selectedState.value;
    cityController.text = selectedCity.value;
    pincodeController.text = selection.pincode.trim();
    placeSuggestions.clear();
  }

  void _syncAddressControllersToRx() {
    selectedState.value = stateController.text.trim();
    selectedCity.value = cityController.text.trim();
    selectedCountry.value = selectedCountry.value.trim();
  }

  Future<void> onSave() async {
    final name = fullNameController.text.trim();
    final landmark = landmarkController.text.trim();
    final address = addressController.text.trim();
    final state = stateController.text.trim();
    final city = cityController.text.trim();
    final pincode = pincodeController.text.trim();
    final gstNumber = gstNumberController.text.trim().toUpperCase();

    if (name.isEmpty) {
      AppSnackbar.error('Required', 'Please enter your name to continue.');
      return;
    }
    if (landmark.isEmpty) {
      AppSnackbar.error(
        'Required',
        'Please enter landmark or direction details to continue.',
      );
      return;
    }
    if (pincode.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(pincode)) {
      AppSnackbar.error('Required', 'Please enter valid 6-digit pincode.');
      return;
    }
    if (gstNumber.isNotEmpty &&
        !RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$')
            .hasMatch(gstNumber)) {
      AppSnackbar.error('Invalid GST', 'Please enter a valid GST number.');
      return;
    }
    if (!hasSelectedLocation) {
      AppSnackbar.error(
        'Location Required',
        'Please select your permanent address on map.',
      );
      return;
    }

    final saved = await profileController.updatePersonalInfo(
      name: name,
      landmark: landmark,
      address: address,
      state: state,
      city: city,
      pincode: pincode,
      gstNumber: gstNumber,
      latitude: selectedLatitude.value!,
      longitude: selectedLongitude.value!,
      showSuccessMessage: !forceCompletion,
    );
    if (!saved) {
      return;
    }

    if (forceCompletion) {
      Get.offAllNamed(AppRoutes.customerBottomNavigationRoute);
      return;
    }
    Get.back();
  }

  @override
  void onClose() {
    _placeSearchDebounceTimer?.cancel();
    fullNameController.dispose();
    landmarkController.dispose();
    addressController.dispose();
    stateController.dispose();
    cityController.dispose();
    pincodeController.dispose();
    gstNumberController.dispose();
    super.onClose();
  }
}

class EditPersonalInformationScreen extends StatefulWidget {
  const EditPersonalInformationScreen({
    super.key,
    this.forceCompletion = false,
  });

  final bool forceCompletion;

  @override
  State<EditPersonalInformationScreen> createState() =>
      _EditPersonalInformationScreenState();
}

class _EditPersonalInformationScreenState
    extends State<EditPersonalInformationScreen> {
  static const String _tag = 'edit_personal_info';

  late final CustomerProfileController _profileController;
  late final EditPersonalInformationController _controller;

  @override
  void initState() {
    super.initState();
    _profileController = CustomerProfileController.instance;
    if (Get.isRegistered<EditPersonalInformationController>(tag: _tag)) {
      Get.delete<EditPersonalInformationController>(tag: _tag, force: true);
    }
    _controller = Get.put(
      EditPersonalInformationController(
        _profileController,
        forceCompletion: widget.forceCompletion,
      ),
      tag: _tag,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initializeLocation();
    });
  }

  Future<void> _openLargeMapPicker() async {
    if (!_controller.isMapApiConfigured) {
      return;
    }

    final selectedLatitude = _controller.selectedLatitude.value;
    final selectedLongitude = _controller.selectedLongitude.value;
    AddressSelection? initialSelection;

    if (selectedLatitude != null && selectedLongitude != null) {
      initialSelection = AddressSelection(
        formattedAddress: _controller.addressController.text.trim(),
        state: _controller.stateController.text.trim(),
        city: _controller.cityController.text.trim(),
        pincode: _controller.pincodeController.text.trim(),
        latitude: selectedLatitude,
        longitude: selectedLongitude,
      );
    }

    final pickedLocation = await Get.to<AddressSelection>(
      () => ProfessionalLocationPickerScreen(
        initialCenterLatitude: _controller.mapCenterLatitude.value,
        initialCenterLongitude: _controller.mapCenterLongitude.value,
        initialSelection: initialSelection,
      ),
      fullscreenDialog: true,
    );

    if (pickedLocation == null) {
      return;
    }

    await _controller.applyAddressSelectionFromPicker(pickedLocation);
  }

  @override
  void dispose() {
    // Keep controller cleanup out of the widget tear-down frame.
    // Deleting immediately here can race with TextField transition work.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = HelperFunctions.isDarkMode(context);
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark
        ? const Color(0xff1E2939)
        : const Color(0xffD9D9D9);
    final bodyBg = isDark ? const Color(0xff0F1120) : Colors.white;
    final buttonBg = isDark ? Colors.white : const Color(0xff3E015E);
    final buttonText = isDark ? const Color(0xff3E015E) : Colors.white;

    return PopScope(
      canPop: !widget.forceCompletion,
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: textPrimary,
            selectionColor: const Color(0x665663D8),
            selectionHandleColor: textPrimary,
          ),
        ),
        child: Scaffold(
          backgroundColor: bodyBg,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveUtility.width(18),
                    ResponsiveUtility.height(12),
                    ResponsiveUtility.width(18),
                    ResponsiveUtility.height(10),
                  ),
                  child: Row(
                    children: [
                      if (!widget.forceCompletion)
                        InkWell(
                          onTap: Get.back,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: ResponsiveUtility.all(6),
                            child: Icon(Icons.arrow_back, color: textPrimary),
                          ),
                        ),
                      if (!widget.forceCompletion)
                        SizedBox(width: ResponsiveUtility.width(6)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.forceCompletion
                                  ? 'Complete Your Profile'
                                  : 'Edit Personal Information',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveUtility.fontSize(16),
                              ),
                            ),
                            Text(
                              widget.forceCompletion
                                  ? 'Complete required details to continue'
                                  : 'Update your personal information',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: ResponsiveUtility.fontSize(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: borderColor),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveUtility.width(16),
                      ResponsiveUtility.height(12),
                      ResponsiveUtility.width(16),
                      ResponsiveUtility.height(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Full Name', textPrimary),
                        _input(
                          _controller.fullNameController,
                          hint: 'Enter your full name',
                          icon: Icons.phone_outlined,
                          isDark: isDark,
                        ),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _label('GST Number (optional)', textPrimary),
                        _input(
                          _controller.gstNumberController,
                          hint: 'Enter customer GST number',
                          icon: Icons.receipt_long_outlined,
                          isDark: isDark,
                        ),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _label('Landmark / Direction Details', textPrimary),
                        _input(
                          _controller.landmarkController,
                          hint: 'Enter necessary details',
                          isDark: isDark,
                        ),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        _label('Permanent Address', textPrimary),
                        Obx(
                          () => LocationSearchField(
                            controller: _controller.addressController,
                            onChanged: _controller.onAddressSearchChanged,
                            onSuggestionTap:
                                _controller.selectAddressSuggestion,
                            suggestions: _controller.placeSuggestions,
                            isSearching: _controller.isSearchingPlaces.value,
                            onUseCurrentLocation:
                                _controller.useCurrentLocationForAddress,
                            isFetchingCurrentLocation:
                                _controller.isFetchingCurrentLocation.value,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        Obx(
                          () => AddressPreviewCard(
                            formattedAddress:
                                _controller.addressController.text,
                            city: _controller.cityController.text.trim(),
                            state: _controller.stateController.text.trim(),
                            country: _controller.selectedCountry.value,
                            pincode: _controller.pincodeController.text.trim(),
                            latitude: _controller.selectedLatitude.value,
                            longitude: _controller.selectedLongitude.value,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        Obx(
                          () => Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark
                                    ? Colors.black
                                    : Color(0xffD9D9D9),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: MapPickerWidget(
                              centerLatitude:
                                  _controller.mapCenterLatitude.value,
                              centerLongitude:
                                  _controller.mapCenterLongitude.value,
                              selectedLatitude:
                                  _controller.selectedLatitude.value,
                              selectedLongitude:
                                  _controller.selectedLongitude.value,
                              isResolvingAddress:
                                  _controller.isResolvingAddressFromMap.value,
                              onLocationChanged:
                                  (double latitude, double longitude) {
                                    return _controller.onMapLocationChanged(
                                      latitude: latitude,
                                      longitude: longitude,
                                    );
                                  },
                              onConfirmLocation:
                                  _controller.confirmSelectedLocation,
                              canConfirmLocation:
                                  _controller.hasSelectedLocation,
                              showMap: _controller.isMapApiConfigured,
                              fallbackMessage:
                                  "Google Maps API key is missing.\n"
                                  "Please set ApiConstants.googleMapsApiKey.",
                              onOpenExpandedMap: _controller.isMapApiConfigured
                                  ? _openLargeMapPicker
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtility.height(18)),
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: ResponsiveUtility.height(44),
                            child: ElevatedButton(
                              onPressed:
                                  _profileController.isSavingPersonalInfo.value
                                  ? null
                                  : _controller.onSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonBg,
                                foregroundColor: buttonText,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child:
                                  _profileController.isSavingPersonalInfo.value
                                  ? SizedBox(
                                      width: ResponsiveUtility.width(18),
                                      height: ResponsiveUtility.height(18),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: buttonText,
                                      ),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: ResponsiveUtility.fontSize(
                                          16,
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
        ),
      ),
    );
  }

  Widget _label(String text, Color textColor) {
    return Padding(
      padding: ResponsiveUtility.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveUtility.fontSize(16),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller, {
    required String hint,
    required bool isDark,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: false,
      enableSuggestions: true,
      autocorrect: true,
      cursorColor: isDark ? Colors.white : Colors.black,
      cursorErrorColor: isDark ? Colors.white : Colors.black,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(
        color: isDark ? const Color(0xFFF7F8FF) : Colors.black87,
        fontWeight: FontWeight.w500,
        fontSize: ResponsiveUtility.fontSize(12),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF9EA5D9) : Colors.black45,
          fontSize: ResponsiveUtility.fontSize(12),
        ),
        prefixIcon: icon == null
            ? null
            : Icon(
                icon,
                color: isDark ? const Color(0xFFB3BAF4) : Colors.black54,
                size: ResponsiveUtility.width(18),
              ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF211E56)
            : const Color(0xffF6F4FF).withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2C2F63) : const Color(0xffD9D9D9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF2C2F63) : const Color(0xffD9D9D9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF5663D8) : AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}

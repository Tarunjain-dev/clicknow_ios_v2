import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/screens/customer/profile/getx/customer_profile_controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:clicknow_version2/app/widgets/searchable_selection_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SavedAddressScreen extends StatelessWidget {
  const SavedAddressScreen({super.key});

  static const Map<String, List<String>> _stateCityOptions = {
    'Madhya Pradesh': <String>[
      'Indore',
      'Bhopal',
      'Jabalpur',
      'Ujjain',
      'Gwalior',
      'Sagar',
      'Rewa',
    ],
    'Maharashtra': <String>['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Thane'],
    'Gujarat': <String>['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot'],
    'Rajasthan': <String>['Jaipur', 'Udaipur', 'Jodhpur', 'Kota'],
    'Delhi': <String>['New Delhi', 'North Delhi', 'South Delhi', 'West Delhi'],
  };

  @override
  Widget build(BuildContext context) {
    /// -- scaling utility instance
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    /// -- Customer profile Controller
    final controller = CustomerProfileController.instance;

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  scale.getScaledWidth(10),
                  scale.getScaledHeight(10),
                  scale.getScaledWidth(12),
                  scale.getScaledHeight(8),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: Get.back,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.arrow_back,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(width: scale.getScaledWidth(6)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved address',
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveUtility.fontSize(18),
                            ),
                          ),
                          Text(
                            'Manage your delivery locations',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.black.withValues(alpha: 0.7),
                              fontSize: ResponsiveUtility.fontSize(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _showAddressEditor(
                        context,
                        scale,
                        controller,
                        isDark,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: scale.getScaledWidth(34),
                        height: scale.getScaledHeight(34),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Color(0xFF20334F) : Color(0xFFFCFBFF),
                          border: Border.all(
                            color: isDark
                                ? Color(0xFF2A5083)
                                : Color(0xFFD9D9D9),
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: isDark ? Color(0xFF54AEFF) : Color(0xFF043053),
                          size: scale.getScaledWidth(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: isDark ? Color(0xFF2A3363) : Color(0xFFD9D9D9),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isGuestUser.value) {
                    return _guestLockWidget(scale);
                  }
                  if (controller.isAddressLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD000FF),
                      ),
                    );
                  }
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      scale.getScaledWidth(12),
                      scale.getScaledHeight(10),
                      scale.getScaledWidth(12),
                      scale.getScaledHeight(10),
                    ),
                    children: [
                      if (controller.savedAddresses.isEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: scale.getScaledHeight(18),
                            horizontal: scale.getScaledWidth(12),
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Color(0xFF151233).withValues(alpha: 0.95)
                                : Color(0xFFFCFBFF).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Color(0xFF2A3363)
                                  : Color(0xFFD9D9D9),
                            ),
                          ),
                          child: Text(
                            'No saved address found. Tap + to add.',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.75)
                                  : Colors.black.withValues(alpha: 0.75),
                              fontSize: scale.getScaledFont(14),
                            ),
                          ),
                        ),
                      ...controller.savedAddresses.map(
                        (item) => Padding(
                          padding: EdgeInsets.only(
                            bottom: scale.getScaledHeight(8),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Color(0xFF151233).withValues(alpha: 0.95)
                                  : Color(0xFFFCFBFF).withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? Color(0xFF2A3363)
                                    : Color(0xFFD9D9D9),
                              ),
                            ),
                            padding: EdgeInsets.fromLTRB(
                              scale.getScaledWidth(10),
                              scale.getScaledHeight(10),
                              scale.getScaledWidth(10),
                              scale.getScaledHeight(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: scale.getScaledWidth(20),
                                  height: scale.getScaledHeight(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E315E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    color: const Color(0xFF4F86FF),
                                    size: scale.getScaledWidth(12),
                                  ),
                                ),
                                SizedBox(width: scale.getScaledWidth(8)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.black,
                                          fontWeight: FontWeight.w600,
                                          fontSize: scale.getScaledFont(16),
                                        ),
                                      ),
                                      SizedBox(
                                        height: scale.getScaledHeight(2),
                                      ),
                                      Text(
                                        _formattedAddress(item),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.65,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.65,
                                                ),
                                          fontSize: scale.getScaledFont(14),
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    _actionIcon(
                                      scale,
                                      icon: Icons.edit_outlined,
                                      color: const Color(0xFFFFB029),
                                      onTap: () => _showAddressEditor(
                                        context,
                                        scale,
                                        controller,
                                        isDark,
                                        item: item,
                                      ),
                                    ),
                                    SizedBox(width: scale.getScaledWidth(8)),
                                    _actionIcon(
                                      scale,
                                      icon: Icons.delete_outline,
                                      color: const Color(0xFFFF4A57),
                                      onTap: () => _confirmDelete(
                                        scale,
                                        onConfirm: () =>
                                            controller.removeAddress(item.id),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: scale.getScaledHeight(8)),
                      SizedBox(
                        width: double.infinity,
                        height: scale.getScaledHeight(44),
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: controller.isAddressSaving.value
                                ? null
                                : () {
                                    AppSnackbar.success(
                                      'Saved',
                                      'All address changes are synced.',
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white
                                  : AppColors.primaryColor,
                              foregroundColor: isDark
                                  ? Color(0xFF4B176F)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: controller.isAddressSaving.value
                                ? SizedBox(
                                    width: scale.getScaledWidth(18),
                                    height: scale.getScaledHeight(18),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isDark
                                          ? Color(0xFF4B176F)
                                          : Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: scale.getScaledFont(18),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guestLockWidget(ScalingUtility scale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(20)),
        child: Container(
          padding: EdgeInsets.all(scale.getScaledWidth(14)),
          decoration: BoxDecoration(
            color: const Color(0xFF151233).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A3363)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                color: const Color(0xFFD000FF),
                size: scale.getScaledWidth(28),
              ),
              SizedBox(height: scale.getScaledHeight(10)),
              Text(
                'Please login to continue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: scale.getScaledFont(16),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: scale.getScaledHeight(6)),
              Text(
                'Saved addresses are available only for logged-in users.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: scale.getScaledFont(13),
                ),
              ),
              SizedBox(height: scale.getScaledHeight(12)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    AuthController.instance.showLoginRequiredSheet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4B176F),
                  ),
                  child: const Text('Continue with Phone'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(
    ScalingUtility scale, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Icon(icon, color: color, size: scale.getScaledWidth(18)),
    );
  }

  String _formattedAddress(CustomerAddressItem item) {
    final extras = [
      if (item.city.isNotEmpty) item.city,
      if (item.state.isNotEmpty) item.state,
      if (item.pincode.isNotEmpty) item.pincode,
    ].join(', ');
    if (extras.isEmpty) {
      return item.address;
    }
    if (item.address.trim().isEmpty) {
      return extras;
    }
    return '${item.address}, $extras';
  }

  Future<void> _confirmDelete(
    ScalingUtility scale, {
    required Future<void> Function() onConfirm,
  }) async {
    await Get.dialog<void>(
      AlertDialog(
        backgroundColor: const Color(0xFF151233),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text(
          'Delete Address?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This saved address will be removed permanently.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              await onConfirm();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFFF4A57)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddressEditor(
    BuildContext context,
    ScalingUtility scale,
    CustomerProfileController controller,
    bool isDark, {
    CustomerAddressItem? item,
  }) async {
    if (controller.isGuestUser.value) {
      await AuthController.instance.showLoginRequiredSheet();
      return;
    }

    final titleController = TextEditingController(text: item?.title ?? '');
    final addressController = TextEditingController(text: item?.address ?? '');
    final stateController = TextEditingController(
      text: item?.state.isNotEmpty == true
          ? item!.state
          : controller.state.value,
    );
    final cityController = TextEditingController(
      text: item?.city.isNotEmpty == true ? item!.city : controller.city.value,
    );
    final pincodeController = TextEditingController(
      text: item?.pincode.isNotEmpty == true
          ? item!.pincode
          : controller.pincode.value,
    );
    var selectedState = stateController.text.trim();
    var selectedCity = cityController.text.trim();

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Container(
          padding: EdgeInsets.fromLTRB(
            scale.getScaledWidth(12),
            scale.getScaledHeight(12),
            scale.getScaledWidth(12),
            scale.getScaledHeight(12),
          ),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF161235) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item == null ? 'Add Address' : 'Edit Address',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveUtility.fontSize(18),
                    ),
                  ),
                  SizedBox(height: scale.getScaledHeight(10)),
                  TextField(
                    controller: titleController,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.black,
                    ),
                    decoration: _inputDecoration(
                      'Address title (Home, Office)',
                      isDark,
                    ),
                  ),
                  SizedBox(height: scale.getScaledHeight(8)),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.black,
                    ),
                    decoration: _inputDecoration('Enter full address', isDark),
                  ),
                  SizedBox(height: scale.getScaledHeight(8)),
                  InkWell(
                    onTap: () async {
                      final selected =
                          await SearchableSelectionBottomSheet.show(
                            context: sheetContext,
                            title: 'Select State',
                            options: _stateCityOptions.keys.toList(
                              growable: false,
                            ),
                            initialValue: selectedState,
                            searchHint: 'Search state',
                          );
                      if (selected == null) {
                        return;
                      }
                      selectedState = selected;
                      selectedCity = '';
                      stateController.text = selected;
                      cityController.clear();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: IgnorePointer(
                      child: TextField(
                        controller: stateController,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.black,
                        ),
                        decoration: _inputDecoration('State', isDark).copyWith(
                          suffixIcon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDark ? Color(0xFF9EA5D9) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: scale.getScaledHeight(8)),
                  InkWell(
                    onTap: () async {
                      final activeState = selectedState.isNotEmpty
                          ? selectedState
                          : stateController.text.trim();
                      if (activeState.isEmpty) {
                        AppSnackbar.error(
                          'State Required',
                          'Please select state first.',
                        );
                        return;
                      }
                      final cities =
                          _stateCityOptions[activeState] ?? const <String>[];
                      if (cities.isEmpty) {
                        AppSnackbar.error(
                          'Unavailable',
                          'No cities found for selected state.',
                        );
                        return;
                      }
                      final selected =
                          await SearchableSelectionBottomSheet.show(
                            context: sheetContext,
                            title: 'Select City',
                            options: cities,
                            initialValue: selectedCity,
                            searchHint: 'Search city',
                          );
                      if (selected == null) {
                        return;
                      }
                      selectedCity = selected;
                      cityController.text = selected;
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: IgnorePointer(
                      child: TextField(
                        controller: cityController,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.black,
                        ),
                        decoration: _inputDecoration('City', isDark).copyWith(
                          suffixIcon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF9EA5D9),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: scale.getScaledHeight(8)),
                  TextField(
                    controller: pincodeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : AppColors.black.withValues(alpha: 0.6),
                    ),
                    decoration: _inputDecoration('Pincode', isDark),
                  ),
                  SizedBox(height: scale.getScaledHeight(12)),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isAddressSaving.value
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                final address = addressController.text.trim();
                                final state = stateController.text.trim();
                                final city = cityController.text.trim();
                                final pincode = pincodeController.text.trim();

                                if (title.isEmpty ||
                                    address.isEmpty ||
                                    state.isEmpty ||
                                    city.isEmpty) {
                                  AppSnackbar.error(
                                    'Required',
                                    'Please fill all required fields.',
                                  );
                                  return;
                                }
                                if (!RegExp(r'^\d{6}$').hasMatch(pincode)) {
                                  AppSnackbar.error(
                                    'Required',
                                    'Please enter valid 6-digit pincode.',
                                  );
                                  return;
                                }

                                bool success;
                                if (item == null) {
                                  success = await controller.addAddress(
                                    title: title,
                                    address: address,
                                    state: state,
                                    city: city,
                                    pincode: pincode,
                                  );
                                } else {
                                  success = await controller.updateAddress(
                                    id: item.id,
                                    title: title,
                                    address: address,
                                    state: state,
                                    city: city,
                                    pincode: pincode,
                                  );
                                }
                                if (success && sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white
                              : AppColors.primaryColor,
                          foregroundColor: isDark
                              ? Color(0xFF4B176F)
                              : Colors.white,
                        ),
                        child: controller.isAddressSaving.value
                            ? SizedBox(
                                width: scale.getScaledWidth(16),
                                height: scale.getScaledHeight(16),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF4B176F),
                                ),
                              )
                            : Text(
                                item == null ? 'Add Address' : 'Update Address',
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      titleController.dispose();
      addressController.dispose();
      stateController.dispose();
      cityController.dispose();
      pincodeController.dispose();
    }
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: isDark ? Color(0xFF1D1B47) : Color(0xFFFCFBFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Color(0xFF2C2F63) : Color(0xFFD9D9D9),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Color(0xFF2C2F63) : Color(0xFFD9D9D9),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4F52A6)),
      ),
    );
  }
}

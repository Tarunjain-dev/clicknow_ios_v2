import 'package:clicknow_version2/app/screens/professional/professionalDashboard/profile/getx/professionalProfile_Controller.dart';
import 'package:clicknow_version2/app/screens/professional/professionalDashboard/profile/models/professional_profile_data.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:clicknow_version2/app/widgets/searchable_selection_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditProfessionalInformationScreen extends StatefulWidget {
  const EditProfessionalInformationScreen({super.key});

  @override
  State<EditProfessionalInformationScreen> createState() =>
      _EditProfessionalInformationScreenState();
}

class _EditProfessionalInformationScreenState
    extends State<EditProfessionalInformationScreen> {
  /// -- Professional profile controller instance
  final ProfessionalProfileController _controller =
      ProfessionalProfileController.instance;
  final TextEditingController _experienceController = TextEditingController();
  String _selectedTeamSize = '';
  List<String> _currentTeamSizeOptions = <String>[];

  /// -- State : { City } options
  static const Map<String, List<String>> _stateCityOptions = {
    'Madhya Pradesh': ['Indore', 'Bhopal', 'Jabalpur', 'Ujjain', 'Gwalior'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'West Delhi'],
  };

  /// -- working Days (7 Days)
  static const List<String> _workingDayOptions = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// -- Team Size Options
  static const List<String> _generalTeamSizeOptions = [
    '1-5 Members',
    '5-10 Members',
    '10-20 Members',
    '20+ Members',
  ];

  /// -- Music team side options
  static const List<String> _musicTeamSizeOptions = ['Solo', 'Duo', 'Band'];

  final Set<String> _selectedWorkingDays = <String>{};
  final Map<String, Set<String>> _workingLocationMap = <String, Set<String>>{};
  final Map<String, Set<String>> _travelLocationMap = <String, Set<String>>{};

  bool _workingExpanded = true;
  bool _travelExpanded = true;
  Worker? _profileWorker;

  @override
  void initState() {
    super.initState();
    _hydrateFromProfile(_controller.profile.value);
    _profileWorker = ever<ProfessionalProfileData>(
      _controller.profile,
      _hydrateFromProfile,
    );
  }

  @override
  void dispose() {
    _profileWorker?.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// -- Dark Mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling Utility instance
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              /// -- Header Section
              _header(scale, isDark),
              Expanded(
                child: ListView(
                  padding: ResponsiveUtility.only(
                    left: 14,
                    top: 12,
                    right: 14,
                    bottom: 16,
                  ),
                  children: [
                    _teamAndDaysCard(scale, isDark),
                    SizedBox(height: ResponsiveUtility.height(10)),
                    _locationsCard(
                      scale: scale,
                      title: 'Working Locations',
                      expanded: _workingExpanded,
                      onExpandToggle: () {
                        setState(() => _workingExpanded = !_workingExpanded);
                      },
                      data: _workingLocationMap,
                      editLabel: 'Edit Working Locations',
                      note:
                          'Note : These are the locations you are willingly wanted to work.',
                      onEdit: () => _openLocationDialog(
                        isTravel: false,
                        scale: scale,
                        isDark: isDark,
                      ), // TODO: Start from here.
                      isDark: isDark,
                    ),
                    SizedBox(height: scale.getScaledHeight(10)),
                    _locationsCard(
                      scale: scale,
                      title: 'Travel Preference Locations',
                      expanded: _travelExpanded,
                      onExpandToggle: () {
                        setState(() => _travelExpanded = !_travelExpanded);
                      },
                      data: _travelLocationMap,
                      editLabel: 'Edit Travel Preference',
                      note:
                          'Note : These are the locations where you are willing to travel.',
                      onEdit: () => _openLocationDialog(
                        isTravel: true,
                        scale: scale,
                        isDark: isDark,
                      ),
                      isDark: isDark,
                    ),
                    SizedBox(height: scale.getScaledHeight(20)),
                    Obx(
                      () => SizedBox(
                        height: scale.getScaledHeight(46),
                        child: ElevatedButton(
                          onPressed: _controller.isSavingProfessionalInfo.value
                              ? null
                              : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white
                                : AppColors.primaryColor,
                            foregroundColor: isDark
                                ? Color(0xff4A176F)
                                : Colors.white,
                            disabledBackgroundColor: Colors.white.withValues(
                              alpha: 0.42,
                            ),
                            disabledForegroundColor: const Color(
                              0xff4A176F,
                            ).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _controller.isSavingProfessionalInfo.value
                              ? SizedBox(
                                  height: scale.getScaledHeight(20),
                                  width: scale.getScaledWidth(20),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Color(0xff4A176F),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ScalingUtility scale, bool isDark) {
    return Container(
      padding: ResponsiveUtility.only(left: 8, top: 8, right: 12, bottom: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              'Edit Professional Information',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveUtility.fontSize(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamAndDaysCard(ScalingUtility scale, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xff17122F) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Color(0xff2C2750) : Color(0xffD9D9D9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(scale, 'Team & Working Days', isDark),
          Container(
            height: 1,
            color: isDark ? Color(0xff2C2750) : Color(0xffD9D9D9),
          ),
          Padding(
            padding: ResponsiveUtility.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(scale, 'Years of Experience', isDark),
                _textField(
                  scale: scale,
                  controller: _experienceController,
                  hint: 'Years of experience',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                ),
                SizedBox(height: ResponsiveUtility.height(8)),
                _label(scale, 'Team Size', isDark),
                _teamSizeDropdown(scale, isDark),
                SizedBox(height: scale.getScaledHeight(8)),
                _label(scale, 'Available Working Days', isDark),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(scale.getScaledWidth(8)),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Color(0xff1D1B47)
                        : Color(0xffF6F4FF).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Color(0xff2C2F63) : Color(0xffD9D9D9),
                    ),
                  ),
                  child: Wrap(
                    spacing: scale.getScaledWidth(7),
                    runSpacing: scale.getScaledHeight(7),
                    children: _workingDayOptions
                        .map((day) => _workingDayChip(scale, day, isDark))
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamSizeDropdown(ScalingUtility scale, bool isDark) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedTeamSize.isEmpty ? null : _selectedTeamSize,
      dropdownColor: isDark ? Color(0xff1A1435) : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: isDark ? Color(0xff878EB6) : Colors.black,
      ),
      decoration: InputDecoration(
        hintText: 'Select Team Size',
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.35),
          fontSize: ResponsiveUtility.fontSize(12),
        ),
        filled: true,
        fillColor: isDark
            ? Color(0xff211E56)
            : Color(0xffF6F4FF).withValues(alpha: 0.8),
        contentPadding: ResponsiveUtility.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Color(0xff2C2750) : Color(0xffD9D9D9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Color(0xff2C2750) : Color(0xffD9D9D9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Color(0xff2C2750) : Color(0xffD9D9D9),
          ),
        ),
      ),
      items: _currentTeamSizeOptions
          .map(
            (option) =>
                DropdownMenuItem<String>(value: option, child: Text(option)),
          )
          .toList(growable: false),
      onChanged: (value) {
        setState(() {
          _selectedTeamSize = value ?? '';
        });
      },
    );
  }

  Widget _workingDayChip(ScalingUtility scale, String day, bool isDark) {
    final selected = _selectedWorkingDays.contains(day);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedWorkingDays.remove(day);
          } else {
            _selectedWorkingDays.add(day);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: scale.getScaledWidth(10),
          vertical: scale.getScaledHeight(6),
        ),
        decoration: BoxDecoration(
          color: selected
              ? isDark
                    ? Color(0xffB629FF)
                    : Color(0xff9810FA)
              : isDark
              ? Color(0xff31374F)
              : Color(0xffEEEEEE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          day,
          style: TextStyle(
            color: selected
                ? Colors.white
                : isDark
                ? Colors.white
                : Colors.black.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
            fontSize: scale.getScaledFont(14),
          ),
        ),
      ),
    );
  }

  Widget _locationsCard({
    required ScalingUtility scale,
    required String title,
    required bool expanded,
    required VoidCallback onExpandToggle,
    required Map<String, Set<String>> data,
    required String editLabel,
    required String note,
    required VoidCallback onEdit,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Color(0xff1A1436)
            : Color(0xffF6F4FF).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onExpandToggle,
            child: Padding(
              padding: ResponsiveUtility.only(
                left: 12,
                top: 9,
                right: 8,
                bottom: 9,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveUtility.fontSize(16),
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Container(
              height: 1,
              color: isDark ? Color(0xff2C2750) : Color(0xffD9D9D9),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                scale.getScaledWidth(12),
                scale.getScaledHeight(8),
                scale.getScaledWidth(12),
                scale.getScaledHeight(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.isEmpty)
                    Text(
                      'No locations added yet.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.58)
                            : Colors.black.withValues(alpha: 0.58),
                        fontSize: scale.getScaledFont(13),
                      ),
                    )
                  else
                    ...data.entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          bottom: scale.getScaledHeight(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key} :',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: scale.getScaledFont(15),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            ...entry.value.map(
                              (city) => Text(
                                '  - $city.',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.78)
                                      : Colors.black.withValues(alpha: 0.78),
                                  fontSize: scale.getScaledFont(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: scale.getScaledHeight(8)),
                  SizedBox(
                    width: double.infinity,
                    height: scale.getScaledHeight(40),
                    child: ElevatedButton(
                      onPressed: onEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.white
                            : AppColors.primaryColor,
                        foregroundColor: isDark
                            ? Color(0xff4A176F)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        editLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: scale.getScaledFont(17),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: scale.getScaledHeight(8)),
                  Text(
                    note,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.48)
                          : Colors.black.withValues(alpha: 0.48),
                      fontSize: scale.getScaledFont(13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(ScalingUtility scale, String title, bool isDark) {
    return Padding(
      padding: ResponsiveUtility.only(left: 12, top: 10, right: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: ResponsiveUtility.fontSize(16),
        ),
      ),
    );
  }

  Widget _label(ScalingUtility scale, String title, bool isDark) {
    return Padding(
      padding: ResponsiveUtility.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
          fontSize: ResponsiveUtility.fontSize(14),
        ),
      ),
    );
  }

  Widget _textField({
    required ScalingUtility scale,
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: ResponsiveUtility.fontSize(14),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.35),
          fontSize: ResponsiveUtility.fontSize(14),
        ),
        filled: true,
        fillColor: isDark
            ? Color(0xff211E56)
            : Color(0xffF6F4FF).withValues(alpha: 0.8),
        contentPadding: ResponsiveUtility.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Color(0xff2C2F63) : Color(0xffD9D9D9),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Color(0xff2C2F63) : Color(0xffD9D9D9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Color(0xff2C2F63) : Color(0xffD9D9D9),
          ),
        ),
      ),
    );
  }

  Future<void> _openLocationDialog({
    required bool isTravel,
    required ScalingUtility scale,
    required bool isDark,
  }) async {
    final source = isTravel ? _travelLocationMap : _workingLocationMap;

    final temp = source.map(
      (state, cities) => MapEntry(state, Set<String>.from(cities)),
    );

    String selectedState = '';
    String selectedCity = '';
    var committed = false;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cities = _stateCityOptions[selectedState] ?? const <String>[];
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Color(0xff211A47) : Color(0xffFCFBFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        scale.getScaledWidth(12),
                        scale.getScaledHeight(10),
                        scale.getScaledWidth(8),
                        scale.getScaledHeight(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xffD000FF),
                            size: 17,
                          ),
                          SizedBox(width: scale.getScaledWidth(8)),
                          Expanded(
                            child: Text(
                              isTravel
                                  ? 'Travel Preference Locations'
                                  : 'Working Locations',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: ResponsiveUtility.fontSize(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 1,
                      color: isDark ? Color(0xff2C2750) : Color(0xffD9D9D9),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        scale.getScaledWidth(12),
                        scale.getScaledHeight(10),
                        scale.getScaledWidth(12),
                        scale.getScaledHeight(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(scale, 'Working State', isDark),
                          _selectorField(
                            scale: scale,
                            isDark: isDark,
                            hint: 'Select working state',
                            value: selectedState,
                            onTap: () async {
                              final selected =
                                  await SearchableSelectionBottomSheet.show(
                                    context: context,
                                    title: 'Select Working State',
                                    options: _stateCityOptions.keys.toList(
                                      growable: false,
                                    ),
                                    initialValue: selectedState,
                                    searchHint: 'Search state',
                                  );
                              if (selected == null) {
                                return;
                              }
                              setDialogState(() {
                                selectedState = selected;
                                selectedCity = '';
                              });
                            },
                          ),
                          SizedBox(height: scale.getScaledHeight(8)),
                          _label(scale, 'Working City', isDark),
                          _selectorField(
                            scale: scale,
                            isDark: isDark,
                            hint: 'Select working City',
                            value: selectedCity,
                            enabled: cities.isNotEmpty,
                            onTap: () async {
                              if (cities.isEmpty) {
                                return;
                              }
                              final selected =
                                  await SearchableSelectionBottomSheet.show(
                                    context: context,
                                    title: 'Select Working City',
                                    options: cities,
                                    initialValue: selectedCity,
                                    searchHint: 'Search city',
                                  );
                              if (selected == null) {
                                return;
                              }
                              setDialogState(() => selectedCity = selected);
                            },
                          ),
                          SizedBox(height: scale.getScaledHeight(12)),
                          Row(
                            children: [
                              Expanded(
                                child: _dialogButton(
                                  scale: scale,
                                  isDark: isDark,
                                  title: 'Save Location',
                                  onTap: () {
                                    if (_addLocation(
                                      target: temp,
                                      state: selectedState,
                                      city: selectedCity,
                                    )) {
                                      committed = true;
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: scale.getScaledWidth(8)),
                              Expanded(
                                child: _dialogButton(
                                  scale: scale,
                                  isDark: isDark,
                                  title: 'Add More',
                                  onTap: () {
                                    final added = _addLocation(
                                      target: temp,
                                      state: selectedState,
                                      city: selectedCity,
                                    );
                                    if (added) {
                                      setDialogState(() {
                                        selectedState = '';
                                        selectedCity = '';
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 1,
                      color: isDark ? Color(0xff2C2750) : Color(0xffD9D9D9),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        scale.getScaledWidth(12),
                        scale.getScaledHeight(10),
                        scale.getScaledWidth(12),
                        scale.getScaledHeight(8),
                      ),
                      child: Text(
                        isTravel
                            ? 'Selected Travel Preference Locations :'
                            : 'Selected Working Locations :',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.45)
                              : Colors.black.withValues(alpha: 0.45),
                          fontSize: ResponsiveUtility.fontSize(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        scale.getScaledWidth(12),
                        0,
                        scale.getScaledWidth(12),
                        scale.getScaledHeight(10),
                      ),
                      child: temp.isEmpty
                          ? Text(
                              'No locations selected yet.',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : Colors.black.withValues(alpha: 0.45),
                                fontSize: ResponsiveUtility.fontSize(12),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: temp.entries
                                  .map(
                                    (entry) => Text(
                                      '- ${entry.key} : ${entry.value.join(', ')}.',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.62,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.62,
                                              ),
                                        fontSize: ResponsiveUtility.fontSize(
                                          12,
                                        ),
                                        height: 1.4,
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (committed) {
      setState(() {
        source
          ..clear()
          ..addAll(temp);
      });
    }
  }

  Widget _selectorField({
    required ScalingUtility scale,
    required String hint,
    required String value,
    required bool isDark,
    required Future<void> Function() onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: scale.getScaledWidth(12),
          vertical: scale.getScaledHeight(12),
        ),
        decoration: BoxDecoration(
          color: isDark ? Color(0xff211E56) : Color(0xffFCFBFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Color(0xff2C2F63) : Color(0xffD9D9D9),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.trim().isEmpty ? hint : value.trim(),
                style: TextStyle(
                  color: value.trim().isEmpty
                      ? isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.35)
                      : isDark
                      ? Colors.white
                      : Colors.black,
                  fontSize: scale.getScaledFont(14),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xff878EB6)),
          ],
        ),
      ),
    );
  }

  Widget _dialogButton({
    required ScalingUtility scale,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return SizedBox(
      height: scale.getScaledHeight(40),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
          foregroundColor: isDark ? Color(0xff4A176F) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtility.fontSize(14),
          ),
        ),
      ),
    );
  }

  bool _addLocation({
    required Map<String, Set<String>> target,
    required String state,
    required String city,
  }) {
    if (state.trim().isEmpty || city.trim().isEmpty) {
      AppSnackbar.error('Required', 'Please select state and city.');
      return false;
    }
    final cities = target.putIfAbsent(state.trim(), () => <String>{});
    cities.add(city.trim());
    return true;
  }

  void _hydrateFromProfile(ProfessionalProfileData data) {
    _experienceController.text = data.experienceYears <= 0
        ? ''
        : data.experienceYears.toString();
    _currentTeamSizeOptions = _teamSizeOptionsForService(data.serviceType);
    if (data.teamSize.isNotEmpty &&
        !_currentTeamSizeOptions.contains(data.teamSize)) {
      _currentTeamSizeOptions = <String>[
        ..._currentTeamSizeOptions,
        data.teamSize,
      ];
    }
    _selectedTeamSize = data.teamSize;
    _selectedWorkingDays
      ..clear()
      ..addAll(data.workingDays);

    _workingLocationMap
      ..clear()
      ..addAll(_mapFromLocations(data.primaryLocations));
    _travelLocationMap
      ..clear()
      ..addAll(_mapFromLocations(data.secondaryLocations));
    if (mounted) {
      setState(() {});
    }
  }

  Map<String, Set<String>> _mapFromLocations(
    List<ProfessionalWorkingLocation> locations,
  ) {
    final map = <String, Set<String>>{};
    for (final location in locations) {
      map[location.state] = location.cities.toSet();
    }
    return map;
  }

  Future<void> _saveChanges() async {
    final experienceYears =
        int.tryParse(_experienceController.text.trim()) ?? 0;
    final workingLocations = _locationsFromMap(_workingLocationMap);
    final travelLocations = _locationsFromMap(_travelLocationMap);
    await _controller.updateProfessionalInformation(
      experienceYears: experienceYears,
      teamSize: _selectedTeamSize,
      workingDays: _selectedWorkingDays.toList(growable: false),
      workingLocations: workingLocations,
      travelPreferenceLocations: travelLocations,
    );
  }

  List<ProfessionalWorkingLocation> _locationsFromMap(
    Map<String, Set<String>> source,
  ) {
    return source.entries
        .map(
          (entry) => ProfessionalWorkingLocation(
            state: entry.key.trim(),
            cities: entry.value.toList(growable: false),
          ).normalized(),
        )
        .where(
          (location) => location.state.isNotEmpty && location.cities.isNotEmpty,
        )
        .toList(growable: false);
  }

  List<String> _teamSizeOptionsForService(String serviceType) {
    if (serviceType.trim().isEmpty) {
      return List<String>.from(<String>[
        ..._generalTeamSizeOptions,
        ..._musicTeamSizeOptions,
      ]);
    }
    if (_isMusicService(serviceType)) {
      return List<String>.from(_musicTeamSizeOptions);
    }
    return List<String>.from(_generalTeamSizeOptions);
  }

  bool _isMusicService(String value) {
    return value.toLowerCase().trim().contains('music');
  }
}

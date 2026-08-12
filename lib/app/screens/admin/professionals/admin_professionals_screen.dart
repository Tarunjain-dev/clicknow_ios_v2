import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/admin/professionals/getx/admin_professionals_controller.dart';
import 'package:clicknow_version2/app/screens/admin/professionals/models/admin_professional_profile.dart';
import 'package:clicknow_version2/app/screens/admin/professionals/professional_review_details_screen.dart';
import 'package:clicknow_version2/app/screens/admin/widgets/admin_drawer.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:clicknow_version2/app/widgets/searchable_selection_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminProfessionalsScreen extends StatefulWidget {
  const AdminProfessionalsScreen({super.key});

  @override
  State<AdminProfessionalsScreen> createState() => _AdminProfessionalsScreenState();
}

class _AdminProfessionalsScreenState extends State<AdminProfessionalsScreen> {
  late final AdminProfessionalsController controller;
  late final TextEditingController searchController;
  bool showSearchBar = false;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminProfessionalsController>() ? Get.find<AdminProfessionalsController>() : Get.put(AdminProfessionalsController());
    final initialQuery = controller.searchQuery.value;
    showSearchBar = initialQuery.isNotEmpty;
    searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AdminDrawer(
          scale: scale,
          activeRoute: AppRoutes.adminProfessionalsRoute,
        ),
        body: Obx(
          () => RefreshIndicator(
            onRefresh: () => controller.refreshProfessionals(showMessage: true),
            child: Column(
              children: [
                /// -- App Bar
                _header(scale),
        
                /// -- Body
                Expanded(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: ResponsiveUtility.only(left: 14, top: 10, bottom: 16, right: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _overviewTitle(scale),
                            SizedBox(height: ResponsiveUtility.height(10)),
                            _overviewCards(scale),
                            SizedBox(height: ResponsiveUtility.height(16)),
                            _listHeader(scale),
                            SizedBox(height: ResponsiveUtility.height(10)),
                            if (controller.isLoading.value && controller.filteredProfessionals.isEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: scale.getScaledHeight(36),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (controller.filteredProfessionals.isEmpty)
                              _emptyState(scale)
                            else
                              ...controller.filteredProfessionals.map(
                                (profile) => _professionalCard(profile, scale),
                              ),
                          ],
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
    );
  }

  Widget _header(ScalingUtility scale) {
    return Container(
      padding: ResponsiveUtility.only(left: 10, top: 60, right: 12, bottom: showSearchBar ? 12 : 10),
      color: Color(0xff6F18A8),
      child: Column(
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  splashRadius: 22,
                  icon: Icon(Icons.menu_rounded, color: Colors.white, size: ResponsiveUtility.height(28),),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Professionals", style: TextStyle(color: Colors.white, fontSize: ResponsiveUtility.fontSize(18), fontWeight: FontWeight.w700,),),
                    Text("Manage & Approve Professional Services", style: TextStyle(color: Colors.white.withValues(alpha: 0.56), fontSize: ResponsiveUtility.fontSize(12),),),
                  ],
                ),
              ),
              if (!showSearchBar)
                _topActionButton(
                  scale: scale,
                  icon: Icons.search_rounded,
                  onTap: () {
                    setState(() => showSearchBar = true);
                  },
                ),
              if (!showSearchBar) SizedBox(width: scale.getScaledWidth(8)),
              _topActionButton(
                scale: scale,
                icon: Icons.tune_rounded,
                onTap: () => _openFilterBottomSheet(context),
                badgeValue: controller.activeFilterCount > 0 ? '${controller.activeFilterCount}' : null,
              ),
            ],
          ),
          if (showSearchBar) SizedBox(height: ResponsiveUtility.height(10)),
          if (showSearchBar)
            Padding(
              padding: ResponsiveUtility.symmetric(horizontal: 6),
              child: TextField(
                controller: searchController,
                onChanged: controller.updateSearchQuery,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search professionals by name or their IDs.",
                  hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.black.withValues(alpha: 0.6),),
                  suffixIcon: IconButton(
                    onPressed: () {
                      searchController.clear();
                      controller.updateSearchQuery('');
                      setState(() => showSearchBar = false);
                    },
                    icon: Icon(Icons.close_rounded, color: Colors.black.withValues(alpha: 0.6),),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xffD9D9D9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xffD9D9D9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xffD9D9D9)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _topActionButton({
    required ScalingUtility scale,
    required IconData icon,
    required VoidCallback onTap,
    String? badgeValue,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: scale.getScaledHeight(42),
            width: scale.getScaledWidth(42),
            decoration: const BoxDecoration(
              color: Color(0xffECEFF3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xff1D1D26),
              size: scale.getScaledWidth(24),
            ),
          ),
        ),
        if (badgeValue != null)
          Positioned(
            right: -2,
            top: -4,
            child: Container(
              height: scale.getScaledHeight(16),
              width: scale.getScaledWidth(16),
              decoration: BoxDecoration(
                color: const Color(0xff6C3DFF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.1),
              ),
              child: Center(
                child: Text(
                  badgeValue,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtility.fontSize(8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _overviewTitle(ScalingUtility scale) {
    return Text(
      "Professional Overview",
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: ResponsiveUtility.fontSize(14),
      ),
    );
  }

  Widget _overviewCards(ScalingUtility scale) {
    final selected = controller.selectedBucket.value;
    final waitConfig = _bucketConfig(AdminProfessionalBucket.waiting);
    final onlineConfig = _bucketConfig(AdminProfessionalBucket.online);
    final workingConfig = _bucketConfig(AdminProfessionalBucket.working);
    final verifiedConfig = _bucketConfig(AdminProfessionalBucket.verified);
    final suspendedConfig = _bucketConfig(AdminProfessionalBucket.suspended);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _overviewCard(
                title: "Waiting for admin approval",
                count: controller.countForBucket(AdminProfessionalBucket.waiting,),
                config: waitConfig,
                isSelected: selected == AdminProfessionalBucket.waiting,
                onTap: () => controller.selectBucket(AdminProfessionalBucket.waiting),
                scale: scale,
              ),
            ),
            SizedBox(width: ResponsiveUtility.width(10)),
            Expanded(
              child: _overviewCard(
                title: "Active for Booking Allotment",
                count: controller.countForBucket(AdminProfessionalBucket.online,),
                config: onlineConfig,
                isSelected: selected == AdminProfessionalBucket.online,
                onTap: () => controller.selectBucket(AdminProfessionalBucket.online),
                scale: scale,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtility.height(10)),
        Row(
          children: [
            Expanded(
              child: _overviewCard(
                title: "Professionals working on Ground",
                count: controller.countForBucket(AdminProfessionalBucket.working,),
                config: workingConfig,
                isSelected: selected == AdminProfessionalBucket.working,
                onTap: () => controller.selectBucket(AdminProfessionalBucket.working),
                scale: scale,
              ),
            ),
            SizedBox(width: ResponsiveUtility.width(10)),
            Expanded(
              child: _overviewCard(
                title: "Total Verified Professionals",
                count: controller.countForBucket(AdminProfessionalBucket.verified,),
                config: verifiedConfig,
                isSelected: selected == AdminProfessionalBucket.verified,
                onTap: () => controller.selectBucket(AdminProfessionalBucket.verified),
                scale: scale,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtility.height(10)),
        _overviewCard(
          title: "Suspended / Blocked",
          count: controller.countForBucket(AdminProfessionalBucket.suspended),
          config: suspendedConfig,
          isSelected: selected == AdminProfessionalBucket.suspended,
          onTap: () => controller.selectBucket(AdminProfessionalBucket.suspended),
          scale: scale,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _overviewCard({
    required String title,
    required int count,
    required _BucketUiConfig config,
    required bool isSelected,
    required VoidCallback onTap,
    required ScalingUtility scale,
    bool fullWidth = false,
  }) {
    final borderColor = isSelected ? config.accentColor : const Color(0xffD9D9D9);
    final titleColor = isSelected ? config.accentColor : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: scale.getScaledHeight(78),
        padding: ResponsiveUtility.only(left: 8, top: 7, right: 10, bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xffF6F4FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: ResponsiveUtility.height(24),
                  width: ResponsiveUtility.width(24),
                  decoration: BoxDecoration(
                    color: config.iconColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 15),
                ),
                SizedBox(width: ResponsiveUtility.width(8)),
                Expanded(
                  child: Text(
                    title,
                    maxLines: fullWidth ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: fullWidth ? TextAlign.start : TextAlign.right,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: scale.getScaledFont(12),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      height: 1.22,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "$count",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: ResponsiveUtility.fontSize(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listHeader(ScalingUtility scale) {
    return Text(
      _listTitleForBucket(controller.selectedBucket.value),
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: ResponsiveUtility.fontSize(14),
      ),
    );
  }

  Widget _emptyState(ScalingUtility scale) {
    return Container(
      padding: ResponsiveUtility.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF6F4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Text(
        "No professionals found for current filters.",
        style: TextStyle(
          color: Colors.black,
          fontSize: ResponsiveUtility.fontSize(12),
        ),
      ),
    );
  }

  Widget _professionalCard(AdminProfessionalProfile profile, ScalingUtility scale,){
    final statusStyle = _statusStyleForProfile(profile);
    return GestureDetector(
      onTap: () => Get.to(() => ProfessionalReviewDetailsScreen(professionalId: profile.uid),),
      child: Container(
        margin: EdgeInsets.only(bottom: scale.getScaledHeight(10)),
        decoration: BoxDecoration(
          color: const Color(0xffF6F4FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xffD9D9D9)),
        ),
        child: Column(
          children: [
            Padding(
              padding: ResponsiveUtility.only(left: 10, top: 8, right: 10, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          profile.fullName,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveUtility.fontSize(14),
                          ),
                        ),
                      ),
                      Container(
                        padding: ResponsiveUtility.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusStyle.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusStyle.color.withValues(alpha: 0.58),
                          ),
                        ),
                        child: Text(
                          statusStyle.label,
                          style: TextStyle(
                            color: statusStyle.color,
                            fontSize: ResponsiveUtility.fontSize(10),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtility.height(2)),
                  _infoLine("ID: ${_displayProfessionalId(profile.uid)}", scale,),
                  _infoLine("Services : ${_serviceSummary(profile)}", scale),
                  _infoLine("Experience : ${_experienceLabel(profile.experienceYears)}", scale,),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xffD9D9D9)),
            Padding(
              padding: ResponsiveUtility.only(left: 12, top: 6, right: 12, bottom: 6),
              child: Row(
                children: [
                  Text(
                    "See Details",
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.88),
                      fontSize: ResponsiveUtility.fontSize(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.black,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String value, ScalingUtility scale) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.black.withValues(alpha: 0.76),
        fontSize: ResponsiveUtility.fontSize(12),
        height: 1.33,
      ),
    );
  }

  String _listTitleForBucket(AdminProfessionalBucket bucket) {
    switch (bucket) {
      case AdminProfessionalBucket.waiting:
        return "Professional waiting for admin approval";
      case AdminProfessionalBucket.online:
        return "Professional active for booking allotment";
      case AdminProfessionalBucket.working:
        return "Professional working on ground";
      case AdminProfessionalBucket.verified:
        return "Total Verified Professionals";
      case AdminProfessionalBucket.suspended:
        return "Suspended / Blocked Professionals";
    }
  }

  _BucketUiConfig _bucketConfig(AdminProfessionalBucket bucket) {
    switch (bucket) {
      case AdminProfessionalBucket.waiting:
        return const _BucketUiConfig(
          accentColor: Color(0xffFFB300),
          iconColor: Color(0xffFF8A00),
        );
      case AdminProfessionalBucket.online:
        return const _BucketUiConfig(
          accentColor: Color(0xff5D5CFF),
          iconColor: Color(0xff4B45FF),
        );
      case AdminProfessionalBucket.working:
        return const _BucketUiConfig(
          accentColor: Color(0xffB533FF),
          iconColor: Color(0xffA71CFF),
        );
      case AdminProfessionalBucket.verified:
        return const _BucketUiConfig(
          accentColor: Color(0xff0CDB6D),
          iconColor: Color(0xff16CF63),
        );
      case AdminProfessionalBucket.suspended:
        return const _BucketUiConfig(
          accentColor: Color(0xffFF001A),
          iconColor: Color(0xffF30000),
        );
    }
  }

  _StatusUiStyle _statusStyleForBucket(AdminProfessionalBucket bucket) {
    final config = _bucketConfig(bucket);
    switch (bucket) {
      case AdminProfessionalBucket.waiting:
        return _StatusUiStyle(label: "Pending", color: config.accentColor);
      case AdminProfessionalBucket.online:
        return _StatusUiStyle(label: "Online", color: config.accentColor);
      case AdminProfessionalBucket.working:
        return _StatusUiStyle(label: "Working", color: config.accentColor);
      case AdminProfessionalBucket.verified:
        return _StatusUiStyle(label: "Verified", color: config.accentColor);
      case AdminProfessionalBucket.suspended:
        return _StatusUiStyle(label: "Suspended", color: config.accentColor);
    }
  }

  _StatusUiStyle _statusStyleForProfile(AdminProfessionalProfile profile) {
    switch (profile.accountStatus) {
      case 'BLOCKED':
        return const _StatusUiStyle(label: "Blocked", color: Color(0xffFF001A));
      case 'SUSPENDED':
        return const _StatusUiStyle(
          label: "Suspended",
          color: Color(0xffFF8A00),
        );
    }
    return _statusStyleForBucket(controller.selectedBucket.value);
  }

  String _displayProfessionalId(String uid) {
    final cleaned = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (cleaned.isEmpty) return "PR000000";
    final suffix = cleaned.length > 6
        ? cleaned.substring(cleaned.length - 6)
        : cleaned.padLeft(6, '0');
    return "PR$suffix";
  }

  String _serviceSummary(AdminProfessionalProfile profile) {
    return _shortServiceName(profile.serviceType);
  }

  String _shortServiceName(String service) {
    final value = service.trim();
    if (value.isEmpty) return "-";
    final lower = value.toLowerCase();
    if (lower.contains('photo')) return "Photo & Videography";
    if (lower.contains('music')) return "Music & Live Performance";
    if (lower.contains('anchor')) return "Professional Anchor Services";
    if (lower.contains('dj')) return "Professional DJ Services";
    if (lower.contains('magician')) return "Professional Magician Services";
    if (lower.contains('wedding')) return "Wedding Planner Services";
    return value;
  }

  String _experienceLabel(int years) {
    if (years <= 0) return "-";
    return "$years years";
  }

  String _addressSummary(AdminProfessionalProfile profile) {
    final city = profile.city.trim();
    final state = profile.state.trim();
    final pincode = profile.pincode.trim();
    final segments = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (pincode.isNotEmpty) pincode,
    ];
    if (segments.isEmpty) return "-";
    return segments.join(", ");
  }

  Future<void> _openFilterBottomSheet(BuildContext context) async {
    String service = controller.serviceFilter.value ?? '';
    String state = controller.stateFilter.value ?? '';
    String city = controller.cityFilter.value ?? '';
    String pincode = controller.pincodeFilter.value ?? '';
    AdminProfessionalBucket statusBucket = controller.selectedBucket.value;
    final pincodeController = TextEditingController(text: pincode);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cities = controller.availableCities(forState: state);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: ResponsiveUtility.height(6)),
                  Container(
                    height: ResponsiveUtility.height(2),
                    width: ResponsiveUtility.width(84),
                    decoration: BoxDecoration(color: const Color(0xffD9D9D9), borderRadius: BorderRadius.circular(10),),
                  ),
                  SizedBox(height: ResponsiveUtility.height(22)),
                  Container(
                    margin: ResponsiveUtility.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Color(0xffF6F4FF).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xffD9D9D9)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: ResponsiveUtility.only(left: 14, top: 12, bottom: 10, right: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text("Filter Customers by:", style: TextStyle(color: Colors.black, fontSize: ResponsiveUtility.fontSize(14), fontWeight: FontWeight.w700,),),
                              ),
                              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.black,),),
                            ],
                          ),
                        ),
                        Container(height: ResponsiveUtility.height(1), color: Color(0xffD9D9D9)),
                        Padding(
                          padding: ResponsiveUtility.only(left: 14, top: 10, bottom: 14, right: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sheetLabel("Services"),
                              SizedBox(height: ResponsiveUtility.height(6)),
                              _sheetDropdown(
                                value: service,
                                hint: "Select Services",
                                options: ['', ...controller.serviceTypeOptions],
                                onChanged: (value) {
                                  setSheetState(() => service = value ?? '');
                                },
                              ),
                              SizedBox(height: ResponsiveUtility.height(10)),
                              _sheetLabel("Status"),
                              SizedBox(height: ResponsiveUtility.height(6)),
                              _sheetDropdown(
                                value: statusBucket.code,
                                hint: "Select Status",
                                options: [
                                  AdminProfessionalBucket.waiting.code,
                                  AdminProfessionalBucket.online.code,
                                  AdminProfessionalBucket.working.code,
                                  AdminProfessionalBucket.verified.code,
                                  AdminProfessionalBucket.suspended.code,
                                ],
                                displayMapper: (value) {
                                  switch (value) {
                                    case 'waiting':
                                      return 'Waiting';
                                    case 'online':
                                      return 'Active';
                                    case 'working':
                                      return 'Working';
                                    case 'verified':
                                      return 'Verified';
                                    case 'suspended':
                                      return 'Suspended';
                                    default:
                                      return value;
                                  }
                                },
                                onChanged: (value) {
                                  setSheetState(() {
                                    statusBucket = AdminProfessionalBucket
                                        .values
                                        .firstWhere(
                                          (bucket) => bucket.code == value,
                                          orElse: () =>
                                              AdminProfessionalBucket.waiting,
                                        );
                                  });
                                },
                              ),
                              SizedBox(height: ResponsiveUtility.height(10)),
                              _sheetLabel("State"),
                              SizedBox(height: ResponsiveUtility.height(6)),
                              _sheetSelectorField(
                                value: state,
                                hint: "Select State",
                                onTap: () async {
                                  final selected = await SearchableSelectionBottomSheet.show(
                                    context: context,
                                    title: 'Select State',
                                    options: controller.availableStates,
                                    initialValue: state,
                                    searchHint: 'Search state',
                                  );
                                  if (selected == null) {
                                    return;
                                  }
                                  setSheetState(() {
                                    state = selected;
                                    city = '';
                                  });
                                },
                              ),
                              SizedBox(height: ResponsiveUtility.height(10)),
                              _sheetLabel("City"),
                              SizedBox(height: ResponsiveUtility.height(6)),
                              _sheetSelectorField(
                                value: city,
                                hint: "Select City",
                                enabled: state.trim().isNotEmpty && cities.isNotEmpty,
                                onTap: () async {
                                  if (state.trim().isEmpty || cities.isEmpty) {
                                    return;
                                  }
                                  final selected = await SearchableSelectionBottomSheet.show(
                                    context: context,
                                    title: 'Select City',
                                    options: cities,
                                    initialValue: city,
                                    searchHint: 'Search city',
                                  );
                                  if (selected == null) {
                                    return;
                                  }
                                  setSheetState(() => city = selected);
                                },
                              ),
                              SizedBox(height: ResponsiveUtility.height(10)),
                              _sheetLabel("PINCODE"),
                              SizedBox(height: ResponsiveUtility.height(6)),
                              TextField(
                                controller: pincodeController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                onChanged: (value) => pincode = value.trim(),
                                decoration: _sheetFieldDecoration(
                                  "Enter PINCODE",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtility.height(16)),
                  Padding(
                    padding: ResponsiveUtility.symmetric(horizontal: 28),
                    child: Row(
                      children: [
                        Expanded(
                          child: _sheetActionButton(
                            title: "Apply Filters",
                            onTap: () {
                              controller.selectBucket(
                                statusBucket,
                                fromFilterSheet: true,
                              );
                              controller.applyFilter(
                                serviceType: service,
                                state: state,
                                city: city,
                                pincode: pincode,
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        SizedBox(width: ResponsiveUtility.width(14)),
                        Expanded(
                          child: _sheetActionButton(
                            title: "Clear",
                            onTap: () {
                              controller.clearFilters();
                              controller.selectBucket(
                                AdminProfessionalBucket.waiting,
                              );
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    pincodeController.dispose();
  }

  Widget _sheetLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.black,
        fontSize: ResponsiveUtility.fontSize(14),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _sheetDropdown({
    required String value,
    required String hint,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    String Function(String)? displayMapper,
  }) {
    final current = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<String>(
      initialValue: current,
      dropdownColor: Colors.white,
      style: TextStyle(color: Colors.black),
      decoration: _sheetFieldDecoration(hint),
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.black),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(
                option.isEmpty ? hint : (displayMapper?.call(option) ?? option),
                style: TextStyle(
                  color: option.isEmpty
                      ? const Color(0xff636B90)
                      : Colors.black.withValues(alpha: 0.92),
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _sheetSelectorField({
    required String value,
    required String hint,
    required Future<void> Function() onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xffF6F4FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xffD9D9D9)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.trim().isEmpty ? hint : value.trim(),
                style: TextStyle(
                  color: value.trim().isEmpty
                      ? const Color(0xff636B90)
                      : Colors.black.withValues(alpha: 0.92),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          ],
        ),
      ),
    );
  }

  InputDecoration _sheetFieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Color(0xffD9D9D9)),
      filled: true,
      fillColor: const Color(0xffF6F4FF),
      contentPadding: ResponsiveUtility.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xffD9D9D9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color:Color(0xffD9D9D9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
    );
  }

  Widget _sheetActionButton({required String title, required VoidCallback onTap,}){
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff42155E),
        foregroundColor: const Color(0xffECECEF),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: ResponsiveUtility.symmetric(vertical: 14),
      ),
      child: Text(title, style: TextStyle(fontSize: ResponsiveUtility.fontSize(14), fontWeight: FontWeight.w700,),),
    );
  }
}

class _BucketUiConfig {
  const _BucketUiConfig({required this.accentColor, required this.iconColor});

  final Color accentColor;
  final Color iconColor;
}

class _StatusUiStyle {
  const _StatusUiStyle({required this.label, required this.color});

  final String label;
  final Color color;
}

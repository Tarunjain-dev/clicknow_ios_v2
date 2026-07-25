import 'dart:async';
import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/screens/customer/getx/customer_booking_controller.dart';
import 'package:clicknow_version2/app/screens/customer/home/customer_bookings_screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/professional_location_picker_screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/widgets/address_preview_card.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/widgets/location_search_field.dart';
import 'package:clicknow_version2/app/screens/professional/professionalRegistration/widgets/map_picker_widget.dart';
import 'package:clicknow_version2/app/services/location_service.dart';
import 'package:clicknow_version2/app/services/maps_service.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:clicknow_version2/app/widgets/searchable_selection_bottom_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CustomerServiceDetailScreen extends StatefulWidget {
  const CustomerServiceDetailScreen({
    super.key,
    required this.config,
    this.initialBookingItem,
    this.editingMode,
    this.editingIndex,
  });

  final CustomerServiceDetailConfig config;
  final CustomerBookingItem? initialBookingItem;
  final CustomerBookingViewMode? editingMode;
  final int? editingIndex;

  @override
  State<CustomerServiceDetailScreen> createState() => _CustomerServiceDetailScreenState();
}

class _CustomerServiceDetailScreenState
    extends State<CustomerServiceDetailScreen> {
  static const double _fixedGstPercent = 18.0;
  static const double _defaultIndiaLatitude = 22.9734;
  static const double _defaultIndiaLongitude = 78.6569;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CustomerBookingController _bookingController =
      CustomerBookingController.instance;
  final MapsService _mapsService = MapsService.instance;
  final LocationService _locationService = LocationService.instance;

  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _eventTimeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(
    text: '1',
  );
  final TextEditingController _guestController = TextEditingController();
  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _venueHouseDetailsController =
      TextEditingController();
  final TextEditingController _venueLandmarkController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  String _country = '';
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _onsiteContactNameController =
      TextEditingController();
  final TextEditingController _onsiteContactPhoneController =
      TextEditingController();

  late int _selectedPlanIndex;
  late String _selectedFallbackEventType;
  String? _selectedEventTypeId;
  DateTime? _selectedEventDate;
  TimeOfDay? _selectedEventTime;
  double _gstPercent = 18.0;
  bool _isCatalogLoading = true;
  bool _isAddingToCart = false;
  bool _isEventDetailsExpanded = true;
  bool _isLocationDetailsExpanded = true;
  bool _isPlanSelectionExpanded = true;
  bool _isAdditionalPreferenceExpanded = true;
  bool _isContactDetailsExpanded = true;
  int _requirementLength = 0;
  bool _isSearchingPlaces = false;
  bool _isResolvingAddressFromMap = false;
  bool _isFetchingCurrentLocation = false;
  double _mapCenterLatitude = _defaultIndiaLatitude;
  double _mapCenterLongitude = _defaultIndiaLongitude;
  double? _selectedLatitude;
  double? _selectedLongitude;
  List<PlaceSuggestion> _placeSuggestions = const <PlaceSuggestion>[];
  List<_CustomerCatalogEventType> _catalogEvents = const [];
  Timer? _placeSearchDebounceTimer;
  int _placeSearchRequestId = 0;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _gstSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventSub;

  @override
  void initState() {
    super.initState();
    _selectedPlanIndex = 0;
    _selectedFallbackEventType =
        widget.config.eventTypes[widget.config.initialSelectedEventTypeIndex];
    _requirementsController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() => _requirementLength = _requirementsController.text.length);
    });
    _prefillFromInitialBooking();
    _listenCatalog();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEventLocation();
    });
  }

  void _prefillFromInitialBooking() {
    final item = widget.initialBookingItem;
    if (item == null) {
      return;
    }
    _selectedEventDate = item.eventDate;
    _eventDateController.text = item.eventDate == null
        ? ''
        : _formatDate(item.eventDate!);
    _eventTimeController.text = item.eventTime;
    final initialDuration = int.tryParse(item.eventDurationHours.trim()) ?? 1;
    _durationController.text = initialDuration.clamp(1, 10).toString();
    _guestController.text = item.guestCount;
    _venueNameController.text = item.venueName;
    _venueHouseDetailsController.text = item.venueHouseDetails;
    _venueLandmarkController.text = item.venueLandmarkDetails;
    _addressController.text = item.fullAddress;
    _stateController.text = item.state;
    _cityController.text = item.city;
    _pincodeController.text = item.pincode;
    _requirementsController.text = item.specialRequirements;
    _onsiteContactNameController.text = item.onsiteContactName;
    _onsiteContactPhoneController.text = item.onsiteContactPhone;
    _selectedLatitude = item.latitude;
    _selectedLongitude = item.longitude;
    _mapCenterLatitude = item.latitude;
    _mapCenterLongitude = item.longitude;
    _selectedEventTypeId = item.eventTypeId.trim().isEmpty
        ? null
        : item.eventTypeId;
    _selectedFallbackEventType = item.eventTypeName;
  }

  bool get _hasSelectedEventLocation =>
      _selectedLatitude != null &&
      _selectedLongitude != null &&
      _addressController.text.trim().isNotEmpty;

  int get _durationHours =>
      widget.config.usesEventDuration
          ? (int.tryParse(_durationController.text.trim()) ?? 1).clamp(1, 10)
          : 1;

  void _changeDuration(int delta) {
    final next = (_durationHours + delta).clamp(1, 10);
    if (next == _durationHours) return;
    setState(() => _durationController.text = next.toString());
  }

  void _normalizeDuration(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      setState(() {});
      return;
    }
    final bounded = parsed.clamp(1, 10);
    if (bounded != parsed) {
      _durationController.text = bounded.toString();
      _durationController.selection = TextSelection.collapsed(
        offset: _durationController.text.length,
      );
    }
    setState(() {});
  }

  void _listenCatalog() {
    _gstSub = _db
        .collection(ServiceCatalogPaths.appSettingsCollection)
        .doc(ServiceCatalogPaths.serviceSettingsDoc)
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          final data = snapshot.data() ?? <String, dynamic>{};
          final next = _asDouble(data['gstPercent'], fallback: 18.0);
          setState(() {
            _gstPercent = next;
          });
        });

    _eventSub = _db
        .collection(ServiceCatalogPaths.servicesCollection)
        .doc(widget.config.catalogServiceId)
        .collection(ServiceCatalogPaths.eventTypesSubcollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            final events =
                snapshot.docs
                    .map(_catalogEventFromDoc)
                    .where((event) => event.name.trim().isNotEmpty)
                    .toList(growable: false)
                  ..sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );

            setState(() {
              _catalogEvents = events;
              _isCatalogLoading = false;
              _syncSelectedEventAfterCatalogChange();
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _isCatalogLoading = false;
            });
          },
        );
  }

  void _syncSelectedEventAfterCatalogChange() {
    if (_catalogEvents.isEmpty) {
      return;
    }
    if (_selectedEventTypeId != null &&
        _catalogEvents.any((event) => event.id == _selectedEventTypeId)) {
      return;
    }

    final preferredName = _selectedFallbackEventType.toLowerCase();
    final preferred = _catalogEvents
        .where((event) {
          return event.name.toLowerCase() == preferredName;
        })
        .toList(growable: false);

    _selectedEventTypeId = preferred.isNotEmpty
        ? preferred.first.id
        : _catalogEvents.first.id;

    final maxPlanIndex = _effectivePricingPlans().length - 1;
    if (maxPlanIndex < 0) {
      _selectedPlanIndex = 0;
      return;
    }
    _selectedPlanIndex = 0;
  }

  _CustomerCatalogEventType? get _selectedCatalogEvent {
    if (_catalogEvents.isEmpty || _selectedEventTypeId == null) {
      return null;
    }
    try {
      return _catalogEvents.firstWhere(
        (event) => event.id == _selectedEventTypeId,
      );
    } catch (_) {
      return _catalogEvents.first;
    }
  }

  String get _selectedEventTypeName {
    return _selectedCatalogEvent?.name ?? _selectedFallbackEventType;
  }

  List<ServicePricingPlan> _effectivePricingPlans() {
    final fallbackPlans = widget.config.pricingPlans;
    if (_selectedCatalogEvent == null) {
      return fallbackPlans
          .where((plan) => _amountFromText(plan.totalAmount) > 0)
          .toList(growable: false);
    }

    final catalogPlans = _selectedCatalogEvent!.orderedPlans;
    final plans = <ServicePricingPlan>[];
    for (var i = 0; i < catalogPlans.length; i++) {
      final catalogPlan = catalogPlans[i];
      if (catalogPlan.basePrice <= 0) {
        continue;
      }
      final fallbackIndex = i.clamp(0, fallbackPlans.length - 1);
      final fallback = fallbackPlans[fallbackIndex];
      final gstValue = ((catalogPlan.basePrice * _gstPercent) / 100).round();
      final total = catalogPlan.basePrice + gstValue;
      final planName = widget.config.catalogServiceId == 'live_wedding_painter'
          ? _weddingPainterCanvasSize(i)
          : catalogPlan.label;
      final features = catalogPlan.descriptionPoints.isEmpty
          ? fallback.features.take(4).toList(growable: false)
          : catalogPlan.descriptionPoints.take(4).toList(growable: false);

      plans.add(
        ServicePricingPlan(
          key: catalogPlan.key,
          name: planName,
          tier: i == 0
              ? 'Basic'
              : i == 1
              ? 'Standard'
              : 'Recommended',
          totalAmount: 'Rs.${_formatAmount(total)}',
          baseBreakdown:
              'Base : Rs.${_formatAmount(catalogPlan.basePrice)} + GST ${_formatPercent(_gstPercent)}% : Rs.${_formatAmount(gstValue)}',
          features: features,
          headerColor: fallback.headerColor,
          accentColor: fallback.accentColor,
        ),
      );
    }
    return plans
        .where((plan) => _amountFromText(plan.totalAmount) > 0)
        .toList(growable: false);
  }

  String _weddingPainterCanvasSize(int index) {
    if (index == 0) return '21" X 28"';
    if (index == 1) return '24" X 30"';
    return '28" X 36"';
  }

  String _formatAmount(int value) {
    final raw = value.toString();
    final chars = <String>[];
    for (var i = 0; i < raw.length; i++) {
      final index = raw.length - i;
      chars.add(raw[i]);
      if (index > 1 && index % 3 == 1) {
        chars.add(',');
      }
    }
    return chars.join();
  }

  String _formatPercent(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _gstSub?.cancel();
    _eventSub?.cancel();
    _placeSearchDebounceTimer?.cancel();
    _eventDateController.dispose();
    _eventTimeController.dispose();
    _durationController.dispose();
    _guestController.dispose();
    _venueNameController.dispose();
    _venueHouseDetailsController.dispose();
    _venueLandmarkController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _requirementsController.dispose();
    _onsiteContactNameController.dispose();
    _onsiteContactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    final scale = ScalingUtility(context: context);
    scale.setCurrentDeviceSize();

    final pricingPlans = _effectivePricingPlans();

    if (pricingPlans.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: Center(
          child: Text(
            'Pricing unavailable for this service right now.',
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.black.withValues(alpha: 0.85),
              fontSize: ResponsiveUtility.fontSize(14),
            ),
          ),
        ),
      );
    }

    final safePlanIndex = _selectedPlanIndex.clamp(0, pricingPlans.length - 1);
    final selectedPlan = pricingPlans[safePlanIndex];
    final selectedEventName = _selectedEventTypeName;
    final calculatedPrice = _calculatePrice(selectedPlan);
    final pageBg = isDark ? Colors.black : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xff2A2A2A);
    final bodyTextColor = isDark
        ? Colors.white.withValues(alpha: 0.86)
        : Colors.black54;

    return Scaffold(
      backgroundColor: pageBg,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.transparent : const Color(0xffF3F3F3),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: ResponsiveUtility.width(42),
        leading: InkWell(
          onTap: Get.back,
          child: Icon(Icons.arrow_back, color: titleColor),
        ),
        titleSpacing: 4,
        title: Text(
          widget.config.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: titleColor,
            fontSize: ResponsiveUtility.fontSize(16),
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.22)
                : const Color(0xffD9D9D9),
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _HeroHeader(
                  scale: scale,
                  config: widget.config,
                  isDark: isDark,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: ResponsiveUtility.only(
                    left: 14,
                    top: 10,
                    right: 14,
                    bottom: 120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PremiumAndRatingRow(
                        scale: scale,
                        isDark: isDark,
                        serviceCatalogId: widget.config.catalogServiceId,
                      ),
                      SizedBox(height: ResponsiveUtility.height(10)),
                      Text(
                        widget.config.title,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: ResponsiveUtility.fontSize(16),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtility.height(6)),
                      Text(
                        widget.config.description,
                        style: TextStyle(
                          color: bodyTextColor,
                          fontSize: ResponsiveUtility.fontSize(12),
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtility.height(10)),
                      _buildEventDetailsCard(scale, selectedEventName, isDark),
                      SizedBox(height: ResponsiveUtility.height(10)),
                      _buildLocationDetailsCard(scale, isDark),
                      SizedBox(height: ResponsiveUtility.height(10)),
                      _buildPlanSelectionCard(scale, pricingPlans, isDark),
                      SizedBox(height: ResponsiveUtility.height(10)),
                      _buildAdditionalPreferenceCard(scale, isDark),
                      SizedBox(height: ResponsiveUtility.height(10)),
                      _buildContactDetailsCard(scale, isDark),
                      SizedBox(height: ResponsiveUtility.height(10)),
                      _buildPricePreviewCard(
                        scale,
                        selectedPlan,
                        selectedEventName,
                        calculatedPrice,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomActionBar(
            scale: scale,
            totalPayable: calculatedPrice.totalAmount,
            isDark: isDark,
          ),
          if (_isCatalogLoading)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.28),
                  alignment: Alignment.center,
                  child: Container(
                    padding: ResponsiveUtility.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Color(0xFF13153A).withValues(alpha: 0.95)
                          : Color(0xFFFCFBFF).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Color(0xFF2B2E63) : Color(0xffD9D9D9),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: ResponsiveUtility.width(26),
                          height: ResponsiveUtility.height(26),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFFD000FF),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtility.height(10)),
                        Text(
                          'Loading your event types...',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.9),
                            fontSize: ResponsiveUtility.fontSize(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventDetailsCard(
    ScalingUtility scale,
    String selectedEventName,
    bool isDark,
  ) {
    return _ServiceBookingSectionCard(
      scale: scale,
      title: 'Event Details',
      isDark: isDark,
      expanded: _isEventDetailsExpanded,
      onToggle: () {
        setState(() => _isEventDetailsExpanded = !_isEventDetailsExpanded);
      },
      child: Column(
        children: [
          _ServiceFieldLabel(
            scale: scale,
            label: 'Speciality or Event type',
            isDark: isDark,
            child: InkWell(
              onTap: _showEventTypePicker,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: scale.getScaledWidth(12),
                  vertical: scale.getScaledHeight(12),
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1D1B47)
                      : const Color(0xffF6F4FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2C2F63)
                        : const Color(0xffD9D9D9),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedEventName,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: scale.getScaledFont(14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.45)
                          : Colors.black45,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _ServiceFieldLabel(
            scale: scale,
            label: 'Event Date',
            isDark: isDark,
            child: _ServiceInputBox(
              scale: scale,
              hintText: 'Select event date',
              controller: _eventDateController,
              readOnly: true,
              prefixIcon: Icons.calendar_today_outlined,
              onTap: _pickDate,
              isDark: isDark,
            ),
          ),
          _ServiceFieldLabel(
            scale: scale,
            label: 'Event Start Time',
            isDark: isDark,
            child: _ServiceInputBox(
              scale: scale,
              hintText: 'Select event time',
              controller: _eventTimeController,
              readOnly: true,
              prefixIcon: Icons.access_time_outlined,
              onTap: _pickTime,
              isDark: isDark,
            ),
          ),
          if (widget.config.usesEventDuration)
            _ServiceFieldLabel(
              scale: scale,
              label: 'Event Duration (hours)',
              isDark: isDark,
              child: Row(
                children: [
                  _durationButton(
                    scale: scale,
                    icon: Icons.remove,
                    enabled: _durationHours > 1,
                    isDark: isDark,
                    onTap: () => _changeDuration(-1),
                  ),
                  SizedBox(width: scale.getScaledWidth(8)),
                  Expanded(
                    child: _ServiceInputBox(
                      scale: scale,
                      hintText: '1',
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _normalizeDuration,
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: scale.getScaledWidth(8)),
                  _durationButton(
                    scale: scale,
                    icon: Icons.add,
                    enabled: _durationHours < 10,
                    isDark: isDark,
                    onTap: () => _changeDuration(1),
                  ),
                ],
              ),
            ),
          _ServiceFieldLabel(
            scale: scale,
            label: 'Number of guest [optional]',
            isDark: isDark,
            child: _ServiceInputBox(
              scale: scale,
              hintText: 'Enter number of guest',
              controller: _guestController,
              keyboardType: TextInputType.number,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetailsCard(ScalingUtility scale, bool isDark) {
    return _ServiceBookingSectionCard(
      scale: scale,
      title: 'Venue & Location Details',
      isDark: isDark,
      expanded: _isLocationDetailsExpanded,
      onToggle: () {
        setState(
          () => _isLocationDetailsExpanded = !_isLocationDetailsExpanded,
        );
      },
      child: Column(
        children: [
          _ServiceFieldLabel(
            scale: scale,
            label: 'Venue name',
            isDark: isDark,
            child: _ServiceInputBox(
              scale: scale,
              hintText: 'Enter venue name',
              controller: _venueNameController,
              isDark: isDark,
            ),
          ),
          _ServiceFieldLabel(
            scale: scale,
            label: 'House / Plot / Hall Details',
            isDark: isDark,
            child: _ServiceInputBox(
              scale: scale,
              hintText: 'Enter necessary details',
              controller: _venueHouseDetailsController,
              isDark: isDark,
            ),
          ),
          _ServiceFieldLabel(
            scale: scale,
            label: 'Landmark / Direction Details',
            isDark: isDark,
            child: _ServiceInputBox(
              scale: scale,
              hintText: 'Enter necessary details',
              controller: _venueLandmarkController,
              isDark: isDark,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: scale.getScaledHeight(6)),
              child: Text(
                'Venue Address',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xff2A2A2A),
                  fontSize: scale.getScaledFont(14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          LocationSearchField(
            controller: _addressController,
            onChanged: _onEventAddressSearchChanged,
            onSuggestionTap: _selectEventAddressSuggestion,
            suggestions: _placeSuggestions,
            isSearching: _isSearchingPlaces,
            onUseCurrentLocation: _useCurrentLocationForEvent,
            isFetchingCurrentLocation: _isFetchingCurrentLocation,
            isDark: isDark,
          ),
          SizedBox(height: scale.getScaledHeight(10)),
          AddressPreviewCard(
            formattedAddress: _addressController.text,
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            country: _country,
            pincode: _pincodeController.text.trim(),
            latitude: _selectedLatitude,
            longitude: _selectedLongitude,
          ),
          SizedBox(height: scale.getScaledHeight(10)),
          MapPickerWidget(
            centerLatitude: _mapCenterLatitude,
            centerLongitude: _mapCenterLongitude,
            selectedLatitude: _selectedLatitude,
            selectedLongitude: _selectedLongitude,
            isResolvingAddress: _isResolvingAddressFromMap,
            onLocationChanged: (double latitude, double longitude) {
              return _onEventMapLocationChanged(
                latitude: latitude,
                longitude: longitude,
              );
            },
            onConfirmLocation: _confirmEventLocation,
            canConfirmLocation: _hasSelectedEventLocation,
            showMap: _mapsService.isApiKeyConfigured,
            fallbackMessage:
                "Google Maps API key is missing.\n"
                "Please set ApiConstants.googleMapsApiKey.",
            onOpenExpandedMap: _mapsService.isApiKeyConfigured
                ? _openLargeEventMapPicker
                : null,
          ),
          SizedBox(height: scale.getScaledHeight(10)),
          _buildEventLocationNotice(scale, isDark),
        ],
      ),
    );
  }

  Widget _buildPlanSelectionCard(
    ScalingUtility scale,
    List<ServicePricingPlan> pricingPlans,
    bool isDark,
  ) {
    return _ServiceBookingSectionCard(
      scale: scale,
      title: 'Plan Selection',
      isDark: isDark,
      expanded: _isPlanSelectionExpanded,
      onToggle: () {
        setState(() => _isPlanSelectionExpanded = !_isPlanSelectionExpanded);
      },
      child: Column(
        children: pricingPlans.asMap().entries.map((entry) {
          final index = entry.key;
          final plan = entry.value;
          final isSelected = _selectedPlanIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedPlanIndex = index),
            child: Container(
              margin: EdgeInsets.only(bottom: scale.getScaledHeight(10)),
              padding: EdgeInsets.symmetric(
                horizontal: scale.getScaledWidth(10),
                vertical: scale.getScaledHeight(10),
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1637) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? plan.accentColor
                      : isDark
                      ? Color(0xFF2C2F63)
                      : Color(0xffD9D9D9),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                plan.name,
                                style: TextStyle(
                                  color: plan.accentColor,
                                  fontSize: scale.getScaledFont(15),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(width: scale.getScaledWidth(4)),
                            InkWell(
                              onTap: () => _showPlanDetailsBottomSheet(
                                scale,
                                plan,
                                isDark,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Icon(
                                Icons.info_outline,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : Colors.black45,
                                size: scale.getScaledWidth(14),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: scale.getScaledHeight(3)),
                        Text(
                          'Rs.${_formatAmount(_calculatePrice(plan).ratePerHour)} per hrs.',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.96)
                                : Colors.black87,
                            fontSize: scale.getScaledFont(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: scale.getScaledWidth(8)),
                  _RadioSelectionDot(
                    color: plan.accentColor,
                    selected: isSelected,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _durationButton({
    required ScalingUtility scale,
    required IconData icon,
    required bool enabled,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return IconButton.filledTonal(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: Size(scale.getScaledWidth(44), scale.getScaledHeight(44)),
        backgroundColor: isDark
            ? const Color(0xFF1D1B47)
            : const Color(0xffF6F4FF),
        foregroundColor: isDark ? Colors.white : const Color(0xff561C87),
      ),
    );
  }

  Widget _buildAdditionalPreferenceCard(ScalingUtility scale, bool isDark) {
    return _ServiceBookingSectionCard(
      scale: scale,
      title: 'Additional Preferences',
      isDark: isDark,
      expanded: _isAdditionalPreferenceExpanded,
      onToggle: () {
        setState(
          () => _isAdditionalPreferenceExpanded =
              !_isAdditionalPreferenceExpanded,
        );
      },
      child: Column(
        children: [
          _ServiceFieldLabel(
            scale: scale,
            label: 'Special Requirements [optional]',
            isDark: isDark,
            child: _ServiceInputBox(
              scale: scale,
              hintText: 'Any specific requirements, preferences or notes...',
              controller: _requirementsController,
              maxLines: 4,
              isDark: isDark,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_requirementLength/300 Characters',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.black45,
                fontSize: scale.getScaledFont(11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactDetailsCard(ScalingUtility scale, bool isDark) {
    return _ServiceBookingSectionCard(
      scale: scale,
      title: 'Contact at event location',
      isDark: isDark,
      expanded: _isContactDetailsExpanded,
      onToggle: () {
        setState(() => _isContactDetailsExpanded = !_isContactDetailsExpanded);
      },
      child: Column(
        children: [
          _ServiceFieldLabel(
            scale: scale,
            label: 'On-site contact name [optional]',
            isDark: isDark,
            child: _ServiceInputBox(
              scale: scale,
              hintText: 'Enter name of contact person',
              controller: _onsiteContactNameController,
              isDark: isDark,
            ),
          ),
          _ServiceFieldLabel(
            scale: scale,
            label: 'On-site phone number [optional]',
            isDark: isDark,
            child: _ServiceInputBox(
              scale: scale,
              hintText: 'Enter phone number',
              controller: _onsiteContactPhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricePreviewCard(
    ScalingUtility scale,
    ServicePricingPlan selectedPlan,
    String selectedEventName,
    _ServiceCalculatedPrice calculatedPrice,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF141539).withValues(alpha: 0.98)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2B2E63) : const Color(0xffD9D9D9),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: scale.getScaledWidth(10),
              vertical: scale.getScaledHeight(10),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF6A0878),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Text(
              'Price Preview',
              style: TextStyle(
                color: Colors.white,
                fontSize: scale.getScaledFont(15),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(10),
              scale.getScaledHeight(10),
              scale.getScaledWidth(10),
              scale.getScaledHeight(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.config.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xff2A2A2A),
                    fontSize: scale.getScaledFont(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(2)),
                Text(
                  '${_displayPlanForPreview(selectedPlan.name)} . $selectedEventName',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black45,
                    fontSize: scale.getScaledFont(12),
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(8)),
                _priceRow(
                  scale,
                  'Rate per hour',
                  'Rs.${_formatAmount(calculatedPrice.ratePerHour)}',
                  isDark: isDark,
                ),
                SizedBox(height: scale.getScaledHeight(6)),
                if (widget.config.usesEventDuration) ...[
                  _priceRow(
                    scale,
                    'Duration',
                    '${calculatedPrice.durationHours} Hrs.',
                    isDark: isDark,
                  ),
                  SizedBox(height: scale.getScaledHeight(6)),
                ],
                _priceRow(
                  scale,
                  'GST (${_formatPercent(_fixedGstPercent)}%)',
                  'Rs.${_formatAmount(calculatedPrice.gstAmount)}',
                  isDark: isDark,
                ),
                SizedBox(height: scale.getScaledHeight(8)),
                Container(
                  height: 1,
                  color: const Color(0xFF2A2E62).withValues(alpha: 0.8),
                ),
                SizedBox(height: scale.getScaledHeight(8)),
                _priceRow(
                  scale,
                  'Total Payable',
                  'Rs.${_formatAmount(calculatedPrice.totalAmount)}',
                  highlight: true,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar({
  required ScalingUtility scale,
  required int totalPayable,
  required bool isDark,
}) {
  return Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Material(
      elevation: 12,
      color: isDark ? const Color(0xFF0F1017) : Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: scale.getScaledWidth(12),
            vertical: scale.getScaledHeight(10),
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1017) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE5E5E5),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Price Section
              Expanded(
                flex: 9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Payable",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: scale.getScaledFont(12),
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                    ),
                    SizedBox(height: scale.getScaledHeight(2)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            "Rs.${_formatAmount(totalPayable)}",
                            style: TextStyle(
                              fontSize: scale.getScaledFont(16),
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF2A2A2A),
                            ),
                          ),
                          SizedBox(width: scale.getScaledWidth(4)),
                          Text(
                            "(inc. GST)",
                            style: TextStyle(
                              fontSize: scale.getScaledFont(11),
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: scale.getScaledWidth(10)),

              /// Buttons
              Expanded(
                flex: 16,
                child: widget.editingMode == null
                    ? Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: scale.getScaledHeight(46),
                              child: ElevatedButton(
                                onPressed: _isAddingToCart
                                    ? null
                                    : _handleBookNow,
                                style: _actionButtonStyle(scale, isDark),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Book Now",
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize:
                                          scale.getScaledFont(13),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: scale.getScaledWidth(8)),
                          Expanded(
                            child: SizedBox(
                              height: scale.getScaledHeight(46),
                              child: ElevatedButton(
                                onPressed: _isAddingToCart
                                    ? null
                                    : _handleAddToCart,
                                style: _actionButtonStyle(scale, isDark),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Add to Cart",
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize:
                                          scale.getScaledFont(13),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        height: scale.getScaledHeight(46),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isAddingToCart
                              ? null
                              : _handleSaveChanges,
                          style: _actionButtonStyle(scale, isDark),
                          child: _isAddingToCart
                              ? SizedBox(
                                  width: scale.getScaledWidth(18),
                                  height: scale.getScaledHeight(18),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark
                                        ? const Color(0xFF561C87)
                                        : Colors.white,
                                  ),
                                )
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      fontSize:
                                          scale.getScaledFont(14),
                                      fontWeight: FontWeight.w700,
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
    ),
  );
}

  ButtonStyle _actionButtonStyle(ScalingUtility scale, bool isDark) {
    return ElevatedButton.styleFrom(
      backgroundColor: isDark ? Colors.white : const Color(0xFF561C87),
      foregroundColor: isDark ? const Color(0xFF561C87) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(14)),
    );
  }

  _ServiceCalculatedPrice _calculatePrice(ServicePricingPlan plan) {
    final priceParts = _extractPriceParts(plan.baseBreakdown);
    final ratePerHour = _amountFromText(priceParts.basePrice);
    final durationHours = widget.config.usesEventDuration
        ? int.tryParse(_durationController.text.trim()) ?? 0
        : 1;
    final subtotal = ratePerHour * durationHours;
    final gstAmount = ((subtotal * _fixedGstPercent) / 100).round();
    final totalAmount = subtotal + gstAmount;
    return _ServiceCalculatedPrice(
      ratePerHour: ratePerHour,
      durationHours: durationHours,
      subtotal: subtotal,
      gstAmount: gstAmount,
      totalAmount: totalAmount,
    );
  }

  Future<void> _initializeEventLocation() async {
    if (!mounted) {
      return;
    }
    if (_selectedLatitude != null && _selectedLongitude != null) {
      return;
    }
    if (_addressController.text.trim().isNotEmpty) {
      return;
    }
    await _useCurrentLocationForEvent(showSuccessSnackbar: false);
  }

  void _onEventAddressSearchChanged(String input) {
    _placeSearchDebounceTimer?.cancel();
    final query = input.trim();

    if (query.isEmpty) {
      _placeSearchRequestId++;
      setState(() {
        _placeSuggestions = const <PlaceSuggestion>[];
        _isSearchingPlaces = false;
      });
      return;
    }

    _placeSearchDebounceTimer = Timer(
      const Duration(milliseconds: 400),
      () async {
        final requestId = ++_placeSearchRequestId;
        if (!mounted) {
          return;
        }
        setState(() {
          _isSearchingPlaces = true;
        });
        try {
          final suggestions = await _mapsService.fetchPlaceSuggestions(query);
          if (!mounted) {
            return;
          }
          if (requestId != _placeSearchRequestId) {
            return;
          }
          setState(() {
            _placeSuggestions = suggestions;
          });
        } catch (_) {
          if (!mounted) {
            return;
          }
          if (requestId != _placeSearchRequestId) {
            return;
          }
          setState(() {
            _placeSuggestions = const <PlaceSuggestion>[];
          });
          AppSnackbar.error(
            "Search Failed",
            "Unable to fetch location suggestions right now.",
          );
        } finally {
          if (mounted && requestId == _placeSearchRequestId) {
            setState(() {
              _isSearchingPlaces = false;
            });
          }
        }
      },
    );
  }

  Widget _buildEventLocationNotice(ScalingUtility scale, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: scale.getScaledWidth(12),
        vertical: scale.getScaledHeight(12),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isDark ? const Color(0xFF1D2459) : const Color(0xFFEFFFF6),
        border: Border.all(
          color: isDark
              ? const Color(0xFF5A5DBA).withValues(alpha: 0.7)
              : const Color(0xffBCE7D1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: scale.getScaledWidth(28),
            height: scale.getScaledHeight(28),
            decoration: BoxDecoration(
              color: const Color(0xFF00D3A7).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: Color(0xFF00F5C5),
              size: 18,
            ),
          ),
          SizedBox(width: scale.getScaledWidth(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event location for smooth arrival',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xff1F5137),
                    fontWeight: FontWeight.w700,
                    fontSize: scale.getScaledFont(13),
                  ),
                ),
                SizedBox(height: scale.getScaledHeight(4)),
                Text(
                  'This pinned map location is shared with professionals to help them navigate accurately for your booking.',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.82)
                        : const Color(0xff2A7350),
                    fontSize: scale.getScaledFont(12),
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectEventAddressSuggestion(PlaceSuggestion suggestion) async {
    setState(() {
      _placeSuggestions = const <PlaceSuggestion>[];
      _isSearchingPlaces = false;
      _isResolvingAddressFromMap = true;
    });
    try {
      final details = await _mapsService.getPlaceDetails(suggestion.placeId);
      if (details == null) {
        AppSnackbar.error(
          "Location Error",
          "Could not resolve selected place details.",
        );
        return;
      }
      _applyEventAddressSelection(details);
    } catch (_) {
      AppSnackbar.error(
        "Location Error",
        "Unable to fetch selected place details.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddressFromMap = false;
        });
      }
    }
  }

  Future<void> _onEventMapLocationChanged({
    required double latitude,
    required double longitude,
  }) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isResolvingAddressFromMap = true;
    });

    try {
      final result = await _mapsService.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );
      if (result != null) {
        _applyEventAddressSelection(result);
      } else {
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedLatitude = latitude;
          _selectedLongitude = longitude;
          _mapCenterLatitude = latitude;
          _mapCenterLongitude = longitude;
          _addressController.text =
              'Pinned location (${latitude.toStringAsFixed(6)}, '
              '${longitude.toStringAsFixed(6)})';
          _stateController.clear();
          _cityController.clear();
          _pincodeController.clear();
          _country = '';
        });
      }
    } catch (_) {
      AppSnackbar.error(
        "Location Error",
        "Unable to resolve address for selected map pin.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddressFromMap = false;
        });
      }
    }
  }

  Future<void> _useCurrentLocationForEvent({
    bool showSuccessSnackbar = true,
  }) async {
    if (_isFetchingCurrentLocation) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isFetchingCurrentLocation = true;
    });
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

      await _onEventMapLocationChanged(
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
      if (mounted) {
        setState(() {
          _isFetchingCurrentLocation = false;
        });
      }
    }
  }

  void _confirmEventLocation() {
    if (!_hasSelectedEventLocation) {
      AppSnackbar.error(
        "Location Required",
        "Please select a valid event location first.",
      );
      return;
    }
    AppSnackbar.success(
      "Location Confirmed",
      "Event location has been confirmed.",
    );
  }

  Future<void> _openLargeEventMapPicker() async {
    if (!_mapsService.isApiKeyConfigured) {
      return;
    }

    AddressSelection? initialSelection;
    if (_selectedLatitude != null && _selectedLongitude != null) {
      initialSelection = AddressSelection(
        formattedAddress: _addressController.text.trim(),
        state: _stateController.text.trim(),
        city: _cityController.text.trim(),
        pincode: _pincodeController.text.trim(),
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
      );
    }

    final pickedLocation = await Get.to<AddressSelection>(
      () => ProfessionalLocationPickerScreen(
        initialCenterLatitude: _mapCenterLatitude,
        initialCenterLongitude: _mapCenterLongitude,
        initialSelection: initialSelection,
      ),
      fullscreenDialog: true,
    );

    if (pickedLocation == null) {
      return;
    }
    _applyEventAddressSelection(pickedLocation);
    AppSnackbar.success(
      "Location Saved",
      "Selected map location has been applied.",
    );
  }

  void _applyEventAddressSelection(AddressSelection selection) {
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedLatitude = selection.latitude;
      _selectedLongitude = selection.longitude;
      _mapCenterLatitude = selection.latitude;
      _mapCenterLongitude = selection.longitude;
      _addressController.text = selection.formattedAddress;
      _stateController.text = selection.state.trim();
      _cityController.text = selection.city.trim();
      _pincodeController.text = selection.pincode.trim();
      _country = selection.country.trim();
      _placeSuggestions = const <PlaceSuggestion>[];
      _isSearchingPlaces = false;
    });
  }

  Future<void> _showPlanDetailsBottomSheet(
    ScalingUtility scale,
    ServicePricingPlan plan,
    bool isDark,
  ) async {
    await Get.bottomSheet<void>(
      Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF06070B) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              scale.getScaledWidth(0),
              scale.getScaledHeight(0),
              scale.getScaledWidth(0),
              scale.getScaledHeight(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    scale.getScaledWidth(14),
                    scale.getScaledHeight(10),
                    scale.getScaledWidth(14),
                    scale.getScaledHeight(10),
                  ),
                  decoration: BoxDecoration(
                    color: plan.headerColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan Details',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: scale.getScaledFont(13),
                              ),
                            ),
                            SizedBox(height: scale.getScaledHeight(2)),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    plan.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: scale.getScaledFont(24 / 2),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(width: scale.getScaledWidth(8)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: scale.getScaledWidth(10),
                                    vertical: scale.getScaledHeight(3),
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    plan.tier,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: scale.getScaledFont(11),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    scale.getScaledWidth(16),
                    scale.getScaledHeight(12),
                    scale.getScaledWidth(16),
                    scale.getScaledHeight(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What\'s included:',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: scale.getScaledFont(16),
                        ),
                      ),
                      SizedBox(height: scale.getScaledHeight(10)),
                      ...plan.features.map(
                        (point) => Padding(
                          padding: EdgeInsets.only(
                            bottom: scale.getScaledHeight(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: isDark
                                    ? Color(0xFF00E980)
                                    : Color(0xFF00A63E),
                                size: scale.getScaledWidth(16),
                              ),
                              SizedBox(width: scale.getScaledWidth(8)),
                              Expanded(
                                child: Text(
                                  point,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : Colors.black.withValues(alpha: 0.9),
                                    fontSize: scale.getScaledFont(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: scale.getScaledHeight(12)),
                      SizedBox(
                        width: double.infinity,
                        height: scale.getScaledHeight(44),
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white
                                : AppColors.primaryColor,
                            foregroundColor: isDark
                                ? Color(0xFF5A197F)
                                : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Got it!',
                            style: TextStyle(
                              fontSize: scale.getScaledFont(16),
                              fontWeight: FontWeight.w700,
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
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Future<void> _pickDate() async {
    final isDark = HelperFunctions.isDarkMode(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEventDate ?? now,
      firstDate: today,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                (isDark ? const ColorScheme.dark() : const ColorScheme.light())
                    .copyWith(
                      primary: const Color(0xFF7D5DFF),
                      surface: isDark ? const Color(0xFF1B1538) : Colors.white,
                    ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedEventDate = picked;
      _eventDateController.text = _formatDate(picked);
    });
  }

  Future<void> _pickTime() async {
    final isDark = HelperFunctions.isDarkMode(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedEventTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                (isDark ? const ColorScheme.dark() : const ColorScheme.light())
                    .copyWith(
                      primary: const Color(0xFF7D5DFF),
                      surface: isDark ? const Color(0xFF1B1538) : Colors.white,
                    ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedEventTime = picked;
      _eventTimeController.text = _formatTime(picked);
    });
  }

  Future<void> _showEventTypePicker() async {
    if (_catalogEvents.isNotEmpty) {
      final selectedName = await SearchableSelectionBottomSheet.show(
        context: context,
        title: 'Select Speciality & Event type',
        options: _catalogEvents
            .map((event) => event.name)
            .toList(growable: false),
        initialValue: _selectedEventTypeName,
        searchHint: 'Search event type',
      );
      if (selectedName == null) {
        return;
      }
      final selectedEvent = _catalogEvents.firstWhere(
        (event) => event.name == selectedName,
        orElse: () => _catalogEvents.first,
      );
      setState(() {
        _selectedEventTypeId = selectedEvent.id;
        _selectedFallbackEventType = selectedEvent.name;
        _selectedPlanIndex = 0;
      });
      return;
    }

    final selectedName = await SearchableSelectionBottomSheet.show(
      context: context,
      title: 'Select Speciality & Event type',
      options: widget.config.eventTypes,
      initialValue: _selectedEventTypeName,
      searchHint: 'Search event type',
    );

    if (selectedName == null) {
      return;
    }
    setState(() {
      _selectedFallbackEventType = selectedName;
      _selectedPlanIndex = 0;
    });
  }

  Future<void> _handleAddToCart() async {
    if (_isAddingToCart) {
      return;
    }
    final allowed = await _ensureAuthenticatedForAction();
    if (!allowed) {
      return;
    }
    final booking = _createBookingItem();
    if (booking == null) {
      return;
    }

    setState(() => _isAddingToCart = true);
    try {
      if (widget.editingMode == CustomerBookingViewMode.cart &&
          widget.editingIndex != null) {
        await _bookingController.updateCartItem(
          index: widget.editingIndex!,
          item: booking,
        );
        AppSnackbar.success('Updated', 'Booking updated successfully.');
        Get.off(
          () =>
              const CustomerBookingsScreen(mode: CustomerBookingViewMode.cart),
        );
        return;
      }
      final success = await _bookingController.addToCart(booking);
      if (!success) {
        return;
      }
      AppSnackbar.success('Added', 'Booking added to cart successfully.');
      Get.off(
        () => const CustomerBookingsScreen(mode: CustomerBookingViewMode.cart),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  Future<void> _handleBookNow() async {
    final allowed = await _ensureAuthenticatedForAction();
    if (!allowed) {
      return;
    }
    final booking = _createBookingItem();
    if (booking == null) {
      return;
    }
    if (widget.editingMode == CustomerBookingViewMode.checkout &&
        widget.editingIndex != null) {
      _bookingController.updateCheckoutItem(
        index: widget.editingIndex!,
        item: booking,
      );
      AppSnackbar.success('Updated', 'Checkout booking updated.');
      Get.off(
        () => const CustomerBookingsScreen(
          mode: CustomerBookingViewMode.checkout,
        ),
      );
      return;
    }
    _bookingController.setInstantCheckout(booking);
    await Get.to(
      () => const CustomerBookingsScreen(mode: CustomerBookingViewMode.checkout),
      preventDuplicates: false,
    );
  }

  Future<void> _handleSaveChanges() async {
    if (widget.editingMode == CustomerBookingViewMode.checkout) {
      await _handleBookNow();
      return;
    }
    await _handleAddToCart();
  }

  Future<bool> _ensureAuthenticatedForAction() async {
    final storage = GetStorage();
    final isGuest = storage.read(AuthController.guestUserStorageKey) == true;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (isGuest || !isLoggedIn) {
      await AuthController.instance.showLoginRequiredSheet();
      return false;
    }

    final isProfileCompleted =
        storage.read(AuthController.customerProfileCompletedStorageKey) == true;
    if (!isProfileCompleted) {
      AppSnackbar.error(
        'Complete Profile',
        'Please complete your profile before continuing.',
      );
      Get.toNamed(AppRoutes.customerProfileCompletionRoute);
      return false;
    }
    return true;
  }

  CustomerBookingItem? _createBookingItem() {
    if (_selectedEventTypeName.trim().isEmpty) {
      AppSnackbar.error('Required', 'Please select speciality or event type.');
      return null;
    }
    if (_eventDateController.text.trim().isEmpty) {
      AppSnackbar.error('Required', 'Please select event date.');
      return null;
    }
    if (_eventTimeController.text.trim().isEmpty) {
      AppSnackbar.error('Required', 'Please select event time.');
      return null;
    }
    final durationHours = widget.config.usesEventDuration
        ? int.tryParse(_durationController.text.trim()) ?? 0
        : 1;
    if (widget.config.usesEventDuration &&
        (durationHours < 1 || durationHours > 10)) {
      AppSnackbar.error(
        'Invalid Duration',
        'Event duration must be between 1 and 10 hours.',
      );
      return null;
    }
    if (_addressController.text.trim().isEmpty) {
      AppSnackbar.error('Required', 'Please enter full address.');
      return null;
    }
    if (_venueNameController.text.trim().isEmpty) {
      AppSnackbar.error('Required', 'Please enter venue name.');
      return null;
    }
    if (_venueHouseDetailsController.text.trim().isEmpty) {
      AppSnackbar.error('Required', 'Please enter house/plot/hall details.');
      return null;
    }
    if (_venueLandmarkController.text.trim().isEmpty) {
      AppSnackbar.error(
        'Required',
        'Please enter landmark or direction details.',
      );
      return null;
    }
    if (!_hasSelectedEventLocation) {
      AppSnackbar.error(
        'Location Required',
        'Please pin the exact event location on map.',
      );
      return null;
    }
    final pincode = _pincodeController.text.trim();
    if (pincode.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(pincode)) {
      AppSnackbar.error('Required', 'Please enter valid 6-digit pincode.');
      return null;
    }
    final onsitePhone = _onsiteContactPhoneController.text.trim();
    if (onsitePhone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(onsitePhone)) {
      AppSnackbar.error(
        'Required',
        'Please enter valid 10-digit phone number.',
      );
      return null;
    }

    final pricingPlans = _effectivePricingPlans();
    if (pricingPlans.isEmpty) {
      AppSnackbar.error(
        'Unavailable',
        'Pricing is not configured for this service.',
      );
      return null;
    }
    final safeIndex = _selectedPlanIndex.clamp(0, pricingPlans.length - 1);
    final selectedPlan = pricingPlans[safeIndex];
    final calculatedPrice = _calculatePrice(selectedPlan);

    return CustomerBookingItem(
      id: '',
      serviceCatalogId: widget.config.catalogServiceId,
      serviceTitle: widget.config.title,
      eventTypeId: _selectedEventTypeId ?? '',
      eventTypeName: _selectedEventTypeName,
      planKey: selectedPlan.key,
      planName: selectedPlan.name,
      basePrice: calculatedPrice.subtotal,
      gstPercent: _fixedGstPercent,
      gstAmount: calculatedPrice.gstAmount,
      totalAmount: calculatedPrice.totalAmount,
      eventDate: _selectedEventDate,
      eventTime: _eventTimeController.text.trim(),
      eventDurationHours: durationHours.toString(),
      guestCount: _guestController.text.trim(),
      venueName: _venueNameController.text.trim(),
      venueHouseDetails: _venueHouseDetailsController.text.trim(),
      venueLandmarkDetails: _venueLandmarkController.text.trim(),
      fullAddress: _addressController.text.trim(),
      state: _stateController.text.trim(),
      city: _cityController.text.trim(),
      pincode: pincode,
      latitude: _selectedLatitude!,
      longitude: _selectedLongitude!,
      specialRequirements: _requirementsController.text.trim(),
      urgentBooking: false,
      onsiteContactName: _onsiteContactNameController.text.trim(),
      onsiteContactPhone: onsitePhone,
      createdAt: DateTime.now(),
    );
  }

  int _amountFromText(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  Widget _priceRow(
    ScalingUtility scale,
    String label,
    String value, {
    bool highlight = false,
    required bool isDark,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: highlight ? 0.96 : 0.7)
                : (highlight ? const Color(0xff2A2A2A) : Colors.black54),
            fontSize: scale.getScaledFont(highlight ? 14 : 13),
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: highlight ? 0.96 : 0.62)
                : (highlight ? const Color(0xff2A2A2A) : Colors.black54),
            fontSize: scale.getScaledFont(highlight ? 14 : 13),
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _displayPlanForPreview(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('default')) {
      return 'Default Plan';
    }
    if (lower.contains('normal')) {
      return 'Normal Plan';
    }
    if (lower.contains('professional')) {
      return 'Professional Plan';
    }
    return value;
  }

  String _formatDate(DateTime value) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  _ServicePlanPriceParts _extractPriceParts(String text) {
    final matches = RegExp(r'Rs\.?\s*([\d,]+)').allMatches(text).toList();
    final base = matches.isNotEmpty ? 'Rs.${matches[0].group(1)!}' : 'Rs.0';
    final gst = matches.length > 1 ? 'Rs.${matches[1].group(1)!}' : 'Rs.0';
    return _ServicePlanPriceParts(basePrice: base, gstAmount: gst);
  }
}

class _ServiceBookingSectionCard extends StatelessWidget {
  const _ServiceBookingSectionCard({
    required this.scale,
    required this.title,
    required this.isDark,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final ScalingUtility scale;
  final String title;
  final bool isDark;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F1031).withValues(alpha: 0.96)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2B2E63) : const Color(0xffD9D9D9),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: scale.getScaledWidth(8),
                vertical: scale.getScaledHeight(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: scale.getScaledWidth(20),
                    height: scale.getScaledHeight(20),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF2B2D58) : Color(0xffFCFBFF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _iconForTitle(title),
                      color: isDark
                          ? const Color(0xFF3E7AFF)
                          : const Color(0xFF6A4CCF),
                      size: scale.getScaledWidth(12),
                    ),
                  ),
                  SizedBox(width: scale.getScaledWidth(8)),
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xff2A2A2A),
                      fontSize: scale.getScaledFont(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black45,
                    size: scale.getScaledWidth(22),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              height: 1,
              color: isDark
                  ? const Color(0xFF262A57).withValues(alpha: 0.8)
                  : const Color(0xffECECEC),
            ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(
                scale.getScaledWidth(12),
                scale.getScaledHeight(10),
                scale.getScaledWidth(12),
                scale.getScaledHeight(12),
              ),
              child: child,
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  IconData _iconForTitle(String title) {
    final value = title.toLowerCase();
    if (value.contains('event')) {
      return Icons.event_note_outlined;
    }
    if (value.contains('location')) {
      return Icons.location_on_outlined;
    }
    if (value.contains('plan')) {
      return Icons.sell_outlined;
    }
    if (value.contains('preference')) {
      return Icons.tune_rounded;
    }
    if (value.contains('contact')) {
      return Icons.contacts_outlined;
    }
    return Icons.description_outlined;
  }
}

class _ServiceFieldLabel extends StatelessWidget {
  const _ServiceFieldLabel({
    required this.scale,
    required this.label,
    required this.isDark,
    required this.child,
  });

  final ScalingUtility scale;
  final String label;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: scale.getScaledHeight(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xff2A2A2A),
              fontSize: scale.getScaledFont(14),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: scale.getScaledHeight(6)),
          child,
        ],
      ),
    );
  }
}

class _ServiceInputBox extends StatelessWidget {
  const _ServiceInputBox({
    required this.scale,
    required this.hintText,
    this.controller,
    this.readOnly = false,
    this.maxLines = 1,
    this.onTap,
    this.onChanged,
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    required this.isDark,
  });

  final ScalingUtility scale;
  final String hintText;
  final TextEditingController? controller;
  final bool readOnly;
  final int maxLines;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      cursorColor: isDark ? Colors.white : Colors.black,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: scale.getScaledFont(14),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.35) : Colors.black45,
          fontSize: scale.getScaledFont(14),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1D1B47) : const Color(0xffF6F4FF),
        contentPadding: EdgeInsets.symmetric(
          horizontal: scale.getScaledWidth(12),
          vertical: scale.getScaledHeight(12),
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.black45,
                size: 20,
              ),
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
            color: isDark ? const Color(0xFF4D4DA0) : const Color(0xff6A4CCF),
          ),
        ),
      ),
    );
  }
}

class _ServicePlanPriceParts {
  const _ServicePlanPriceParts({
    required this.basePrice,
    required this.gstAmount,
  });

  final String basePrice;
  final String gstAmount;
}

class _ServiceCalculatedPrice {
  const _ServiceCalculatedPrice({
    required this.ratePerHour,
    required this.durationHours,
    required this.subtotal,
    required this.gstAmount,
    required this.totalAmount,
  });

  final int ratePerHour;
  final int durationHours;
  final int subtotal;
  final int gstAmount;
  final int totalAmount;
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.scale,
    required this.config,
    required this.isDark,
  });

  final ScalingUtility scale;
  final CustomerServiceDetailConfig config;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: scale.getScaledHeight(350),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(config.imagePath, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      colors: [
                        Color(0x2D000000),
                        Color(0x75000000),
                        Color(0xFF000000),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumAndRatingRow extends StatelessWidget {
  const _PremiumAndRatingRow({
    required this.scale,
    required this.isDark,
    required this.serviceCatalogId,
  });

  final ScalingUtility scale;
  final bool isDark;
  final String serviceCatalogId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: ResponsiveUtility.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFFE7EBFF) : Color(0xffF6F7FD),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'PREMIUM MANAGED',
            style: TextStyle(
              color: isDark ? Color(0xFF1E2DC4) : Color(0xff0007A1),
              fontSize: ResponsiveUtility.fontSize(12),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.star,
          color: isDark ? Color(0xFFFFCC00) : Color(0xFFFF8C00),
          size: ResponsiveUtility.width(18),
        ),
        SizedBox(width: ResponsiveUtility.width(4)),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(ServiceCatalogPaths.serviceStatsCollection)
              .doc(serviceCatalogId)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? const <String, dynamic>{};
            final rating = (data['averageRating'] as num?)?.toDouble() ?? 0;
            final bookings =
                (data['totalCompletedBookings'] as num?)?.toInt() ?? 0;
            final label = snapshot.connectionState == ConnectionState.waiting
                ? 'Loading...'
                : '${rating.toStringAsFixed(1)} ($bookings bookings)';
            return Text(
              label,
              style: TextStyle(
                color: isDark ? Color(0xFFFFCC00) : Color(0xFFFF8C00),
                fontSize: ResponsiveUtility.fontSize(14),
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RadioSelectionDot extends StatelessWidget {
  const _RadioSelectionDot({required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.6),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class CustomerServiceDetailConfig {
  const CustomerServiceDetailConfig({
    required this.title,
    required this.catalogServiceId,
    required this.imagePath,
    required this.description,
    required this.eventTypes,
    required this.initialSelectedEventTypeIndex,
    required this.processSteps,
    required this.pricingPlans,
    required this.initialSelectedPlanIndex,
    this.pricingSectionTitle = 'Our Process',
    this.usesEventDuration = true,
  });

  final String title;
  final String catalogServiceId;
  final String imagePath;
  final String description;
  final List<String> eventTypes;
  final int initialSelectedEventTypeIndex;
  final List<ServiceProcessStep> processSteps;
  final List<ServicePricingPlan> pricingPlans;
  final int initialSelectedPlanIndex;
  final String pricingSectionTitle;
  final bool usesEventDuration;
}

class ServiceProcessStep {
  const ServiceProcessStep({required this.title, required this.description});

  final String title;
  final String description;
}

class ServicePricingPlan {
  const ServicePricingPlan({
    required this.key,
    required this.name,
    required this.tier,
    required this.totalAmount,
    required this.baseBreakdown,
    required this.features,
    required this.headerColor,
    required this.accentColor,
  });

  final String key;
  final String name;
  final String tier;
  final String totalAmount;
  final String baseBreakdown;
  final List<String> features;
  final Color headerColor;
  final Color accentColor;
}

class CustomerServiceDetailConfigs {
  CustomerServiceDetailConfigs._();

  static const List<ServiceProcessStep> _defaultProcess = [
    ServiceProcessStep(
      title: 'Submit Request',
      description: 'Tell us your requirements and schedule.',
    ),
    ServiceProcessStep(
      title: 'Expert Matching',
      description:
          'We route your inquiry to the beat professional for the Job.',
    ),
    ServiceProcessStep(
      title: 'Session Delivery',
      description: 'Receive your high-res photos via secure digital gallery.',
    ),
  ];

  static const List<ServicePricingPlan> _visualMediaPlans = [
    ServicePricingPlan(
      key: 'basic',
      name: 'Default plan',
      tier: 'Basic',
      totalAmount: 'Rs. 26,550',
      baseBreakdown: 'Base : Rs.22,500 + GST 18% : Rs.4,050',
      features: [
        '4 hrs coverage.',
        '200 edited photos',
        'Online gallery',
        'Basic album',
      ],
      headerColor: Color(0xFF0F5E35),
      accentColor: Color(0xFF00E980),
    ),
    ServicePricingPlan(
      key: 'normal',
      name: 'Normal plan',
      tier: 'Standard',
      totalAmount: 'Rs. 44, 250',
      baseBreakdown: 'Base : Rs.37,500 + GST 18% : Rs.6,750',
      features: [
        '8 hrs coverage.',
        '500 edited photos',
        '4k video highlight & premium album',
        'Drone shorts',
      ],
      headerColor: Color(0xFF123572),
      accentColor: Color(0xFF0E8CFF),
    ),
    ServicePricingPlan(
      key: 'professional',
      name: 'Professional plan',
      tier: 'Recommended',
      totalAmount: 'Rs. 79,650',
      baseBreakdown: 'Base : Rs.67,500 + GST 18% : Rs.12,150',
      features: [
        'Full day coverage',
        '1000+ edited photos',
        'Cinematic film',
        'Drone shorts & Instagram Reels',
      ],
      headerColor: Color(0xFF5A0F6B),
      accentColor: Color(0xFFD000FF),
    ),
  ];

  static const List<ServicePricingPlan> _musicPlans = [
    ServicePricingPlan(
      key: 'basic',
      name: 'Default plan',
      tier: 'Basic',
      totalAmount: 'Rs. 26,550',
      baseBreakdown: 'Base : Rs.22,500 + GST 18% : Rs.4,050',
      features: [
        'Solo artist',
        '2hrs performance',
        'Basic sound setup',
        '10-song set',
      ],
      headerColor: Color(0xFF0F5E35),
      accentColor: Color(0xFF00E980),
    ),
    ServicePricingPlan(
      key: 'normal',
      name: 'Normal plan',
      tier: 'Standard',
      totalAmount: 'Rs. 44, 250',
      baseBreakdown: 'Base : Rs.37,500 + GST 18% : Rs.6,750',
      features: [
        'Duo/Trio Band',
        '3hrs performance',
        'Full PA System',
        'Custom playlist',
      ],
      headerColor: Color(0xFF123572),
      accentColor: Color(0xFF0E8CFF),
    ),
    ServicePricingPlan(
      key: 'professional',
      name: 'Professional plan',
      tier: 'Recommended',
      totalAmount: 'Rs. 79,650',
      baseBreakdown: 'Base : Rs.67,500 + GST 18% : Rs.12,150',
      features: [
        'Full band 5+',
        '5Hrs Performance',
        'Concert PA',
        'Live Mixing & Stage lighting',
      ],
      headerColor: Color(0xFF5A0F6B),
      accentColor: Color(0xFFD000FF),
    ),
  ];

  static const List<ServicePricingPlan> _weddingPainterPlans = [
    ServicePricingPlan(
      key: 'basic',
      name: "21'' X 28''",
      tier: 'Basic',
      totalAmount: 'Rs. 9,440',
      baseBreakdown: 'Base : Rs.8,000 + GST 18% : Rs.1,440',
      features: ['Perfect for intimate settings. A4 proportionate.'],
      headerColor: Color(0xFF0F5E35),
      accentColor: Color(0xFF00E980),
    ),
    ServicePricingPlan(
      key: 'normal',
      name: "24'' X 30''",
      tier: 'Standard',
      totalAmount: 'Rs. 14,160',
      baseBreakdown: 'Base : Rs.12,000 + GST 18% : Rs.2,160',
      features: ['Most popular. Great balance of detail and display.'],
      headerColor: Color(0xFF123572),
      accentColor: Color(0xFF0E8CFF),
    ),
    ServicePricingPlan(
      key: 'professional',
      name: "28'' X 30''",
      tier: 'Recommended',
      totalAmount: 'Rs. 21,240',
      baseBreakdown: 'Base : Rs.18,000 + GST 18% : Rs.3,240',
      features: ['Grand canvas for majestic events. Museum quality.'],
      headerColor: Color(0xFF5A0F6B),
      accentColor: Color(0xFFD000FF),
    ),
  ];

  static const CustomerServiceDetailConfig
  photography = CustomerServiceDetailConfig(
    title: 'Photography & Videography',
    catalogServiceId: 'photo_videography',
    imagePath: AppImages.photographer,
    description:
        'Professional photography and videography for all your special occasions. Our certified photographers use DSLR & cinema cameras to deliver stunning visuals you will cherish forever.',
    eventTypes: [
      'Family events',
      'Pre-wedding events',
      'Corporate events',
      'Private Parties',
      'Product Shoot',
      'Fashion Shoots',
      'Real estate',
      'Makeup Shoots',
      'Wedding',
      'Makeup shoots',
    ],
    initialSelectedEventTypeIndex: 1,
    processSteps: _defaultProcess,
    pricingPlans: _visualMediaPlans,
    initialSelectedPlanIndex: 0,
  );

  static const CustomerServiceDetailConfig music = CustomerServiceDetailConfig(
    title: 'Music & Live Performance',
    catalogServiceId: 'music_live_performance',
    imagePath: AppImages.musician,
    description:
        'Live music performances by professional bands and solo artists. From classical to contemporary, we match the perfect ensemble for your event mood and audience.',
    eventTypes: [
      'Cafes',
      'Birthdays',
      'Family events',
      'Wedding',
      'Corporate Events',
      'Private Parties',
      'Hotel lounges',
    ],
    initialSelectedEventTypeIndex: 1,
    processSteps: _defaultProcess,
    pricingPlans: _musicPlans,
    initialSelectedPlanIndex: 0,
  );

  static const CustomerServiceDetailConfig dj = CustomerServiceDetailConfig(
    title: 'Professional DJ Services',
    catalogServiceId: 'professional_dj',
    imagePath: AppImages.dj,
    description:
        'Professional DJ services with state-of-the-art sound equipment, dynamic light shows, and curated music sets that keep your guests on the dance floor all night.',
    eventTypes: [
      'Cafes',
      'Birthdays',
      'Family events',
      'Wedding',
      'Corporate Events',
      'Private Parties',
      'Hotel lounges',
    ],
    initialSelectedEventTypeIndex: 1,
    processSteps: _defaultProcess,
    pricingPlans: _visualMediaPlans,
    initialSelectedPlanIndex: 0,
  );

  static const CustomerServiceDetailConfig
  liveWeddingPainter = CustomerServiceDetailConfig(
    title: 'Live wedding painter',
    catalogServiceId: 'live_wedding_painter',
    imagePath: AppImages.weddingPlanner,
    description:
        'A professional live painter who creates a beautiful painting of your ceremony in real-time. Watch your special day transform into a timeless work of art on canvas.',
    eventTypes: [
      'Wedding',
      'Engagements',
      'Receptions',
      'Destination Weddings',
      'Private Events',
    ],
    initialSelectedEventTypeIndex: 1,
    processSteps: _defaultProcess,
    pricingPlans: _weddingPainterPlans,
    initialSelectedPlanIndex: 0,
    usesEventDuration: false,
  );

  static const CustomerServiceDetailConfig anchor = CustomerServiceDetailConfig(
    title: 'Professional Anchor',
    catalogServiceId: 'professional_anchor',
    imagePath: AppImages.anchor,
    description:
        'Charismatic professional anchors who keep your audience engaged throughout the event. Bilingual hosts experienced in ceremonies, award nights, and corporate events.',
    eventTypes: [
      'Cafes',
      'Birthdays',
      'Family events',
      'Wedding',
      'Corporate Events',
      'Private Parties',
      'Hotel lounges',
    ],
    initialSelectedEventTypeIndex: 1,
    processSteps: _defaultProcess,
    pricingPlans: _visualMediaPlans,
    initialSelectedPlanIndex: 0,
  );

  static const CustomerServiceDetailConfig
  magician = CustomerServiceDetailConfig(
    title: 'Professional Magician',
    catalogServiceId: 'professional_magician',
    imagePath: AppImages.magician,
    description:
        'Professional magicians who create unforgettable moments of wonder. From close-up card magic to grand illusions - perfect entertainment for all ages at any celebration.',
    eventTypes: [
      'Cafes',
      'Birthdays',
      'Family events',
      'Wedding',
      'Corporate Events',
      'Private Parties',
      'Hotel lounges',
    ],
    initialSelectedEventTypeIndex: 1,
    processSteps: _defaultProcess,
    pricingPlans: _visualMediaPlans,
    initialSelectedPlanIndex: 0,
  );

  static CustomerServiceDetailConfig? fromCatalogServiceId(String catalogId) {
    const all = <CustomerServiceDetailConfig>[
      photography,
      music,
      dj,
      liveWeddingPainter,
      anchor,
      magician,
    ];
    for (final config in all) {
      if (config.catalogServiceId == catalogId) {
        return config;
      }
    }
    return null;
  }
}

class _CustomerCatalogEventType {
  const _CustomerCatalogEventType({
    required this.id,
    required this.name,
    required this.plans,
  });

  final String id;
  final String name;
  final List<_CustomerCatalogPlan> plans;

  List<_CustomerCatalogPlan> get orderedPlans {
    final byKey = <String, _CustomerCatalogPlan>{
      for (final plan in plans) plan.key: plan,
    };
    return <_CustomerCatalogPlan>[
      byKey['basic'] ??
          const _CustomerCatalogPlan(
            key: 'basic',
            label: 'Default Plan',
            basePrice: 0,
            descriptionPoints: <String>[],
          ),
      byKey['normal'] ??
          const _CustomerCatalogPlan(
            key: 'normal',
            label: 'Normal Plan',
            basePrice: 0,
            descriptionPoints: <String>[],
          ),
      byKey['professional'] ??
          const _CustomerCatalogPlan(
            key: 'professional',
            label: 'Professional Plan',
            basePrice: 0,
            descriptionPoints: <String>[],
          ),
    ];
  }
}

class _CustomerCatalogPlan {
  const _CustomerCatalogPlan({
    required this.key,
    required this.label,
    required this.basePrice,
    required this.descriptionPoints,
  });

  final String key;
  final String label;
  final int basePrice;
  final List<String> descriptionPoints;
}

_CustomerCatalogEventType _catalogEventFromDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();
  final plansRaw = data['pricingPlans'];
  final plans = <_CustomerCatalogPlan>[];
  if (plansRaw is Map) {
    final map = Map<String, dynamic>.from(plansRaw);
    plans.add(
      _parseCatalogPlan(
        map['basic'],
        key: 'basic',
        fallbackLabel: 'Default Plan',
      ),
    );
    plans.add(
      _parseCatalogPlan(
        map['normal'],
        key: 'normal',
        fallbackLabel: 'Normal Plan',
      ),
    );
    plans.add(
      _parseCatalogPlan(
        map['professional'],
        key: 'professional',
        fallbackLabel: 'Professional Plan',
      ),
    );
  }

  return _CustomerCatalogEventType(
    id: doc.id,
    name: (data['name'] as String? ?? '').trim(),
    plans: plans,
  );
}

_CustomerCatalogPlan _parseCatalogPlan(
  dynamic raw, {
  required String key,
  required String fallbackLabel,
}) {
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    final label = (map['label'] as String?)?.trim();
    return _CustomerCatalogPlan(
      key: key,
      label: label == null || label.isEmpty ? fallbackLabel : label,
      basePrice: _asInt(map['price']),
      descriptionPoints: _readCatalogPlanDescriptionPoints(
        map['descriptionPoints'],
      ),
    );
  }

  return _CustomerCatalogPlan(
    key: key,
    label: fallbackLabel,
    basePrice: 0,
    descriptionPoints: const <String>[],
  );
}

List<String> _readCatalogPlanDescriptionPoints(dynamic raw) {
  Iterable<String> values;
  if (raw is List) {
    values = raw.map((item) => item.toString());
  } else if (raw is String) {
    values = raw.split('\n');
  } else {
    values = const <String>[];
  }
  return values
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .take(4)
      .toList(growable: false);
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

double _asDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

import 'dart:async';
import 'dart:io';

import 'package:clicknow_version2/app/data/india_locations.dart';
import 'package:clicknow_version2/app/services/location_service.dart';
import 'package:clicknow_version2/app/services/maps_service.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/screens/professional/getx/professional_onboarding_storage.dart';
import 'package:clicknow_version2/app/services/rbac_service.dart';
import 'package:clicknow_version2/app/services/recaptcha_service.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_auth/smart_auth.dart';

class WorkingLocation {
  WorkingLocation({required this.state, required this.cities});

  final String state;
  final List<String> cities;

  Map<String, dynamic> toMap() {
    return {'state': state, 'cities': cities};
  }

  factory WorkingLocation.fromMap(Map<String, dynamic> map) {
    return WorkingLocation(
      state: map['state'] as String? ?? '',
      cities: List<String>.from(map['cities'] as List? ?? const []),
    );
  }
}

enum ServiceQuestionInputType {
  text,
  number,
  radio,
  dropdown,
}

class ServiceQuestionConfiguration {
  const ServiceQuestionConfiguration({
    required this.id,
    required this.label,
    required this.hint,
    required this.inputType,
    this.options = const <String>[],
    this.maxLength = 300,
  });

  final String id;
  final String label;
  final String hint;
  final ServiceQuestionInputType inputType;
  final List<String> options;
  final int maxLength;
}

class ProfessionalRegistrationController extends GetxController {
  static ProfessionalRegistrationController get instance => Get.find();

  final GetStorage _localStorage = GetStorage();
  static const String _profileStorageKey = 'professional_profile_data';
  static const String _draftStep1Key = 'step1';
  static const String _draftStep2Key = 'step2';
  static const String _draftStep3Key = 'step3';
  static const String _draftStep4Key = 'step4';
  static const String _draftStep5Key = 'step5';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  PlatformFile? _aadharFile;
  PlatformFile? _panFile;
  PlatformFile? _bankPassbookFile;
  static const int maxPdfSizeBytes = 5 * 1024 * 1024;

  /// -- Form Keys
  final GlobalKey<FormState> professionalRegistrationFormKey = GlobalKey<FormState>();

  /// -- Textfield Controllers
  final TextEditingController genderController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  /// -- Step 1 TextField Controllers
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  /// -- Step 2 TextField Controllers
  final TextEditingController nameController = TextEditingController();
  final List<String> genderOptions = ["Male", "Female", "Other"];
  RxString selectedGender = "".obs;
  Rx<DateTime?> selectedDob = Rx<DateTime?>(null);
  final List<String> languageOptions = [
    "English",
    "Hindi",
    "Tamil",
    "Telugu",
    "Kannada",
    "Malayalam",
    "Bengali",
    "Marathi",
  ];
  RxList<String> selectedLanguages = <String>[].obs;
  final TextEditingController permanentAddressController = TextEditingController();
  final List<String> stateOptions = IndiaLocations.states;
  final Map<String, List<String>> cityOptionsByState =
      IndiaLocations.citiesByState;
  final Map<String, List<String>> pincodeOptionsByCity = {
    "Bhopal": ["462001", "462002", "462003"],
    "Indore": ["452001", "452002", "452003"],
    "Ujjain": ["456001", "456002"],
    "Jabalpur": ["482001", "482002"],
    "Sagar": ["470001", "470002"],
    "Mumbai": ["400001", "400002", "400003"],
    "Pune": ["411001", "411002"],
    "Nagpur": ["440001", "440002"],
    "Nashik": ["422001", "422002"],
    "Lucknow": ["226001", "226002"],
    "Kanpur": ["208001", "208002"],
    "Varanasi": ["221001", "221002"],
    "Agra": ["282001", "282002"],
    "Jaipur": ["302001", "302002"],
    "Udaipur": ["313001", "313002"],
    "Jodhpur": ["342001", "342002"],
    "Kota": ["324001", "324002"],
    "Ahmedabad": ["380001", "380002"],
    "Surat": ["395001", "395002"],
    "Vadodara": ["390001", "390002"],
    "Rajkot": ["360001", "360002"],
  };
  RxString selectedState = "".obs;
  RxString selectedCity = "".obs;
  RxString selectedCountry = "".obs;
  RxString selectedPincode = "".obs;
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  static const double _defaultIndiaLatitude = 22.9734;
  static const double _defaultIndiaLongitude = 78.6569;

  final LocationService _locationService = LocationService.instance;
  final MapsService _mapsService = MapsService.instance;
  Timer? _placeSearchDebounceTimer;
  int _placeSearchRequestId = 0;
  bool _step2LocationInitialized = false;

  final RxDouble mapCenterLatitude = _defaultIndiaLatitude.obs;
  final RxDouble mapCenterLongitude = _defaultIndiaLongitude.obs;
  final RxnDouble selectedLatitude = RxnDouble();
  final RxnDouble selectedLongitude = RxnDouble();
  final RxList<PlaceSuggestion> placeSuggestions = <PlaceSuggestion>[].obs;
  final RxBool isSearchingPlaces = false.obs;
  final RxBool isResolvingAddressFromMap = false.obs;
  final RxBool isFetchingCurrentLocation = false.obs;
  final RxString step2LocationStatus = ''.obs;

  bool get isMapApiConfigured => _mapsService.isApiKeyConfigured;
  bool get hasSelectedLocation =>
      selectedLatitude.value != null &&
      selectedLongitude.value != null &&
      permanentAddressController.text.trim().isNotEmpty;

  /// -- Step 3 Working Locations
  RxBool isWorkingLocationExpanded = false.obs;
  void toggleWorkingLocation() => isWorkingLocationExpanded.toggle();

  RxString selectedWorkingState = "".obs;
  RxList<String> selectedWorkingCities = <String>[].obs;
  RxList<WorkingLocation> workingLocations = <WorkingLocation>[].obs;

  /// -- Step 5 Secondary Working Locations
  RxString selectedSecondaryWorkingState = "".obs;
  RxList<String> selectedSecondaryWorkingCities = <String>[].obs;
  RxList<WorkingLocation> secondaryWorkingLocations = <WorkingLocation>[].obs;

  /// -- Step 3 States
  RxBool isWorkExpanded = false.obs;
  RxBool isProfileExpanded = false.obs;
  RxBool isAdditionalExpanded = false.obs;

  /// -- Step 4 States
  RxBool isAadharExpanded = false.obs;
  RxBool isPanExpanded = false.obs;
  void toggleAadhar() => isAadharExpanded.toggle();
  void togglePan() => isPanExpanded.toggle();
  final TextEditingController aadharController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  RxString aadharFileName = "".obs;
  RxString panFileName = "".obs;

  /// -- Step 5 States
  RxBool isPricingExpanded = true.obs;
  RxBool isBankExpanded = false.obs;

  void togglePricing() => isPricingExpanded.toggle();
  void toggleBank() => isBankExpanded.toggle();

  final TextEditingController basePriceController = TextEditingController();
  final TextEditingController perHourController = TextEditingController();

  RxString professionalType = "Full-Time".obs;

  final List<String> teamSizeOptions = [
    "1-5 Members",
    "5-10 Members",
    "10-20 Members",
    "20+ Members",
  ];

  RxString selectedTeamSize = "".obs;

  static const String servicePhotoVideo = "Photo and Videography Services";
  static const String serviceMusic = "Music & Live Performance Services";
  static const String serviceAnchor = "Professional Anchor Services";
  static const String serviceDj = "Professional DJ Services";
  static const String serviceWeddingPainter = "Live Wedding Painter Services";
  static const String serviceMagician = "Professional Magician Services";

  static const String _questionProfessionalType = "professionalType";
  static const String _questionTeamSize = "teamSize";

  late final List<String> _defaultServiceTypeOptions = <String>[
    servicePhotoVideo,
    serviceMusic,
    serviceAnchor,
    serviceDj,
    serviceWeddingPainter,
    serviceMagician,
  ];

  final List<String> _commonProfessionalTypeOptions = const <String>[
    "Full-Time",
    "Freelancer",
  ];

  final List<String> _generalTeamSizeOptions = const <String>[
    "1-5 Members",
    "5-10 Members",
    "10-20 Members",
    "20+ Members",
  ];

  final List<String> _musicTeamSizeOptions = const <String>[
    "Solo",
    "Duo",
    "Band",
  ];

  final RxString selectedServiceType = "".obs;
  final RxList<String> selectedServiceSpecialities = <String>[].obs;
  final RxMap<String, String> serviceQuestionAnswers = <String, String>{}.obs;

  final RxList<String> serviceTypeOptions = <String>[].obs;
  final RxMap<String, List<String>> serviceSpecialityMap =
      <String, List<String>>{}.obs;

  late final Map<String, List<String>> _defaultServiceSpecialityMap = {
    servicePhotoVideo: [
      "Wedding",
      "Pre-Wedding",
      "Engagement",
      "Birthday",
      "Corporate Event",
      "Product Shoot",
      "Fashion Shoot",
      "Real Estate Shoot",
    ],
    serviceMusic: [
      "Wedding Sangeet",
      "Corporate Event",
      "Private Party",
      "Live Concert",
      "Religious Event",
      "College Fest",
    ],
    serviceAnchor: [
      "Wedding Hosting",
      "Corporate Hosting",
      "Award Show",
      "Product Launch",
      "Private Event",
      "Live Show",
    ],
    serviceDj: [
      "Wedding DJ",
      "Club DJ",
      "Corporate DJ",
      "Festival DJ",
      "Private Party DJ",
    ],
    serviceWeddingPainter: [
      "Live Couple Portrait",
      "Ceremony Live Painting",
      "Reception Live Painting",
      "Family Live Portrait",
    ],
    serviceMagician: [
      "Stage Magic",
      "Close-Up Magic",
      "Kids Magic Show",
      "Corporate Magic Show",
      "Wedding Magic Show",
    ],
  };

  late final Map<String, List<ServiceQuestionConfiguration>>
      serviceQuestionMap = {
    servicePhotoVideo: <ServiceQuestionConfiguration>[
      _professionalTypeQuestion(),
      _teamSizeQuestion(),
      const ServiceQuestionConfiguration(
        id: "cameraOwned",
        label: "What camera(s) do you own?",
        hint: "List the camera equipment you own.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "lensesOwned",
        label: "What lenses do you own?",
        hint: "List the lenses equipment you use.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "lightingEquipment",
        label: "Do you own lighting equipment?",
        hint: "If yes, list the lighting equipment you have.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "droneOwned",
        label: "Do you own a drone?",
        hint: "If yes, list the drone equipment you have.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "editingSoftware",
        label: "What editing software do you use?",
        hint: "List the software you use for editing.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "hourlyPrice",
        label: "What is your hourly price?",
        hint: "Enter hourly price (Rs.)",
        inputType: ServiceQuestionInputType.number,
      ),
      const ServiceQuestionConfiguration(
        id: "packagePricePerEvent",
        label: "What is your package price per event?",
        hint: "Enter package price (Rs.)",
        inputType: ServiceQuestionInputType.number,
      ),
    ],
    serviceMusic: <ServiceQuestionConfiguration>[
      _professionalTypeQuestion(),
      _teamSizeQuestion(label: "What is your team size (solo/duo/band)?"),
      const ServiceQuestionConfiguration(
        id: "instrumentsOwned",
        label: "What instrument(s) do you own?",
        hint: "List your instruments.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "microphoneOwned",
        label: "Do you have your own microphone?",
        hint: "Share details of your microphone setup.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "amplifierSoundGear",
        label: "Do you have your own amplifier or sound gear?",
        hint: "Share details of your sound gear.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "performanceGenres",
        label: "What genres do you perform in?",
        hint: "List music genres you perform in.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "hourlyPrice",
        label: "What is your hourly price?",
        hint: "Enter hourly price (Rs.)",
        inputType: ServiceQuestionInputType.number,
      ),
      const ServiceQuestionConfiguration(
        id: "packagePricePerEvent",
        label: "What is your package price per event?",
        hint: "Enter package price (Rs.)",
        inputType: ServiceQuestionInputType.number,
      ),
    ],
    serviceAnchor: <ServiceQuestionConfiguration>[
      _professionalTypeQuestion(),
      _teamSizeQuestion(),
      const ServiceQuestionConfiguration(
        id: "eventTypesHosted",
        label: "What types of events have you hosted?",
        hint: "List event types you have hosted.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "anchorLanguages",
        label: "What languages can you anchor in?",
        hint: "List the languages.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "scriptFlowCreation",
        label: "Do you create your own event script/flow?",
        hint: "Share your approach.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "micHeadsetOwned",
        label: "Do you have your own mic/headset?",
        hint: "Share your mic/headset details.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "hostingVideos",
        label: "Do you have sample hosting videos?",
        hint: "Share sample video details or links.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "hourlyPrice",
        label: "What is your hourly price?",
        hint: "Enter hourly price (Rs.)",
        inputType: ServiceQuestionInputType.number,
      ),
      const ServiceQuestionConfiguration(
        id: "packagePricePerEvent",
        label: "What is your package price per event?",
        hint: "Enter package price (Rs.)",
        inputType: ServiceQuestionInputType.number,
      ),
    ],
    serviceDj: <ServiceQuestionConfiguration>[
      _professionalTypeQuestion(),
      _teamSizeQuestion(),
      const ServiceQuestionConfiguration(
        id: "djConsole",
        label: "What DJ console do you use?",
        hint: "Enter your DJ console details.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "speakersSystemOwned",
        label: "Do you own speakers or a sound system?",
        hint: "Share your sound system details.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "djGenres",
        label: "What genres do you specialize in?",
        hint: "List genres you specialize in.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "djSoftware",
        label: "What DJ software do you use?",
        hint: "List DJ software used.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "lightingEffectsOwned",
        label: "Do you bring your own lighting effects?",
        hint: "Share lighting setup details.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "hourlyPrice",
        label: "What is your hourly price?",
        hint: "Enter hourly price (Rs.)",
        inputType: ServiceQuestionInputType.number,
      ),
      const ServiceQuestionConfiguration(
        id: "packagePricePerEvent",
        label: "What is your package price per event?",
        hint: "Enter package price (Rs.)",
        inputType: ServiceQuestionInputType.number,
      ),
    ],
    serviceWeddingPainter: <ServiceQuestionConfiguration>[
      _professionalTypeQuestion(),
      _teamSizeQuestion(),
      const ServiceQuestionConfiguration(
        id: "canvasSizes",
        label: "What canvas sizes do you offer?",
        hint: "List canvas sizes offered.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "paintingStyle",
        label: "What painting style do you specialize in?",
        hint: "Describe your style specialization.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "materialsTools",
        label: "What materials/tools do you bring?",
        hint: "List materials and tools.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "portraitDuration",
        label: "How long does one portrait take?",
        hint: "Enter average time per portrait.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "sameDayDelivery",
        label: "Do you deliver the artwork on the same day?",
        hint: "Share your delivery timeline.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "portraitPrice",
        label: "What is your price per portrait?",
        hint: "Enter price per portrait (Rs.)",
        inputType: ServiceQuestionInputType.number,
      ),
    ],
    serviceMagician: <ServiceQuestionConfiguration>[
      _professionalTypeQuestion(),
      _teamSizeQuestion(),
      const ServiceQuestionConfiguration(
        id: "magicType",
        label: "What type of magic do you perform (stage/close-up)?",
        hint: "Describe your magic style.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "propsEquipment",
        label: "What props/equipment do you bring?",
        hint: "List props and equipment.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "showDuration",
        label: "What is your show duration?",
        hint: "Enter show duration details.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "interactiveMagic",
        label: "Do you offer interactive magic for guests?",
        hint: "Describe interactive segments.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "showVideos",
        label: "Do you have videos of previous shows?",
        hint: "Share sample video details or links.",
        inputType: ServiceQuestionInputType.text,
      ),
      const ServiceQuestionConfiguration(
        id: "showPrice",
        label: "What is your total price for the show?",
        hint: "Enter total show price (Rs.)",
        inputType: ServiceQuestionInputType.number,
      ),
    ],
  };

  /// Toggles
  RxBool urgentAvailable = false.obs;
  RxBool willingToTravel = false.obs;
  RxBool cancellationAccepted = false.obs;
  RxBool commissionAccepted = false.obs;

  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController upiController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController branchNameController = TextEditingController();
  final TextEditingController ifscController = TextEditingController();

  RxString bankPassbookFileName = "".obs;

  Future<void> pickBankPassbook() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      if (file.path == null && file.bytes == null) {
        AppSnackbar.error("File Error", "Unable to read selected file.");
        return;
      }
      if (file.size <= 0 || file.size > maxPdfSizeBytes) {
        AppSnackbar.error(
          "Invalid File",
          "Please upload a PDF up to 5 MB.",
        );
        return;
      }
      _bankPassbookFile = file;
      bankPassbookFileName.value = file.name;
    }
  }

  Future<void> pickAadharFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      if (file.path == null && file.bytes == null) {
        AppSnackbar.error("File Error", "Unable to read selected file.");
        return;
      }
      if (file.size <= 0 || file.size > maxPdfSizeBytes) {
        AppSnackbar.error(
          "Invalid File",
          "Please upload a PDF up to 5 MB.",
        );
        return;
      }
      _aadharFile = file;
      aadharFileName.value = file.name;
    }
  }

  Future<void> pickPanFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      if (file.path == null && file.bytes == null) {
        AppSnackbar.error("File Error", "Unable to read selected file.");
        return;
      }
      if (file.size <= 0 || file.size > maxPdfSizeBytes) {
        AppSnackbar.error(
          "Invalid File",
          "Please upload a PDF up to 5 MB.",
        );
        return;
      }
      _panFile = file;
      panFileName.value = file.name;
    }
  }

  /// Toggle Sections
  void toggleWork() {
    isWorkExpanded.toggle();
  }

  void toggleProfile() {
    isProfileExpanded.toggle();
  }

  void toggleAdditional() {
    isAdditionalExpanded.toggle();
  }

  /// Work Information
  final TextEditingController workCityController = TextEditingController();
  final TextEditingController shortBioController = TextEditingController();
  final List<String> experienceOptions = List.generate(
    11,
    (index) => "$index Years",
  );
  RxString selectedExperience = "".obs;

  final List<String> workingDaysOptions = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  RxList<String> selectedWorkingDays = <String>[].obs;

  void toggleWorkingDay(String day) {
    if (selectedWorkingDays.contains(day)) {
      selectedWorkingDays.remove(day);
    } else {
      selectedWorkingDays.add(day);
    }
  }

  /// Profile Links
  final TextEditingController googleDriveController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();

  /// Additional Details
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController clientExperienceController =
      TextEditingController();
  final TextEditingController awardsController = TextEditingController();

  /// Toggle Language Selection
  void toggleLanguage(String language) {
    if (selectedLanguages.contains(language)) {
      selectedLanguages.remove(language);
    } else {
      selectedLanguages.add(language);
    }
  }

  ServiceQuestionConfiguration _professionalTypeQuestion() {
    return ServiceQuestionConfiguration(
      id: _questionProfessionalType,
      label: "Are you a full-time professional or a freelancer?",
      hint: "",
      inputType: ServiceQuestionInputType.radio,
      options: _commonProfessionalTypeOptions,
    );
  }

  ServiceQuestionConfiguration _teamSizeQuestion({
    String label = "What is your team size?",
  }) {
    return ServiceQuestionConfiguration(
      id: _questionTeamSize,
      label: label,
      hint: "Select Team Size",
      inputType: ServiceQuestionInputType.dropdown,
      options: label.contains("solo/duo/band")
          ? _musicTeamSizeOptions
          : _generalTeamSizeOptions,
    );
  }

  List<String> get currentServiceSpecialityOptions =>
      serviceSpecialityMap[selectedServiceType.value] ??
      _defaultServiceSpecialityMap[_resolveServiceQuestionKey(
            selectedServiceType.value,
          )] ??
      <String>[];

  List<ServiceQuestionConfiguration> get activeServiceQuestions =>
      (serviceQuestionMap[_resolveServiceQuestionKey(selectedServiceType.value)] ??
              <ServiceQuestionConfiguration>[])
          .where(
            (question) => !const {
              'hourlyPrice',
              'packagePrice',
              'packagePricePerEvent',
            }.contains(question.id),
          )
          .toList(growable: false);

  void onServiceTypeChanged(String? value) {
    final next = value ?? "";
    if (selectedServiceType.value == next) {
      return;
    }
    selectedServiceType.value = next;
    selectedServiceSpecialities.clear();
    serviceQuestionAnswers.clear();
  }

  void onServiceSpecialitySelection(List<String> values) {
    selectedServiceSpecialities.assignAll(values);
  }

  void _applyDefaultServiceCatalog() {
    serviceTypeOptions.assignAll(_defaultServiceTypeOptions);
    serviceSpecialityMap.assignAll(
      _defaultServiceSpecialityMap.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
    );
    _sanitizeSelectedServiceData();
  }

  void _listenServiceCatalog() {
    _serviceCatalogSub?.cancel();
    _serviceCatalogSub = _db
        .collection(ServiceCatalogPaths.servicesCollection)
        .snapshots()
        .listen(
          (snapshot) {
            _applyServiceCatalogSnapshot(snapshot.docs);
          },
          onError: (_) {
            _applyDefaultServiceCatalog();
          },
        );
  }

  void _applyServiceCatalogSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final parsed = docs
        .map((doc) {
          final data = doc.data();
          final name = (data['name'] as String? ?? '').trim();
          final active = (data['isActive'] as bool?) ?? true;
          final sortOrderRaw = data['sortOrder'];
          final sortOrder = sortOrderRaw is int
              ? sortOrderRaw
              : int.tryParse('$sortOrderRaw') ?? 999;
          final events = _readStringList(data['activeEventTypeNames']);
          final hasEventsField = data.containsKey('activeEventTypeNames');
          return (
            name: name,
            active: active,
            sortOrder: sortOrder,
            events: events,
            hasEventsField: hasEventsField,
          );
        })
        .where((item) => item.active && item.name.isNotEmpty)
        .toList(growable: false)
      ..sort((left, right) {
          final sortCompare = left.sortOrder.compareTo(right.sortOrder);
          if (sortCompare != 0) {
            return sortCompare;
          }
          return left.name.toLowerCase().compareTo(right.name.toLowerCase());
        });

    if (parsed.isEmpty) {
      _applyDefaultServiceCatalog();
      return;
    }

    final nextTypes = <String>[];
    final nextSpecialities = <String, List<String>>{};
    for (final item in parsed) {
      nextTypes.add(item.name);
      if (item.events.isNotEmpty) {
        nextSpecialities[item.name] = item.events;
      } else if (item.hasEventsField) {
        nextSpecialities[item.name] = <String>[];
      } else {
        nextSpecialities[item.name] = _defaultServiceSpecialityMap[
                _resolveServiceQuestionKey(item.name)] ??
            <String>[];
      }
    }

    serviceTypeOptions.assignAll(nextTypes);
    serviceSpecialityMap.assignAll(nextSpecialities);
    _sanitizeSelectedServiceData();
  }

  void _sanitizeSelectedServiceData() {
    if (selectedServiceType.value.isEmpty) {
      return;
    }
    if (!serviceTypeOptions.contains(selectedServiceType.value)) {
      selectedServiceType.value = '';
      selectedServiceSpecialities.clear();
      serviceQuestionAnswers.clear();
      return;
    }
    final available = currentServiceSpecialityOptions;
    selectedServiceSpecialities.assignAll(
      selectedServiceSpecialities
          .where((item) => available.contains(item))
          .toList(growable: false),
    );
  }

  String _resolveServiceQuestionKey(String serviceName) {
    final normalized = serviceName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalized.contains('photo') && normalized.contains('video')) {
      return servicePhotoVideo;
    }
    if (normalized.contains('music') && normalized.contains('live')) {
      return serviceMusic;
    }
    if (normalized.contains('anchor')) {
      return serviceAnchor;
    }
    if (normalized.contains('dj')) {
      return serviceDj;
    }
    if (normalized.contains('painter')) {
      return serviceWeddingPainter;
    }
    if (normalized.contains('magician')) {
      return serviceMagician;
    }
    return serviceName;
  }

  String getServiceQuestionAnswer(String questionId) {
    return serviceQuestionAnswers[questionId] ?? "";
  }

  void setServiceQuestionAnswer(String questionId, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      serviceQuestionAnswers.remove(questionId);
      return;
    }
    serviceQuestionAnswers[questionId] = trimmed;
  }

  List<String> get currentCityOptions =>
      cityOptionsByState[selectedState.value] ?? [];

  List<String> get currentPincodeOptions =>
      pincodeOptionsByCity[selectedCity.value] ?? [];

  Future<void> initializeStep2Location() async {
    if (_step2LocationInitialized) {
      return;
    }
    _step2LocationInitialized = true;

    _syncAddressControllersToRx();

    if (selectedLatitude.value != null && selectedLongitude.value != null) {
      mapCenterLatitude.value = selectedLatitude.value!;
      mapCenterLongitude.value = selectedLongitude.value!;
      return;
    }

    final fallbackHasAddress = permanentAddressController.text.trim().isNotEmpty;
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

    _placeSearchDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
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
    });
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
      await persistStep2Draft();
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
        permanentAddressController.text =
            'Pinned location (${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)})';
        selectedState.value = '';
        selectedCity.value = '';
        selectedCountry.value = '';
        selectedPincode.value = '';
        stateController.clear();
        cityController.clear();
        pincodeController.clear();
      }
      await persistStep2Draft();
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
    unawaited(persistStep2Draft());
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
      await persistStep2Draft();
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

    permanentAddressController.text = selection.formattedAddress;
    selectedState.value = selection.state.trim();
    selectedCity.value = selection.city.trim();
    selectedCountry.value = selection.country.trim();
    selectedPincode.value = selection.pincode.trim();

    stateController.text = selectedState.value;
    cityController.text = selectedCity.value;
    pincodeController.text = selectedPincode.value;
    placeSuggestions.clear();
  }

  void _syncAddressControllersToRx() {
    selectedState.value = stateController.text.trim().isEmpty
        ? selectedState.value
        : stateController.text.trim();
    selectedCity.value = cityController.text.trim().isEmpty
        ? selectedCity.value
        : cityController.text.trim();
    selectedCountry.value = selectedCountry.value.trim();
    selectedPincode.value = pincodeController.text.trim().isEmpty
        ? selectedPincode.value
        : pincodeController.text.trim();
    stateController.text = selectedState.value;
    cityController.text = selectedCity.value;
    pincodeController.text = selectedPincode.value;
  }

  void onStateChanged(String? value) {
    selectedState.value = value ?? "";
    stateController.text = selectedState.value;
    selectedCity.value = "";
    cityController.clear();
    selectedPincode.value = "";
    pincodeController.clear();
  }

  void onCityChanged(String? value) {
    selectedCity.value = value ?? "";
    cityController.text = selectedCity.value;
    selectedPincode.value = "";
    pincodeController.clear();
  }

  List<String> get currentWorkingCityOptions =>
      cityOptionsByState[selectedWorkingState.value] ?? [];

  void onWorkingStateChanged(String? value) {
    selectedWorkingState.value = value ?? "";
    selectedWorkingCities.clear();
  }

  void toggleWorkingCity(String city) {
    if (selectedWorkingCities.contains(city)) {
      selectedWorkingCities.remove(city);
    } else {
      selectedWorkingCities.add(city);
    }
  }

  bool saveWorkingLocation({bool clearAfter = false}) {
    if (selectedWorkingState.value.isEmpty) {
      AppSnackbar.error("Required", "Please select working state.");
      return false;
    }
    if (selectedWorkingCities.isEmpty) {
      AppSnackbar.error("Required", "Please select at least one working city.");
      return false;
    }

    final existingIndex = workingLocations.indexWhere(
      (loc) => loc.state == selectedWorkingState.value,
    );
    if (existingIndex >= 0) {
      final current = workingLocations[existingIndex];
      final merged = {...current.cities, ...selectedWorkingCities}.toList();
      workingLocations[existingIndex] = WorkingLocation(
        state: current.state,
        cities: merged,
      );
    } else {
      workingLocations.add(
        WorkingLocation(
          state: selectedWorkingState.value,
          cities: List<String>.from(selectedWorkingCities),
        ),
      );
    }

    if (clearAfter) {
      selectedWorkingState.value = "";
      selectedWorkingCities.clear();
    }
    return true;
  }

  void addMoreWorkingLocation() {
    saveWorkingLocation(clearAfter: true);
  }

  List<String> get currentSecondaryWorkingCityOptions =>
      cityOptionsByState[selectedSecondaryWorkingState.value] ?? [];

  void onSecondaryWorkingStateChanged(String? value) {
    selectedSecondaryWorkingState.value = value ?? "";
    selectedSecondaryWorkingCities.clear();
  }

  bool saveSecondaryWorkingLocation({bool clearAfter = false}) {
    if (selectedSecondaryWorkingState.value.isEmpty) {
      AppSnackbar.error("Required", "Please select working state.");
      return false;
    }
    if (selectedSecondaryWorkingCities.isEmpty) {
      AppSnackbar.error("Required", "Please select at least one working city.");
      return false;
    }

    final existingIndex = secondaryWorkingLocations.indexWhere(
      (loc) => loc.state == selectedSecondaryWorkingState.value,
    );
    if (existingIndex >= 0) {
      final current = secondaryWorkingLocations[existingIndex];
      final merged = {
        ...current.cities,
        ...selectedSecondaryWorkingCities,
      }.toList();
      secondaryWorkingLocations[existingIndex] = WorkingLocation(
        state: current.state,
        cities: merged,
      );
    } else {
      secondaryWorkingLocations.add(
        WorkingLocation(
          state: selectedSecondaryWorkingState.value,
          cities: List<String>.from(selectedSecondaryWorkingCities),
        ),
      );
    }

    if (clearAfter = true) {
      selectedSecondaryWorkingState.value = "";
      selectedSecondaryWorkingCities.clear();
    }
    return true;
  }

  void addMoreSecondaryWorkingLocation() {
    saveSecondaryWorkingLocation(clearAfter: true);
  }

  /// -- Reactive States
  RxBool isOtpSent = false.obs;
  RxBool isPhoneVerified = false.obs;
  RxInt secondsRemaining = 60.obs;
  RxBool canResendOtp = false.obs;
  RxInt failedOtpAttempts = 0.obs;
  RxInt otpLockSecondsRemaining = 0.obs;
  RxBool isLoading = false.obs;
  RxBool isSubmittingProfile = false.obs;
  RxDouble uploadProgress = 0.0.obs;
  RxString uploadProgressLabel = "Preparing upload...".obs;
  RxBool isDraftLoaded = false.obs;

  Timer? _timer;
  Timer? _otpLockTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _serviceCatalogSub;
  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _confirmationResult;
  int _otpListenEpoch = 0;
  bool _phoneAuthSettingsConfigured = false;
  bool get isOtpLocked => otpLockSecondsRemaining.value > 0;
  String get resendCountdown => _formatCountdown(secondsRemaining.value);
  String get otpLockCountdown => _formatCountdown(otpLockSecondsRemaining.value);

  Duration get _firebasePhoneAutoRetrievalTimeout {
    if (kIsWeb) {
      return const Duration(seconds: 60);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Defensive: avoid Firebase internal SmsRetriever crash path on some devices.
      return const Duration(seconds: 0);
    }
    return const Duration(seconds: 60);
  }

  /// -- Request OTP via API
  void requestOtp() async {
    if (phoneController.text.length != 10) {
      AppSnackbar.error("Error", "Enter valid 10-digit phone number");
      return;
    }

    final phoneNumber = RbacService.normalizePhone(
      "+91${phoneController.text.trim()}",
    );
    final isDuplicateProfessional =
        await _isPhoneAlreadyRegisteredAsProfessional(phoneNumber);
    if (isDuplicateProfessional) {
      AppSnackbar.error(
        "Already Registered",
        "User already registered with the number $phoneNumber",
      );
      return;
    }
    isLoading.value = true;
    try {
      await _configurePhoneAuthSettings();
      if (kIsWeb) {
        final verifier = RecaptchaService.getVerifier(_auth);
        _confirmationResult = await _auth.signInWithPhoneNumber(
          phoneNumber,
          verifier,
        );
        isOtpSent.value = true;
        isPhoneVerified.value = false;
        startTimer();
        unawaited(
          persistStep1Draft(
            otpRequestedOverride: true,
            phoneVerifiedOverride: false,
          ),
        );
        AppSnackbar.success("OTP Sent", "OTP has been sent to your phone.");
        return;
      }
      final timeout = _firebasePhoneAutoRetrievalTimeout;
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: timeout,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _handlePhoneCredential(credential, phoneNumber);
          } catch (e) {
            debugPrint('Professional auto OTP verify callback failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          AppSnackbar.error(
            "OTP Failed",
            e.message ?? "Could not send OTP. Please try again.",
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          otpController.clear();
          isOtpSent.value = true;
          isPhoneVerified.value = false;
          startTimer();
          _startOtpAutoFillListener();
          unawaited(
            persistStep1Draft(
              otpRequestedOverride: true,
              phoneVerifiedOverride: false,
            ),
          );
          AppSnackbar.success("OTP Sent", "OTP has been sent to your phone.");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (timeout.inSeconds > 0 &&
              isOtpSent.value &&
              !isPhoneVerified.value) {
            AppSnackbar.info(
              "Auto-read unavailable",
              "Enter OTP manually or tap resend if needed.",
            );
          }
        },
      );
    } on FirebaseAuthException catch (e) {
      AppSnackbar.error(
        "OTP Failed",
        e.message ?? "Could not send OTP. Please try again.",
      );
    } catch (e) {
      debugPrint('Professional verifyPhoneNumber failed: $e');
      AppSnackbar.error(
        "OTP Failed",
        "Could not send OTP. Please try again.",
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _isPhoneAlreadyRegisteredAsProfessional(
    String normalizedPhone,
  ) async {
    final usersSnapshot = await _db
        .collection('users')
        .where('phoneNumber', isEqualTo: normalizedPhone)
        .limit(20)
        .get();
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final role = '${data['role'] ?? ''}'.trim().toLowerCase();
      final rbacRole = '${data['rbacRole'] ?? ''}'.trim().toLowerCase();
      final isProfessionalRecord =
          role == 'professional' ||
          role == 'professional_pending' ||
          rbacRole == 'professional' ||
          data['isProfessionalOnboarded'] == true ||
          data['hasProfessionalProfile'] == true;
      if (isProfessionalRecord) {
        return true;
      }
    }

    final profileSnapshot = await _db
        .collection('professional_profiles')
        .where('phoneNumber', isEqualTo: normalizedPhone)
        .limit(1)
        .get();
    return profileSnapshot.docs.isNotEmpty;
  }

  /// -- Verify OTP via API
  void verifyOtp() async {
    if (isOtpLocked || isLoading.value) {
      return;
    }
    if (otpController.text.length != 6) {
      AppSnackbar.error("Error", "Enter valid 6-digit OTP");
      return;
    }
    if (kIsWeb) {
      if (_confirmationResult == null) {
        AppSnackbar.error("Error", "Please request OTP first.");
        return;
      }
      isLoading.value = true;
      try {
        final userCredential =
            await _confirmationResult!.confirm(otpController.text.trim());
        RecaptchaService.markVerified();
        await _handleSignedInUser(
          userCredential.user,
          "+91${phoneController.text.trim()}",
        );
      } on FirebaseAuthException catch (e) {
        _recordOtpFailure(e);
        AppSnackbar.error(
          "Verification Failed",
          e.message ?? "Invalid OTP. Please try again.",
        );
      } finally {
        isLoading.value = false;
      }
      return;
    }
    if (_verificationId == null) {
      AppSnackbar.error("Error", "Please request OTP first.");
      return;
    }

    isLoading.value = true;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpController.text.trim(),
      );
      await _handlePhoneCredential(
        credential,
        "+91${phoneController.text.trim()}",
      );
    } on FirebaseAuthException catch (e) {
      _recordOtpFailure(e);
      AppSnackbar.error(
        "Verification Failed",
        e.message ?? "Invalid OTP. Please try again.",
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// -- Start Timer
  void startTimer() {
    secondsRemaining.value = 120;
    canResendOtp.value = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        canResendOtp.value = true;
        timer.cancel();
      }
    });
  }

  /// -- Resend OTP via API
  void resendOtp() async {
    if (!canResendOtp.value || isOtpLocked || isLoading.value) return;
    if (phoneController.text.length != 10) {
      AppSnackbar.error("Error", "Enter valid 10-digit phone number");
      return;
    }

    final phoneNumber = RbacService.normalizePhone(
      "+91${phoneController.text.trim()}",
    );
    isLoading.value = true;
    try {
      await _configurePhoneAuthSettings();
      if (kIsWeb) {
        final verifier = RecaptchaService.getVerifier(_auth);
        _confirmationResult = await _auth.signInWithPhoneNumber(
          phoneNumber,
          verifier,
        );
        startTimer();
        unawaited(
          persistStep1Draft(
            otpRequestedOverride: true,
            phoneVerifiedOverride: false,
          ),
        );
        AppSnackbar.success("OTP Resent", "A new OTP has been sent.");
        return;
      }
      final timeout = _firebasePhoneAutoRetrievalTimeout;
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: timeout,
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _handlePhoneCredential(credential, phoneNumber);
          } catch (e) {
            debugPrint(
              'Professional auto OTP verify callback failed on resend: $e',
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          AppSnackbar.error(
            "OTP Failed",
            e.message ?? "Could not resend OTP.",
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          otpController.clear();
          startTimer();
          _startOtpAutoFillListener();
          unawaited(
            persistStep1Draft(
              otpRequestedOverride: true,
              phoneVerifiedOverride: false,
            ),
          );
          AppSnackbar.success("OTP Resent", "A new OTP has been sent.");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (timeout.inSeconds > 0 &&
              isOtpSent.value &&
              !isPhoneVerified.value) {
            AppSnackbar.info(
              "Auto-read unavailable",
              "Enter OTP manually or tap resend if needed.",
            );
          }
        },
      );
    } on FirebaseAuthException catch (e) {
      AppSnackbar.error(
        "OTP Failed",
        e.message ?? "Could not resend OTP.",
      );
    } catch (e) {
      debugPrint('Professional resend verifyPhoneNumber failed: $e');
      AppSnackbar.error(
        "OTP Failed",
        "Could not resend OTP.",
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> enablePhoneNumberEdit() async {
    if (isLoading.value) {
      return;
    }
    isOtpSent.value = false;
    isPhoneVerified.value = false;
    otpController.clear();
    _verificationId = null;
    _resendToken = null;
    _confirmationResult = null;
    _stopOtpAutoFillListener();
    _timer?.cancel();
    secondsRemaining.value = 0;
    canResendOtp.value = false;
    await persistStep1Draft(
      otpRequestedOverride: false,
      phoneVerifiedOverride: false,
    );
    AppSnackbar.info(
      "Update Number",
      "You can now edit your number and request a new OTP.",
    );
  }

  void _recordOtpFailure(FirebaseAuthException error) {
    if (!const {
      'invalid-verification-code',
      'invalid-verification-id',
      'session-expired',
    }.contains(error.code)) {
      return;
    }
    failedOtpAttempts.value++;
    if (failedOtpAttempts.value < 5) return;
    _otpLockTimer?.cancel();
    otpLockSecondsRemaining.value = 600;
    _otpLockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpLockSecondsRemaining.value <= 1) {
        timer.cancel();
        otpLockSecondsRemaining.value = 0;
        failedOtpAttempts.value = 0;
      } else {
        otpLockSecondsRemaining.value--;
      }
    });
    AppSnackbar.error(
      "OTP Locked",
      "Too many incorrect attempts. Please try again after 10 minutes.",
    );
  }

  String _formatCountdown(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }

  Future<void> _handlePhoneCredential(
    PhoneAuthCredential credential,
    String phoneNumber,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      await _handleSignedInUser(userCredential.user, phoneNumber);
    } on FirebaseAuthException catch (e) {
      _recordOtpFailure(e);
      AppSnackbar.error(
        "Verification Failed",
        e.message ?? "Unable to verify phone number.",
      );
    }
  }

  Future<void> _handleSignedInUser(User? user, String phoneNumber) async {
    if (user == null) {
      AppSnackbar.error("Login Failed", "Unable to verify phone number.");
      return;
    }

    await _upsertUser(user, phoneNumber, status: 'phone_verified');
    failedOtpAttempts.value = 0;
    otpLockSecondsRemaining.value = 0;
    _otpLockTimer?.cancel();
    _localStorage.write(AuthController.hideGuestCtaStorageKey, true);
    _localStorage.write(AuthController.hideProfessionalCtaStorageKey, true);
    isPhoneVerified.value = true;
    isOtpSent.value = false;
    _confirmationResult = null;
    _stopOtpAutoFillListener();
    _timer?.cancel();
    _otpLockTimer?.cancel();
    canResendOtp.value = true;
    secondsRemaining.value = 0;
    await persistStep1Draft(
      otpRequestedOverride: false,
      phoneVerifiedOverride: true,
    );
    AppSnackbar.success("Verified", "Phone number verified successfully.");
  }

  void _attemptOtpAutofill(String rawOtp) {
    if (isClosed || rawOtp.trim().isEmpty) {
      return;
    }
    final digits = rawOtp.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 6 || !isOtpSent.value || isPhoneVerified.value) {
      return;
    }
    otpController.text = digits.substring(0, 6);
    if (!isLoading.value) {
      verifyOtp();
    }
  }

  void _startOtpAutoFillListener() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final listenEpoch = ++_otpListenEpoch;
    unawaited(_logSmsRetrieverSignatureForDebug());
    unawaited(_listenWithRetrieverApi(listenEpoch));
    unawaited(_listenWithUserConsentApi(listenEpoch));
  }

  bool _isOtpAutoFillSessionActive(int epoch) {
    return epoch == _otpListenEpoch && isOtpSent.value && !isPhoneVerified.value;
  }

  Future<void> _listenWithRetrieverApi(int epoch) async {
    try {
      final result = await SmartAuth.instance.getSmsWithRetrieverApi(
        matcher: r'\d{6}',
      );
      if (!_isOtpAutoFillSessionActive(epoch) || !result.hasData) {
        return;
      }
      _attemptOtpAutofill(result.data?.code?.trim() ?? '');
    } catch (_) {}
  }

  Future<void> _listenWithUserConsentApi(int epoch) async {
    try {
      final result = await SmartAuth.instance.getSmsWithUserConsentApi(
        matcher: r'\d{6}',
      );
      if (!_isOtpAutoFillSessionActive(epoch) || !result.hasData) {
        return;
      }
      _attemptOtpAutofill(result.data?.code?.trim() ?? '');
    } catch (_) {}
  }

  Future<void> _logSmsRetrieverSignatureForDebug() async {
    if (kReleaseMode) {
      return;
    }
    try {
      final result = await SmartAuth.instance.getAppSignature();
      final signature = result.data;
      if (signature != null && signature.isNotEmpty) {
        debugPrint('Professional SMS Retriever app signature: $signature');
      }
    } catch (e) {
      debugPrint('Unable to read professional SMS app signature: $e');
    }
  }

  void _stopOtpAutoFillListener() {
    _otpListenEpoch++;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    unawaited(SmartAuth.instance.removeSmsRetrieverApiListener());
    unawaited(SmartAuth.instance.removeUserConsentApiListener());
  }

  Future<void> _upsertUser(
    User user,
    String phoneNumber, {
    required String status,
  }) async {
    final doc = _db.collection('users').doc(user.uid);
    final snapshot = await doc.get();
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'uid': user.uid,
      'phoneNumber': phoneNumber,
      'role': 'professional_pending',
      'rbacRole': 'professional',
      'approvalStatus': 'pending',
      'isProfessionalOnboarded': true,
      'hasProfessionalProfile': false,
      'professionalStatus': status,
      'lastLoginAt': now,
    };
    if (!snapshot.exists) {
      data['createdAt'] = now;
    }
    await doc.set(data, SetOptions(merge: true));
  }

  /// -- Step Validations
  bool validateStep1() {
    if (!isPhoneVerified.value) {
      AppSnackbar.error(
        "Verification required",
        "Please verify your phone number to continue.",
      );
      return false;
    }
    return true;
  }

  bool validateStep2() {
    final fullName = nameController.text.trim();
    if (fullName.isEmpty) {
      AppSnackbar.error("Required", "Please enter your full name.");
      return false;
    }
    if (!RegExp(r'^[a-zA-Z ]{2,}$').hasMatch(fullName)) {
      AppSnackbar.error("Invalid Value", "Please enter a valid full name.");
      return false;
    }
    if (selectedGender.value.isEmpty) {
      AppSnackbar.error("Required", "Please select gender.");
      return false;
    }
    if (selectedDob.value == null) {
      AppSnackbar.error("Required", "Please select date of birth.");
      return false;
    }
    final dob = selectedDob.value!;
    final today = DateTime.now();
    final age =
        today.year - dob.year - ((today.month < dob.month || (today.month == dob.month && today.day < dob.day)) ? 1 : 0);
    if (age < 18) {
      AppSnackbar.error("Invalid Age", "You must be at least 18 years old.");
      return false;
    }
    if (permanentAddressController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please enter your permanent address.");
      return false;
    }
    if (selectedLatitude.value == null || selectedLongitude.value == null) {
      AppSnackbar.error(
        "Location Required",
        "Please select your location on map.",
      );
      return false;
    }

    if (selectedLanguages.isEmpty) {
      AppSnackbar.error("Required", "Please select at least one language.");
      return false;
    }
    return true;
  }

  Future<void> saveStep2ProfileToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await _upsertProfessionalProfileDocument(user.uid);
    } catch (_) {
      AppSnackbar.error(
        "Draft Save Failed",
        "Unable to sync Step 2 data right now. It will retry on final submit.",
      );
    }
  }

  Future<void> _upsertProfessionalProfileDocument(String uid) async {
    await _db.collection('professionals').doc(uid).set({
      'uid': uid,
      'profile': _buildStep2ProfilePayload(),
      'profile.address.state': FieldValue.delete(),
      'profile.address.city': FieldValue.delete(),
      'profile.address.pincode': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Map<String, dynamic> _buildStep2ProfilePayload() {
    return <String, dynamic>{
      'fullName': nameController.text.trim(),
      'gender': selectedGender.value,
      'dob': selectedDob.value?.toIso8601String() ?? '',
      'languages': selectedLanguages.toList(),
      'address': <String, dynamic>{
        'formattedAddress': permanentAddressController.text.trim(),
        'latitude': selectedLatitude.value ?? 0.0,
        'longitude': selectedLongitude.value ?? 0.0,
      },
    };
  }

  bool validateStep3() {
    if (selectedExperience.value.isEmpty) {
      AppSnackbar.error("Required", "Please select years of experience.");
      return false;
    }
    if (selectedWorkingDays.isEmpty) {
      AppSnackbar.error("Required", "Please select available working days.");
      return false;
    }
    if (shortBioController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please add a short bio.");
      return false;
    }
    if (workingLocations.isEmpty) {
      AppSnackbar.error(
        "Required",
        "Please add at least one working location.",
      );
      return false;
    }
    if (googleDriveController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please enter Google Work Drive URL.");
      return false;
    }
    if (!_isValidUrl(googleDriveController.text.trim())) {
      AppSnackbar.error("Invalid Value", "Please enter a valid Google Drive URL.");
      return false;
    }
    if (instagramController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please enter Instagram profile URL.");
      return false;
    }
    if (!_isValidUrl(instagramController.text.trim())) {
      AppSnackbar.error("Invalid Value", "Please enter a valid Instagram URL.");
      return false;
    }
    if (websiteController.text.trim().isNotEmpty &&
        !_isValidUrl(websiteController.text.trim())) {
      AppSnackbar.error("Invalid Value", "Please enter a valid website URL.");
      return false;
    }
    return true;
  }

  bool validateStep4() {
    if (aadharController.text.trim().length != 12) {
      AppSnackbar.error(
        "Required",
        "Please enter a valid 12-digit Aadhaar number.",
      );
      return false;
    }
    if (aadharFileName.value.isEmpty || _aadharFile == null) {
      AppSnackbar.error("Required", "Please upload Aadhaar card.");
      return false;
    }
    if (_aadharFile!.size <= 0 || _aadharFile!.size > maxPdfSizeBytes) {
      AppSnackbar.error("Invalid File", "Aadhaar PDF must be up to 5 MB.");
      return false;
    }
    final panValue = panController.text.trim().toUpperCase();
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
    if (panValue.isEmpty || !panRegex.hasMatch(panValue)) {
      AppSnackbar.error(
        "Required",
        "Please enter a valid PAN number (e.g. ABCDE1234F).",
      );
      return false;
    }
    if (panFileName.value.isEmpty || _panFile == null) {
      AppSnackbar.error("Required", "Please upload PAN card.");
      return false;
    }
    if (_panFile!.size <= 0 || _panFile!.size > maxPdfSizeBytes) {
      AppSnackbar.error("Invalid File", "PAN PDF must be up to 5 MB.");
      return false;
    }
    return true;
  }

  bool validateStep5() {
    if (selectedServiceType.value.isEmpty) {
      AppSnackbar.error("Required", "Please select a service type.");
      return false;
    }
    if (!serviceTypeOptions.contains(selectedServiceType.value)) {
      AppSnackbar.error(
        "Invalid Service",
        "Selected service is not available anymore. Please reselect.",
      );
      return false;
    }
    if (selectedServiceSpecialities.isEmpty) {
      AppSnackbar.error("Required", "Please choose at least one speciality.");
      return false;
    }
    final availableSpecialities = currentServiceSpecialityOptions;
    if (availableSpecialities.isEmpty) {
      AppSnackbar.error(
        "No Event Types",
        "No active event types are available for the selected service.",
      );
      return false;
    }
    if (availableSpecialities.isNotEmpty &&
        selectedServiceSpecialities.any(
          (speciality) => !availableSpecialities.contains(speciality),
        )) {
      AppSnackbar.error(
        "Invalid Speciality",
        "One or more selected specialities are no longer available.",
      );
      return false;
    }
    for (final question in activeServiceQuestions) {
      final answer = getServiceQuestionAnswer(question.id);
      if (answer.isEmpty) {
        AppSnackbar.error("Required", "Please answer '${question.label}'.");
        return false;
      }
      if (question.inputType == ServiceQuestionInputType.number &&
          !_isNumeric(answer)) {
        AppSnackbar.error(
          "Invalid Value",
          "Please enter a valid number for '${question.label}'.",
        );
        return false;
      }
      if ((question.inputType == ServiceQuestionInputType.dropdown ||
              question.inputType == ServiceQuestionInputType.radio) &&
          question.options.isNotEmpty &&
          !question.options.contains(answer)) {
        AppSnackbar.error(
          "Invalid Value",
          "Please choose a valid option for '${question.label}'.",
        );
        return false;
      }
    }

    if (willingToTravel.value && secondaryWorkingLocations.isEmpty) {
      AppSnackbar.error(
        "Required",
        "Please add at least one secondary working location.",
      );
      return false;
    }
    if (!cancellationAccepted.value || !commissionAccepted.value) {
      AppSnackbar.error(
        "Required",
        "Both agreements and policy must be accepted to continue.",
      );
      return false;
    }
    if (accountNumberController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please enter account number.");
      return false;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(accountNumberController.text.trim())) {
      AppSnackbar.error(
        "Invalid Value",
        "Account number must contain digits only.",
      );
      return false;
    }
    if (!RegExp(r'^[0-9]{9,18}$').hasMatch(accountNumberController.text.trim())) {
      AppSnackbar.error(
        "Invalid Value",
        "Account number must be between 9 and 18 digits.",
      );
      return false;
    }
    if (bankPassbookFileName.value.isEmpty || _bankPassbookFile == null) {
      AppSnackbar.error("Required", "Please upload bank passbook.");
      return false;
    }
    if (_bankPassbookFile!.size <= 0 ||
        _bankPassbookFile!.size > maxPdfSizeBytes) {
      AppSnackbar.error("Invalid File", "Bank passbook PDF must be up to 5 MB.");
      return false;
    }
    if (upiController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please enter UPI ID.");
      return false;
    }
    if (!RegExp(r'^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}$')
        .hasMatch(upiController.text.trim())) {
      AppSnackbar.error("Invalid Value", "Please enter a valid UPI ID.");
      return false;
    }
    if (bankNameController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please enter bank name.");
      return false;
    }
    if (branchNameController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please enter branch name.");
      return false;
    }
    if (ifscController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please enter IFSC code.");
      return false;
    }
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$')
        .hasMatch(ifscController.text.trim().toUpperCase())) {
      AppSnackbar.error("Invalid Value", "Please enter a valid IFSC code.");
      return false;
    }
    return true;
  }

  bool _isNumeric(String value) {
    return double.tryParse(value) != null;
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  /// Submit the professional profile to Firestore & Storage
  Future<bool> submitProfessionalProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppSnackbar.error(
        "Login Required",
        "Please verify your phone number first.",
      );
      return false;
    }

    if (_aadharFile == null || _panFile == null || _bankPassbookFile == null) {
      AppSnackbar.error(
        "Missing Documents",
        "Please upload Aadhaar, PAN, and bank passbook PDF files.",
      );
      return false;
    }

    isLoading.value = true;
    isSubmittingProfile.value = true;
    _setUploadProgress(0.0, status: "Preparing documents...");
    try {
      final uid = user.uid;
      final phoneNumber = "+91${phoneController.text.trim()}";

      final aadharUrl = await _uploadPdf(
        _aadharFile!,
        uid: uid,
        label: 'aadhaar',
        progressStart: 0.00,
        progressEnd: 0.30,
        statusLabel: "Uploading Aadhaar document...",
      );
      final panUrl = await _uploadPdf(
        _panFile!,
        uid: uid,
        label: 'pan',
        progressStart: 0.30,
        progressEnd: 0.60,
        statusLabel: "Uploading PAN document...",
      );
      final bankUrl = await _uploadPdf(
        _bankPassbookFile!,
        uid: uid,
        label: 'bank_passbook',
        progressStart: 0.60,
        progressEnd: 0.90,
        statusLabel: "Uploading bank passbook...",
      );

      final now = FieldValue.serverTimestamp();
      final experienceYears = int.tryParse(
            selectedExperience.value.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
      final docRef = _db.collection('professional_profiles').doc(uid);
      final existing = await docRef.get();

      final profileData = <String, dynamic>{
        'uid': uid,
        'phoneNumber': phoneNumber,
        'status': 'under_review',
        'updatedAt': now,
        'basicInfo': {
          'fullName': nameController.text.trim(),
          'gender': selectedGender.value,
          'dob': selectedDob.value,
          'languages': selectedLanguages.toList(),
        },
        'address': {
          'formattedAddress': permanentAddressController.text.trim(),
          'permanentAddress': permanentAddressController.text.trim(),
          'latitude': selectedLatitude.value ?? 0.0,
          'longitude': selectedLongitude.value ?? 0.0,
        },
        'professional': {
          'experienceYears': experienceYears,
          'teamSize': getServiceQuestionAnswer(_questionTeamSize),
          'workingDays': selectedWorkingDays.toList(),
          'workingLocations': workingLocations.map((e) => e.toMap()).toList(),
          'secondaryLocations':
              secondaryWorkingLocations.map((e) => e.toMap()).toList(),
          'shortBio': shortBioController.text.trim(),
          'googleDrive': googleDriveController.text.trim(),
          'instagram': instagramController.text.trim(),
          'website': websiteController.text.trim(),
          'companyName': companyNameController.text.trim(),
          'clientExperience': clientExperienceController.text.trim(),
          'awards': awardsController.text.trim(),
        },
        'services': {
          'serviceType': selectedServiceType.value,
          'specialities': selectedServiceSpecialities.toList(),
          'questionnaire': _buildServiceQuestionnairePayload(),
        },
        'legal': {
          'aadhaarNumber': aadharController.text.trim(),
          'panNumber': panController.text.trim().toUpperCase(),
          'aadhaarUrl': aadharUrl,
          'panUrl': panUrl,
        },
        'availability': {'willingToTravel': willingToTravel.value},
        'agreements': {
          'cancellationAccepted': cancellationAccepted.value,
          'commissionAccepted': commissionAccepted.value,
        },
        'bank': {
          'accountNumber': accountNumberController.text.trim(),
          'upi': upiController.text.trim(),
          'bankName': bankNameController.text.trim(),
          'branchName': branchNameController.text.trim(),
          'ifsc': ifscController.text.trim(),
          'passbookUrl': bankUrl,
        },
      };

      if (!existing.exists) {
        profileData['createdAt'] = now;
      }

      _setUploadProgress(0.95, status: "Saving profile details...");
      await docRef.set(profileData, SetOptions(merge: true));
      await docRef.update({
        'address.state': FieldValue.delete(),
        'address.city': FieldValue.delete(),
        'address.pincode': FieldValue.delete(),
      });
      await _upsertProfessionalProfileDocument(uid);

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'phoneNumber': phoneNumber,
        'role': 'professional_pending',
        'rbacRole': 'professional',
        'approvalStatus': 'pending',
        'isProfessionalOnboarded': true,
        'hasProfessionalProfile': true,
        'professionalStatus': 'under_review',
        'updatedAt': now,
      }, SetOptions(merge: true));
      _localStorage.write('userRole', 'professional_pending');
      _localStorage.write('rbacRole', 'professional');
      _localStorage.write('approvalStatus', 'pending');
      _localStorage.write('isProfessionalOnboarded', true);
      _localStorage.write('hasProfessionalProfile', true);
      _localStorage.write('hideGuestCTA', true);
      _localStorage.write('hideProfessionalCTA', true);
      _setUploadProgress(1.0, status: "Upload complete.");

      AppSnackbar.success(
        "Profile Submitted",
        "Your professional profile has been submitted for review.",
      );
      return true;
    } catch (_) {
      _setUploadProgress(0.0, status: "Upload failed.");
      AppSnackbar.error(
        "Submission Failed",
        "Could not submit profile. Please try again.",
      );
      return false;
    } finally {
      isLoading.value = false;
      isSubmittingProfile.value = false;
    }
  }

  Future<String> _uploadPdf(
    PlatformFile file, {
    required String uid,
    required String label,
    required double progressStart,
    required double progressEnd,
    required String statusLabel,
  }) async {
    final safeName = file.name.replaceAll(RegExp(r'\s+'), '_');
    final ref = _storage
        .ref()
        .child('professional_documents/$uid/$label-$safeName');
    UploadTask task;
    if (file.bytes != null) {
      task = ref.putData(
        file.bytes!,
        SettableMetadata(contentType: 'application/pdf'),
      );
    } else if (file.path != null) {
      task = ref.putFile(
        File(file.path!),
        SettableMetadata(contentType: 'application/pdf'),
      );
    } else {
      throw Exception('File data missing');
    }

    _setUploadProgress(progressStart, status: statusLabel);
    StreamSubscription<TaskSnapshot>? progressSub;
    try {
      progressSub = task.snapshotEvents.listen((snapshot) {
        final totalBytes = snapshot.totalBytes;
        final rawProgress = totalBytes <= 0
            ? 0.0
            : snapshot.bytesTransferred / totalBytes;
        final mappedProgress =
            progressStart + ((progressEnd - progressStart) * rawProgress);
        _setUploadProgress(mappedProgress, status: statusLabel);
      });

      final snapshot = await task;
      _setUploadProgress(progressEnd, status: statusLabel);
      return await snapshot.ref.getDownloadURL();
    } finally {
      await progressSub?.cancel();
    }
  }

  void _setUploadProgress(double progress, {required String status}) {
    uploadProgress.value = progress.clamp(0.0, 1.0).toDouble();
    uploadProgressLabel.value = status;
  }

  Future<void> _configurePhoneAuthSettings() async {
    if (_phoneAuthSettingsConfigured || kIsWeb) {
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      _phoneAuthSettingsConfigured = true;
      return;
    }
    const forceRecaptchaInDebug = bool.fromEnvironment(
      'FORCE_RECAPTCHA_OTP_DEBUG',
      defaultValue: true,
    );
    const forceRecaptchaInRelease = bool.fromEnvironment(
      'FORCE_RECAPTCHA_OTP_RELEASE',
      defaultValue: false,
    );
    final shouldForceRecaptcha = kReleaseMode
        ? forceRecaptchaInRelease
        : forceRecaptchaInDebug;
    try {
      await _auth.setSettings(forceRecaptchaFlow: shouldForceRecaptcha);
      _phoneAuthSettingsConfigured = true;
      debugPrint(
        'Professional phone settings configured: forceRecaptchaFlow=$shouldForceRecaptcha',
      );
    } catch (e) {
      debugPrint('Failed to configure professional phone settings: $e');
    }
  }

  List<Map<String, dynamic>> _buildServiceQuestionnairePayload() {
    return activeServiceQuestions
        .map(
          (question) => <String, dynamic>{
            'id': question.id,
            'question': question.label,
            'answer': getServiceQuestionAnswer(question.id),
            'inputType': question.inputType.name,
          },
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    _applyDefaultServiceCatalog();
    _listenServiceCatalog();
    _restoreDraftState();
    unawaited(_configurePhoneAuthSettings());
  }

  Future<void> _restoreDraftState() async {
    try {
      await ProfessionalOnboardingStorage.migrateLegacyDraftIfNeeded(
        legacyKey: _profileStorageKey,
      );
      final draft = await ProfessionalOnboardingStorage.readDraft();
      if (draft.isNotEmpty) {
        _hydrateFromDraft(draft);
      }
    } finally {
      isDraftLoaded.value = true;
    }
  }

  Future<void> saveDraftForStep(int stepIndex) async {
    switch (stepIndex) {
      case 0:
        await persistStep1Draft();
        break;
      case 1:
        await persistStep2Draft();
        break;
      case 2:
        await persistStep3Draft();
        break;
      case 3:
        await persistStep4Draft();
        break;
      case 4:
        await persistStep5Draft();
        break;
      default:
        break;
    }
  }

  Future<void> persistStep1Draft({
    bool? otpRequestedOverride,
    bool? phoneVerifiedOverride,
  }) async {
    await _mergeDraftSection(_draftStep1Key, <String, dynamic>{
      'phone': phoneController.text.trim(),
      'otpRequested': otpRequestedOverride ?? isOtpSent.value,
      'phoneVerified': phoneVerifiedOverride ?? isPhoneVerified.value,
    });
  }

  Future<void> persistStep2Draft() async {
    await _mergeDraftSection(_draftStep2Key, <String, dynamic>{
      'name': nameController.text.trim(),
      'gender': selectedGender.value,
      'dob': selectedDob.value?.toIso8601String() ?? '',
      'permanentAddress': permanentAddressController.text.trim(),
      'latitude': selectedLatitude.value,
      'longitude': selectedLongitude.value,
      'languages': selectedLanguages.toList(),
    });
  }

  Future<void> persistStep3Draft() async {
    await _mergeDraftSection(_draftStep3Key, <String, dynamic>{
      'experience': selectedExperience.value,
      'workingDays': selectedWorkingDays.toList(),
      'workingLocations': workingLocations.map((e) => e.toMap()).toList(),
      'shortBio': shortBioController.text.trim(),
      'googleDrive': googleDriveController.text.trim(),
      'instagram': instagramController.text.trim(),
      'website': websiteController.text.trim(),
      'companyName': companyNameController.text.trim(),
      'clientExperience': clientExperienceController.text.trim(),
      'awards': awardsController.text.trim(),
    });
  }

  Future<void> persistStep4Draft() async {
    await _mergeDraftSection(_draftStep4Key, <String, dynamic>{
      'aadhaarFileName': aadharFileName.value,
      'aadhaarFilePath': _aadharFile?.path ?? '',
      'panFileName': panFileName.value,
      'panFilePath': _panFile?.path ?? '',
    });
  }

  Future<void> persistStep5Draft() async {
    await _mergeDraftSection(_draftStep5Key, <String, dynamic>{
      'serviceType': selectedServiceType.value,
      'serviceSpecialities': selectedServiceSpecialities.toList(),
      'serviceQuestionAnswers': Map<String, String>.from(serviceQuestionAnswers),
      'urgentAvailable': urgentAvailable.value,
      'willingToTravel': willingToTravel.value,
      'cancellationAccepted': cancellationAccepted.value,
      'commissionAccepted': commissionAccepted.value,
      'secondaryLocations': secondaryWorkingLocations.map((e) => e.toMap()).toList(),
      'bankName': bankNameController.text.trim(),
      'branchName': branchNameController.text.trim(),
      'bankPassbookFileName': bankPassbookFileName.value,
      'bankPassbookFilePath': _bankPassbookFile?.path ?? '',
    });
  }

  Future<void> clearOnboardingDraft() async {
    await ProfessionalOnboardingStorage.clearDraft();
    await _localStorage.remove(_profileStorageKey);
  }

  Future<void> _mergeDraftSection(
    String sectionKey,
    Map<String, dynamic> sectionData,
  ) async {
    final draft = await ProfessionalOnboardingStorage.readDraft();
    draft[sectionKey] = sectionData;
    await ProfessionalOnboardingStorage.writeDraft(draft);
  }

  void _hydrateFromDraft(Map<String, dynamic> draft) {
    final step1 = _readMap(draft[_draftStep1Key]);
    if (step1.isNotEmpty) {
      phoneController.text = _readString(step1, 'phone');
      final phoneVerified = _readBool(step1, 'phoneVerified');
      final otpRequested = _readBool(step1, 'otpRequested');
      isPhoneVerified.value = phoneVerified;
      isOtpSent.value = !phoneVerified && otpRequested;
      if (isOtpSent.value) {
        _timer?.cancel();
        canResendOtp.value = true;
        secondsRemaining.value = 0;
        _startOtpAutoFillListener();
      }
    }

    final step2 = _readMap(draft[_draftStep2Key]);
    if (step2.isNotEmpty) {
      nameController.text = _readString(step2, 'name');
      final gender = _readString(step2, 'gender');
      selectedGender.value = genderOptions.contains(gender) ? gender : '';
      selectedDob.value = _readDate(step2, 'dob');
      permanentAddressController.text = _readString(step2, 'permanentAddress');

      final latitudeRaw = step2['latitude'];
      final longitudeRaw = step2['longitude'];
      final latitude = (latitudeRaw as num?)?.toDouble();
      final longitude = (longitudeRaw as num?)?.toDouble();
      if (latitude != null && longitude != null) {
        selectedLatitude.value = latitude;
        selectedLongitude.value = longitude;
        mapCenterLatitude.value = latitude;
        mapCenterLongitude.value = longitude;
      }

      final langs = _readStringList(step2['languages']);
      selectedLanguages.assignAll(
        langs.where((lang) => languageOptions.contains(lang)),
      );
    }

    final step3 = _readStep3Draft(draft);
    if (step3.isNotEmpty) {
      final experience = _readString(step3, 'experience');
      selectedExperience.value =
          experienceOptions.contains(experience) ? experience : '';
      selectedWorkingDays.assignAll(
        _readStringList(step3['workingDays'])
            .where((day) => workingDaysOptions.contains(day)),
      );
      workingLocations.assignAll(_mapToLocations(step3['workingLocations']));

      shortBioController.text = _readString(step3, 'shortBio');
      googleDriveController.text = _readString(step3, 'googleDrive');
      instagramController.text = _readString(step3, 'instagram');
      websiteController.text = _readString(step3, 'website');
      companyNameController.text = _readString(step3, 'companyName');
      clientExperienceController.text = _readString(step3, 'clientExperience');
      awardsController.text = _readString(step3, 'awards');
    }

    final step4 = _readMap(draft[_draftStep4Key]);
    if (step4.isNotEmpty) {
      _restoreFileFromPath(
        filePath: _readString(step4, 'aadhaarFilePath'),
        fallbackName: _readString(step4, 'aadhaarFileName'),
        assignFile: (file) => _aadharFile = file,
        assignLabel: (label) => aadharFileName.value = label,
      );
      _restoreFileFromPath(
        filePath: _readString(step4, 'panFilePath'),
        fallbackName: _readString(step4, 'panFileName'),
        assignFile: (file) => _panFile = file,
        assignLabel: (label) => panFileName.value = label,
      );
    }

    final step5 = _readStep5Draft(draft);
    if (step5.isNotEmpty) {
      final serviceType = _readString(step5, 'serviceType');
      selectedServiceType.value = serviceType;

      final specialities = _readStringList(step5['serviceSpecialities']);
      selectedServiceSpecialities.assignAll(specialities);

      final answersRaw = step5['serviceQuestionAnswers'];
      if (answersRaw is Map) {
        serviceQuestionAnswers.assignAll(
          answersRaw.map(
            (key, value) => MapEntry('$key', '${value ?? ""}'.trim()),
          ),
        );
      }

      urgentAvailable.value = _readBool(step5, 'urgentAvailable');
      willingToTravel.value = _readBool(step5, 'willingToTravel');
      cancellationAccepted.value = _readBool(step5, 'cancellationAccepted');
      commissionAccepted.value = _readBool(step5, 'commissionAccepted');
      secondaryWorkingLocations.assignAll(
        _mapToLocations(step5['secondaryLocations']),
      );

      bankNameController.text = _readString(step5, 'bankName');
      branchNameController.text = _readString(step5, 'branchName');

      _restoreFileFromPath(
        filePath: _readString(step5, 'bankPassbookFilePath'),
        fallbackName: _readString(step5, 'bankPassbookFileName'),
        assignFile: (file) => _bankPassbookFile = file,
        assignLabel: (label) => bankPassbookFileName.value = label,
      );
    }

    _sanitizeSelectedServiceData();
  }

  Map<String, dynamic> _readStep3Draft(Map<String, dynamic> draft) {
    final step3 = _readMap(draft[_draftStep3Key]);
    if (step3.isNotEmpty) {
      return step3;
    }
    final legacyKeys = <String>[
      'experience',
      'workingDays',
      'workingLocations',
      'shortBio',
      'googleDrive',
      'instagram',
      'website',
      'companyName',
      'clientExperience',
      'awards',
    ];
    final legacy = <String, dynamic>{};
    for (final key in legacyKeys) {
      if (draft.containsKey(key)) {
        legacy[key] = draft[key];
      }
    }
    return legacy;
  }

  Map<String, dynamic> _readStep5Draft(Map<String, dynamic> draft) {
    final step5 = _readMap(draft[_draftStep5Key]);
    if (step5.isNotEmpty) {
      return step5;
    }
    final legacyKeys = <String>[
      'serviceType',
      'serviceSpecialities',
      'serviceQuestionAnswers',
      'urgentAvailable',
      'willingToTravel',
      'cancellationAccepted',
      'commissionAccepted',
      'secondaryLocations',
    ];
    final legacy = <String, dynamic>{};
    for (final key in legacyKeys) {
      if (draft.containsKey(key)) {
        legacy[key] = draft[key];
      }
    }
    return legacy;
  }

  void _restoreFileFromPath({
    required String filePath,
    required String fallbackName,
    required void Function(PlatformFile?) assignFile,
    required void Function(String) assignLabel,
  }) {
    if (filePath.isEmpty) {
      assignFile(null);
      if (fallbackName.isNotEmpty) {
        assignLabel('Re-upload required');
      }
      return;
    }
    final file = File(filePath);
    if (!file.existsSync()) {
      assignFile(null);
      assignLabel('Re-upload required');
      return;
    }
    final fileName = fallbackName.isNotEmpty
        ? fallbackName
        : file.path.split(Platform.pathSeparator).last;
    assignFile(
      PlatformFile(name: fileName, size: file.lengthSync(), path: filePath),
    );
    assignLabel(fileName);
  }

  Map<String, dynamic> _readMap(dynamic value) {
    if (value is! Map) {
      return <String, dynamic>{};
    }
    return value.map((key, val) => MapEntry('$key', val));
  }

  String _readString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  bool _readBool(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  DateTime? _readDate(Map<String, dynamic> source, String key) {
    final raw = _readString(source, key);
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<WorkingLocation> _mapToLocations(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => WorkingLocation.fromMap(Map<String, dynamic>.from(item)))
        .where((loc) => loc.state.isNotEmpty && loc.cities.isNotEmpty)
        .toList();
  }

  @override
  void onClose() {
    _stopOtpAutoFillListener();
    _timer?.cancel();
    _placeSearchDebounceTimer?.cancel();
    _serviceCatalogSub?.cancel();
    super.onClose();
  }
}

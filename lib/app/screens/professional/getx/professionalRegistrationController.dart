import 'dart:async';
import 'dart:io';

import 'package:clicknow_version2/app/services/recaptcha_service.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  PlatformFile? _aadharFile;
  PlatformFile? _panFile;
  PlatformFile? _bankPassbookFile;

  /// -- Form Keys
  final GlobalKey<FormState> professionalRegistrationFormKey =
      GlobalKey<FormState>();

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
  final TextEditingController permanentAddressController =
      TextEditingController();
  final List<String> stateOptions = [
    "Madhya Pradesh",
    "Maharashtra",
    "Uttar Pradesh",
    "Rajasthan",
    "Gujarat",
  ];
  final Map<String, List<String>> cityOptionsByState = {
    "Madhya Pradesh": ["Bhopal", "Indore", "Ujjain", "Jabalpur", "Sagar"],
    "Maharashtra": ["Mumbai", "Pune", "Nagpur", "Nashik"],
    "Uttar Pradesh": ["Lucknow", "Kanpur", "Varanasi", "Agra"],
    "Rajasthan": ["Jaipur", "Udaipur", "Jodhpur", "Kota"],
    "Gujarat": ["Ahmedabad", "Surat", "Vadodara", "Rajkot"],
  };
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
  RxString selectedPincode = "".obs;

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

  final List<String> serviceTypeOptions = const <String>[
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

  final Map<String, List<String>> serviceSpecialityMap = const {
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
      serviceSpecialityMap[selectedServiceType.value] ?? <String>[];

  List<ServiceQuestionConfiguration> get activeServiceQuestions =>
      serviceQuestionMap[selectedServiceType.value] ??
      <ServiceQuestionConfiguration>[];

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

  void onStateChanged(String? value) {
    selectedState.value = value ?? "";
    selectedCity.value = "";
    selectedPincode.value = "";
  }

  void onCityChanged(String? value) {
    selectedCity.value = value ?? "";
    selectedPincode.value = "";
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

    if (clearAfter) {
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
  RxBool isLoading = false.obs;

  Timer? _timer;
  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _confirmationResult;

  /// -- Request OTP via API
  void requestOtp() async {
    if (phoneController.text.length != 10) {
      AppSnackbar.error("Error", "Enter valid 10-digit phone number");
      return;
    }

    final phoneNumber = "+91${phoneController.text.trim()}";
    isLoading.value = true;
    try {
      if (kIsWeb) {
        final verifier = RecaptchaService.getVerifier(_auth);
        _confirmationResult = await _auth.signInWithPhoneNumber(
          phoneNumber,
          verifier,
        );
        isOtpSent.value = true;
        isPhoneVerified.value = false;
        startTimer();
        AppSnackbar.success("OTP Sent", "OTP has been sent to your phone.");
        return;
      }
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _handlePhoneCredential(credential, phoneNumber);
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
          isOtpSent.value = true;
          isPhoneVerified.value = false;
          startTimer();
          AppSnackbar.success("OTP Sent", "OTP has been sent to your phone.");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// -- Verify OTP via API
  void verifyOtp() async {
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
    secondsRemaining.value = 60;
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
    if (!canResendOtp.value) return;
    if (phoneController.text.length != 10) {
      AppSnackbar.error("Error", "Enter valid 10-digit phone number");
      return;
    }

    final phoneNumber = "+91${phoneController.text.trim()}";
    isLoading.value = true;
    try {
      if (kIsWeb) {
        final verifier = RecaptchaService.getVerifier(_auth);
        _confirmationResult = await _auth.signInWithPhoneNumber(
          phoneNumber,
          verifier,
        );
        startTimer();
        AppSnackbar.success("OTP Resent", "A new OTP has been sent.");
        return;
      }
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _handlePhoneCredential(credential, phoneNumber);
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
          startTimer();
          AppSnackbar.success("OTP Resent", "A new OTP has been sent.");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handlePhoneCredential(
    PhoneAuthCredential credential,
    String phoneNumber,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      await _handleSignedInUser(userCredential.user, phoneNumber);
    } on FirebaseAuthException catch (e) {
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
    isPhoneVerified.value = true;
    isOtpSent.value = false;
    _confirmationResult = null;
    _timer?.cancel();
    AppSnackbar.success("Verified", "Phone number verified successfully.");
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
    if (nameController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please enter your full name.");
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
    if (permanentAddressController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please enter your permanent address.");
      return false;
    }
    if (selectedState.value.isEmpty) {
      AppSnackbar.error("Required", "Please select state.");
      return false;
    }
    if (selectedCity.value.isEmpty) {
      AppSnackbar.error("Required", "Please select city.");
      return false;
    }
    if (selectedPincode.value.isEmpty) {
      AppSnackbar.error("Required", "Please select pincode.");
      return false;
    }
    if (selectedLanguages.isEmpty) {
      AppSnackbar.error("Required", "Please select at least one language.");
      return false;
    }
    return true;
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
    if (instagramController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please enter Instagram profile URL.");
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
    if (aadharFileName.value.isEmpty) {
      AppSnackbar.error("Required", "Please upload Aadhaar card.");
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
    if (panFileName.value.isEmpty) {
      AppSnackbar.error("Required", "Please upload PAN card.");
      return false;
    }
    return true;
  }

  bool validateStep5() {
    if (selectedServiceType.value.isEmpty) {
      AppSnackbar.error("Required", "Please select a service type.");
      return false;
    }
    if (selectedServiceSpecialities.isEmpty) {
      AppSnackbar.error("Required", "Please choose at least one speciality.");
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
    if (bankPassbookFileName.value.isEmpty) {
      AppSnackbar.error("Required", "Please upload bank passbook.");
      return false;
    }
    if (upiController.text.trim().isEmpty) {
      AppSnackbar.error("Required", "Please enter UPI ID.");
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
    saveProfileSnapshot();
    return true;
  }

  bool _isNumeric(String value) {
    return double.tryParse(value) != null;
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
    try {
      final uid = user.uid;
      final phoneNumber = "+91${phoneController.text.trim()}";

      final aadharUrl = await _uploadPdf(
        _aadharFile!,
        uid: uid,
        label: 'aadhaar',
      );
      final panUrl = await _uploadPdf(
        _panFile!,
        uid: uid,
        label: 'pan',
      );
      final bankUrl = await _uploadPdf(
        _bankPassbookFile!,
        uid: uid,
        label: 'bank_passbook',
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
          'permanentAddress': permanentAddressController.text.trim(),
          'state': selectedState.value,
          'city': selectedCity.value,
          'pincode': selectedPincode.value,
        },
        'professional': {
          'experienceYears': experienceYears,
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
        'availability': {
          'urgentAvailable': urgentAvailable.value,
          'willingToTravel': willingToTravel.value,
        },
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

      await docRef.set(profileData, SetOptions(merge: true));

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'phoneNumber': phoneNumber,
        'role': 'professional_pending',
        'professionalStatus': 'under_review',
        'updatedAt': now,
      }, SetOptions(merge: true));

      AppSnackbar.success(
        "Profile Submitted",
        "Your professional profile has been submitted for review.",
      );
      return true;
    } catch (_) {
      AppSnackbar.error(
        "Submission Failed",
        "Could not submit profile. Please try again.",
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> _uploadPdf(
    PlatformFile file, {
    required String uid,
    required String label,
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

    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
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
    loadProfileSnapshot();
  }

  void saveProfileSnapshot() {
    final data = {
      'experience': selectedExperience.value,
      'teamSize': selectedTeamSize.value,
      'workingDays': selectedWorkingDays.toList(),
      'workingLocations': workingLocations.map((e) => e.toMap()).toList(),
      'secondaryLocations': secondaryWorkingLocations
          .map((e) => e.toMap())
          .toList(),
      'serviceType': selectedServiceType.value,
      'serviceSpecialities': selectedServiceSpecialities.toList(),
      'serviceQuestionAnswers': Map<String, String>.from(serviceQuestionAnswers),
      'urgentAvailable': urgentAvailable.value,
      'willingToTravel': willingToTravel.value,
      'cancellationAccepted': cancellationAccepted.value,
      'commissionAccepted': commissionAccepted.value,
    };
    _localStorage.write(_profileStorageKey, data);
  }

  void loadProfileSnapshot() {
    final raw = _localStorage.read(_profileStorageKey);
    if (raw is! Map) {
      return;
    }

    selectedExperience.value = raw['experience'] as String? ?? '';
    selectedTeamSize.value = raw['teamSize'] as String? ?? '';

    final workingDays = raw['workingDays'] as List? ?? const [];
    selectedWorkingDays.assignAll(workingDays.map((e) => e.toString()));

    final workingLocRaw = raw['workingLocations'];
    workingLocations.assignAll(_mapToLocations(workingLocRaw));

    final secondaryLocRaw = raw['secondaryLocations'];
    secondaryWorkingLocations.assignAll(_mapToLocations(secondaryLocRaw));

    selectedServiceType.value = raw['serviceType'] as String? ?? '';
    final specialities = raw['serviceSpecialities'] as List? ?? const [];
    selectedServiceSpecialities.assignAll(specialities.map((e) => '$e'));

    final questionAnswersRaw = raw['serviceQuestionAnswers'];
    if (questionAnswersRaw is Map) {
      serviceQuestionAnswers.assignAll(
        questionAnswersRaw.map(
          (key, value) => MapEntry('$key', '${value ?? ""}'.trim()),
        ),
      );
    }

    urgentAvailable.value = raw['urgentAvailable'] as bool? ?? false;
    willingToTravel.value = raw['willingToTravel'] as bool? ?? false;
    cancellationAccepted.value = raw['cancellationAccepted'] as bool? ?? false;
    commissionAccepted.value = raw['commissionAccepted'] as bool? ?? false;
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
    _timer?.cancel();
    super.onClose();
  }
}

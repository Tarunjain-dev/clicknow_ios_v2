import 'package:cloud_firestore/cloud_firestore.dart';

class AdminWorkingLocation {
  const AdminWorkingLocation({required this.state, required this.cities});

  final String state;
  final List<String> cities;

  factory AdminWorkingLocation.fromMap(Map<String, dynamic> map) {
    return AdminWorkingLocation(
      state: (map['state'] ?? '').toString().trim(),
      cities: _stringList(map['cities']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

class ServiceQuestionAnswer {
  const ServiceQuestionAnswer({
    required this.id,
    required this.question,
    required this.answer,
    required this.inputType,
  });

  final String id;
  final String question;
  final String answer;
  final String inputType;

  factory ServiceQuestionAnswer.fromMap(Map<String, dynamic> map) {
    return ServiceQuestionAnswer(
      id: (map['id'] ?? '').toString().trim(),
      question: (map['question'] ?? '').toString().trim(),
      answer: (map['answer'] ?? '').toString().trim(),
      inputType: (map['inputType'] ?? '').toString().trim(),
    );
  }
}

class AdminBookingHistoryItem {
  const AdminBookingHistoryItem({
    required this.bookingId,
    required this.eventName,
    required this.status,
    required this.amount,
    required this.date,
  });

  final String bookingId;
  final String eventName;
  final String status;
  final double amount;
  final DateTime? date;

  factory AdminBookingHistoryItem.fromMap(Map<String, dynamic> map) {
    return AdminBookingHistoryItem(
      bookingId: (map['bookingId'] ?? '').toString().trim(),
      eventName: (map['eventName'] ?? '').toString().trim(),
      status: (map['status'] ?? '').toString().trim(),
      amount: _toDouble(map['amount']),
      date: _toDateTime(map['date']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value.trim());
    return null;
  }
}

class AdminProfessionalProfile {
  AdminProfessionalProfile({
    required this.uid,
    required this.status,
    required this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.basicInfo,
    required this.address,
    required this.professional,
    required this.services,
    required this.legal,
    required this.availability,
    required this.agreements,
    required this.bank,
    required this.performance,
    required this.adminReview,
    required this.primaryLocations,
    required this.secondaryLocations,
    required this.questionnaire,
    required this.bookingHistory,
    required this.adminProfessionalType,
    required this.adminComment,
    required this.raw,
  });

  final String uid;
  final String status;
  final String phoneNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> basicInfo;
  final Map<String, dynamic> address;
  final Map<String, dynamic> professional;
  final Map<String, dynamic> services;
  final Map<String, dynamic> legal;
  final Map<String, dynamic> availability;
  final Map<String, dynamic> agreements;
  final Map<String, dynamic> bank;
  final Map<String, dynamic> performance;
  final Map<String, dynamic> adminReview;
  final List<AdminWorkingLocation> primaryLocations;
  final List<AdminWorkingLocation> secondaryLocations;
  final List<ServiceQuestionAnswer> questionnaire;
  final List<AdminBookingHistoryItem> bookingHistory;
  final String adminProfessionalType;
  final String adminComment;
  final Map<String, dynamic> raw;

  factory AdminProfessionalProfile.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AdminProfessionalProfile.fromMap(
      uid: doc.id,
      map: doc.data() ?? const <String, dynamic>{},
    );
  }

  factory AdminProfessionalProfile.fromMap({
    required String uid,
    required Map<String, dynamic> map,
  }) {
    final status = _firstNonEmptyString(<dynamic>[
      map['status'],
      map['professionalStatus'],
    ]).toLowerCase();
    final basicInfo = _asMap(map['basicInfo']);
    final address = _asMap(map['address']);
    final professional = _asMap(map['professional']);
    final services = _asMap(map['services']);
    final legal = _asMap(map['legal']);
    final availability = _asMap(map['availability']);
    final agreements = _asMap(map['agreements']);
    final bank = _asMap(map['bank']);

    final metricsMap = _asMap(map['performance']);
    final fallbackMetrics = _asMap(map['metrics']);
    final performance = metricsMap.isEmpty ? fallbackMetrics : metricsMap;

    final adminReview = _asMap(map['adminReview']);
    final adminProfessionalType = _readAdminType(
      map,
      adminReview,
    ).toLowerCase().trim();
    final adminComment = (adminReview['comment'] ?? map['reviewComment'] ?? '')
        .toString()
        .trim();

    final primaryLocations = _firstLocations(<dynamic>[
      _firstMapValue(professional, const <String>[
        'workingLocations',
        'primaryLocations',
      ]),
    ]);
    final secondaryLocations = _firstLocations(<dynamic>[
      _firstMapValue(professional, const <String>[
        'secondaryLocations',
        'secondaryWorkingLocations',
        'travelPreferenceLocations',
        'travelLocations',
      ]),
    ]);

    final questionnaire = _readQuestionnaire(
      _firstMapValue(services, const <String>['questionnaire', 'questions']),
    );
    final bookingHistory = _readBookingHistory(
      map['bookingHistory'] ?? map['bookings'],
    );

    return AdminProfessionalProfile(
      uid: uid,
      status: status,
      phoneNumber: _firstNonEmptyString(<dynamic>[
        map['phoneNumber'],
        map['phone'],
        map['mobileNumber'],
      ]),
      createdAt: _firstDateTime(<dynamic>[map['createdAt'], map['created_at']]),
      updatedAt: _firstDateTime(<dynamic>[map['updatedAt'], map['updated_at']]),
      basicInfo: basicInfo,
      address: address,
      professional: professional,
      services: services,
      legal: legal,
      availability: availability,
      agreements: agreements,
      bank: bank,
      performance: performance,
      adminReview: adminReview,
      primaryLocations: primaryLocations,
      secondaryLocations: secondaryLocations,
      questionnaire: questionnaire,
      bookingHistory: bookingHistory,
      adminProfessionalType: adminProfessionalType,
      adminComment: adminComment,
      raw: Map<String, dynamic>.from(map),
    );
  }

  String get fullName =>
      _firstNonEmptyString(<dynamic>[
        _firstMapValue(basicInfo, const <String>[
          'fullName',
          'name',
          'full_name',
        ]),
        raw['fullName'],
        raw['name'],
      ]).isNotEmpty
      ? _firstNonEmptyString(<dynamic>[
          _firstMapValue(basicInfo, const <String>[
            'fullName',
            'name',
            'full_name',
          ]),
          raw['fullName'],
          raw['name'],
        ])
      : 'Unnamed Professional';

  String get gender => _firstNonEmptyString(<dynamic>[
    _firstMapValue(basicInfo, const <String>['gender', 'sex']),
    raw['gender'],
  ]);

  DateTime? get dob => _firstDateTime(<dynamic>[
    _firstMapValue(basicInfo, const <String>['dob', 'dateOfBirth']),
    raw['dob'],
  ]);

  List<String> get languages => _firstStringList(<dynamic>[
    _firstMapValue(basicInfo, const <String>[
      'languages',
      'languagesKnown',
      'knownLanguages',
    ]),
    raw['languages'],
  ]);

  String get permanentAddress => _firstNonEmptyString(<dynamic>[
    _firstMapValue(address, const <String>[
      'permanentAddress',
      'fullAddress',
      'address',
    ]),
    raw['permanentAddress'],
    raw['address'],
  ]);

  String get state => _firstNonEmptyString(<dynamic>[
    _firstMapValue(address, const <String>['state']),
    raw['state'],
  ]);

  String get city => _firstNonEmptyString(<dynamic>[
    _firstMapValue(address, const <String>['city']),
    raw['city'],
  ]);

  String get pincode => _firstNonEmptyString(<dynamic>[
    _firstMapValue(address, const <String>['pincode', 'pinCode', 'pin_code']),
    raw['pincode'],
    raw['pinCode'],
  ]);

  int get experienceYears => _toInt(
    _firstMapValue(professional, const <String>[
      'experienceYears',
      'experience',
      'yearsOfExperience',
    ]),
  );

  List<String> get workingDays => _firstStringList(<dynamic>[
    _firstMapValue(professional, const <String>[
      'workingDays',
      'availableWorkingDays',
      'availableDays',
    ]),
  ]);

  String get shortBio => (professional['shortBio'] ?? '').toString().trim();

  String get googleDriveUrl =>
      (professional['googleDrive'] ?? '').toString().trim();

  String get instagramUrl =>
      (professional['instagram'] ?? '').toString().trim();

  String get websiteUrl => (professional['website'] ?? '').toString().trim();

  String get companyName =>
      (professional['companyName'] ?? '').toString().trim();

  String get clientExperience =>
      (professional['clientExperience'] ?? '').toString().trim();

  String get awards => (professional['awards'] ?? '').toString().trim();

  String get serviceType => _firstNonEmptyString(<dynamic>[
    _firstMapValue(services, const <String>[
      'serviceType',
      'service',
      'serviceName',
    ]),
    raw['serviceType'],
  ]);

  List<String> get serviceSpecialities => _firstStringList(<dynamic>[
    _firstMapValue(services, const <String>[
      'specialities',
      'specialty',
      'specialitiesList',
      'eventTypes',
    ]),
    raw['specialities'],
  ]);

  String get aadhaarNumber => _firstNonEmptyString(<dynamic>[
    _firstMapValue(legal, const <String>[
      'aadhaarNumber',
      'aadharNumber',
      'adharNumber',
    ]),
  ]);

  String get panNumber => _firstNonEmptyString(<dynamic>[
    _firstMapValue(legal, const <String>['panNumber', 'panNo']),
  ]);

  String get aadhaarUrl => _firstNonEmptyString(<dynamic>[
    _firstMapValue(legal, const <String>['aadhaarUrl', 'aadharUrl']),
  ]);

  String get panUrl => _firstNonEmptyString(<dynamic>[
    _firstMapValue(legal, const <String>['panUrl', 'panCardUrl']),
  ]);

  bool get urgentBookingAvailable => _toBool(availability['urgentAvailable']);

  bool get willingToTravel => _toBool(availability['willingToTravel']);

  String get professionalAvailabilityStatus => _firstNonEmptyString(<dynamic>[
    availability['professionalAvailabilityStatus'],
    availability['visibilityStatus'],
    availability['status'],
    raw['professionalAvailabilityStatus'],
  ]).toLowerCase();

  bool get cancellationPolicyAccepted =>
      _toBool(agreements['cancellationAccepted']);

  bool get platformCommissionAccepted =>
      _toBool(agreements['commissionAccepted']);

  String get accountNumber => _firstNonEmptyString(<dynamic>[
    _firstMapValue(bank, const <String>['accountNumber', 'bankAccountNumber']),
  ]);

  String get bankPassbookUrl => _firstNonEmptyString(<dynamic>[
    _firstMapValue(bank, const <String>['passbookUrl', 'bankPassbookUrl']),
  ]);

  String get upiId => _firstNonEmptyString(<dynamic>[
    _firstMapValue(bank, const <String>['upi', 'upiId', 'upiID']),
  ]);

  String get bankName => _firstNonEmptyString(<dynamic>[
    _firstMapValue(bank, const <String>['bankName', 'name']),
  ]);

  String get branchName => _firstNonEmptyString(<dynamic>[
    _firstMapValue(bank, const <String>['branchName', 'branch']),
  ]);

  String get ifscCode => _firstNonEmptyString(<dynamic>[
    _firstMapValue(bank, const <String>['ifsc', 'ifscCode']),
  ]);

  String get accountHolderName =>
      (bank['accountHolderName'] ?? bank['holderName'] ?? '').toString().trim();

  int get totalBookings => _toInt(performance['totalBookings']);

  double get acceptanceRate => _toDouble(performance['acceptanceRate']);

  double get cancellationRate => _toDouble(performance['cancellationRate']);

  double get totalRevenue => _toDouble(performance['totalRevenue']);

  DateTime? get referenceDate => updatedAt ?? createdAt;

  String get professionalTypeForFilter {
    if (adminProfessionalType == 'pro') {
      return 'pro';
    }
    if (adminProfessionalType == 'normal') {
      return 'normal';
    }
    return 'normal';
  }

  String get professionalTypeLabel =>
      professionalTypeForFilter == 'pro' ? 'Pro' : 'Normal';

  String get accountStatus => _firstNonEmptyString(<dynamic>[
    raw['accountStatus'],
    status == 'suspended' || status == 'blocked' ? status : 'ACTIVE',
  ]).toUpperCase();

  String get approvalStatus => _firstNonEmptyString(<dynamic>[
    raw['approvalStatus'],
    status,
  ]).toUpperCase();

  bool get isFeatured => _toBool(raw['isFeatured']);

  bool get documentsVerified => _toBool(raw['documentsVerified']);

  bool get bankDetailsUpdateRequired =>
      _toBool(raw['bankDetailsUpdateRequired']);

  String get suspensionReason =>
      (raw['suspensionReason'] ?? '').toString().trim();

  String get blockedReason => (raw['blockedReason'] ?? '').toString().trim();

  String get reuploadReason => (raw['reuploadReason'] ?? '').toString().trim();

  List<String> get reuploadRequestedDocuments =>
      _stringList(raw['reuploadRequestedDocuments']);

  Map<String, String> get reuploadedDocuments {
    final documents = _asMap(raw['reuploadedDocuments']);
    return documents.map(
      (key, value) => MapEntry(key, value?.toString().trim() ?? ''),
    )..removeWhere((key, value) => value.isEmpty);
  }

  String get searchableText {
    return <String>[
      uid,
      fullName,
      phoneNumber,
      serviceType,
      state,
      city,
      pincode,
      professionalTypeLabel,
    ].join(' ').toLowerCase();
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<AdminWorkingLocation> _readLocations(dynamic value) {
    if (value is! List) return const <AdminWorkingLocation>[];
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .map(AdminWorkingLocation.fromMap)
        .where(
          (location) => location.state.isNotEmpty && location.cities.isNotEmpty,
        )
        .toList(growable: false);
  }

  static List<AdminWorkingLocation> _firstLocations(List<dynamic> values) {
    for (final value in values) {
      final locations = _readLocations(value);
      if (locations.isNotEmpty) {
        return locations;
      }
    }
    return const <AdminWorkingLocation>[];
  }

  static List<ServiceQuestionAnswer> _readQuestionnaire(dynamic value) {
    if (value is! List) return const <ServiceQuestionAnswer>[];
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .map(ServiceQuestionAnswer.fromMap)
        .where((item) => item.question.isNotEmpty)
        .toList(growable: false);
  }

  static dynamic _firstMapValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key)) {
        return map[key];
      }
    }
    return null;
  }

  static List<String> _firstStringList(List<dynamic> values) {
    for (final value in values) {
      final parsed = _stringList(value);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }
    return const <String>[];
  }

  static String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static List<AdminBookingHistoryItem> _readBookingHistory(dynamic value) {
    if (value is! List) return const <AdminBookingHistoryItem>[];
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .map(AdminBookingHistoryItem.fromMap)
        .toList(growable: false);
  }

  static String _readAdminType(
    Map<String, dynamic> map,
    Map<String, dynamic> adminReview,
  ) {
    final direct = (map['adminProfessionalType'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;

    final reviewType = (adminReview['professionalType'] ?? '')
        .toString()
        .trim();
    if (reviewType.isNotEmpty) return reviewType;

    final fallback = (map['professionalType'] ?? '').toString().trim();
    if (fallback == 'pro' || fallback == 'normal') {
      return fallback;
    }

    return '';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static DateTime? _firstDateTime(List<dynamic> values) {
    for (final value in values) {
      final date = _toDateTime(value);
      if (date != null) {
        return date;
      }
    }
    return null;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final parsed = value?.toString().toLowerCase().trim();
    return parsed == 'true' || parsed == '1' || parsed == 'yes';
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return 0;
    }
    final direct = int.tryParse(text);
    if (direct != null) {
      return direct;
    }
    final matched = RegExp(r'\d+').firstMatch(text)?.group(0);
    return int.tryParse(matched ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalWorkingLocation {
  const ProfessionalWorkingLocation({
    required this.state,
    required this.cities,
  });

  final String state;
  final List<String> cities;

  factory ProfessionalWorkingLocation.fromMap(Map<String, dynamic> map) {
    return ProfessionalWorkingLocation(
      state: (map['state'] ?? '').toString().trim(),
      cities: ProfessionalProfileData._stringList(map['cities']),
    );
  }

  ProfessionalWorkingLocation normalized() {
    final cleanState = state.trim();
    final cleanCities = cities
        .map((city) => city.trim())
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return ProfessionalWorkingLocation(state: cleanState, cities: cleanCities);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'state': state.trim(),
      'cities': cities
          .map((city) => city.trim())
          .where((city) => city.isNotEmpty)
          .toSet()
          .toList(growable: false),
    };
  }
}

class ProfessionalProfileData {
  const ProfessionalProfileData({
    required this.uid,
    required this.status,
    required this.profileImageUrl,
    required this.phoneNumber,
    required this.fullName,
    required this.gender,
    required this.dob,
    required this.languages,
    required this.permanentAddress,
    required this.state,
    required this.city,
    required this.pincode,
    required this.experienceYears,
    required this.teamSize,
    required this.workingDays,
    required this.primaryLocations,
    required this.secondaryLocations,
    required this.serviceType,
    required this.specialities,
    required this.aadhaarNumber,
    required this.panNumber,
    required this.aadhaarUrl,
    required this.panUrl,
    required this.bankAccountNumber,
    required this.bankName,
    required this.bankBranchName,
    required this.bankIfsc,
    required this.upiId,
    required this.bankPassbookUrl,
    required this.bankDetailsUpdateRequired,
    required this.bankDetailsUpdateReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String status;
  final String profileImageUrl;
  final String phoneNumber;
  final String fullName;
  final String gender;
  final String dob;
  final List<String> languages;
  final String permanentAddress;
  final String state;
  final String city;
  final String pincode;
  final int experienceYears;
  final String teamSize;
  final List<String> workingDays;
  final List<ProfessionalWorkingLocation> primaryLocations;
  final List<ProfessionalWorkingLocation> secondaryLocations;
  final String serviceType;
  final List<String> specialities;
  final String aadhaarNumber;
  final String panNumber;
  final String aadhaarUrl;
  final String panUrl;
  final String bankAccountNumber;
  final String bankName;
  final String bankBranchName;
  final String bankIfsc;
  final String upiId;
  final String bankPassbookUrl;
  final bool bankDetailsUpdateRequired;
  final String bankDetailsUpdateReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ProfessionalProfileData.empty() {
    return const ProfessionalProfileData(
      uid: '',
      status: '',
      profileImageUrl: '',
      phoneNumber: '',
      fullName: 'Professional',
      gender: '',
      dob: '',
      languages: <String>[],
      permanentAddress: '',
      state: '',
      city: '',
      pincode: '',
      experienceYears: 0,
      teamSize: '',
      workingDays: <String>[],
      primaryLocations: <ProfessionalWorkingLocation>[],
      secondaryLocations: <ProfessionalWorkingLocation>[],
      serviceType: '',
      specialities: <String>[],
      aadhaarNumber: '',
      panNumber: '',
      aadhaarUrl: '',
      panUrl: '',
      bankAccountNumber: '',
      bankName: '',
      bankBranchName: '',
      bankIfsc: '',
      upiId: '',
      bankPassbookUrl: '',
      bankDetailsUpdateRequired: false,
      bankDetailsUpdateReason: '',
      createdAt: null,
      updatedAt: null,
    );
  }

  factory ProfessionalProfileData.fromMap({
    required String uid,
    required Map<String, dynamic> map,
  }) {
    final basicInfo = _asMap(map['basicInfo']);
    final address = _asMap(map['address']);
    final professional = _asMap(map['professional']);
    final services = _asMap(map['services']);
    final legal = _asMap(map['legal']);
    final bank = _asMap(map['bank']);

    final questionnaire = _firstMapValue(services, const <String>[
      'questionnaire',
      'questions',
    ]);
    final extractedTeamSize = _extractTeamSize(questionnaire);
    final fallbackTeamSize = _firstNonEmptyString(<dynamic>[
      _firstMapValue(professional, const <String>['teamSize', 'team_size']),
      map['teamSize'],
      map['team_size'],
    ]);
    final teamSize = extractedTeamSize.isNotEmpty
        ? extractedTeamSize
        : fallbackTeamSize;

    return ProfessionalProfileData(
      uid: uid,
      status: _firstNonEmptyString(<dynamic>[
        map['status'],
        map['professionalStatus'],
      ]).toLowerCase(),
      profileImageUrl: _firstNonEmptyString(<dynamic>[
        _firstMapValue(basicInfo, const <String>[
          'profileImageUrl',
          'photoUrl',
          'imageUrl',
        ]),
        map['profileImageUrl'],
        map['photoUrl'],
      ]),
      phoneNumber: _firstNonEmptyString(<dynamic>[
        map['phoneNumber'],
        map['phone'],
        map['mobileNumber'],
      ]),
      fullName:
          _firstNonEmptyString(<dynamic>[
            _firstMapValue(basicInfo, const <String>[
              'fullName',
              'name',
              'full_name',
            ]),
            map['fullName'],
            map['name'],
          ]).isEmpty
          ? 'Professional'
          : _firstNonEmptyString(<dynamic>[
              _firstMapValue(basicInfo, const <String>[
                'fullName',
                'name',
                'full_name',
              ]),
              map['fullName'],
              map['name'],
            ]),
      gender: _firstNonEmptyString(<dynamic>[
        _firstMapValue(basicInfo, const <String>['gender', 'sex']),
        map['gender'],
      ]),
      dob: _firstNonEmptyString(<dynamic>[
        _firstMapValue(basicInfo, const <String>['dob', 'dateOfBirth']),
        map['dob'],
        map['dateOfBirth'],
      ]),
      languages: _firstStringList(<dynamic>[
        _firstMapValue(basicInfo, const <String>[
          'languages',
          'languagesKnown',
          'knownLanguages',
        ]),
        map['languages'],
      ]),
      permanentAddress: _firstNonEmptyString(<dynamic>[
        _firstMapValue(address, const <String>[
          'permanentAddress',
          'fullAddress',
          'address',
        ]),
        map['permanentAddress'],
        map['address'],
      ]),
      state: _firstNonEmptyString(<dynamic>[
        _firstMapValue(address, const <String>['state']),
        map['state'],
      ]),
      city: _firstNonEmptyString(<dynamic>[
        _firstMapValue(address, const <String>['city']),
        map['city'],
      ]),
      pincode: _firstNonEmptyString(<dynamic>[
        _firstMapValue(address, const <String>[
          'pincode',
          'pinCode',
          'pin_code',
        ]),
        map['pincode'],
        map['pinCode'],
      ]),
      experienceYears: _firstIntValue(<dynamic>[
        _firstMapValue(professional, const <String>[
          'experienceYears',
          'experience',
          'yearsOfExperience',
        ]),
        map['experienceYears'],
      ]),
      teamSize: teamSize,
      workingDays: _firstStringList(<dynamic>[
        _firstMapValue(professional, const <String>[
          'workingDays',
          'availableWorkingDays',
          'availableDays',
        ]),
      ]),
      primaryLocations: _firstLocations(<dynamic>[
        _firstMapValue(professional, const <String>[
          'workingLocations',
          'primaryLocations',
        ]),
      ]),
      secondaryLocations: _firstLocations(<dynamic>[
        _firstMapValue(professional, const <String>[
          'secondaryLocations',
          'secondaryWorkingLocations',
          'travelPreferenceLocations',
          'travelLocations',
        ]),
      ]),
      serviceType: _firstNonEmptyString(<dynamic>[
        _firstMapValue(services, const <String>[
          'serviceType',
          'service',
          'serviceName',
        ]),
        map['serviceType'],
      ]),
      specialities: _firstStringList(<dynamic>[
        _firstMapValue(services, const <String>[
          'specialities',
          'specialty',
          'specialitiesList',
          'eventTypes',
        ]),
        map['specialities'],
      ]),
      aadhaarNumber: _firstNonEmptyString(<dynamic>[
        _firstMapValue(legal, const <String>[
          'aadhaarNumber',
          'aadharNumber',
          'adharNumber',
        ]),
      ]),
      panNumber: _firstNonEmptyString(<dynamic>[
        _firstMapValue(legal, const <String>['panNumber', 'panNo']),
      ]),
      aadhaarUrl: _firstNonEmptyString(<dynamic>[
        _firstMapValue(legal, const <String>['aadhaarUrl', 'aadharUrl']),
      ]),
      panUrl: _firstNonEmptyString(<dynamic>[
        _firstMapValue(legal, const <String>['panUrl', 'panCardUrl']),
      ]),
      bankAccountNumber: _firstNonEmptyString(<dynamic>[
        _firstMapValue(bank, const <String>[
          'accountNumber',
          'bankAccountNumber',
        ]),
      ]),
      bankName: _firstNonEmptyString(<dynamic>[
        _firstMapValue(bank, const <String>['bankName', 'name']),
      ]),
      bankBranchName: _firstNonEmptyString(<dynamic>[
        _firstMapValue(bank, const <String>['branchName', 'branch']),
      ]),
      bankIfsc: _firstNonEmptyString(<dynamic>[
        _firstMapValue(bank, const <String>['ifsc', 'ifscCode']),
      ]),
      upiId: _firstNonEmptyString(<dynamic>[
        _firstMapValue(bank, const <String>['upi', 'upiId', 'upiID']),
      ]),
      bankPassbookUrl: _firstNonEmptyString(<dynamic>[
        _firstMapValue(bank, const <String>['passbookUrl', 'bankPassbookUrl']),
      ]),
      bankDetailsUpdateRequired: _toBool(map['bankDetailsUpdateRequired']),
      bankDetailsUpdateReason: _firstNonEmptyString(<dynamic>[
        map['bankDetailsUpdateReason'],
      ]),
      createdAt: _firstDateTime(<dynamic>[map['createdAt'], map['created_at']]),
      updatedAt: _firstDateTime(<dynamic>[map['updatedAt'], map['updated_at']]),
    );
  }

  String get locationLabel {
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (pincode.isNotEmpty) pincode,
    ];
    if (parts.isEmpty) {
      return 'Location not added';
    }
    return parts.join(', ');
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
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

  static List<ProfessionalWorkingLocation> _readLocations(dynamic value) {
    if (value is! List) return const <ProfessionalWorkingLocation>[];
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .map(ProfessionalWorkingLocation.fromMap)
        .where((item) => item.state.isNotEmpty && item.cities.isNotEmpty)
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

  static String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }
      if (value is Timestamp) {
        return value.toDate().toIso8601String();
      }
      if (value is DateTime) {
        return value.toIso8601String();
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static List<String> _firstStringList(List<dynamic> values) {
    for (final value in values) {
      final list = _stringList(value);
      if (list.isNotEmpty) {
        return list;
      }
    }
    return const <String>[];
  }

  static List<ProfessionalWorkingLocation> _firstLocations(
    List<dynamic> values,
  ) {
    for (final value in values) {
      final locations = _readLocations(value);
      if (locations.isNotEmpty) {
        return locations;
      }
    }
    return const <ProfessionalWorkingLocation>[];
  }

  static int _firstIntValue(List<dynamic> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isEmpty) {
        continue;
      }
      return _toInt(value);
    }
    return 0;
  }

  static String _extractTeamSize(dynamic questionnaire) {
    if (questionnaire is! List) {
      return '';
    }
    for (final entry in questionnaire) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final id = (map['id'] ?? '').toString().toLowerCase().trim();
      final question = (map['question'] ?? '').toString().toLowerCase().trim();
      if (id.contains('team') || question.contains('team size')) {
        return (map['answer'] ?? '').toString().trim();
      }
    }
    return '';
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

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value.trim());
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
}

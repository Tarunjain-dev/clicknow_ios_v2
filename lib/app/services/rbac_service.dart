import 'package:clicknow_version2/app/utils/device_constants/appConstants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';

class RbacDecision {
  const RbacDecision({
    required this.role,
    required this.approvalStatus,
    required this.isProfessionalOnboarded,
    required this.hasProfessionalProfile,
  });

  static const String roleCustomer = 'customer';
  static const String roleProfessional = 'professional';
  static const String roleAdmin = 'admin';

  final String role;
  final String approvalStatus;
  final bool isProfessionalOnboarded;
  final bool hasProfessionalProfile;

  bool get isAdmin => role == roleAdmin;
  bool get isProfessional => role == roleProfessional;
  bool get isCustomer => role == roleCustomer;
  bool get isProfessionalApproved =>
      isProfessional && approvalStatus == 'approved';

  String get compatibleUserRole {
    if (isAdmin) {
      return AppConstants.adminRole;
    }
    if (isProfessional) {
      return isProfessionalApproved ? 'professional' : 'professional_pending';
    }
    return 'customer';
  }

  Map<String, dynamic> toLocalMap() {
    return <String, dynamic>{
      'role': role,
      'approvalStatus': approvalStatus,
      'isProfessionalOnboarded': isProfessionalOnboarded,
      'hasProfessionalProfile': hasProfessionalProfile,
      'compatibleUserRole': compatibleUserRole,
    };
  }
}

class RbacService {
  RbacService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _localRbacRoleKey = 'rbacRole';
  static const String _localApprovalStatusKey = 'approvalStatus';
  static const String _localProfessionalOnboardedKey = 'isProfessionalOnboarded';
  static const String _localProfessionalProfileKey = 'hasProfessionalProfile';
  static const String _localUserRoleKey = 'userRole';
  static const String _localGuestCtaKey = 'hideGuestCTA';
  static const String _localProfessionalCtaKey = 'hideProfessionalCTA';
  static const String _localSessionUidKey = 'rbacSessionUid';

  static String normalizePhone(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      return '+91$digits';
    }
    if (digits.startsWith('91') && digits.length == 12) {
      return '+$digits';
    }
    if (phoneNumber.trim().startsWith('+')) {
      return '+$digits';
    }
    return '+$digits';
  }

  static bool isAdminPhone(String phoneNumber) {
    final normalizedInput = normalizePhone(phoneNumber);
    return AppConstants.adminPhoneNumbers
        .map(normalizePhone)
        .contains(normalizedInput);
  }

  static Future<RbacDecision> resolveByPhone(String phoneNumber) async {
    final normalizedPhone = normalizePhone(phoneNumber);
    if (isAdminPhone(normalizedPhone)) {
      return const RbacDecision(
        role: RbacDecision.roleAdmin,
        approvalStatus: 'approved',
        isProfessionalOnboarded: false,
        hasProfessionalProfile: false,
      );
    }

    final usersFuture = _db
        .collection('users')
        .where('phoneNumber', isEqualTo: normalizedPhone)
        .limit(20)
        .get();
    final profilesFuture = _db
        .collection('professional_profiles')
        .where('phoneNumber', isEqualTo: normalizedPhone)
        .limit(20)
        .get();

    final results = await Future.wait([usersFuture, profilesFuture]);
    final userSnapshot = results[0];
    final profileSnapshot = results[1];

    final userMaps = userSnapshot.docs.map((doc) => doc.data()).toList();
    final profileMaps = profileSnapshot.docs.map((doc) => doc.data()).toList();

    return _buildDecision(
      normalizedPhone: normalizedPhone,
      userMaps: userMaps,
      profileMaps: profileMaps,
    );
  }

  static Future<RbacDecision> resolveByUid({
    required String uid,
    String? fallbackPhone,
  }) async {
    Map<String, dynamic>? userMap;
    Map<String, dynamic>? profileMap;
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      userMap = userDoc.data();
    } catch (_) {
      userMap = null;
    }
    try {
      final profileDoc = await _db.collection('professional_profiles').doc(uid).get();
      profileMap = profileDoc.data();
    } catch (_) {
      profileMap = null;
    }

    if (userMap == null && profileMap == null && (fallbackPhone ?? '').trim().isNotEmpty) {
      return resolveByPhone(fallbackPhone!);
    }

    final normalizedPhone = normalizePhone(
      _firstNonEmptyString(<dynamic>[
        userMap?['phoneNumber'],
        profileMap?['phoneNumber'],
        fallbackPhone,
      ]),
    );

    return _buildDecision(
      normalizedPhone: normalizedPhone,
      userMaps: userMap == null
          ? const <Map<String, dynamic>>[]
          : <Map<String, dynamic>>[userMap],
      profileMaps: profileMap == null
          ? const <Map<String, dynamic>>[]
          : <Map<String, dynamic>>[profileMap],
    );
  }

  static Future<void> persistLocalDecision(
    GetStorage storage,
    RbacDecision decision, {
    String? uid,
    bool hideProfessionalCta = true,
  }) async {
    final scopedUid = _resolvedUid(uid);
    if (scopedUid.isNotEmpty) {
      await storage.write(_localSessionUidKey, scopedUid);
    } else {
      await storage.remove(_localSessionUidKey);
    }
    await storage.write(_localRbacRoleKey, decision.role);
    await storage.write(_localApprovalStatusKey, decision.approvalStatus);
    await storage.write(
      _localProfessionalOnboardedKey,
      decision.isProfessionalOnboarded,
    );
    await storage.write(
      _localProfessionalProfileKey,
      decision.hasProfessionalProfile,
    );
    await storage.write(_localUserRoleKey, decision.compatibleUserRole);
    if (hideProfessionalCta) {
      await storage.write(_localGuestCtaKey, true);
      await storage.write(_localProfessionalCtaKey, true);
    }
  }

  static Future<void> clearLocalDecision(
    GetStorage storage, {
    bool clearGuestCtas = true,
  }) async {
    await storage.remove(_localSessionUidKey);
    await storage.remove(_localRbacRoleKey);
    await storage.remove(_localApprovalStatusKey);
    await storage.remove(_localProfessionalOnboardedKey);
    await storage.remove(_localProfessionalProfileKey);
    await storage.remove(_localUserRoleKey);
    if (clearGuestCtas) {
      await storage.remove(_localGuestCtaKey);
      await storage.remove(_localProfessionalCtaKey);
    }
  }

  static bool isLocalDecisionScopedToUid(GetStorage storage, {String? uid}) {
    final scopedUid = _resolvedUid(uid);
    if (scopedUid.isEmpty) {
      return false;
    }
    final cachedUid = (storage.read(_localSessionUidKey) as String?)?.trim();
    return cachedUid != null && cachedUid == scopedUid;
  }

  static String _resolvedUid(String? uid) {
    final directUid = uid?.trim();
    if (directUid != null && directUid.isNotEmpty) {
      return directUid;
    }
    final currentUid = FirebaseAuth.instance.currentUser?.uid.trim();
    return currentUid ?? '';
  }

  static RbacDecision _buildDecision({
    required String normalizedPhone,
    required List<Map<String, dynamic>> userMaps,
    required List<Map<String, dynamic>> profileMaps,
  }) {
    final lowerCaseRoles = userMaps
        .expand(
          (item) => <String>[
            _firstNonEmptyString(<dynamic>[item['role']]),
            _firstNonEmptyString(<dynamic>[item['rbacRole']]),
          ],
        )
        .map((item) => item.toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();

    if (isAdminPhone(normalizedPhone) || lowerCaseRoles.contains('admin')) {
      return const RbacDecision(
        role: RbacDecision.roleAdmin,
        approvalStatus: 'approved',
        isProfessionalOnboarded: false,
        hasProfessionalProfile: false,
      );
    }

    final hasProfessionalProfile = profileMaps.isNotEmpty ||
        userMaps.any((item) => _asBool(item['hasProfessionalProfile']));

    final hasProfessionalRole = lowerCaseRoles.any(
      (role) => role == 'professional' || role == 'professional_pending',
    );
    final hasProfessionalOnboardFlag = userMaps.any(
      (item) => _asBool(item['isProfessionalOnboarded']),
    );

    final profileStatusCandidates = <String>[
      ...profileMaps.map(
        (item) => _firstNonEmptyString(
          <dynamic>[item['status'], item['professionalStatus']],
        ),
      ),
    ];
    final userProfessionalStatusCandidates = <String>[
      ...userMaps.map(
        (item) => _firstNonEmptyString(
          <dynamic>[item['professionalStatus']],
        ),
      ),
    ];
    final hasProfessionalStatus =
        profileStatusCandidates.any((status) => status.trim().isNotEmpty) ||
            ((hasProfessionalRole ||
                    hasProfessionalOnboardFlag ||
                    hasProfessionalProfile) &&
                userProfessionalStatusCandidates.any(_isKnownProfessionalStatus));

    final isProfessionalOnboarded =
        hasProfessionalProfile ||
        hasProfessionalRole ||
        hasProfessionalOnboardFlag ||
        hasProfessionalStatus;

    if (isProfessionalOnboarded) {
      final approvalStatusCandidates = <String>[
        ...profileStatusCandidates,
        ...userProfessionalStatusCandidates,
        if (hasProfessionalRole ||
            hasProfessionalOnboardFlag ||
            hasProfessionalProfile)
          ...userMaps.map(
            (item) => _firstNonEmptyString(
              <dynamic>[item['approvalStatus']],
            ),
          ),
      ];
      final approvalStatus =
          _approvalStatusFromStatuses(approvalStatusCandidates);
      return RbacDecision(
        role: RbacDecision.roleProfessional,
        approvalStatus: approvalStatus,
        isProfessionalOnboarded: true,
        hasProfessionalProfile: hasProfessionalProfile,
      );
    }

    return const RbacDecision(
      role: RbacDecision.roleCustomer,
      approvalStatus: 'approved',
      isProfessionalOnboarded: false,
      hasProfessionalProfile: false,
    );
  }

  static String _approvalStatusFromStatuses(Iterable<String> statuses) {
    final normalized = statuses
        .map((status) => status.toLowerCase().trim())
        .where((status) => status.isNotEmpty)
        .toList(growable: false);

    if (normalized.any(_isApprovedProfessionalStatus)) {
      return 'approved';
    }
    if (normalized.any(_isRejectedProfessionalStatus)) {
      return 'rejected';
    }
    return 'pending';
  }

  static bool _isApprovedProfessionalStatus(String status) {
    return const <String>{
      'approved',
      'verified',
      'online',
      'active',
      'available',
      'working',
      'on_ground',
      'engaged',
      'in_service',
    }.contains(status);
  }

  static bool _isRejectedProfessionalStatus(String status) {
    return const <String>{'rejected', 'suspended'}.contains(status);
  }

  static bool _isKnownProfessionalStatus(String status) {
    final normalized = status.toLowerCase().trim();
    if (normalized.isEmpty) {
      return false;
    }
    return const <String>{
      'phone_verified',
      'under_review',
      'pending',
      'reupload_requested',
      're-upload_requested',
      'approved',
      'verified',
      'online',
      'active',
      'available',
      'working',
      'on_ground',
      'engaged',
      'in_service',
      'rejected',
      'suspended',
    }.contains(normalized);
  }

  static bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value?.toString().toLowerCase().trim();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
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
}

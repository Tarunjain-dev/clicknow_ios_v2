import 'dart:async';

import 'package:clicknow_version2/app/screens/admin/professionals/models/admin_professional_profile.dart';
import 'package:clicknow_version2/app/services/admin_user_management_service.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

enum AdminProfessionalBucket { waiting, online, working, verified, suspended }

enum AdminProfessionalAction {
  approve,
  reject,
  suspend,
  reactivate,
  block,
  unblock,
  markFeatured,
  removeFeatured,
  verifyDocuments,
  requestBankUpdate,
}

extension AdminProfessionalBucketX on AdminProfessionalBucket {
  String get title {
    switch (this) {
      case AdminProfessionalBucket.waiting:
        return 'Waiting Approval';
      case AdminProfessionalBucket.online:
        return 'Active (Online)';
      case AdminProfessionalBucket.working:
        return 'Working On Ground';
      case AdminProfessionalBucket.verified:
        return 'Verified Professionals';
      case AdminProfessionalBucket.suspended:
        return 'Suspended / Blocked';
    }
  }

  String get code {
    return name;
  }
}

class AdminProfessionalsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AdminUserManagementService _accountService =
      AdminUserManagementService.instance;

  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;

  final RxList<AdminProfessionalProfile> allProfessionals =
      <AdminProfessionalProfile>[].obs;
  final RxList<AdminProfessionalProfile> filteredProfessionals =
      <AdminProfessionalProfile>[].obs;

  final Rx<AdminProfessionalBucket> selectedBucket =
      AdminProfessionalBucket.waiting.obs;
  final RxString searchQuery = ''.obs;

  final RxnString serviceFilter = RxnString();
  final RxnString professionalTypeFilter = RxnString();
  final RxnString stateFilter = RxnString();
  final RxnString cityFilter = RxnString();
  final RxnString pincodeFilter = RxnString();
  final Rxn<AdminProfessionalBucket> statusFilter =
      Rxn<AdminProfessionalBucket>();

  final RxMap<String, bool> actionLoadingByKey = <String, bool>{}.obs;
  final RxMap<String, String> availabilityStatusByUid = <String, String>{}.obs;

  final List<String> serviceTypeOptions = const <String>[
    'Photo and Videography Services',
    'Music & Live Performance Services',
    'Professional Anchor Services',
    'Professional DJ Services',
    'Live Wedding Painter Services',
    'Professional Magician Services',
  ];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _profilesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;

  @override
  void onInit() {
    super.onInit();
    _listenProfessionals();
  }

  bool get hasActiveFilters {
    return activeFilterCount > 0;
  }

  int get activeFilterCount {
    var count = 0;
    if (serviceFilter.value != null) count++;
    if (professionalTypeFilter.value != null) count++;
    if (stateFilter.value != null) count++;
    if (cityFilter.value != null) count++;
    if (pincodeFilter.value != null) count++;
    if (statusFilter.value != null) count++;
    return count;
  }

  List<String> get availableStates {
    final set = <String>{};
    for (final profile in allProfessionals) {
      if (profile.state.isNotEmpty) {
        set.add(profile.state);
      }
    }
    final sorted = set.toList()..sort();
    return sorted;
  }

  List<String> availableCities({String? forState}) {
    final set = <String>{};
    for (final profile in allProfessionals) {
      if (forState != null &&
          forState.isNotEmpty &&
          profile.state != forState) {
        continue;
      }
      if (profile.city.isNotEmpty) {
        set.add(profile.city);
      }
    }
    final sorted = set.toList()..sort();
    return sorted;
  }

  List<String> availablePincodes({String? forState, String? forCity}) {
    final set = <String>{};
    for (final profile in allProfessionals) {
      if (forState != null &&
          forState.isNotEmpty &&
          profile.state != forState) {
        continue;
      }
      if (forCity != null && forCity.isNotEmpty && profile.city != forCity) {
        continue;
      }
      if (profile.pincode.isNotEmpty) {
        set.add(profile.pincode);
      }
    }
    final sorted = set.toList()..sort();
    return sorted;
  }

  int countForBucket(AdminProfessionalBucket bucket) {
    return allProfessionals.where((p) => _matchesBucket(p, bucket)).length;
  }

  bool isActionLoading(String uid, {AdminProfessionalAction? action}) {
    if (action != null) {
      return actionLoadingByKey[_actionKey(uid, action)] == true;
    }
    return AdminProfessionalAction.values.any(
      (item) => actionLoadingByKey[_actionKey(uid, item)] == true,
    );
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query.trim();
    _applyFilters();
  }

  void selectBucket(
    AdminProfessionalBucket bucket, {
    bool fromFilterSheet = false,
  }) {
    selectedBucket.value = bucket;
    if (fromFilterSheet) {
      statusFilter.value = bucket;
    } else {
      statusFilter.value = null;
    }
    _applyFilters();
  }

  void applyFilter({
    String? serviceType,
    String? professionalType,
    String? state,
    String? city,
    String? pincode,
  }) {
    serviceFilter.value = _normalizeFilterValue(serviceType);
    professionalTypeFilter.value = _normalizeFilterValue(professionalType);
    stateFilter.value = _normalizeFilterValue(state);
    cityFilter.value = _normalizeFilterValue(city);
    pincodeFilter.value = _normalizeFilterValue(pincode);
    _applyFilters();
  }

  void clearFilters() {
    serviceFilter.value = null;
    professionalTypeFilter.value = null;
    stateFilter.value = null;
    cityFilter.value = null;
    pincodeFilter.value = null;
    statusFilter.value = null;
    _applyFilters();
  }

  Future<void> refreshProfessionals({bool showMessage = false}) async {
    isRefreshing.value = true;
    try {
      final snapshot = await _db.collection('professional_profiles').get();
      _consumeSnapshot(snapshot.docs);
      if (showMessage) {
        AppSnackbar.success(
          'Refreshed',
          'Professionals list has been refreshed successfully.',
        );
      }
    } catch (_) {
      if (showMessage) {
        AppSnackbar.error(
          'Refresh Failed',
          'Unable to refresh professionals right now.',
        );
      }
    } finally {
      isRefreshing.value = false;
      isLoading.value = false;
    }
  }

  Future<bool> approveProfessional({
    required AdminProfessionalProfile profile,
    required String professionalType,
    String comment = '',
  }) async {
    final selectedType = professionalType.toLowerCase() == 'pro'
        ? 'pro'
        : 'normal';

    return _runProfileAction(
      uid: profile.uid,
      action: AdminProfessionalAction.approve,
      onAction: () async {
        final now = FieldValue.serverTimestamp();
        final adminUid = _auth.currentUser?.uid ?? '';

        await _db.collection('professional_profiles').doc(profile.uid).set({
          'status': 'approved',
          'approvalStatus': 'APPROVED',
          'accountStatus': 'ACTIVE',
          'adminProfessionalType': selectedType,
          'adminReview': {
            'decision': 'approved',
            'professionalType': selectedType,
            'comment': comment.trim(),
            'updatedBy': adminUid,
            'updatedAt': now,
          },
          'approvedAt': now,
          'professionalAvailabilityStatus': 'offline',
          'updatedAt': now,
        }, SetOptions(merge: true));

        await _db.collection('users').doc(profile.uid).set({
          'role': 'professional',
          'rbacRole': 'professional',
          'approvalStatus': 'approved',
          'isProfessionalOnboarded': true,
          'hasProfessionalProfile': true,
          'professionalStatus': 'approved',
          'professionalType': selectedType,
          'professionalAvailableForBooking': false,
          'professionalAvailabilityStatus': 'offline',
          'updatedAt': now,
        }, SetOptions(merge: true));
        await _writeAdminUserAudit(
          profile: profile,
          action: 'APPROVE_PROFESSIONAL',
          oldValue: profile.status,
          newValue: 'approved',
          reason: comment,
        );
      },
      successTitle: 'Professional Approved',
      successMessage: 'Professional was approved and moved to verified.',
      errorMessage: 'Could not approve this professional.',
    );
  }

  Future<bool> rejectProfessional({
    required AdminProfessionalProfile profile,
    required String comment,
  }) async {
    final reason = comment.trim();
    if (reason.isEmpty) {
      AppSnackbar.error('Comment Required', 'Please add rejection comment.');
      return false;
    }

    return _runProfileAction(
      uid: profile.uid,
      action: AdminProfessionalAction.reject,
      onAction: () async {
        final now = FieldValue.serverTimestamp();
        final adminUid = _auth.currentUser?.uid ?? '';

        await _db.collection('professional_profiles').doc(profile.uid).set({
          'status': 'rejected',
          'approvalStatus': 'REJECTED',
          'rejectionReason': reason,
          'adminReview': {
            'decision': 'rejected',
            'comment': reason,
            'updatedBy': adminUid,
            'updatedAt': now,
          },
          'rejectedAt': now,
          'professionalAvailabilityStatus': 'offline',
          'updatedAt': now,
        }, SetOptions(merge: true));

        await _db.collection('users').doc(profile.uid).set({
          'role': 'professional_pending',
          'rbacRole': 'professional',
          'approvalStatus': 'rejected',
          'rejectionReason': reason,
          'isProfessionalOnboarded': true,
          'hasProfessionalProfile': true,
          'professionalStatus': 'rejected',
          'professionalAvailableForBooking': false,
          'professionalAvailabilityStatus': 'offline',
          'updatedAt': now,
        }, SetOptions(merge: true));
        await _writeAdminUserAudit(
          profile: profile,
          action: 'REJECT_PROFESSIONAL',
          oldValue: profile.status,
          newValue: 'rejected',
          reason: reason,
        );
      },
      successTitle: 'Professional Rejected',
      successMessage: 'Rejection has been recorded successfully.',
      errorMessage: 'Could not reject this professional.',
    );
  }

  Future<bool> manageProfessional({
    required AdminProfessionalProfile profile,
    required AdminProfessionalAction action,
    String reason = '',
  }) {
    final config = _professionalActionConfig(action);
    return _runProfileAction(
      uid: profile.uid,
      action: action,
      onAction: () => _accountService.performAction(
        targetUserId: profile.uid,
        targetUserRole: 'professional',
        action: config.backendAction,
        reason: reason,
      ),
      successTitle: config.successTitle,
      successMessage: config.successMessage,
      errorMessage: config.errorMessage,
    );
  }

  _ProfessionalActionConfig _professionalActionConfig(
    AdminProfessionalAction action,
  ) {
    switch (action) {
      case AdminProfessionalAction.suspend:
        return const _ProfessionalActionConfig(
          backendAction: AdminUserAction.suspendProfessional,
          successTitle: 'Professional Suspended',
          successMessage:
              'The professional can no longer accept or start bookings.',
          errorMessage: 'Could not suspend this professional.',
        );
      case AdminProfessionalAction.reactivate:
        return const _ProfessionalActionConfig(
          backendAction: AdminUserAction.reactivateProfessional,
          successTitle: 'Professional Reactivated',
          successMessage: 'The professional account is active again.',
          errorMessage: 'Could not reactivate this professional.',
        );
      case AdminProfessionalAction.block:
        return const _ProfessionalActionConfig(
          backendAction: AdminUserAction.blockProfessional,
          successTitle: 'Professional Blocked',
          successMessage: 'The professional account has been blocked.',
          errorMessage: 'Could not block this professional.',
        );
      case AdminProfessionalAction.unblock:
        return const _ProfessionalActionConfig(
          backendAction: AdminUserAction.unblockProfessional,
          successTitle: 'Professional Unblocked',
          successMessage: 'The professional account is active again.',
          errorMessage: 'Could not unblock this professional.',
        );
      case AdminProfessionalAction.markFeatured:
        return const _ProfessionalActionConfig(
          backendAction: AdminUserAction.markFeatured,
          successTitle: 'Featured Professional',
          successMessage: 'The professional is now featured.',
          errorMessage: 'Could not feature this professional.',
        );
      case AdminProfessionalAction.removeFeatured:
        return const _ProfessionalActionConfig(
          backendAction: AdminUserAction.removeFeatured,
          successTitle: 'Featured Badge Removed',
          successMessage: 'The professional is no longer featured.',
          errorMessage: 'Could not remove the featured badge.',
        );
      case AdminProfessionalAction.verifyDocuments:
        return const _ProfessionalActionConfig(
          backendAction: AdminUserAction.verifyDocuments,
          successTitle: 'Documents Verified',
          successMessage: 'Documents were verified manually.',
          errorMessage: 'Could not verify these documents.',
        );
      case AdminProfessionalAction.requestBankUpdate:
        return const _ProfessionalActionConfig(
          backendAction: AdminUserAction.requestBankUpdate,
          successTitle: 'Bank Update Requested',
          successMessage:
              'The professional has been asked to update bank details.',
          errorMessage: 'Could not request a bank details update.',
        );
      case AdminProfessionalAction.approve:
      case AdminProfessionalAction.reject:
        throw ArgumentError('Use the existing application review method.');
    }
  }

  Future<void> _listenProfessionals() async {
    await refreshProfessionals();
    _profilesSub = _db
        .collection('professional_profiles')
        .snapshots()
        .listen(
          (snapshot) {
            _consumeSnapshot(snapshot.docs);
            isLoading.value = false;
          },
          onError: (_) {
            isLoading.value = false;
            AppSnackbar.error(
              'Fetch Failed',
              'Unable to fetch professionals from server.',
            );
          },
        );

    _usersSub = _db
        .collection('users')
        .snapshots()
        .listen(
          (snapshot) {
            _consumeUsersSnapshot(snapshot.docs);
          },
          onError: (_) {
            // Keep existing list rendering even if users stream fails.
          },
        );
  }

  void _consumeSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final parsed =
        docs.map(AdminProfessionalProfile.fromDocument).toList(growable: false)
          ..sort((a, b) {
            final right = b.referenceDate;
            final left = a.referenceDate;
            if (left == null && right == null) return 0;
            if (left == null) return 1;
            if (right == null) return -1;
            return right.compareTo(left);
          });

    allProfessionals.assignAll(parsed);
    _applyFilters();
  }

  void _consumeUsersSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final map = <String, String>{};
    for (final doc in docs) {
      final data = doc.data();
      final role = (data['role'] ?? '').toString().trim().toLowerCase();
      final rbacRole = (data['rbacRole'] ?? '').toString().trim().toLowerCase();
      final isProfessional =
          rbacRole == 'professional' ||
          role == 'professional' ||
          role == 'professional_pending';
      if (!isProfessional) {
        continue;
      }
      final status = (data['professionalAvailabilityStatus'] ?? '')
          .toString()
          .trim();
      if (status.isNotEmpty) {
        map[doc.id] = status.toLowerCase();
      }
    }
    availabilityStatusByUid.assignAll(map);
    _applyFilters();
  }

  void _applyFilters() {
    final query = searchQuery.value.toLowerCase();

    final filtered = allProfessionals
        .where((profile) {
          if (!_matchesBucket(profile, selectedBucket.value)) {
            return false;
          }

          if (query.isNotEmpty && !profile.searchableText.contains(query)) {
            return false;
          }

          final selectedService = serviceFilter.value;
          if (selectedService != null &&
              selectedService.isNotEmpty &&
              profile.serviceType.toLowerCase() !=
                  selectedService.toLowerCase()) {
            return false;
          }

          final selectedProfessionalType = professionalTypeFilter.value;
          if (selectedProfessionalType != null &&
              selectedProfessionalType.isNotEmpty &&
              profile.professionalTypeForFilter != selectedProfessionalType) {
            return false;
          }

          final selectedState = stateFilter.value;
          if (selectedState != null &&
              selectedState.isNotEmpty &&
              profile.state.toLowerCase() != selectedState.toLowerCase()) {
            return false;
          }

          final selectedCity = cityFilter.value;
          if (selectedCity != null &&
              selectedCity.isNotEmpty &&
              profile.city.toLowerCase() != selectedCity.toLowerCase()) {
            return false;
          }

          final selectedPincode = pincodeFilter.value;
          if (selectedPincode != null && selectedPincode.isNotEmpty) {
            if (!profile.pincode.toLowerCase().contains(
              selectedPincode.toLowerCase(),
            )) {
              return false;
            }
          }

          return true;
        })
        .toList(growable: false);

    filteredProfessionals.assignAll(filtered);
  }

  bool _matchesBucket(
    AdminProfessionalProfile profile,
    AdminProfessionalBucket bucket,
  ) {
    final status = profile.status;
    final accountStatus = profile.accountStatus;

    switch (bucket) {
      case AdminProfessionalBucket.waiting:
        if (accountStatus == 'SUSPENDED' || accountStatus == 'BLOCKED') {
          return false;
        }
        return const <String>{
          'under_review',
          'pending',
          'profile_submitted',
          'submitted',
          'reupload_requested',
          'phone_verified',
        }.contains(status);
      case AdminProfessionalBucket.online:
        if (accountStatus == 'SUSPENDED' || accountStatus == 'BLOCKED') {
          return false;
        }
        return _isAvailableForBooking(profile);
      case AdminProfessionalBucket.working:
        if (accountStatus == 'SUSPENDED' || accountStatus == 'BLOCKED') {
          return false;
        }
        return const <String>{
          'working',
          'on_ground',
          'engaged',
          'in_service',
        }.contains(status);
      case AdminProfessionalBucket.verified:
        if (accountStatus == 'SUSPENDED' || accountStatus == 'BLOCKED') {
          return false;
        }
        return const <String>{'approved', 'verified'}.contains(status);
      case AdminProfessionalBucket.suspended:
        return accountStatus == 'SUSPENDED' ||
            accountStatus == 'BLOCKED' ||
            const <String>{'suspended', 'blocked'}.contains(status);
    }
  }

  bool _isAvailableForBooking(AdminProfessionalProfile profile) {
    final status = profile.status;
    final isApprovedProfessional = const <String>{
      'approved',
      'verified',
      'online',
      'active',
      'available',
      'working',
      'on_ground',
      'in_service',
    }.contains(status);
    if (!isApprovedProfessional) {
      return false;
    }

    final fromUsers = (availabilityStatusByUid[profile.uid] ?? '')
        .trim()
        .toLowerCase();
    final fromProfile = profile.professionalAvailabilityStatus;
    final effective = fromUsers.isNotEmpty ? fromUsers : fromProfile;
    return const <String>{'online', 'active', 'available'}.contains(effective);
  }

  String? _normalizeFilterValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<bool> _runProfileAction({
    required String uid,
    required AdminProfessionalAction action,
    required Future<void> Function() onAction,
    required String successTitle,
    required String successMessage,
    required String errorMessage,
  }) async {
    if (_auth.currentUser == null) {
      AppSnackbar.error('Session Expired', 'Please login as admin again.');
      return false;
    }

    final key = _actionKey(uid, action);
    actionLoadingByKey[key] = true;
    try {
      await onAction();
      AppSnackbar.success(successTitle, successMessage);
      return true;
    } catch (_) {
      AppSnackbar.error('Action Failed', errorMessage);
      return false;
    } finally {
      actionLoadingByKey.remove(key);
    }
  }

  Future<void> _writeAdminUserAudit({
    required AdminProfessionalProfile profile,
    required String action,
    required String oldValue,
    required String newValue,
    String reason = '',
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) return;
    try {
      final ref = _db
          .collection(ServiceCatalogPaths.adminActionLogsCollection)
          .doc();
      await ref.set(<String, dynamic>{
        'logId': ref.id,
        'targetUserId': profile.uid,
        'targetUserRole': 'professional',
        'action': action,
        'reason': reason.trim().isEmpty ? null : reason.trim(),
        'performedByAdminId': admin.uid,
        'performedByAdminName': admin.displayName ?? 'Admin',
        'oldValue': oldValue,
        'newValue': newValue,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Existing approval writes remain successful if legacy rules deny logs.
    }
  }

  String _actionKey(String uid, AdminProfessionalAction action) {
    return '$uid|${action.name}';
  }

  @override
  void onClose() {
    _profilesSub?.cancel();
    _usersSub?.cancel();
    super.onClose();
  }
}

class _ProfessionalActionConfig {
  const _ProfessionalActionConfig({
    required this.backendAction,
    required this.successTitle,
    required this.successMessage,
    required this.errorMessage,
  });

  final String backendAction;
  final String successTitle;
  final String successMessage;
  final String errorMessage;
}

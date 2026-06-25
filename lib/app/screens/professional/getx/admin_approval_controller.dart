import 'dart:async';

import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

enum ApplicationStage {
  phoneVerified,
  profileSubmitted,
  underReview,
  approved,
  welcomed,
}

class AdminApprovalController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();

  Rx<ApplicationStage> currentStage = ApplicationStage.underReview.obs;
  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final statusLabel = 'Under Review'.obs;
  final adminComment = ''.obs;
  final lastCheckedAt = Rxn<DateTime>();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  bool _markedApproved = false;
  bool _approvalFlowInProgress = false;

  @override
  void onInit() {
    super.onInit();
    _listenToApprovalStatus();
  }

  void _listenToApprovalStatus() {
    final user = _auth.currentUser;
    if (user == null) {
      isLoading.value = false;
      statusLabel.value = 'Login Required';
      return;
    }

    _sub = _db
        .collection('professional_profiles')
        .doc(user.uid)
        .snapshots()
        .listen(
          (doc) async {
            isLoading.value = false;
            if (!doc.exists) {
              currentStage.value = ApplicationStage.phoneVerified;
              statusLabel.value = 'Phone Verified';
              adminComment.value = '';
              lastCheckedAt.value = DateTime.now();
              return;
            }
            await _applyStatusFromData(doc.data(), user.uid);
          },
          onError: (_) {
            isLoading.value = false;
            statusLabel.value = 'Unable to fetch status';
          },
        );
  }

  Future<void> refreshStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppSnackbar.error(
        "Not Logged In",
        "Please login again to track your application status.",
      );
      return;
    }

    isRefreshing.value = true;
    try {
      final doc = await _db
          .collection('professional_profiles')
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        currentStage.value = ApplicationStage.phoneVerified;
        statusLabel.value = 'Phone Verified';
        adminComment.value = '';
      } else {
        await _applyStatusFromData(doc.data(), user.uid);
      }
      lastCheckedAt.value = DateTime.now();
      AppSnackbar.success(
        "Status Updated",
        "Application status has been refreshed.",
      );
    } catch (_) {
      AppSnackbar.error(
        "Refresh Failed",
        "Could not refresh application status right now.",
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> _applyStatusFromData(
    Map<String, dynamic>? data,
    String uid,
  ) async {
    var status = (data?['status'] ?? data?['professionalStatus'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    if (status.isEmpty) {
      final userSnapshot = await _db.collection('users').doc(uid).get();
      status = (userSnapshot.data()?['professionalStatus'] ?? '')
          .toString()
          .toLowerCase()
          .trim();
    }
    final review = data?['adminReview'];
    if (review is Map) {
      adminComment.value = (review['comment'] ?? '').toString().trim();
    } else {
      adminComment.value = (data?['reviewComment'] ?? '').toString().trim();
    }
    lastCheckedAt.value = DateTime.now();

    if (status == 'approved') {
      await _startApprovedFlow(uid);
      return;
    }
    _approvalFlowInProgress = false;

    if (status == 'under_review' ||
        status == 'pending' ||
        status == 'reupload_requested') {
      currentStage.value = ApplicationStage.underReview;
      statusLabel.value = 'Under Review';
      return;
    }

    if (status == 'profile_submitted' || status == 'submitted') {
      currentStage.value = ApplicationStage.profileSubmitted;
      statusLabel.value = 'Profile Submitted';
      return;
    }

    if (status == 'phone_verified') {
      currentStage.value = ApplicationStage.phoneVerified;
      statusLabel.value = 'Phone Verified';
      return;
    }

    if (status == 'rejected') {
      currentStage.value = ApplicationStage.underReview;
      statusLabel.value = 'Rejected';
      return;
    }

    currentStage.value = ApplicationStage.phoneVerified;
    statusLabel.value = 'Pending';
  }

  Future<void> _startApprovedFlow(String uid) async {
    await _markApproved(uid);
    if (_approvalFlowInProgress) {
      return;
    }
    _approvalFlowInProgress = true;

    currentStage.value = ApplicationStage.approved;
    statusLabel.value = 'Approved by admin. Preparing your dashboard...';

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (isClosed) return;

    currentStage.value = ApplicationStage.welcomed;
    statusLabel.value = 'Welcome to ClickNow. Redirecting now...';

    await Future<void>.delayed(const Duration(milliseconds: 1700));
    if (isClosed) return;

    if (Get.currentRoute != AppRoutes.professionalBottomNavigationRoute) {
      Get.offAllNamed(AppRoutes.professionalBottomNavigationRoute);
    }
  }

  Future<void> _markApproved(String uid) async {
    if (_markedApproved) return;
    _markedApproved = true;
    final now = FieldValue.serverTimestamp();
    await _db.collection('users').doc(uid).set({
      'role': 'professional',
      'rbacRole': 'professional',
      'approvalStatus': 'approved',
      'isProfessionalOnboarded': true,
      'hasProfessionalProfile': true,
      'professionalStatus': 'approved',
      'updatedAt': now,
    }, SetOptions(merge: true));
    _storage.write('hideGuestCTA', true);
    _storage.write('hideProfessionalCTA', true);
    _storage.write('userRole', 'professional');
    _storage.write('rbacRole', 'professional');
    _storage.write('approvalStatus', 'approved');
    _storage.write('isProfessionalOnboarded', true);
    _storage.write('hasProfessionalProfile', true);
  }

  /// Update Stage
  void updateStage(ApplicationStage stage) {
    currentStage.value = stage;
  }

  bool isCompleted(ApplicationStage stage) {
    return stage.index < currentStage.value.index;
  }

  bool isActive(ApplicationStage stage) {
    return stage.index == currentStage.value.index;
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}

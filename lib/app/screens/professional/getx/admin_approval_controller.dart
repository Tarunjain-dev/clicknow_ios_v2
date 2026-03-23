import 'dart:async';

import 'package:clicknow_version2/app/routes/appRoutes.dart';
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

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  bool _markedApproved = false;

  @override
  void onInit() {
    super.onInit();
    _listenToApprovalStatus();
  }

  void _listenToApprovalStatus() {
    final user = _auth.currentUser;
    if (user == null) {
      isLoading.value = false;
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
          return;
        }

        final status =
            (doc.data()?['status'] ?? '').toString().toLowerCase();

        if (status == 'approved') {
          currentStage.value = ApplicationStage.welcomed;
          await _markApproved(user.uid);
          if (Get.currentRoute !=
              AppRoutes.professionalBottomNavigationRoute) {
            Get.offAllNamed(AppRoutes.professionalBottomNavigationRoute);
          }
          return;
        }

        if (status == 'under_review' || status == 'pending') {
          currentStage.value = ApplicationStage.underReview;
        } else if (status == 'profile_submitted' || status == 'submitted') {
          currentStage.value = ApplicationStage.profileSubmitted;
        } else if (status == 'phone_verified') {
          currentStage.value = ApplicationStage.phoneVerified;
        } else {
          currentStage.value = ApplicationStage.phoneVerified;
        }
      },
      onError: (_) => isLoading.value = false,
    );
  }

  Future<void> _markApproved(String uid) async {
    if (_markedApproved) return;
    _markedApproved = true;
    final now = FieldValue.serverTimestamp();
    await _db.collection('users').doc(uid).set({
      'role': 'professional',
      'professionalStatus': 'approved',
      'updatedAt': now,
    }, SetOptions(merge: true));
    _storage.write('hideProfessionalCTA', true);
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

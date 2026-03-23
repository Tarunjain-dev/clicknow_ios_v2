import 'dart:async';

import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/utils/device_constants/appConstants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SplashController extends GetxController {
  static SplashController get instance => Get.find<SplashController>();

  final GetStorage _storage = GetStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _timer;

  @override
  void onReady() {
    super.onReady();
    _timer = Timer(const Duration(seconds: 3), () {
      _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    final hasSeenOnboarding = _storage.read('hasSeenOnboarding') ?? false;
    if (!hasSeenOnboarding) {
      Get.offAllNamed(AppRoutes.onBoardingRoute);
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      Get.offAllNamed(AppRoutes.loginRoute);
      return;
    }

    final cachedRole = _storage.read('userRole');
    if (cachedRole is String && cachedRole.isNotEmpty) {
      _routeByRole(cachedRole);
      return;
    }

    try {
      final snapshot = await _db.collection('users').doc(user.uid).get();
      final role = snapshot.data()?['role'] as String? ?? 'customer';
      _storage.write('userRole', role);
      _routeByRole(role);
    } catch (_) {
      Get.offAllNamed(AppRoutes.loginRoute);
    }
  }

  void _routeByRole(String role) {
    if (role == AppConstants.adminRole) {
      Get.offAllNamed(AppRoutes.adminDashboardRoute);
      return;
    }
    if (role == 'professional_pending') {
      Get.offAllNamed(AppRoutes.adminApprovalScreen);
      return;
    }
    if (role.startsWith('professional')) {
      Get.offAllNamed(AppRoutes.professionalBottomNavigationRoute);
      return;
    }
    Get.offAllNamed(AppRoutes.customerBottomNavigationRoute);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

import 'dart:async';
import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/screens/professional/getx/professional_onboarding_storage.dart';
import 'package:clicknow_version2/app/services/rbac_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SplashController extends GetxController {
  static SplashController get instance => Get.find<SplashController>();

  final GetStorage _storage = GetStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[SplashController] onInit');
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('[SplashController] onReady — scheduling navigation');
    // Skip the splash delay entirely when returning from iOS reCAPTCHA so the
    // OTP screen appears immediately without the 3-second wait.
    final delay = AuthController.hasPendingOtp
        ? Duration.zero
        : const Duration(seconds: 3);
    _timer = Timer(delay, _navigateNext);
  }

  Future<void> _navigateNext() async {
    debugPrint('[SplashController] _navigateNext start');

    // If AuthController is already live and the OTP screen is visible, the
    // user is mid-verification (e.g. returning from iOS reCAPTCHA). Do not
    // navigate away — the OTP screen must remain visible.
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (auth.showOtp.value) {
        debugPrint(
          '[SplashController] OTP screen active — skipping navigation',
        );
        return;
      }
    }

    final hasSeenOnboarding = _storage.read('hasSeenOnboarding') ?? false;
    if (!hasSeenOnboarding) {
      debugPrint('[SplashController] → onboarding (first launch)');
      Get.offAllNamed(AppRoutes.onBoardingRoute);
      return;
    }

    final user = _auth.currentUser;

    // --- Authenticated user: route to their dashboard ---
    if (user != null) {
      debugPrint('[SplashController] user authenticated uid=${user.uid}');
      _storage.write(AuthController.guestUserStorageKey, false);
      try {
        final useCached = RbacService.isLocalDecisionScopedToUid(
          _storage,
          uid: user.uid,
        );
        final decision = useCached
            ? _cachedDecisionFallback()
            : await RbacService.resolveByUid(
                uid: user.uid,
                fallbackPhone: user.phoneNumber,
              );
        await RbacService.persistLocalDecision(_storage, decision, uid: user.uid);
        await _routeByDecision(decision);
      } catch (_) {
        final useScopedCache = RbacService.isLocalDecisionScopedToUid(
          _storage,
          uid: user.uid,
        );
        final fallback = useScopedCache
            ? _cachedDecisionFallback()
            : _safeFallbackForCurrentUser(user);
        await RbacService.persistLocalDecision(_storage, fallback, uid: user.uid);
        await _routeByDecision(fallback);
      }
      return;
    }

    // --- No authenticated user ---

    // If there is a pending OTP (e.g. returning from iOS reCAPTCHA), go to
    // the login screen so AuthController can restore the OTP state.
    if (AuthController.hasPendingOtp) {
      debugPrint(
        '[SplashController] → login (pending OTP — restoring after reCAPTCHA return)',
      );
      // Ensure AuthController is initialised so it can restore OTP state.
      AuthController.instance;
      Get.offAllNamed(AppRoutes.loginRoute);
      return;
    }

    final isGuestUser =
        _storage.read(AuthController.guestUserStorageKey) == true;
    if (isGuestUser) {
      debugPrint('[SplashController] → customer dashboard (guest mode)');
      Get.offAllNamed(AppRoutes.customerBottomNavigationRoute);
      return;
    }

    debugPrint('[SplashController] → login (unauthenticated)');
    AuthController.instance.resetLocalAuthState(keepGuestMode: false);
    Get.offAllNamed(AppRoutes.loginRoute);
  }

  Future<void> _routeByDecision(RbacDecision decision) async {
    if (decision.isAdmin) {
      Get.offAllNamed(AppRoutes.adminDashboardRoute);
      return;
    }

    if (decision.isProfessional) {
      final onboardingCompleted =
          await ProfessionalOnboardingStorage.readOnboardingCompleted();
      final hasProfessionalSetup =
          decision.hasProfessionalProfile ||
          onboardingCompleted ||
          decision.isProfessionalApproved;
      if (!hasProfessionalSetup) {
        Get.offAllNamed(AppRoutes.professionalRegistrationRoute);
        return;
      }
      if (!decision.isProfessionalApproved) {
        Get.offAllNamed(AppRoutes.adminApprovalScreen);
        return;
      }
      Get.offAllNamed(AppRoutes.professionalBottomNavigationRoute);
      return;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      Get.offAllNamed(AppRoutes.loginRoute);
      return;
    }
    final isProfileCompleted = await _isCustomerProfileCompleted(uid);
    _storage.write(
      AuthController.customerProfileCompletedStorageKey,
      isProfileCompleted,
    );
    if (!isProfileCompleted) {
      Get.offAllNamed(AppRoutes.customerProfileCompletionRoute);
      return;
    }
    Get.offAllNamed(AppRoutes.customerBottomNavigationRoute);
  }

  RbacDecision _cachedDecisionFallback() {
    final cachedRbacRole =
        (_storage.read(AuthController.rbacRoleStorageKey) as String?)
            ?.trim()
            .toLowerCase();
    final cachedCompatibleRole = (_storage.read('userRole') as String?)
        ?.trim()
        .toLowerCase();

    final role = () {
      if (cachedRbacRole == RbacDecision.roleAdmin ||
          cachedRbacRole == RbacDecision.roleProfessional ||
          cachedRbacRole == RbacDecision.roleCustomer) {
        return cachedRbacRole!;
      }
      if (cachedCompatibleRole == 'admin') {
        return RbacDecision.roleAdmin;
      }
      if (cachedCompatibleRole == 'professional' ||
          cachedCompatibleRole == 'professional_pending') {
        return RbacDecision.roleProfessional;
      }
      return RbacDecision.roleCustomer;
    }();
    final cachedProfessionalOnboarded =
        _storage.read(AuthController.professionalOnboardedStorageKey) == true;
    final effectiveRole = role;

    final cachedApprovalStatus =
        (_storage.read(AuthController.approvalStatusStorageKey) as String?)
            ?.trim()
            .toLowerCase();
    final approval =
        cachedApprovalStatus == null || cachedApprovalStatus.isEmpty
        ? (cachedCompatibleRole == 'professional_pending'
              ? 'pending'
              : 'approved')
        : cachedApprovalStatus;

    final onboarded =
        cachedProfessionalOnboarded ||
        effectiveRole == RbacDecision.roleProfessional;
    final hasProfile =
        _storage.read(AuthController.professionalProfileStorageKey) == true;

    return RbacDecision(
      role: effectiveRole,
      approvalStatus: approval,
      isProfessionalOnboarded: onboarded,
      hasProfessionalProfile: hasProfile,
    );
  }

  RbacDecision _safeFallbackForCurrentUser(User user) {
    final phoneNumber = (user.phoneNumber ?? '').trim();
    if (phoneNumber.isNotEmpty && RbacService.isAdminPhone(phoneNumber)) {
      return const RbacDecision(
        role: RbacDecision.roleAdmin,
        approvalStatus: 'approved',
        isProfessionalOnboarded: false,
        hasProfessionalProfile: false,
      );
    }
    return const RbacDecision(
      role: RbacDecision.roleCustomer,
      approvalStatus: 'approved',
      isProfessionalOnboarded: false,
      hasProfessionalProfile: false,
    );
  }

  Future<bool> _isCustomerProfileCompleted(String uid) async {
    try {
      final snapshot = await _db.collection('users').doc(uid).get();
      final data = snapshot.data() ?? <String, dynamic>{};
      final fullName = (data['fullName'] as String? ?? '').trim();
      return fullName.isNotEmpty;
    } catch (_) {
      return _storage.read(AuthController.customerProfileCompletedStorageKey) ==
          true;
    }
  }

  @override
  void onClose() {
    debugPrint('[SplashController] onClose');
    _timer?.cancel();
    super.onClose();
  }
}

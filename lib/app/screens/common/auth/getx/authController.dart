import 'dart:async';

import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/professional/getx/professional_onboarding_storage.dart';
import 'package:clicknow_version2/app/services/rbac_service.dart';
import 'package:clicknow_version2/app/services/recaptcha_service.dart';
import 'package:clicknow_version2/app/services/notifications/fcm_notification_service.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_auth/smart_auth.dart';

class AuthController extends GetxController {
  static const String guestUserStorageKey = 'isGuestUser';
  static const String hideGuestCtaStorageKey = 'hideGuestCTA';
  static const String hideProfessionalCtaStorageKey = 'hideProfessionalCTA';
  static const String rbacSessionUidStorageKey = 'rbacSessionUid';
  static const String customerProfileCompletedStorageKey =
      'customerProfileCompleted';
  static const String rbacRoleStorageKey = 'rbacRole';
  static const String approvalStatusStorageKey = 'approvalStatus';
  static const String professionalOnboardedStorageKey =
      'isProfessionalOnboarded';
  static const String professionalProfileStorageKey = 'hasProfessionalProfile';
  static const String loginIntentStorageKey = 'authLoginIntent';

  // Keys for persisting pending OTP state across iOS reCAPTCHA return-flow.
  static const String pendingOtpFlagKey = 'pendingOtpFlag';
  static const String pendingVerificationIdKey = 'pendingVerificationId';
  static const String pendingPhoneKey = 'pendingPhone';
  // Set BEFORE verifyPhoneNumber is called so hasPendingOtp is true while
  // reCAPTCHA is open (codeSent fires only after the browser returns).
  static const String pendingOtpInFlightKey = 'pendingOtpInFlight';

  static AuthController get instance {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>();
    }
    return Get.put(AuthController(), permanent: true);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();

  final phoneController = TextEditingController();
  final otpControllers = List.generate(6, (_) => TextEditingController());
  final otpFocusNodes = List.generate(6, (_) => FocusNode());

  final showOtp = false.obs;
  final secondsLeft = 0.obs;
  final failedOtpAttempts = 0.obs;
  final otpLockSecondsLeft = 0.obs;
  final isLoading = false.obs;
  final isGuestUser = false.obs;
  final userRole = 'customer'.obs;
  final rbacRole = RbacDecision.roleCustomer.obs;
  final approvalStatus = 'approved'.obs;
  final isProfessionalOnboarded = false.obs;
  final hasProfessionalProfile = false.obs;
  final showGuestSection = true.obs;
  final showProfessionalSection = true.obs;
  final loginIntent = RbacDecision.roleCustomer.obs;

  bool get isPhoneFieldLocked => showOtp.value;
  bool get isOtpLocked => otpLockSecondsLeft.value > 0;
  String get resendCountdown => _formatCountdown(secondsLeft.value);
  String get otpLockCountdown => _formatCountdown(otpLockSecondsLeft.value);

  Timer? _resendTimer;
  Timer? _otpLockTimer;
  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _confirmationResult;
  RbacDecision? _otpRoleDecision;
  int _otpListenEpoch = 0;
  bool _phoneAuthSettingsConfigured = false;

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

  @override
  void onInit() {
    super.onInit();
    debugPrint('[AuthController] onInit — boot');
    isGuestUser.value = _storage.read(guestUserStorageKey) == true;
    if (_auth.currentUser == null) {
      _clearLocalRbacCache(
        keepGuestMode: isGuestUser.value,
        clearAuthUiFlags: false,
      );
    }
    _restoreLoginIntent();
    _restoreCachedRbacState();
    _restorePendingOtpState();
    _loadAuthSectionVisibility();
    unawaited(_configurePhoneAuthSettings());
  }

  /// Restores verificationId + phone from storage after iOS reCAPTCHA return.
  void _restorePendingOtpState() {
    final isPending = _storage.read(pendingOtpFlagKey) == true;
    if (!isPending) return;

    final storedVerificationId =
        (_storage.read(pendingVerificationIdKey) as String?)?.trim();
    final storedPhone = (_storage.read(pendingPhoneKey) as String?)?.trim();

    if (storedVerificationId == null ||
        storedVerificationId.isEmpty ||
        storedPhone == null ||
        storedPhone.isEmpty) {
      debugPrint(
        '[AuthController] pendingOtp flag set but data missing — clearing.',
      );
      _clearPendingOtpStorage();
      return;
    }

    debugPrint(
      '[AuthController] Restoring pending OTP state — phone=$storedPhone '
      'verificationId=${storedVerificationId.substring(0, storedVerificationId.length.clamp(0, 8))}…',
    );

    _verificationId = storedVerificationId;
    // Restore the 10-digit local part into the phone controller.
    final localPart = storedPhone.startsWith('+91') && storedPhone.length >= 13
        ? storedPhone.substring(3)
        : storedPhone;
    phoneController.text = localPart;
    showOtp.value = true;
    _hideAuthEntrySectionsForCurrentAttempt();
    // Restart the resend timer so the UI is consistent.
    _startResendTimer();
  }

  /// Returns true when there is a valid pending OTP waiting for the user,
  /// OR when verifyPhoneNumber has been called but codeSent has not yet fired
  /// (i.e. the reCAPTCHA browser is open on iOS).
  static bool get hasPendingOtp {
    final storage = GetStorage();
    // Full pending state: verificationId received, OTP screen should be shown.
    if (storage.read(pendingOtpFlagKey) == true &&
        (storage.read(pendingVerificationIdKey) as String? ?? '').isNotEmpty &&
        (storage.read(pendingPhoneKey) as String? ?? '').isNotEmpty) {
      return true;
    }
    // In-flight state: verifyPhoneNumber called, reCAPTCHA open, codeSent not
    // yet fired. Phone is stored so we know which number is being verified.
    if (storage.read(pendingOtpInFlightKey) == true &&
        (storage.read(pendingPhoneKey) as String? ?? '').isNotEmpty) {
      return true;
    }
    return false;
  }

  void _persistPendingOtpState({
    required String verificationId,
    required String phoneNumber,
  }) {
    _storage.write(pendingOtpFlagKey, true);
    _storage.write(pendingVerificationIdKey, verificationId);
    _storage.write(pendingPhoneKey, phoneNumber);
    debugPrint(
      '[AuthController] Persisted pending OTP — phone=$phoneNumber '
      'verificationId=${verificationId.substring(0, verificationId.length.clamp(0, 8))}…',
    );
  }

  void _clearPendingOtpStorage() {
    _storage.remove(pendingOtpFlagKey);
    _storage.remove(pendingVerificationIdKey);
    _storage.remove(pendingPhoneKey);
    _storage.remove(pendingOtpInFlightKey);
    debugPrint('[AuthController] Cleared pending OTP storage.');
  }

  static bool get isGuestModeActive {
    return GetStorage().read(guestUserStorageKey) == true;
  }

  void _restoreCachedRbacState() {
    final currentUid = _auth.currentUser?.uid;
    final cachedUid = (_storage.read(rbacSessionUidStorageKey) as String?)
        ?.trim();
    if (currentUid == null || cachedUid == null || cachedUid != currentUid) {
      rbacRole.value = RbacDecision.roleCustomer;
      approvalStatus.value = 'approved';
      isProfessionalOnboarded.value = false;
      hasProfessionalProfile.value = false;
      userRole.value = 'customer';
      return;
    }

    final cachedRbacRole = (_storage.read(rbacRoleStorageKey) as String?)
        ?.trim()
        .toLowerCase();
    if (cachedRbacRole == RbacDecision.roleAdmin ||
        cachedRbacRole == RbacDecision.roleProfessional ||
        cachedRbacRole == RbacDecision.roleCustomer) {
      rbacRole.value = cachedRbacRole!;
    }
    approvalStatus.value =
        (_storage.read(approvalStatusStorageKey) as String?)
            ?.trim()
            .toLowerCase() ??
        'approved';
    isProfessionalOnboarded.value =
        _storage.read(professionalOnboardedStorageKey) == true;
    hasProfessionalProfile.value =
        _storage.read(professionalProfileStorageKey) == true;
    final cachedUserRole = (_storage.read('userRole') as String?)?.trim();
    if (cachedUserRole != null && cachedUserRole.isNotEmpty) {
      userRole.value = cachedUserRole;
    }
  }

  void _restoreLoginIntent() {
    final cachedIntent = (_storage.read(loginIntentStorageKey) as String?)
        ?.trim()
        .toLowerCase();
    if (cachedIntent == RbacDecision.roleProfessional ||
        cachedIntent == RbacDecision.roleCustomer) {
      loginIntent.value = cachedIntent!;
    } else {
      loginIntent.value = RbacDecision.roleCustomer;
    }
  }

  void _setLoginIntent(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized == RbacDecision.roleProfessional ||
        normalized == RbacDecision.roleCustomer) {
      loginIntent.value = normalized;
      _storage.write(loginIntentStorageKey, normalized);
    }
  }

  void _loadAuthSectionVisibility() {
    if (showOtp.value) {
      showGuestSection.value = false;
      showProfessionalSection.value = false;
      return;
    }

    final hideGuest = _storage.read(hideGuestCtaStorageKey) == true;
    final hideProfessional =
        _storage.read(hideProfessionalCtaStorageKey) == true;
    final currentRole = rbacRole.value;
    final hideByRole =
        currentRole == RbacDecision.roleAdmin ||
        currentRole == RbacDecision.roleProfessional;

    if (hideByRole) {
      showGuestSection.value = false;
      showProfessionalSection.value = false;
      return;
    }

    if (_auth.currentUser == null) {
      showGuestSection.value = !hideGuest;
      showProfessionalSection.value = !hideProfessional;
      return;
    }

    showGuestSection.value = !hideGuest;
    showProfessionalSection.value = !hideProfessional;
  }

  void _clearLocalRbacCache({
    required bool keepGuestMode,
    bool clearAuthUiFlags = true,
  }) {
    if (!keepGuestMode) {
      _storage.remove(guestUserStorageKey);
    }
    _storage.remove(rbacSessionUidStorageKey);
    _storage.remove(customerProfileCompletedStorageKey);
    _storage.remove(rbacRoleStorageKey);
    _storage.remove(approvalStatusStorageKey);
    _storage.remove(professionalOnboardedStorageKey);
    _storage.remove(professionalProfileStorageKey);
    // Do not remove loginIntentStorageKey when a pending OTP is in progress —
    // the role must survive the iOS reCAPTCHA round-trip.
    if (!hasPendingOtp) {
      _storage.remove(loginIntentStorageKey);
    }
    if (clearAuthUiFlags) {
      _storage.remove(hideGuestCtaStorageKey);
      _storage.remove(hideProfessionalCtaStorageKey);
    }
  }

  void resetLocalAuthState({bool keepGuestMode = false}) {
    _clearLocalRbacCache(keepGuestMode: keepGuestMode, clearAuthUiFlags: true);
    clearAuthInputFields(clearPhone: true);
    showGuestSection.value = true;
    showProfessionalSection.value = true;
    _setLoginIntent(RbacDecision.roleCustomer);
  }

  void clearAuthInputFields({bool clearPhone = true}) {
    _resendTimer?.cancel();
    _otpLockTimer?.cancel();
    secondsLeft.value = 0;
    failedOtpAttempts.value = 0;
    otpLockSecondsLeft.value = 0;
    _verificationId = null;
    _resendToken = null;
    _clearPendingOtpStorage();
    if (clearPhone) {
      phoneController.clear();
    }
    _clearOtpFields();
  }

  void editPhoneNumberForOtp() {
    clearAuthInputFields(clearPhone: false);
    _loadAuthSectionVisibility();
  }

  void _hideAuthEntrySectionsForCurrentAttempt() {
    showGuestSection.value = false;
    showProfessionalSection.value = false;
  }

  Future<void> startProfessionalFlow() async {
    _setLoginIntent(RbacDecision.roleProfessional);
    _setGuestMode(false);
    Get.toNamed(AppRoutes.professionalRegistrationRoute);
  }

  void restoreProfessionalStarterSectionBeforeVerification() {
    final hasProfessionalOnboardedState =
        _storage.read(professionalOnboardedStorageKey) == true ||
        _storage.read(professionalProfileStorageKey) == true ||
        ((_storage.read(rbacRoleStorageKey) as String?)?.trim().toLowerCase() ==
            RbacDecision.roleProfessional);

    if (hasProfessionalOnboardedState) {
      _loadAuthSectionVisibility();
      return;
    }

    _storage.remove(hideProfessionalCtaStorageKey);
    _setLoginIntent(RbacDecision.roleCustomer);
    showProfessionalSection.value = true;
    _loadAuthSectionVisibility();
  }

  Future<void> continueAsGuest() async {
    _setLoginIntent(RbacDecision.roleCustomer);
    _clearOtpFields();
    _setGuestMode(true);
    _clearLocalRbacCache(keepGuestMode: true, clearAuthUiFlags: true);
    _storage.write('userRole', 'guest');
    _storage.write(customerProfileCompletedStorageKey, false);
    if (_auth.currentUser != null) {
      await FcmNotificationService.instance.deactivateLastToken();
      await _auth.signOut();
    }
    Get.offAllNamed(AppRoutes.customerBottomNavigationRoute);
  }

  Future<void> showLoginRequiredSheet({
    String message = 'Please login to continue',
  }) async {
    await Get.bottomSheet<void>(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13153A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: Color(0xFFD000FF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Login Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: Get.back,
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF8D92C6),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFC2C7E4),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: Get.back,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF394078)),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          Future.delayed(const Duration(milliseconds: 80), () {
                            Get.offAllNamed(AppRoutes.loginRoute);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4B176F),
                        ),
                        child: const Text(
                          'Continue with Phone',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
    );
  }

  Future<void> requestOtp() async {
    if (isLoading.value || hasPendingOtp) {
      AppSnackbar.info(
        "OTP Pending",
        "Please wait for the current OTP request.",
      );
      return;
    }
    if (loginIntent.value != RbacDecision.roleProfessional) {
      _setLoginIntent(RbacDecision.roleCustomer);
    }
    final phone = phoneController.text.trim();
    if (phone.length != 10) {
      AppSnackbar.error(
        "Invalid Phone",
        "Please enter a valid 10 digit phone number.",
      );
      return;
    }

    final fullPhone = RbacService.normalizePhone("+91$phone");
    debugPrint('[AuthController] requestOtp — phone=$fullPhone');
    try {
      isLoading.value = true;
      _otpRoleDecision = await RbacService.resolveByPhone(fullPhone);
    } catch (_) {
      _otpRoleDecision = null;
    } finally {
      isLoading.value = false;
    }
    await _configurePhoneAuthSettings();
    await _sendOtp(fullPhone, isResend: false);
  }

  Future<void> resendOtp() async {
    if (secondsLeft.value > 0 || isOtpLocked || isLoading.value) return;
    if (loginIntent.value != RbacDecision.roleProfessional) {
      _setLoginIntent(RbacDecision.roleCustomer);
    }

    final phone = phoneController.text.trim();
    if (phone.length != 10) {
      AppSnackbar.error(
        "Invalid Phone",
        "Please enter a valid 10 digit phone number.",
      );
      return;
    }

    final fullPhone = RbacService.normalizePhone("+91$phone");
    debugPrint('[AuthController] resendOtp — phone=$fullPhone');
    try {
      isLoading.value = true;
      _otpRoleDecision = await RbacService.resolveByPhone(fullPhone);
    } catch (_) {
      _otpRoleDecision = null;
    } finally {
      isLoading.value = false;
    }
    await _configurePhoneAuthSettings();
    await _sendOtp(fullPhone, isResend: true);
  }

  Future<void> _configurePhoneAuthSettings() async {
    if (_phoneAuthSettingsConfigured || kIsWeb) {
      return;
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android: never force reCAPTCHA flow.
        await _auth.setSettings(forceRecaptchaFlow: false);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS debug/profile: disable the reCAPTCHA browser entirely.
        // Firebase will send a real SMS without showing the browser.
        // In release, APNs silent push handles verification without reCAPTCHA.
        if (!kReleaseMode) {
          await _auth.setSettings(appVerificationDisabledForTesting: true);
        }
      }
      _phoneAuthSettingsConfigured = true;
      debugPrint('FirebaseAuth phone settings configured');
    } catch (e) {
      debugPrint('Failed to configure FirebaseAuth phone settings: $e');
    }
  }

  Future<void> verifyOtp() async {
    if (isOtpLocked || isLoading.value) {
      return;
    }
    final smsCode = otpControllers.map((c) => c.text.trim()).join();
    if (smsCode.length != 6) {
      AppSnackbar.error("Invalid OTP", "Please enter the 6 digit OTP.");
      return;
    }
    final phoneNumber = RbacService.normalizePhone(
      "+91${phoneController.text.trim()}",
    );

    if (kIsWeb) {
      if (_confirmationResult == null) {
        AppSnackbar.error("OTP Error", "Please request an OTP first.");
        return;
      }
      try {
        isLoading.value = true;
        final userCredential = await _confirmationResult!.confirm(smsCode);
        RecaptchaService.markVerified();
        await _handleSignedInUser(
          userCredential.user,
          phoneNumber: phoneNumber,
          preResolvedDecision: _otpRoleDecision,
        );
      } on FirebaseAuthException catch (e) {
        _recordOtpFailure(e);
        AppSnackbar.error(
          "Verification Failed",
          e.message ?? "Unable to verify OTP.",
        );
      } catch (_) {
        AppSnackbar.error("Verification Failed", "Unable to verify OTP.");
      } finally {
        isLoading.value = false;
      }
      return;
    }

    if (_verificationId == null) {
      AppSnackbar.error("OTP Error", "Please request an OTP first.");
      return;
    }

    try {
      isLoading.value = true;
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _handleCredential(
        credential,
        phoneNumber: phoneNumber,
        preResolvedDecision: _otpRoleDecision,
      );
    } on FirebaseAuthException catch (e) {
      _recordOtpFailure(e);
      AppSnackbar.error(
        "Verification Failed",
        e.message ?? "Unable to verify OTP.",
      );
    } catch (_) {
      AppSnackbar.error("Verification Failed", "Unable to verify OTP.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> autofillOtpFromSms(
    String rawOtp, {
    bool autoVerify = true,
  }) async {
    if (isClosed || rawOtp.trim().isEmpty) {
      return;
    }
    final digits = rawOtp.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 6 || !showOtp.value) {
      return;
    }
    final normalized = digits.substring(0, 6);
    for (var i = 0; i < otpControllers.length && i < normalized.length; i++) {
      otpControllers[i].text = normalized[i];
    }
    if (otpFocusNodes.isNotEmpty) {
      otpFocusNodes.last.unfocus();
    }
    if (autoVerify && !isLoading.value) {
      await verifyOtp();
    }
  }

  Future<void> _sendOtp(String phoneNumber, {required bool isResend}) async {
    try {
      isLoading.value = true;
      if (kIsWeb) {
        final verifier = RecaptchaService.getVerifier(_auth);
        _confirmationResult = await _auth.signInWithPhoneNumber(
          phoneNumber,
          verifier,
        );
        showOtp.value = true;
        _hideAuthEntrySectionsForCurrentAttempt();
        _startResendTimer();
        AppSnackbar.success("OTP Sent", "OTP sent to $phoneNumber.");
        return;
      }

      final timeout = _firebasePhoneAutoRetrievalTimeout;
      debugPrint(
        '[AuthController] verifyPhoneNumber start — phone=$phoneNumber',
      );
      // Mark in-flight BEFORE calling verifyPhoneNumber so that if iOS opens
      // reCAPTCHA and the app is briefly backgrounded/foregrounded, the splash
      // screen sees hasPendingOtp == true and does not interrupt the flow.
      _storage.write(pendingOtpInFlightKey, true);
      _storage.write(pendingPhoneKey, phoneNumber);
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: timeout,
        forceResendingToken: isResend ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('[AuthController] verificationCompleted (auto-verify)');
          try {
            _clearPendingOtpStorage();
            await _handleCredential(
              credential,
              phoneNumber: phoneNumber,
              preResolvedDecision: _otpRoleDecision,
            );
          } catch (e) {
            debugPrint(
              '[AuthController] Auto OTP verification callback failed: $e',
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint(
            '[AuthController] verificationFailed — code=${e.code} message=${e.message}',
          );
          _clearPendingOtpStorage();
          isLoading.value = false;
          AppSnackbar.error("OTP Failed", _phoneAuthFailureMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint(
            '[AuthController] codeSent — verificationId=${verificationId.substring(0, verificationId.length.clamp(0, 8))}…',
          );
          _verificationId = verificationId;
          _resendToken = resendToken;
          // Persist before any navigation so iOS reCAPTCHA return can restore.
          _persistPendingOtpState(
            verificationId: verificationId,
            phoneNumber: phoneNumber,
          );
          for (final controller in otpControllers) {
            controller.clear();
          }
          showOtp.value = true;
          _hideAuthEntrySectionsForCurrentAttempt();
          _startResendTimer();
          _startOtpAutoFillListener();
          AppSnackbar.success("OTP Sent", "OTP sent to $phoneNumber.");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          // Keep storage in sync with the refreshed verificationId.
          if (_storage.read(pendingOtpFlagKey) == true) {
            _storage.write(pendingVerificationIdKey, verificationId);
          }
          if (timeout.inSeconds > 0 && showOtp.value) {
            AppSnackbar.info(
              "Auto-read unavailable",
              "Enter OTP manually or tap resend if needed.",
            );
          }
        },
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[AuthController] verifyPhoneNumber exception — code=${e.code} message=${e.message}',
      );
      _clearPendingOtpStorage();
      AppSnackbar.error("OTP Failed", _phoneAuthFailureMessage(e));
    } catch (e) {
      debugPrint('verifyPhoneNumber failed: $e');
      AppSnackbar.error("OTP Failed", "Unable to send OTP right now.");
    } finally {
      isLoading.value = false;
    }
  }

  String _phoneAuthFailureMessage(FirebaseAuthException error) {
    if (error.code == 'missing-client-identifier') {
      return "Phone verification could not start. Please restart the app and try again.";
    }
    return error.message ?? "Unable to send OTP.";
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
    return epoch == _otpListenEpoch && showOtp.value;
  }

  Future<void> _listenWithRetrieverApi(int epoch) async {
    try {
      final result = await SmartAuth.instance.getSmsWithRetrieverApi(
        matcher: r'\d{6}',
      );
      if (!_isOtpAutoFillSessionActive(epoch) || !result.hasData) {
        return;
      }
      final code = result.data?.code?.trim() ?? '';
      if (code.length == 6) {
        await autofillOtpFromSms(code);
      }
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
      final code = result.data?.code?.trim() ?? '';
      if (code.length == 6) {
        await autofillOtpFromSms(code);
      }
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
        debugPrint('SMS Retriever app signature: $signature');
      }
    } catch (e) {
      debugPrint('Unable to read SMS Retriever app signature: $e');
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

  Future<void> _handleCredential(
    PhoneAuthCredential credential, {
    required String phoneNumber,
    RbacDecision? preResolvedDecision,
  }) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      await _handleSignedInUser(
        userCredential.user,
        phoneNumber: phoneNumber,
        preResolvedDecision: preResolvedDecision,
      );
    } on FirebaseAuthException catch (e) {
      _recordOtpFailure(e);
      AppSnackbar.error("Login Failed", e.message ?? "Unable to sign in.");
    } catch (_) {
      AppSnackbar.error("Login Failed", "Unable to sign in.");
    }
  }

  Future<void> _handleSignedInUser(
    User? user, {
    required String phoneNumber,
    RbacDecision? preResolvedDecision,
  }) async {
    if (user == null) {
      AppSnackbar.error("Login Failed", "Unable to sign in.");
      return;
    }

    debugPrint(
      '[AuthController] Signed in — uid=${user.uid} phone=$phoneNumber',
    );
    _clearPendingOtpStorage();
    _setGuestMode(false);
    failedOtpAttempts.value = 0;
    otpLockSecondsLeft.value = 0;
    _otpLockTimer?.cancel();
    final decision = await _resolveDecisionAfterLogin(
      user.uid,
      phoneNumber: phoneNumber,
      preResolvedDecision: preResolvedDecision,
      requestedRole: loginIntent.value,
    );
    _setLoginIntent(decision.role);
    await _applyDecisionToState(decision, persistLocal: true);
    await _upsertUser(user, phoneNumber: phoneNumber, decision: decision);
    _clearOtpFields();
    await _navigateByDecision(decision);
  }

  Future<RbacDecision> _resolveDecisionAfterLogin(
    String uid, {
    required String phoneNumber,
    RbacDecision? preResolvedDecision,
    required String requestedRole,
  }) async {
    final normalizedRole = requestedRole.trim().toLowerCase();
    try {
      final resolved = await RbacService.resolveByUid(
        uid: uid,
        fallbackPhone: phoneNumber,
      );

      if (resolved.isAdmin) {
        return resolved;
      }

      // Never downgrade a pre-existing professional account to customer.
      if (resolved.isProfessional) {
        return resolved;
      }

      if (normalizedRole == RbacDecision.roleProfessional) {
        return const RbacDecision(
          role: RbacDecision.roleProfessional,
          approvalStatus: 'pending',
          isProfessionalOnboarded: true,
          hasProfessionalProfile: false,
        );
      }

      if (normalizedRole == RbacDecision.roleCustomer) {
        return const RbacDecision(
          role: RbacDecision.roleCustomer,
          approvalStatus: 'approved',
          isProfessionalOnboarded: false,
          hasProfessionalProfile: false,
        );
      }

      return resolved;
    } catch (_) {
      final cachedScoped = _scopedCachedDecisionForUid(uid);
      if (cachedScoped != null) {
        return cachedScoped;
      }

      if (preResolvedDecision != null) {
        if (preResolvedDecision.isAdmin || preResolvedDecision.isProfessional) {
          return preResolvedDecision;
        }
        if (normalizedRole == RbacDecision.roleCustomer) {
          return preResolvedDecision;
        }
      }

      if (normalizedRole == RbacDecision.roleProfessional) {
        return const RbacDecision(
          role: RbacDecision.roleProfessional,
          approvalStatus: 'pending',
          isProfessionalOnboarded: true,
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
  }

  RbacDecision? _scopedCachedDecisionForUid(String uid) {
    if (!RbacService.isLocalDecisionScopedToUid(_storage, uid: uid)) {
      return null;
    }

    final cachedRole = (_storage.read(rbacRoleStorageKey) as String?)
        ?.trim()
        .toLowerCase();
    final role =
        cachedRole == RbacDecision.roleAdmin ||
            cachedRole == RbacDecision.roleProfessional ||
            cachedRole == RbacDecision.roleCustomer
        ? cachedRole
        : null;
    if (role == null) {
      return null;
    }

    final approval =
        (_storage.read(approvalStatusStorageKey) as String?)
            ?.trim()
            .toLowerCase() ??
        'approved';
    final onboarded = _storage.read(professionalOnboardedStorageKey) == true;
    final hasProfile = _storage.read(professionalProfileStorageKey) == true;

    return RbacDecision(
      role: role,
      approvalStatus: approval,
      isProfessionalOnboarded: role == RbacDecision.roleProfessional
          ? true
          : onboarded,
      hasProfessionalProfile: hasProfile,
    );
  }

  Future<void> _upsertUser(
    User user, {
    required String phoneNumber,
    required RbacDecision decision,
  }) async {
    final doc = _db.collection('users').doc(user.uid);
    final snapshot = await doc.get();
    final now = FieldValue.serverTimestamp();
    final existing = snapshot.data() ?? <String, dynamic>{};
    final existingRole = (existing['role'] as String? ?? '')
        .trim()
        .toLowerCase();
    final existingRbacRole = (existing['rbacRole'] as String? ?? '')
        .trim()
        .toLowerCase();
    final existingProfessional =
        existingRbacRole == RbacDecision.roleProfessional ||
        existingRole == 'professional' ||
        existingRole == 'professional_pending' ||
        existing['isProfessionalOnboarded'] == true ||
        existing['hasProfessionalProfile'] == true;
    final compatibleRole = decision.compatibleUserRole;

    final data = <String, dynamic>{
      'uid': user.uid,
      'phoneNumber': phoneNumber,
      'role': compatibleRole,
      'rbacRole': decision.role,
      'approvalStatus': decision.approvalStatus,
      'isProfessionalOnboarded': decision.isProfessionalOnboarded,
      'hasProfessionalProfile': decision.hasProfessionalProfile,
      'lastLoginAt': now,
      if (decision.isProfessional)
        'professionalStatus': decision.approvalStatus == 'approved'
            ? 'approved'
            : decision.approvalStatus == 'rejected'
            ? 'rejected'
            : 'under_review',
      if (!decision.isProfessional) 'professionalStatus': FieldValue.delete(),
    };

    // Defensive guard: never overwrite an existing professional identity with customer.
    if (decision.isCustomer && existingProfessional) {
      data
        ..remove('role')
        ..remove('rbacRole')
        ..remove('approvalStatus')
        ..remove('isProfessionalOnboarded')
        ..remove('hasProfessionalProfile')
        ..remove('professionalStatus');
    }

    if (!snapshot.exists) {
      data['createdAt'] = now;
      data['profileCompleted'] = compatibleRole == 'customer' ? false : true;
    }
    await doc.set(data, SetOptions(merge: true));
  }

  void _startResendTimer({int seconds = 120}) {
    _resendTimer?.cancel();
    secondsLeft.value = seconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft.value <= 1) {
        timer.cancel();
        secondsLeft.value = 0;
      } else {
        secondsLeft.value--;
      }
    });
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
    if (failedOtpAttempts.value < 5) {
      return;
    }
    _otpLockTimer?.cancel();
    otpLockSecondsLeft.value = 600;
    _otpLockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpLockSecondsLeft.value <= 1) {
        timer.cancel();
        otpLockSecondsLeft.value = 0;
        failedOtpAttempts.value = 0;
      } else {
        otpLockSecondsLeft.value--;
      }
    });
    AppSnackbar.error(
      'OTP Locked',
      'Too many incorrect attempts. Please try again after 10 minutes.',
    );
  }

  String _formatCountdown(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }

  void _clearOtpFields() {
    _stopOtpAutoFillListener();
    for (final controller in otpControllers) {
      controller.clear();
    }
    showOtp.value = false;
    _verificationId = null;
    _resendToken = null;
    _confirmationResult = null;
    _otpRoleDecision = null;
    _clearPendingOtpStorage();
  }

  Future<void> _navigateByDecision(RbacDecision decision) async {
    if (decision.isAdmin) {
      Get.offAllNamed(AppRoutes.adminDashboardRoute);
      return;
    }

    if (decision.isProfessional) {
      final localOnboardingCompleted =
          await ProfessionalOnboardingStorage.readOnboardingCompleted();
      final hasProfessionalSetup =
          decision.hasProfessionalProfile ||
          localOnboardingCompleted ||
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

    final user = _auth.currentUser;
    if (user == null) {
      Get.offAllNamed(AppRoutes.loginRoute);
      return;
    }
    final isProfileCompleted = await _isCustomerProfileCompleted(user.uid);
    _storage.write(customerProfileCompletedStorageKey, isProfileCompleted);
    if (!isProfileCompleted) {
      Get.offAllNamed(AppRoutes.customerProfileCompletionRoute);
      return;
    }
    Get.offAllNamed(AppRoutes.customerBottomNavigationRoute);
  }

  Future<bool> _isCustomerProfileCompleted(String uid) async {
    try {
      final snapshot = await _db.collection('users').doc(uid).get();
      final data = snapshot.data() ?? <String, dynamic>{};

      final fullName = (data['fullName'] as String? ?? '').trim();
      final hasRequiredFields = fullName.isNotEmpty;

      if (hasRequiredFields) {
        if ((data['profileCompleted'] as bool?) != true) {
          await _db.collection('users').doc(uid).set(<String, dynamic>{
            'profileCompleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        return true;
      }
      return false;
    } catch (_) {
      return _storage.read(customerProfileCompletedStorageKey) == true;
    }
  }

  Future<void> _applyDecisionToState(
    RbacDecision decision, {
    required bool persistLocal,
  }) async {
    rbacRole.value = decision.role;
    approvalStatus.value = decision.approvalStatus;
    isProfessionalOnboarded.value = decision.isProfessionalOnboarded;
    hasProfessionalProfile.value = decision.hasProfessionalProfile;
    userRole.value = decision.compatibleUserRole;

    if (persistLocal) {
      await RbacService.persistLocalDecision(_storage, decision);
    }
  }

  void _setGuestMode(bool value) {
    isGuestUser.value = value;
    _storage.write(guestUserStorageKey, value);
  }

  @override
  void onClose() {
    phoneController.dispose();
    for (final controller in otpControllers) {
      controller.dispose();
    }
    for (final node in otpFocusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    _otpLockTimer?.cancel();
    super.onClose();
  }
}

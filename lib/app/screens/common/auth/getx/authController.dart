import 'dart:async';
import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/services/recaptcha_service.dart';
import 'package:clicknow_version2/app/utils/device_constants/appConstants.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  static AuthController get instance {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>();
    }
    return Get.put(AuthController());
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();

  final phoneController = TextEditingController();
  final otpControllers = List.generate(6, (_) => TextEditingController());
  final otpFocusNodes = List.generate(6, (_) => FocusNode());

  final showOtp = false.obs;
  final secondsLeft = 0.obs;
  final isLoading = false.obs;
  final userRole = 'customer'.obs;
  final showProfessionalSection = true.obs;

  Timer? _resendTimer;
  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _confirmationResult;

  @override
  void onInit() {
    super.onInit();
    _loadProfessionalSectionVisibility();
  }

  void startProfessionalFlow() {
    userRole.value = 'professional';
    _storage.write('userRole', 'professional');
    Get.toNamed(AppRoutes.professionalRegistrationRoute);
  }

  void _loadProfessionalSectionVisibility() {
    final hideCta = _storage.read('hideProfessionalCTA') ?? false;
    showProfessionalSection.value = !hideCta;
  }

  Future<void> requestOtp() async {
    final phone = phoneController.text.trim();
    if (phone.length != 10) {
      AppSnackbar.error(
        "Invalid Phone",
        "Please enter a valid 10 digit phone number.",
      );
      return;
    }

    final fullPhone = "+91$phone";
    userRole.value = _resolveRole(fullPhone);
    await _sendOtp(fullPhone, isResend: false);
  }

  Future<void> resendOtp() async {
    if (secondsLeft.value > 0) return;

    final phone = phoneController.text.trim();
    if (phone.length != 10) {
      AppSnackbar.error(
        "Invalid Phone",
        "Please enter a valid 10 digit phone number.",
      );
      return;
    }

    final fullPhone = "+91$phone";
    userRole.value = _resolveRole(fullPhone);
    await _sendOtp(fullPhone, isResend: true);
  }

  Future<void> verifyOtp() async {
    final smsCode = otpControllers.map((c) => c.text.trim()).join();
    if (smsCode.length != 6) {
      AppSnackbar.error("Invalid OTP", "Please enter the 6 digit OTP.");
      return;
    }
    final phoneNumber = "+91${phoneController.text.trim()}";
    final role = _resolveRole(phoneNumber);

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
          role: role,
        );
      } on FirebaseAuthException catch (e) {
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
      );
    } on FirebaseAuthException catch (e) {
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
        _startResendTimer();
        AppSnackbar.success("OTP Sent", "OTP sent to $phoneNumber.");
        return;
      }
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: isResend ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _handleCredential(
            credential,
            phoneNumber: phoneNumber,
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          AppSnackbar.error(
            "OTP Failed",
            e.message ?? "Unable to send OTP.",
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          showOtp.value = true;
          _startResendTimer();
          AppSnackbar.success("OTP Sent", "OTP sent to $phoneNumber.");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleCredential(
    PhoneAuthCredential credential, {
    required String phoneNumber,
  }) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      await _handleSignedInUser(
        userCredential.user,
        phoneNumber: phoneNumber,
        role: _resolveRole(phoneNumber),
      );
    } on FirebaseAuthException catch (e) {
      AppSnackbar.error(
        "Login Failed",
        e.message ?? "Unable to sign in.",
      );
    } catch (_) {
      AppSnackbar.error("Login Failed", "Unable to sign in.");
    }
  }

  Future<void> _handleSignedInUser(
    User? user, {
    required String phoneNumber,
    required String role,
  }) async {
    if (user == null) {
      AppSnackbar.error("Login Failed", "Unable to sign in.");
      return;
    }

    await _upsertUser(
      user,
      phoneNumber: phoneNumber,
      role: role,
    );
    userRole.value = role;
    _storage.write('userRole', role);
    _clearOtpFields();
    _navigateByRole(role);
  }

  Future<void> _upsertUser(
    User user, {
    required String phoneNumber,
    required String role,
  }) async {
    final doc = _db.collection('users').doc(user.uid);
    final snapshot = await doc.get();
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'uid': user.uid,
      'phoneNumber': phoneNumber,
      'role': role,
      'lastLoginAt': now,
    };
    if (!snapshot.exists) {
      data['createdAt'] = now;
    }
    await doc.set(data, SetOptions(merge: true));
  }

  void _startResendTimer({int seconds = 30}) {
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

  void _clearOtpFields() {
    for (final controller in otpControllers) {
      controller.clear();
    }
    showOtp.value = false;
    _confirmationResult = null;
  }

  void _navigateByRole(String role) {
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

  String _resolveRole(String phoneNumber) {
    if (_isAdminPhone(phoneNumber)) {
      return AppConstants.adminRole;
    }
    return userRole.value;
  }

  bool _isAdminPhone(String phoneNumber) {
    final normalizedInput = _normalizePhone(phoneNumber);
    return AppConstants.adminPhoneNumbers
        .map(_normalizePhone)
        .contains(normalizedInput);
  }

  String _normalizePhone(String phoneNumber) {
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
    super.onClose();
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/foundation.dart';

class RecaptchaService {
  RecaptchaService._();

  static bool _verifiedOnce = false;
  static RecaptchaVerifier? _verifier;

  static bool get hasVerifiedOnce => _verifiedOnce;

  static RecaptchaVerifier getVerifier(FirebaseAuth auth) {
    if (!kIsWeb) {
      throw UnsupportedError('RecaptchaVerifier is only supported on web.');
    }

    if (_verifiedOnce && _verifier != null) {
      return _verifier!;
    }

    _verifier?.clear();
    _verifier = RecaptchaVerifier(
      auth: FirebaseAuthPlatform.instanceFor(
        app: auth.app,
        pluginConstants: const <String, dynamic>{},
      ),
      size: RecaptchaVerifierSize.normal,
      onSuccess: () {
        _verifiedOnce = true;
      },
      onExpired: () {
        _verifiedOnce = false;
      },
      onError: (_) {},
    );

    return _verifier!;
  }

  static void markVerified() {
    _verifiedOnce = true;
  }
}

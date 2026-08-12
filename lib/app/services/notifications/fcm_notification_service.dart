import 'dart:async';
import 'dart:io';

import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/screens/customer/home/customer_booking_details_screen.dart';
import 'package:clicknow_version2/app/screens/customer/home/customer_notifications_screen.dart';
import 'package:clicknow_version2/app/screens/professional/professionalDashboard/home/professional_notifications_screen.dart';
import 'package:clicknow_version2/app/services/rbac_service.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class FcmNotificationService {
  FcmNotificationService._();

  static final FcmNotificationService instance = FcmNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();

  StreamSubscription<User?>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  bool _initialized = false;
  bool _initialMessageHandled = false;

  static const String _lastUidKey = 'fcm_last_uid';
  static const String _lastTokenDocKey = 'fcm_last_token_doc';
  static const String _lastTokenKey = 'fcm_last_token';

  Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) {
        debugPrint('Notification initialization skipped; already initialized.');
      }
      return;
    }
    _initialized = true;

    try {
      _authSub ??= _auth.authStateChanges().listen((user) {
        if (user == null) {
          if (kDebugMode) {
            debugPrint(
              'Current Firebase user unavailable; token save skipped.',
            );
          }
          unawaited(_deactivateLastTokenSafely());
          return;
        }
        if (kDebugMode) {
          debugPrint('Current Firebase user available; registering FCM token.');
        }
        unawaited(registerCurrentUserToken());
      });
      _tokenRefreshSub ??= _messaging.onTokenRefresh.listen((token) {
        unawaited(_handleTokenRefresh(token));
      });
      _foregroundSub ??= FirebaseMessaging.onMessage.listen(
        _onForegroundMessage,
      );
      _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen(
        handleNotificationTap,
      );
      if (!_initialMessageHandled) {
        _initialMessageHandled = true;
        final initial = await _messaging.getInitialMessage();
        if (initial != null) {
          Future.microtask(() => handleNotificationTap(initial));
        }
      }
      if (_auth.currentUser != null) {
        await registerCurrentUserToken();
      } else if (kDebugMode) {
        debugPrint('Current Firebase user unavailable; token save skipped.');
      }
    } on FirebaseException catch (error, stackTrace) {
      _initialized = false;
      debugPrint('Firebase Messaging error: ${error.code}: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
    } catch (error, stackTrace) {
      _initialized = false;
      debugPrint('Notification initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> registerCurrentUserToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null || AuthController.isGuestModeActive) {
        if (kDebugMode) {
          debugPrint('Current Firebase user unavailable; token save skipped.');
        }
        return;
      }

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (kDebugMode) {
        debugPrint(
          'Notification permission status: ${settings.authorizationStatus.name}.',
        );
      }
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        AppSnackbar.info(
          'Notifications Disabled',
          'You can enable notifications from app settings anytime.',
        );
        debugPrint('Notification initialization skipped; permission denied.');
        return;
      }

      final canRegisterOnThisPlatform = await _canRegisterFcmToken();
      if (!canRegisterOnThisPlatform) return;

      final token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) {
        debugPrint('FCM token unavailable; token save skipped.');
        return;
      }
      if (kDebugMode) {
        debugPrint('FCM token available; saving token.');
      }
      await _saveTokenSafely(token);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Firebase Messaging error: ${error.code}: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
    } catch (error, stackTrace) {
      debugPrint('FCM token registration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<bool> _canRegisterFcmToken() async {
    if (kIsWeb || !Platform.isIOS) return true;

    String? apnsToken;
    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        apnsToken = await _messaging.getAPNSToken();
      } on FirebaseException catch (error) {
        if (kDebugMode) {
          debugPrint(
            'APNs token check failed: ${error.code}: ${error.message}',
          );
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('APNs token check failed: $error');
        }
      }

      if (apnsToken != null && apnsToken.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('APNs token available.');
        }
        return true;
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    debugPrint(
      'APNs token is unavailable on this launch. '
      'Skipping iOS FCM token registration.',
    );
    return false;
  }

  Future<void> _handleTokenRefresh(String token) async {
    final user = _auth.currentUser;
    if (user == null || AuthController.isGuestModeActive) {
      if (kDebugMode) {
        debugPrint('Current Firebase user unavailable; token refresh skipped.');
      }
      return;
    }
    await _saveTokenSafely(token);
  }

  Future<void> deactivateLastToken() async {
    final uid = (_storage.read(_lastUidKey) as String?)?.trim() ?? '';
    final tokenDoc = (_storage.read(_lastTokenDocKey) as String?)?.trim() ?? '';
    if (uid.isEmpty || tokenDoc.isEmpty) return;
    await _db
        .collection(ServiceCatalogPaths.usersCollection)
        .doc(uid)
        .collection(ServiceCatalogPaths.fcmTokensSubcollection)
        .doc(tokenDoc)
        .set(<String, dynamic>{
          'isActive': false,
          'disabledAt': FieldValue.serverTimestamp(),
          'disabledReason': 'logout_or_user_switch',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    _storage.remove(_lastUidKey);
    _storage.remove(_lastTokenDocKey);
    _storage.remove(_lastTokenKey);
  }

  Future<void> _deactivateLastTokenSafely() async {
    try {
      await deactivateLastToken();
    } catch (error, stackTrace) {
      debugPrint('FCM token deactivation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _saveTokenSafely(String token) async {
    try {
      await _saveToken(token);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('FCM token save failed: ${error.code}: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
    } catch (error, stackTrace) {
      debugPrint('FCM token save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _saveToken(String token) async {
    final user = _auth.currentUser;
    if (user == null || AuthController.isGuestModeActive) {
      if (kDebugMode) {
        debugPrint('Current Firebase user unavailable; token save skipped.');
      }
      return;
    }
    if (token.trim().isEmpty) {
      debugPrint('FCM token unavailable; token save skipped.');
      return;
    }
    final role = await _resolveCurrentRole(user.uid);
    final previousUid = (_storage.read(_lastUidKey) as String?)?.trim() ?? '';
    final previousToken =
        (_storage.read(_lastTokenKey) as String?)?.trim() ?? '';
    if (previousUid == user.uid && previousToken == token) {
      if (kDebugMode) {
        debugPrint('FCM token unchanged; token save skipped.');
      }
      return;
    }
    if (previousUid.isNotEmpty &&
        (previousUid != user.uid || previousToken != token)) {
      await deactivateLastToken();
    }
    final tokenDoc = _tokenDocId(token);
    await _db
        .collection(ServiceCatalogPaths.usersCollection)
        .doc(user.uid)
        .collection(ServiceCatalogPaths.fcmTokensSubcollection)
        .doc(tokenDoc)
        .set(<String, dynamic>{
          'token': token,
          'platform': _platform,
          'role': role,
          'deviceId': '',
          'appVersion': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastSeenAt': FieldValue.serverTimestamp(),
          'isActive': true,
        }, SetOptions(merge: true));
    _storage.write(_lastUidKey, user.uid);
    _storage.write(_lastTokenDocKey, tokenDoc);
    _storage.write(_lastTokenKey, token);
    if (kDebugMode) {
      debugPrint('FCM token saved.');
    }
  }

  Future<String> _resolveCurrentRole(String uid) async {
    try {
      final decision = await RbacService.resolveByUid(uid: uid);
      return decision.role;
    } catch (_) {
      final local =
          (_storage.read(AuthController.rbacRoleStorageKey) as String?)
              ?.trim()
              .toLowerCase() ??
          '';
      return local.isEmpty ? RbacDecision.roleCustomer : local;
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? '';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    if (title.toString().trim().isEmpty && body.toString().trim().isEmpty) {
      return;
    }
    AppSnackbar.info(title.toString(), body.toString());
  }

  Future<void> handleNotificationTap(RemoteMessage message) async {
    await handleNotificationData(message.data);
  }

  Future<void> handleNotificationData(Map<String, dynamic> data) async {
    final role = await _resolveTapRole();
    final route = (data['deepLinkRoute'] ?? '').toString().trim();
    final type = (data['type'] ?? '').toString().trim();
    final bookingId = (data['bookingId'] ?? '').toString().trim();
    if (role == RbacDecision.roleCustomer) {
      if (bookingId.isNotEmpty &&
          (type.startsWith('booking_') ||
              type.startsWith('refund_') ||
              route.contains('booking'))) {
        Get.to(
          () => CustomerBookingStatusScreen(
            bookingId: bookingId,
            bookingCode: (data['bookingCode'] ?? bookingId).toString(),
            serviceTitle: (data['serviceTitle'] ?? 'Booking').toString(),
          ),
        );
        return;
      }
      Get.to(() => const CustomerNotificationsScreen());
      return;
    }
    if (role == RbacDecision.roleProfessional) {
      Get.to(() => const ProfessionalNotificationsScreen());
      return;
    }
    if (role == RbacDecision.roleAdmin) {
      if (type.startsWith('booking_reschedule_') || route.contains('booking')) {
        Get.offNamed(AppRoutes.adminBookingsRoute);
        return;
      }
      Get.offNamed(AppRoutes.adminNotificationsRoute);
      return;
    }
    Get.offNamed(AppRoutes.loginRoute);
  }

  Future<String> _resolveTapRole() async {
    final user = _auth.currentUser;
    if (user == null) return '';
    return _resolveCurrentRole(user.uid);
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  String _tokenDocId(String token) =>
      token.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}

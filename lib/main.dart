import 'dart:async';

import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/themes/appTheme.dart';
import 'package:clicknow_version2/app/widgets/network_connectivity_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:get_storage/get_storage.dart';
import 'package:clicknow_version2/app/services/network_guard_controller.dart';
import 'package:clicknow_version2/app/services/notifications/fcm_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _runStartupStep(
    'Device orientation setup',
    () => SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]),
  );
  await _runStartupStep(
    'Status bar setup',
    () => HelperFunctions.setStatusBarColor(color: Colors.white),
  );
  await _runStartupStep('GetStorage initialization', GetStorage.init);

  Object? firebaseInitializationError;
  StackTrace? firebaseInitializationStackTrace;
  try {
    if (kDebugMode) {
      debugPrint('Firebase Core initialization started.');
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (kDebugMode) {
      debugPrint('Firebase Core initialization succeeded.');
    }
  } catch (error, stackTrace) {
    firebaseInitializationError = error;
    firebaseInitializationStackTrace = stackTrace;
    debugPrint('Firebase Core initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  NetworkGuardController.instance;

  if (kDebugMode) {
    debugPrint('runApp() called.');
  }
  runApp(
    firebaseInitializationError == null
        ? const MyApp()
        : FirebaseStartupErrorApp(error: firebaseInitializationError),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (firebaseInitializationError != null) {
      debugPrint(
        'Optional services skipped because Firebase Core failed to initialize.',
      );
      debugPrintStack(stackTrace: firebaseInitializationStackTrace);
      return;
    }
    unawaited(_initializeOptionalServices());
  });
}

Future<void> _runStartupStep(
  String label,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error, stackTrace) {
    debugPrint('$label failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeOptionalServices() async {
  await _initializeFirebaseAppCheck();

  try {
    if (kDebugMode) {
      debugPrint('Notification initialization started.');
    }
    await FcmNotificationService.instance.initialize();
    if (kDebugMode) {
      debugPrint('Notification initialization completed.');
    }
  } catch (error, stackTrace) {
    debugPrint('Notification initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeFirebaseAppCheck() async {
  const forceDebugAppCheck = bool.fromEnvironment(
    'USE_APPCHECK_DEBUG',
    defaultValue: false,
  );
  const allowReleaseDebugFallback = bool.fromEnvironment(
    'ALLOW_APPCHECK_RELEASE_DEBUG_FALLBACK',
    defaultValue: false,
  );
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: (kReleaseMode && !forceDebugAppCheck)
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    if (kDebugMode || forceDebugAppCheck) {
      debugPrint('Firebase App Check provider: debug');
    } else {
      debugPrint('Firebase App Check provider: playIntegrity');
    }
  } catch (error, stackTrace) {
    debugPrint('AppCheck activation failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (kReleaseMode && !forceDebugAppCheck && allowReleaseDebugFallback) {
      await _activateAppCheckDebugFallback();
    }
  }
}

Future<void> _activateAppCheckDebugFallback() async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidDebugProvider(),
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    debugPrint(
      'Firebase App Check fallback provider: debug (release fallback)',
    );
  } catch (error, stackTrace) {
    debugPrint('AppCheck fallback activation failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "ClickNow",
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.initialRoute,
      getPages: AppRoutes.pages,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return NetworkConnectivityGuard(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class FirebaseStartupErrorApp extends StatelessWidget {
  const FirebaseStartupErrorApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'ClickNow could not start Firebase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

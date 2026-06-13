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
import 'firebase_options.dart';

void main() async {
  /// -- Firebase Integration
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,]);
  await HelperFunctions.setStatusBarColor(color: Colors.white);
  await GetStorage.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  } catch (e) {
    debugPrint('AppCheck activation failed: $e');
    if (kReleaseMode && !forceDebugAppCheck && allowReleaseDebugFallback) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidDebugProvider(),
        );
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
        debugPrint(
          'Firebase App Check fallback provider: debug (release fallback)',
        );
      } catch (fallbackError) {
        debugPrint('AppCheck fallback activation failed: $fallbackError');
      }
    }
  }
  NetworkGuardController.instance;

  runApp(const MyApp());
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

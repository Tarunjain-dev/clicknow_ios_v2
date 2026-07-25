import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkGuardController extends GetxController {
  static NetworkGuardController get instance {
    if (Get.isRegistered<NetworkGuardController>()) {
      return Get.find<NetworkGuardController>();
    }
    return Get.put(NetworkGuardController(), permanent: true);
  }

  final Connectivity _connectivity = Connectivity();
  final RxBool hasInternet = true.obs;

  StreamSubscription<dynamic>? _connectivitySub;

  @override
  void onInit() {
    super.onInit();
    _bindConnectivity();
  }

  Future<void> recheck() async {
    final result = await _connectivity.checkConnectivity();
    _setInternetState(result);
  }

  void _bindConnectivity() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _setInternetState,
      onError: (_) {
        hasInternet.value = false;
      },
    );
    recheck();
  }

  void _setInternetState(dynamic connectivityData) {
    final List<ConnectivityResult> results;
    if (connectivityData is List<ConnectivityResult>) {
      results = connectivityData;
    } else if (connectivityData is ConnectivityResult) {
      results = <ConnectivityResult>[connectivityData];
    } else {
      hasInternet.value = false;
      return;
    }

    if (results.isEmpty) {
      hasInternet.value = false;
      return;
    }
    hasInternet.value = results.any((result) => result != ConnectivityResult.none);
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }
}

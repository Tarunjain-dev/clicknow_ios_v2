import 'package:geolocator/geolocator.dart';

enum LocationPermissionState { granted, denied, deniedForever, serviceDisabled }

class DeviceCoordinate {
  const DeviceCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<LocationPermissionState> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionState.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return LocationPermissionState.denied;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionState.deniedForever;
    }
    return LocationPermissionState.granted;
  }

  Future<DeviceCoordinate?> getCurrentLocation() async {
    final state = await ensurePermission();
    if (state != LocationPermissionState.granted) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return DeviceCoordinate(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

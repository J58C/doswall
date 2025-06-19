import 'package:geolocator/geolocator.dart';

enum LocationPermissionResult {
  granted,
  serviceDisabled,
  denied,
  deniedForever,
}

class LocationPermissionHandler {
  static Future<LocationPermissionResult> handle() async {
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      return LocationPermissionResult.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionResult.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionResult.deniedForever;
    }
    return LocationPermissionResult.granted;
  }

  static String getErrorMessage(LocationPermissionResult result) {
    switch (result) {
      case LocationPermissionResult.serviceDisabled:
        return 'Layanan lokasi tidak aktif. Mohon aktifkan GPS Anda.';
      case LocationPermissionResult.denied:
        return 'Izin lokasi ditolak.';
      case LocationPermissionResult.deniedForever:
        return 'Izin lokasi ditolak permanen. Mohon aktifkan dari pengaturan aplikasi.';
      default:
        return 'Izin lokasi diberikan.';
    }
  }
}
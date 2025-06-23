import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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

enum NotificationPermissionResult {
  granted,
  denied,
  deniedForever,
}

class NotificationPermissionHandler {
  static Future<NotificationPermissionResult> handle() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return NotificationPermissionResult.granted;
    }
    if (status.isPermanentlyDenied) {
      return NotificationPermissionResult.deniedForever;
    }

    final result = await Permission.notification.request();
    if (result.isGranted) {
      return NotificationPermissionResult.granted;
    }
    if (result.isPermanentlyDenied) {
      return NotificationPermissionResult.deniedForever;
    }

    return NotificationPermissionResult.denied;
  }

  static String getErrorMessage(NotificationPermissionResult result) {
    switch (result) {
      case NotificationPermissionResult.denied:
        return 'Izin notifikasi ditolak.';
      case NotificationPermissionResult.deniedForever:
        return 'Izin notifikasi ditolak permanen. Mohon aktifkan dari pengaturan aplikasi.';
      default:
        return 'Izin notifikasi diberikan.';
    }
  }
}
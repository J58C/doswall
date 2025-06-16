import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> handleLocationPermission(BuildContext context) async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    }
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsDialog(context);
      }
      return false;
    }
    var result = await Permission.location.request();
    return result.isGranted;
  }

  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: const Text(
            'Aplikasi ini memerlukan izin lokasi untuk berfungsi. Silakan aktifkan izin di pengaturan aplikasi.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Buka Pengaturan'),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }
}
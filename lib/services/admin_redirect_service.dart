import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../services/user_storage.dart';

class AdminRedirectService {
  static Future<void> launchAdminPanel() async {
    try {
      final user = await UserStorage.getUser();
      final email = user['email'];
      final token = user['token'];

      if (email == null || token == null) {
        throw Exception('Data pengguna atau sesi tidak ditemukan.');
      }
      final urlString = '${ApiConfig.redirectAdminUrl}/$email/$token';
      final url = Uri.parse(urlString);

      if (kDebugMode) {
        log('Mencoba membuka URL Admin: $url');
      }

      if (!await launchUrl(url)) {
        throw Exception('Tidak dapat membuka panel admin.');
      }
    } catch (e) {
      throw Exception('Gagal membuka panel admin: ${e.toString()}');
    }
  }
}
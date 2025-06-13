import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/change_password_response.dart';

class ChangePasswordService {
  static Future<ChangePasswordResponse> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');
      final String? token = prefs.getString('token');

      if (userId == null || token == null) {
        return ChangePasswordResponse(
            success: false, message: 'Data pengguna tidak ditemukan. Silakan login kembali.');
      }

      final url = Uri.parse('${ApiConfig.changePasswordBaseUrl}/$userId');

      final Map<String, dynamic> payload = {
        'oldPW': oldPassword,
        'newPW': newPassword,
        'token': token,
        'appkey': ApiConfig.appKey,
        '_id': userId,
      };

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final responseBody = jsonDecode(response.body);

      if (responseBody is Map<String, dynamic> && responseBody.containsKey('success')) {
        final bool success = responseBody['success'];
        final String message = responseBody['message'] as String? ?? (success ? 'Password berhasil diubah.' : 'Gagal mengubah password.');

        return ChangePasswordResponse(
          success: success,
          message: message,
          statusCode: response.statusCode,
        );
      } else {
        return ChangePasswordResponse(
          success: false,
          message: 'Gagal memproses respons dari server.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('ChangePasswordService Error: $e');
      return ChangePasswordResponse(
        success: false,
        message: 'Terjadi kesalahan koneksi. Silakan coba lagi nanti.',
      );
    }
  }
}
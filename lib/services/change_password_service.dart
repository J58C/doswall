import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/change_password_response.dart';
import './api_client.dart';
import './user_storage.dart';

class ChangePasswordService {
  static Future<ChangePasswordResponse> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final userData = await UserStorage.getUser();
      final String? userId = userData['user_id'];

      if (userId == null) {
        return ChangePasswordResponse(
            success: false, message: 'Data pengguna tidak ditemukan. Silakan login kembali.');
      }

      final url = Uri.parse('${ApiConfig.changePasswordBaseUrl}/$userId');
      final Map<String, dynamic> payload = {
        'oldPW': oldPassword,
        'newPW': newPassword,
        'appkey': ApiConfig.appKey,
        '_id': userId,
      };

      final response = await ApiClient.put(
        url,
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
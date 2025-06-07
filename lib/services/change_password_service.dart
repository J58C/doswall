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

      Map<String, dynamic>? responseBody;
      String messageFromServer = '';

      try {
        if (response.body.isNotEmpty) {
          responseBody = jsonDecode(response.body) as Map<String, dynamic>?;
          messageFromServer = responseBody?['message'] as String? ?? '';
        }
      } catch (e) {
        debugPrint("ChangePasswordService: Error parsing JSON response body: $e");
      }

      if (response.statusCode == 200) {
        bool apiSuccess = responseBody?['success'] as bool? ?? true;
        return ChangePasswordResponse(
          success: apiSuccess,
          message: messageFromServer.isNotEmpty
              ? messageFromServer
              : (apiSuccess ? 'Password berhasil diubah.' : 'Gagal mengubah password dari server.'),
          data: apiSuccess ? responseBody : null,
        );
      } else {
        return ChangePasswordResponse(
          success: false,
          message: messageFromServer.isNotEmpty
              ? messageFromServer
              : 'Gagal mengubah password. (Status: ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('ChangePasswordService Error: $e');
      return ChangePasswordResponse(
        success: false,
        message: 'Terjadi kesalahan koneksi atau lainnya. Silakan coba lagi.',
      );
    }
  }
}
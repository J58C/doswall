import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/password_response.dart';
import './api_client.dart';
import './user_storage.dart';

class PasswordService {
  static Future<PasswordResponse> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final userData = await UserStorage.getUser();
      final String? userId = userData['user_id'];

      if (userId == null) {
        return PasswordResponse(
            success: false, message: 'Data pengguna tidak ditemukan. Silakan login kembali.');
      }
      final url = Uri.parse('${ApiConfig.changePasswordBaseUrl}/$userId');
      final response = await ApiClient.put(url, body: jsonEncode({'oldPW': oldPassword, 'newPW': newPassword, 'appkey': ApiConfig.appKey, '_id': userId}));
      final responseBody = jsonDecode(response.body);

      return PasswordResponse(
        success: responseBody['success'],
        message: responseBody['message'],
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('PasswordService (changePassword) Error: $e');
      return PasswordResponse(
        success: false,
        message: 'Terjadi kesalahan koneksi. Silakan coba lagi nanti.',
      );
    }
  }

  static Future<PasswordResponse> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'appkey': ApiConfig.appKey}),
      );
      final responseBody = jsonDecode(response.body);

      return PasswordResponse(
        success: responseBody['success'],
        message: responseBody['message'],
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('PasswordService (requestPasswordReset) Error: $e');
      return PasswordResponse(
        success: false,
        message: 'Terjadi kesalahan koneksi. Silakan coba lagi nanti.',
      );
    }
  }
}
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/forgot_password_response.dart';

class ForgotPasswordService {
  static Future<ForgotPasswordResponse> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'appkey': ApiConfig.appKey,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (responseBody is Map<String, dynamic> && responseBody.containsKey('success')) {
        final bool success = responseBody['success'];
        final String message = responseBody['message'] as String? ?? (success ? 'Link reset password telah dikirim.' : 'Gagal mengirim permintaan.');

        return ForgotPasswordResponse(
          success: success,
          message: message,
          statusCode: response.statusCode,
        );
      } else {
        return ForgotPasswordResponse(
          success: false,
          message: 'Format respons dari server tidak dikenal.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('ForgotPasswordService Error: $e');
      return ForgotPasswordResponse(
        success: false,
        message: 'Terjadi kesalahan koneksi. Silakan coba lagi nanti.',
      );
    }
  }
}
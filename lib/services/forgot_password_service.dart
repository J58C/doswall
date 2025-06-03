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

      String messageFromServer = '';
      Map<String, dynamic>? responseBody;

      try {
        if (response.body.isNotEmpty) {
          responseBody = jsonDecode(response.body) as Map<String, dynamic>?;
          messageFromServer = responseBody?['message'] as String? ?? '';
        }
      } catch (e) {
        debugPrint("ForgotPasswordService: Error parsing JSON response body: $e");
      }

      if (response.statusCode == 200) {
        return ForgotPasswordResponse(
          success: true,
          message: messageFromServer.isNotEmpty ? messageFromServer : 'Link reset password telah dikirim ke email Anda.',
        );
      } else {
        return ForgotPasswordResponse(
          success: false,
          message: messageFromServer.isNotEmpty ? messageFromServer : 'Gagal mengirim email. (Status: ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('ForgotPasswordService Error: $e');
      return ForgotPasswordResponse(
        success: false,
        message: 'Terjadi kesalahan koneksi atau lainnya. Silakan coba lagi.',
      );
    }
  }
}
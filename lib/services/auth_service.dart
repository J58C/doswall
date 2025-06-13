import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_response.dart';

class AuthService {
  static Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'appkey': ApiConfig.appKey,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {

          final userData = responseBody['data'] as Map<String, dynamic>?;

          if (userData != null &&
              userData.containsKey('role') &&
              userData['role'] is String &&
              ['user', 'admin', 'superadmin'].contains(userData['role'])) {

            return AuthResponse(success: true, userData: userData);
          } else {
            // Jika 'data' tidak ada atau role tidak valid
            return AuthResponse(success: false, message: 'Data pengguna tidak valid atau role tidak dikenal.');
          }
        } else {
          String message = responseBody is Map<String, dynamic> && responseBody.containsKey('message')
              ? responseBody['message'] as String? ?? 'Login gagal, silahkan cek kembali data anda.'
              : 'Login gagal, silahkan cek kembali data anda.';
          return AuthResponse(success: false, message: message);
        }
      }
      else if (response.statusCode == 401) {
        String message = 'Email atau password salah.';
        if (responseBody is Map<String, dynamic> && responseBody.containsKey('message')) {
          message = responseBody['message'] as String? ?? message;
        }
        return AuthResponse(success: false, message: message);
      }
      else if (response.statusCode >= 500) {
        return AuthResponse(success: false, message: 'Server sedang bermasalah. Coba lagi nanti.');
      }
      else {
        return AuthResponse(success: false, message: 'Terjadi kesalahan. Kode: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('AuthService Login Error: $e');
      return AuthResponse(success: false, message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    }
  }
}
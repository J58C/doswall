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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> &&
            data.containsKey('role') &&
            data['role'] is String &&
            ['user', 'admin', 'superadmin'].contains(data['role'])) {
          return AuthResponse(success: true, userData: data);
        } else if (data is Map<String, dynamic> && data.containsKey('message')) {
          return AuthResponse(success: false, message: data['message'] as String? ?? 'Role pengguna tidak valid atau akun tidak aktif.');
        } else {
          return AuthResponse(success: false, message: 'Akun tidak aktif atau role tidak dikenal.');
        }
      } else if (response.statusCode == 401) {
        String message = 'Email atau password salah.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> && errorData.containsKey('message')) {
            message = errorData['message'] as String? ?? message;
          }
        } catch (e) {
          // Biarkan pesan default jika parsing gagal
        }
        return AuthResponse(success: false, message: message);
      } else if (response.statusCode >= 500) {
        return AuthResponse(success: false, message: 'Server sedang bermasalah. Coba lagi nanti.');
      } else {
        return AuthResponse(success: false, message: 'Terjadi kesalahan. Kode: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('AuthService Login Error: $e');
      return AuthResponse(success: false, message: 'Tidak dapat terhubung ke server atau terjadi kesalahan: $e');
    }
  }
}
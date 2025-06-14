import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/token_response.dart';
import './user_storage.dart';

enum AuthResult { authenticated, unauthenticated }

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
            return AuthResponse(success: false, message: 'Data pengguna tidak valid atau role tidak dikenal.');
          }
        } else {
          String message = responseBody is Map<String, dynamic> && responseBody.containsKey('message')
              ? responseBody['message'] as String? ?? 'Login gagal, silahkan cek kembali data anda.'
              : 'Login gagal, silahkan cek kembali data anda.';
          return AuthResponse(success: false, message: message);
        }
      } else if (response.statusCode == 401) {
        String message = 'Email atau password salah.';
        if (responseBody is Map<String, dynamic> && responseBody.containsKey('message')) {
          message = responseBody['message'] as String? ?? message;
        }
        return AuthResponse(success: false, message: message);
      } else if (response.statusCode >= 500) {
        return AuthResponse(success: false, message: 'Server sedang bermasalah. Coba lagi nanti.');
      } else {
        return AuthResponse(success: false, message: 'Terjadi kesalahan. Kode: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('AuthService Login Error: $e');
      return AuthResponse(success: false, message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    }
  }

  static Future<AuthResult> checkAuthentication() async {
    try {
      final user = await UserStorage.getUser();
      if (user['token'] == null || user['user_id'] == null) {
        return AuthResult.unauthenticated;
      }

      final statusResponse = await checkTokenStatus();
      if (statusResponse.success && statusResponse.tokenStatus == true) {
        return AuthResult.authenticated;
      }

      final tokenResponse = await getSessionToken();
      if (tokenResponse.success && tokenResponse.token != null) {
        return AuthResult.authenticated;
      }

      await UserStorage.clearUser();
      return AuthResult.unauthenticated;
    } catch (e) {
      debugPrint("checkAuthentication Error: $e");
      return AuthResult.unauthenticated;
    }
  }

  static Future<CheckTokenStatusResponse> checkTokenStatus() async {
    final user = await UserStorage.getUser();
    final userId = user['user_id'] as String?;
    final token = user['token'] as String?;

    if (userId == null || token == null) {
      return CheckTokenStatusResponse(success: false, tokenStatus: false);
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.checkTokenStatusUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'token': token,
          'appkey': ApiConfig.appKey,
        }),
      );

      if (response.statusCode == 200) {
        return CheckTokenStatusResponse.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('checkTokenStatus Error: $e');
    }
    return CheckTokenStatusResponse(success: false, tokenStatus: false);
  }

  static Future<GetSessionTokenResponse> getSessionToken() async {
    final user = await UserStorage.getUser();
    final userId = user['user_id'] as String?;

    if (userId == null) {
      return GetSessionTokenResponse(success: false, token: null);
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getSessionTokenUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'appkey': ApiConfig.appKey,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = GetSessionTokenResponse.fromJson(data);

        if (result.success && result.token != null) {
          final updatedUser = Map<String, dynamic>.from(user);
          updatedUser['token'] = result.token;
          await UserStorage.saveUser(updatedUser);
        }
        return result;
      }
    } catch (e) {
      debugPrint('getSessionToken Error: $e');
    }
    return GetSessionTokenResponse(success: false);
  }
}
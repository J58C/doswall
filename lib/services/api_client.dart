import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'user_storage.dart';
import 'auth_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
class ApiClient {

  static Future<http.Response> post(Uri url, {Object? body}) async {
    return _handleRequest(() async {
      final finalBody = await _injectAuthDataToBody(body);
      return await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: finalBody,
      );
    });
  }

  static Future<http.Response> put(Uri url, {Object? body}) async {
    return _handleRequest(() async {
      final finalBody = await _injectAuthDataToBody(body);
      return await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: finalBody,
      );
    });
  }

  static Future<http.Response> _handleRequest(Future<http.Response> Function() makeRequest) async {
    http.Response response = await makeRequest();

    if (response.statusCode == 401 || _isUnauthorizedError(response.body)) {
      debugPrint("Unauthorized. Mencoba refresh token...");
      final refreshSuccess = await _refreshToken();
      if (refreshSuccess) {
        debugPrint("Token berhasil diperbarui. Mengulangi request awal...");
        response = await makeRequest();
      } else {
        debugPrint("Gagal memperbarui token. Memaksa logout...");
        _forceLogout();
      }
    }

    return response;
  }
  static Future<String?> _injectAuthDataToBody(Object? originalBody) async {
    if (originalBody == null || originalBody is! String) {
      return null;
    }

    try {
      final user = await UserStorage.getUser();
      final String? userId = user['user_id'];
      final String? token = user['token'];

      Map<String, dynamic> bodyMap = jsonDecode(originalBody);
      bodyMap['_id'] = userId;
      bodyMap['user_id'] = userId;
      bodyMap['token'] = token;
      return jsonEncode(bodyMap);

    } catch (e) {
      return originalBody;
    }
  }
  static Future<bool> _refreshToken() async {
    try {
      final response = await AuthService.getSessionToken();
      return response.success && response.token != null;
    } catch (e) {
      return false;
    }
  }
  static bool _isUnauthorizedError(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      return decoded is Map && decoded['error'] == 'Unauthorized';
    } catch (e) {
      return false;
    }
  }
  static void _forceLogout() async {
    await UserStorage.clearUser();
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _loginUrl = 'https://sigmaskibidi.my.id/appkey/login';
  static const String _appKey = 'DOEGUSAPPACCESSCORS';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(_loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'appkey': _appKey,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (['user', 'admin', 'superadmin'].contains(data['role'])) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Akun tidak aktif'};
      }
    } else if (response.statusCode == 401) {
      return {'success': false, 'message': 'Email atau password salah.'};
    } else if (response.statusCode >= 500) {
      return {'success': false, 'message': 'Server sedang bermasalah. Coba lagi nanti.'};
    } else {
      return {'success': false, 'message': 'Terjadi kesalahan saat login. Kode: ${response.statusCode}'};
    }
  }
}
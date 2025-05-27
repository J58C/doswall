import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_storage.dart';

class UpdateProfileService {
  static const String _baseUrl = 'https://sigmaskibidi.my.id/api/clients/update';

  static Future<Map<String, dynamic>> sendUpdateProfile() async {
    final user = await UserStorage.getUser();

    final String userId = user['user_id'];
    final String geotag = user['geotag'] ?? '';
    final int status = user['status'] ?? 0;
    final String notes = user['notes'] ?? '';
    final String token = user['token'] ?? '';
    const String appkey = 'DOEGUSAPPACCESSCORS';

    final url = Uri.parse('$_baseUrl/$userId');

    final Map<String, dynamic> payload = {
      'geotag': geotag,
      'status': status,
      'notes': notes,
      'appkey': appkey,
      '_id': userId,
      'token': token,
    };

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'message': 'Gagal memperbarui data',
        'status': response.statusCode,
        'body': response.body
      };
    }
  }
}
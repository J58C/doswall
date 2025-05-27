import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_storage.dart';

class AnnouncementService {
  static Future<List<dynamic>> getAnnouncements() async {
    final user = await UserStorage.getUser();
    final token = user['token'];
    final appkey = 'DOEGUSAPPACCESSCORS';

    final response = await http.get(
      Uri.parse('https://sigmaskibidi.my.id/api/announcements'),
      headers: {
        'Authorization': 'Bearer $token',
        'appkey': appkey,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }
}

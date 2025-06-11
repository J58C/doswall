import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import './user_storage.dart';

class AnnouncementAddService {
  Future<String?> addAnnouncement({
    required String title,
    required String content,
  }) async {
    final userData = await UserStorage.getUser();
    final String userId = userData['user_id'];
    final String token = userData['token'];

    if (userId.isEmpty || token.isEmpty) {
      throw Exception('User data is missing. Cannot add announcement.');
    }

    final url = Uri.parse('${ApiConfig.announcementsUrl}/add');

    final requestBody = {
      'title': title,
      'content': content,
      '_id': userId,
      'user_id': userId,
      'token': token,
      'appkey': ApiConfig.appKey,
    };

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody['_id'];
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}
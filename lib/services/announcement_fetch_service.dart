import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/announcement.dart';
import './user_storage.dart';

class AnnouncementFetchService {
  Future<List<Announcement>> fetchAnnouncements() async {
    final userData = await UserStorage.getUser();
    final String userId = userData['user_id'];
    final String token = userData['token'];

    if (userId.isEmpty || token.isEmpty) {
      throw Exception('User not logged in or token is missing.');
    }

    final url = Uri.parse('${ApiConfig.announcementsUrl}/getbyuser/$userId');

    final requestBody = {
      'appkey': ApiConfig.appKey,
      'token': token,
      '_id': userId,
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
        List<dynamic> body = jsonDecode(response.body);
        List<Announcement> announcements = body
            .map((dynamic item) => Announcement.fromJson(item))
            .toList();
        return announcements;
      } else {
        throw Exception(
            'Failed to load announcements. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching announcements: $e');
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import './user_storage.dart';

class AnnouncementManageService {
  Future<bool> updateAnnouncement({
    required String announcementId,
    required String title,
    required String content,
  }) async {
    final userData = await UserStorage.getUser();
    final String userId = userData['user_id'];
    final String token = userData['token'];

    if (userId.isEmpty || token.isEmpty) throw Exception('User data not found.');

    final url = Uri.parse('${ApiConfig.announcementsUrl}/update/$announcementId');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final body = jsonEncode({
      'title': title,
      'content': content,
      '_id': userId,
      'appkey': ApiConfig.appKey,
      'token': token,
    });

    try {
      final response = await http.put(url, headers: headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<bool> deleteAnnouncement({
    required String announcementId,
  }) async {
    final userData = await UserStorage.getUser();
    final String userId = userData['user_id'];
    final String token = userData['token'];

    if (userId.isEmpty || token.isEmpty) throw Exception('User data not found.');

    final url = Uri.parse('${ApiConfig.announcementsUrl}/delete/$announcementId');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    final body = jsonEncode({
      '_id': userId,
      'appkey': ApiConfig.appKey,
      'token': token,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
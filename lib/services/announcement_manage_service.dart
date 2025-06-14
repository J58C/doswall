import 'dart:convert';
import '../config/api_config.dart';

import './user_storage.dart';
import './api_client.dart';

class AnnouncementManageService {
  Future<bool> updateAnnouncement({
    required String announcementId,
    required String title,
    required String content,
  }) async {
    final userData = await UserStorage.getUser();
    final String? userId = userData['user_id'];

    if (userId == null) throw Exception('User data not found.');

    final url = Uri.parse('${ApiConfig.announcementsUrl}/update/$announcementId');
    final body = jsonEncode({
      'title': title,
      'content': content,
      '_id': userId,
      'appkey': ApiConfig.appKey,
    });

    try {
      final response = await ApiClient.put(url, body: body);
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody is Map<String, dynamic> && responseBody['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<bool> deleteAnnouncement({
    required String announcementId,
  }) async {
    final userData = await UserStorage.getUser();
    final String? userId = userData['user_id'];

    if (userId == null) throw Exception('User data not found.');

    final url = Uri.parse('${ApiConfig.announcementsUrl}/delete/$announcementId');
    final body = jsonEncode({
      '_id': userId,
      'appkey': ApiConfig.appKey,
    });

    try {
      final response = await ApiClient.post(url, body: body);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody is Map<String, dynamic> && responseBody['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
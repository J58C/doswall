import 'dart:convert';
import '../config/api_config.dart';
import './user_storage.dart';
import './api_client.dart';

class AnnouncementAddService {
  Future<String?> addAnnouncement({
    required String title,
    required String content,
  }) async {
    final userData = await UserStorage.getUser();
    final String? userId = userData['user_id'];

    if (userId == null) {
      throw Exception('User ID tidak ditemukan. Harap login ulang.');
    }

    final url = Uri.parse('${ApiConfig.announcementsUrl}/add');
    final requestBody = {
      'title': title,
      'content': content,
      '_id': userId,
      'user_id': userId,
      'appkey': ApiConfig.appKey,
    };

    try {
      final response = await ApiClient.post(
        url,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          return responseBody['announcement_id'] as String?;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server: $e');
    }
  }
}
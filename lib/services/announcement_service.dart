import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/announcement.dart';
import './user_storage.dart';
import './api_client.dart';

class AnnouncementService {
  Future<List<Announcement>> fetchAnnouncements() async {
    final userData = await UserStorage.getUser();
    final String? userId = userData['user_id'];

    if (userId == null) {
      throw Exception('User not logged in or token is missing.');
    }
    final url = Uri.parse('${ApiConfig.announcementsUrl}/getbyuser/');
    final requestBody = {
      'appkey': ApiConfig.appKey,
      '_id': userId,
    };

    try {
      final response = await ApiClient.post(
        url,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          final dataList = responseBody['data'] as List?;
          if (dataList != null) {
            List<Announcement> announcements = dataList
                .map((dynamic item) => Announcement.fromJson(item))
                .toList();
            return announcements;
          } else {
            return [];
          }
        } else {
          String message = responseBody is Map<String, dynamic>
              ? responseBody['message'] as String? ?? 'Gagal memuat data.'
              : 'Gagal memuat data.';
          throw Exception('Failed to load announcements: $message');
        }
      } else {
        throw Exception(
            'Failed to load announcements. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('fetchAnnouncements Error: $e');
      throw Exception('Error fetching announcements: $e');
    }
  }

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
        }
      }
      return null;
    } catch (e) {
      debugPrint('addAnnouncement Error: $e');
      throw Exception('Gagal menambahkan pengumuman: $e');
    }
  }

  Future<bool> updateAnnouncement({
    required String announcementId,
    required String title,
    required String content,
  }) async {
    final url = Uri.parse('${ApiConfig.announcementsUrl}/update/$announcementId');
    final body = jsonEncode({
      'title': title,
      'content': content,
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
      debugPrint('updateAnnouncement Error: $e');
      throw Exception('Gagal memperbarui pengumuman: $e');
    }
  }

  Future<bool> deleteAnnouncement({
    required String announcementId,
  }) async {
    final url = Uri.parse('${ApiConfig.announcementsUrl}/delete/$announcementId');
    final body = jsonEncode({
      'appkey': ApiConfig.appKey,
    });

    try {
      final response = await ApiClient.post(url, body: body);
      if(response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody is Map<String, dynamic> && responseBody['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('deleteAnnouncement Error: $e');
      throw Exception('Gagal menghapus pengumuman: $e');
    }
  }
}
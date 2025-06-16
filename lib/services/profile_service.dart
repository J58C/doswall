import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/profile_response.dart';
import './api_client.dart';
import './user_storage.dart';

class ProfileService {
  static Future<UpdateProfileResponse> fetchServerData() async {
    final userData = await UserStorage.getUser();
    final String? userId = userData['user_id'];

    if (userId == null) {
      return UpdateProfileResponse(success: false, message: "User ID not found.");
    }
    final url = Uri.parse(ApiConfig.getUserDataUrl + userId);

    try {
      final response = await ApiClient.post(url);

      if (response.statusCode == 200) {
        return UpdateProfileResponse.fromJson(jsonDecode(response.body));
      } else {
        return UpdateProfileResponse(success: false, message: "Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("ProfileService (fetchServerData) Error: $e");
      return UpdateProfileResponse(success: false, message: "Connection error: $e");
    }
  }

  static Future<UpdateProfileResponse> updateUserProfile() async {
    try {
      final user = await UserStorage.getUser();

      final String? userId = user['user_id'] as String?;
      final String geotag = user['geotag'] as String? ?? '-';
      final int status = (user['status'] as num? ?? 0).toInt();
      final String notes = user['notes'] as String? ?? '-';

      if (userId == null) {
        return UpdateProfileResponse(success: false, message: 'User ID tidak ditemukan.');
      }

      final url = Uri.parse(ApiConfig.updateProfileUrl);
      final Map<String, dynamic> payload = {
        'geotag': geotag,
        'status': status,
        'notes': notes,
        'appkey': ApiConfig.appKey,
        '_id': userId,
      };

      final response = await ApiClient.put(
        url,
        body: jsonEncode(payload),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody is Map<String, dynamic> && responseBody['success'] == true) {
        return UpdateProfileResponse(
          success: true,
          data: responseBody['data'] as Map<String, dynamic>?,
          message: 'Profil berhasil diperbarui.',
        );
      } else {
        String message = responseBody is Map<String, dynamic>
            ? responseBody['message'] as String? ?? 'Gagal memperbarui profil.'
            : 'Gagal memperbarui profil.';

        return UpdateProfileResponse(
          success: false,
          message: message,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('ProfileService (updateUserProfile) Error: $e');
      return UpdateProfileResponse(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }
}
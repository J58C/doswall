import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'user_storage.dart';
import '../config/api_config.dart';
import '../models/update_profile_response.dart';

class UpdateProfileService {
  static Future<UpdateProfileResponse> updateUserProfile() async {
    try {
      final user = await UserStorage.getUser();

      final String? userId = user['user_id'] as String?;
      final String geotag = user['geotag'] as String? ?? '-';
      final int status = (user['status'] as num? ?? 0).toInt();
      final String notes = user['notes'] as String? ?? '-';
      final String? token = user['token'] as String?;

      if (userId == null || token == null) {
        return UpdateProfileResponse(success: false, message: 'User ID atau Token tidak ditemukan.');
      }

      final url = Uri.parse(ApiConfig.updateProfileUrl);

      final Map<String, dynamic> payload = {
        'geotag': geotag,
        'status': status,
        'notes': notes,
        'appkey': ApiConfig.appKey,
        '_id': userId,
        'token': token,
      };

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
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
      debugPrint('UpdateProfileService Error: $e');
      return UpdateProfileResponse(
        success: false,
        message: 'Terjadi kesalahan: $e',
      );
    }
  }
}
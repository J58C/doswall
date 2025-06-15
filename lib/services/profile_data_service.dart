import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:doswall/services/user_storage.dart';
import '../config/api_config.dart';
import '../models/update_profile_response.dart';
import 'api_client.dart';

class ProfileDataService {
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
      debugPrint("fetchServerData Error: $e");
      return UpdateProfileResponse(success: false, message: "Connection error: $e");
    }
  }
}
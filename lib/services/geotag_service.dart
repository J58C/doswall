import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/geotag_response.dart';

class GeotagService {
  static Future<GeotagResponse> fetchGeotagData() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
          return GeotagResponse(success: false, message: 'Izin lokasi ditolak permanen atau tidak diberikan.');
        }
      }

      if (permission == LocationPermission.denied) {
        return GeotagResponse(success: false, message: 'Izin lokasi ditolak.');
      }

      // ignore: deprecated_member_use_from_same_package
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final double lat = position.latitude;
      final double long = position.longitude;

      final prefs = await SharedPreferences.getInstance();
      final String? id = prefs.getString('user_id');
      final String? token = prefs.getString('token');

      if (id == null || token == null) {
        return GeotagResponse(success: false, message: 'Data pengguna tidak lengkap di penyimpanan lokal.');
      }

      final response = await http.post(
        Uri.parse(ApiConfig.getLocationListsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': lat.toString(),
          'long': long.toString(),
          '_id': id,
          'appkey': ApiConfig.appKey,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        if (responseData is List && responseData.isNotEmpty) {
          final List<String> locations = responseData.map((item) => item.toString()).toList();
          return GeotagResponse(
            success: true,
            locationLists: locations,
            lat: lat,
            long: long,
          );
        } else if (responseData is Map && responseData.containsKey('message')) {
          return GeotagResponse(success: false, message: responseData['message'] as String? ?? 'Data lokasi tidak ditemukan dari server.');
        } else {
          return GeotagResponse(success: false, message: 'Data lokasi tidak ditemukan atau format respons tidak sesuai.');
        }
      } else {
        String errorMessage = 'Gagal mengambil data lokasi (Status: ${response.statusCode})';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = 'Gagal: ${errorBody['message']} (Status: ${response.statusCode})';
          }
        } catch (e) {
          // Biarkan errorMessage default
        }
        return GeotagResponse(success: false, message: errorMessage);
      }
    } catch (e) {
      debugPrint('GeotagService Error: $e');
      String errorMessage = 'Terjadi kesalahan pada layanan geotag: $e';
      if (e is TimeoutException) {
        errorMessage = 'Gagal mendapatkan lokasi: Waktu habis. Periksa koneksi internet Anda.';
      } else if (e is LocationServiceDisabledException) {
        errorMessage = 'Layanan lokasi tidak aktif. Mohon aktifkan layanan lokasi pada perangkat Anda.';
      }
      return GeotagResponse(success: false, message: errorMessage);
    }
  }
}
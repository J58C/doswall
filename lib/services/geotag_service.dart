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
      bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        return GeotagResponse(success: false, message: 'Layanan lokasi tidak aktif. Mohon aktifkan GPS Anda.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return GeotagResponse(success: false, message: 'Izin lokasi ditolak.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return GeotagResponse(success: false, message: 'Izin lokasi ditolak permanen. Mohon aktifkan dari pengaturan aplikasi.');
      }

      final LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 20));

      final double lat = position.latitude;
      final double long = position.longitude;

      final prefs = await SharedPreferences.getInstance();
      final String? id = prefs.getString('user_id');
      final String? token = prefs.getString('token');

      if (id == null || token == null) {
        return GeotagResponse(success: false, message: 'Data pengguna tidak lengkap. Silakan login kembali.');
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

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody is Map<String, dynamic>) {
        if (responseBody['success'] == true) {
          final dataList = responseBody['data'] as List?;
          if (dataList != null && dataList.isNotEmpty) {
            final List<String> locations = dataList.map((item) => item.toString()).toList();
            return GeotagResponse(
              success: true,
              locationLists: locations,
              lat: lat,
              long: long,
            );
          } else {
            return GeotagResponse(success: false, message: 'Daftar lokasi tidak ditemukan di sekitar Anda.');
          }
        } else {
          return GeotagResponse(success: false, message: responseBody['message'] ?? 'Server mengembalikan respons gagal.');
        }
      } else {
        return GeotagResponse(success: false, message: 'Gagal terhubung ke server (Status: ${response.statusCode}).');
      }
    } on TimeoutException {
      return GeotagResponse(success: false, message: 'Gagal mendapatkan lokasi: Waktu habis. Periksa koneksi internet dan sinyal GPS.');
    } on LocationServiceDisabledException {
      return GeotagResponse(success: false, message: 'Layanan lokasi tidak aktif. Mohon aktifkan layanan lokasi pada perangkat Anda.');
    } catch (e) {
      debugPrint('GeotagService Error: $e');
      return GeotagResponse(success: false, message: 'Terjadi kesalahan tidak terduga: $e');
    }
  }
}
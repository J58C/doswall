import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String appkey = 'DOEGUSAPPACCESSCORS';

class GeotagService {
  static const String _apiUrl = 'https://sigmaskibidi.my.id/api/clients/getlocationlists';

  static Future<Map<String, dynamic>> sendLocationAndGetName() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
          return {'success': false, 'message': 'Izin lokasi ditolak permanen atau tidak diberikan.'};
        }
      }

      if (permission == LocationPermission.denied) {
        return {'success': false, 'message': 'Izin lokasi ditolak.'};
      }

      // --- MENGGUNAKAN KEMBALI desiredAccuracy ---
      // Ini akan menimbulkan peringatan 'deprecated', tetapi seharusnya bisa berjalan
      // ignore: deprecated_member_use_from_same_package
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      // --- AKHIR PERUBAHAN ---

      final lat = position.latitude;
      final long = position.longitude;

      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('user_id');
      final token = prefs.getString('token');

      if (id == null || token == null) {
        return {'success': false, 'message': 'Data pengguna tidak lengkap di penyimpanan lokal'};
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': lat.toString(),
          'long': long.toString(),
          '_id': id,
          'appkey': appkey,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        if (responseData is List && responseData.isNotEmpty) {
          return {
            'success': true,
            'locationLists': responseData,
            'lat': lat,
            'long': long,
          };
        } else if (responseData is Map && responseData.containsKey('message')) {
          return {'success': false, 'message': responseData['message'] ?? 'Data lokasi tidak ditemukan dari server.'};
        }
        else {
          return {'success': false, 'message': 'Data lokasi tidak ditemukan atau format respons tidak sesuai.'};
        }
      } else {
        String errorMessage = 'Gagal mengambil data lokasi: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = 'Gagal mengambil data lokasi: ${errorBody['message']} (Status: ${response.statusCode})';
          }
        } catch (e) {
          // Biarkan errorMessage default
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      debugPrint('GeotagService Error: $e');
      String errorMessage = 'Terjadi kesalahan dalam GeotagService: $e';
      if (e is TimeoutException) {
        errorMessage = 'Gagal mendapatkan lokasi: Waktu habis. Periksa koneksi internet Anda.';
      } else if (e is LocationServiceDisabledException) {
        errorMessage = 'Layanan lokasi tidak aktif. Mohon aktifkan layanan lokasi pada perangkat Anda.';
      }
      return {'success': false, 'message': errorMessage};
    }
  }
}
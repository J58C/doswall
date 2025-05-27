import 'dart:convert';
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
          return {'success': false, 'message': 'Izin lokasi ditolak'};
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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

      // Cek hasil response
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return {
            'success': true,
            'locationLists': data,
            'lat': lat,
            'long': long,
          };
        } else {
          return {'success': false, 'message': 'Data lokasi tidak ditemukan'};
        }
      } else {
        return {
          'success': false,
          'message': 'Gagal mengambil data lokasi: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
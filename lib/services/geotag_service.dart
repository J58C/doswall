import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'user_storage.dart';

class GeotagService {
  static const String _apiUrl = 'https://sigmaskibidi.my.id/api/clients/getlocationlists';
  static const String _appKey = 'DOEGUSAPPACCESSCORS';

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

      final user = await UserStorage.getUser();
      final token = user['token'];

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': lat.toString(),
          'long': long.toString(),
          'appkey': _appKey,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final locationList = data['locationLists'];
        if (locationList is List && locationList.isNotEmpty) {
          return {
            'success': true,
            'locationLists': locationList,
            'lat': lat,
            'long': long,
          };
        } else {
          return {'success': false, 'message': 'Data lokasi tidak ditemukan'};
        }
      } else {
        return {'success': false, 'message': 'Gagal mengambil data lokasi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
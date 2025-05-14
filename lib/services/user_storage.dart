import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('_id', userData['_id']);
    await prefs.setString('name', userData['name']);
    await prefs.setString('email', userData['email']);
    await prefs.setString('role', userData['role']);
    await prefs.setInt('status', userData['status']);
    await prefs.setString('geotag', userData['geotag']);
    await prefs.setString('notes', userData['notes']);
    await prefs.setString('token', userData['token']);
  }

  static Future<Map<String, dynamic>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      '_id': prefs.getString('_id') ?? '',
      'name': prefs.getString('name') ?? '',
      'email': prefs.getString('email') ?? '',
      'role': prefs.getString('role') ?? '',
      'status': prefs.getInt('status') ?? 0,
      'geotag': prefs.getString('geotag') ?? '',
      'notes': prefs.getString('notes') ?? '',
      'token': prefs.getString('token') ?? '',
    };
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
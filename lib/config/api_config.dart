class ApiConfig {
  static const String baseUrl = 'https://sigmaskibidi.my.id';
  static const String appKey = 'DOEGUSAPPACCESSCORS';

  // --- Definisi Endpoint ---
  static const String announcementsUrl = '$baseUrl/api/announcements';
  static const String loginUrl = '$baseUrl/appkey/login';
  static const String getLocationListsUrl = '$baseUrl/api/clients/getlocationlists';
  static const String updateProfileUrl = '$baseUrl/api/clients/update/';
  static const String forgotPasswordUrl = '$baseUrl/appkey/password/mailpw';
  static const String changePasswordBaseUrl = '$baseUrl/api/password/update';
  static const String getSessionTokenUrl = '$baseUrl/appkey/getsessiontoken';
  static const String checkTokenStatusUrl = '$baseUrl/appkey/checktokenstatus';
  static const String getUserDataUrl = '$baseUrl/api/clients/get/';
}
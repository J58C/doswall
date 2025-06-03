class AuthResponse {
  final bool success;
  final Map<String, dynamic>? userData;
  final String? message;

  AuthResponse({
    required this.success,
    this.userData,
    this.message,
  });
}
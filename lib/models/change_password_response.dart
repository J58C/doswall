class ChangePasswordResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final int? statusCode;

  ChangePasswordResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });
}
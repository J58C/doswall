class UpdateProfileResponse {
  final bool success;
  final Map<String, dynamic>? data;
  final String? message;
  final int? statusCode;

  UpdateProfileResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });
}
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

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      success: json['success'] ?? false,
      data: json['data'] as Map<String, dynamic>?,
      message: json['message'] as String?,
    );
  }
}
class ForgotPasswordResponse {
  final bool success;
  final String? message;
  final int? statusCode;

  ForgotPasswordResponse({
    required this.success,
    this.message,
    this.statusCode,
  });
}
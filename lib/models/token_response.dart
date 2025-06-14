class GetSessionTokenResponse {  final bool success;
  final String? token;

  GetSessionTokenResponse({required this.success, this.token});

  factory GetSessionTokenResponse.fromJson(Map<String, dynamic> json) {
    return GetSessionTokenResponse(
      success: json['success'] ?? false,
      token: json['data']?['token'] as String?,
    );
  }
}

class CheckTokenStatusResponse {
  final bool success;
  final bool? tokenStatus;

  CheckTokenStatusResponse({required this.success, this.tokenStatus});

  factory CheckTokenStatusResponse.fromJson(Map<String, dynamic> json) {
    return CheckTokenStatusResponse(
      success: json['success'] ?? false,
      tokenStatus: json['data']?['tokenStatus'] as bool?,
    );
  }
}
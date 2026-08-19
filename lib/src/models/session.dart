export 'auth_status.dart';

/// Single Sign-On (SSO) validation result from `/sso/validate`.
class SsoValidationResult {
  /// Expiration timestamp in milliseconds for SSO token.
  final int ssoExpires;

  /// Username associated with SSO login.
  final String userName;

  /// Internal user ID.
  final int userId;

  /// Boolean or string result indicating validation status.
  final bool result;

  /// Epoch timestamp of authentication.
  final int authTime;

  /// Raw JSON map response.
  final Map<String, dynamic> raw;

  /// Creates an [SsoValidationResult] instance.
  SsoValidationResult({
    required this.ssoExpires,
    required this.userName,
    required this.userId,
    required this.result,
    required this.authTime,
    required this.raw,
  });

  /// Factory constructor from JSON.
  factory SsoValidationResult.fromJson(Map<String, dynamic> json) {
    return SsoValidationResult(
      ssoExpires: json['SSOExpires'] is int
          ? json['SSOExpires'] as int
          : int.tryParse(json['SSOExpires']?.toString() ?? '0') ?? 0,
      userName:
          json['user_name']?.toString() ?? json['userName']?.toString() ?? '',
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      result: json['RESULT'] == true ||
          json['RESULT'] == 1 ||
          json['result'] == true,
      authTime: json['AUTH_TIME'] is int
          ? json['AUTH_TIME'] as int
          : int.tryParse(json['AUTH_TIME']?.toString() ?? '0') ?? 0,
      raw: json,
    );
  }

  /// Converts [SsoValidationResult] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'SSOExpires': ssoExpires,
      'user_name': userName,
      'user_id': userId,
      'RESULT': result,
      'AUTH_TIME': authTime,
    };
  }

  @override
  String toString() {
    return 'SsoValidationResult(userName: $userName, result: $result, ssoExpires: $ssoExpires)';
  }
}

/// Response returned from `/logout` endpoint.
class LogoutResponse {
  /// Status of the logout request (e.g. true/false or 'success').
  final bool status;

  /// Optional message detailing logout status.
  final String? message;

  /// Creates a [LogoutResponse] instance.
  LogoutResponse({
    required this.status,
    this.message,
  });

  /// Factory constructor from JSON.
  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    final statusVal = json['status'];
    final isConfirmed = statusVal == true ||
        statusVal == 'confirmed' ||
        statusVal == 200 ||
        json['confirmed'] == true;
    return LogoutResponse(
      status: isConfirmed,
      message: json['message']?.toString() ?? json['text']?.toString(),
    );
  }

  /// Converts [LogoutResponse] to JSON.
  Map<String, dynamic> toJson() => {
        'status': status,
        if (message != null) 'message': message,
      };

  @override
  String toString() => 'LogoutResponse(status: $status, message: $message)';
}

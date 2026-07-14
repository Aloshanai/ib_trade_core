/// Standard exception thrown when the Interactive Brokers Client Portal Gateway
/// returns an error response or when request execution fails.
class IbException implements Exception {
  /// The extracted error message.
  final String message;

  /// Optional HTTP status code returned by the gateway.
  final int? statusCode;

  /// Optional raw JSON or string response body.
  final dynamic rawResponse;

  /// Creates a standard [IbException] with [message], [statusCode], and [rawResponse].
  IbException(this.message, {this.statusCode, this.rawResponse});

  /// Factory constructor to parse and construct an [IbException] from a dynamic JSON payload.
  factory IbException.fromJson(dynamic json, [int? statusCode]) {
    if (json == null) {
      return IbException('Unknown error occurred', statusCode: statusCode);
    }

    if (json is String) {
      return IbException(json, statusCode: statusCode, rawResponse: json);
    }

    if (json is Map) {
      // 1. {"error": "message"}
      final errorVal = json['error'];
      if (errorVal != null) {
        if (errorVal is String) {
          return IbException(errorVal,
              statusCode: statusCode, rawResponse: json);
        } else if (errorVal is Map && errorVal['message'] is String) {
          // 2. {"error": {"message": "nested message"}}
          return IbException(errorVal['message'] as String,
              statusCode: statusCode, rawResponse: json);
        }
      }

      // 3. {"errors": ["message1", "message2"]}
      final errorsVal = json['errors'];
      if (errorsVal is List && errorsVal.isNotEmpty) {
        final messages = errorsVal.map((e) => e.toString()).join(', ');
        return IbException(messages, statusCode: statusCode, rawResponse: json);
      }

      // 4. {"message": "message"}
      final msgVal = json['message'];
      if (msgVal is String) {
        return IbException(msgVal, statusCode: statusCode, rawResponse: json);
      }
    }

    return IbException(json.toString(),
        statusCode: statusCode, rawResponse: json);
  }

  @override
  String toString() {
    final statusStr = statusCode != null ? ' (Status $statusCode)' : '';
    return 'IbException$statusStr: $message';
  }
}

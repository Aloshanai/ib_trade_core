import '../client/challenge_handler.dart';

/// Generic result wrapper encapsulating response payloads, status codes, error details, and challenges.
class IbResult<T> {
  /// Whether the operation succeeded.
  final bool isSuccess;

  /// The response data payload [T] if successful.
  final T? data;

  /// Error message or failure detail if failed.
  final String? error;

  /// Compliance or safety warning challenge if triggered.
  final IbChallenge? challenge;

  /// HTTP status code.
  final int statusCode;

  IbResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.challenge,
    this.statusCode = 200,
  });

  /// Factory for successful result.
  factory IbResult.success(T data, {int statusCode = 200}) {
    return IbResult._(
      isSuccess: true,
      data: data,
      statusCode: statusCode,
    );
  }

  /// Factory for failed result.
  factory IbResult.failure(String error,
      {int statusCode = 400, IbChallenge? challenge}) {
    return IbResult._(
      isSuccess: false,
      error: error,
      challenge: challenge,
      statusCode: statusCode,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'IbResult.success(data: $data, statusCode: $statusCode)';
    }
    return 'IbResult.failure(error: $error, statusCode: $statusCode, challenge: $challenge)';
  }
}

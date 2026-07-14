/// Represents the authentication and connection status of the Gateway session.
class AuthStatus {
  /// Whether the session is authenticated with IBKR.
  final bool authenticated;

  /// Whether the session is currently connected to the trade backend.
  final bool connected;

  /// Whether another client session is competing for this connection.
  final bool competing;

  /// The username associated with the authenticated session, if available.
  final String? username;

  /// Explanation for authentication failure, if any.
  final String? failReason;

  /// Creates an [AuthStatus] instance.
  AuthStatus({
    required this.authenticated,
    required this.connected,
    required this.competing,
    this.username,
    this.failReason,
  });

  /// Factory constructor to parse [AuthStatus] from a JSON map.
  factory AuthStatus.fromJson(Map<String, dynamic> json) {
    return AuthStatus(
      authenticated: json['authenticated'] == true,
      connected: json['connected'] == true,
      competing: json['competing'] == true,
      username: json['username'] as String?,
      failReason: json['fail'] as String? ?? json['error'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthStatus &&
          runtimeType == other.runtimeType &&
          authenticated == other.authenticated &&
          connected == other.connected &&
          competing == other.competing &&
          username == other.username &&
          failReason == other.failReason;

  @override
  int get hashCode =>
      authenticated.hashCode ^
      connected.hashCode ^
      competing.hashCode ^
      username.hashCode ^
      failReason.hashCode;

  @override
  String toString() {
    return 'AuthStatus(authenticated: $authenticated, connected: $connected, competing: $competing, username: $username, failReason: $failReason)';
  }
}

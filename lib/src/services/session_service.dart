import 'dart:convert';
import 'package:http/http.dart' as http;
import '../client/session_tickler.dart';
import '../models/session.dart';

/// Service adapting session and authentication endpoints for IBKR Client Portal API.
class SessionService {
  final http.Client client;
  final String baseUrl;
  final SessionTickler? tickler;

  /// Creates a [SessionService] instance.
  SessionService({
    required this.client,
    required this.baseUrl,
    this.tickler,
  });

  String _cleanUrl(String endpoint) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$base$path';
  }

  /// Queries the current session authentication status (`GET /iserver/auth/status`).
  Future<AuthStatus> getAuthStatus() async {
    final response =
        await client.get(Uri.parse(_cleanUrl('/iserver/auth/status')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthStatus.fromJson(json);
    }
    return AuthStatus(
      authenticated: false,
      connected: false,
      competing: false,
      failReason: 'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  /// Sends a session keep-alive heartbeat (`POST /tickle`).
  Future<Map<String, dynamic>> tickle() async {
    final response = await client.post(Uri.parse(_cleanUrl('/tickle')));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {'session': false, 'error': response.body};
  }

  /// Terminate the active gateway session (`POST /logout`).
  Future<LogoutResponse> logout() async {
    tickler?.stop();
    final response = await client.post(Uri.parse(_cleanUrl('/logout')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return LogoutResponse.fromJson(json);
    }
    return LogoutResponse(
      status: false,
      message: 'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  /// Re-authenticates the current gateway session (`POST /iserver/reauthenticate`).
  Future<AuthStatus> reauthenticate() async {
    final response =
        await client.post(Uri.parse(_cleanUrl('/iserver/reauthenticate')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthStatus.fromJson(json);
    }
    return AuthStatus(
      authenticated: false,
      connected: false,
      competing: false,
      failReason: 'Re-authentication failed with status ${response.statusCode}',
    );
  }

  /// Validates Single Sign-On (SSO) token (`GET /sso/validate`).
  Future<SsoValidationResult> validateSso() async {
    final response = await client.get(Uri.parse(_cleanUrl('/sso/validate')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SsoValidationResult.fromJson(json);
    }
    return SsoValidationResult(
      ssoExpires: 0,
      userName: '',
      userId: 0,
      result: false,
      authTime: 0,
      raw: {'error': response.body, 'statusCode': response.statusCode},
    );
  }
}

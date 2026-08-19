import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Preconfigured standard mock payloads returned by Interactive Brokers Client Portal Gateway.
class IbMockPayloads {
  /// Session tickle active payload.
  static const Map<String, dynamic> tickleSuccess = {
    'session': true,
    'authenticated': true,
    'ssoExpires': 86400000,
  };

  /// Auth status success payload.
  static const Map<String, dynamic> authStatusSuccess = {
    'authenticated': true,
    'connected': true,
    'competing': false,
    'username': 'edemo',
    'fail': '',
  };

  /// Auth status disconnected payload.
  static const Map<String, dynamic> authStatusDisconnected = {
    'authenticated': false,
    'connected': false,
    'competing': false,
    'username': '',
    'fail': 'Not logged in',
  };

  /// Standard account list payload.
  static const List<Map<String, dynamic>> accounts = [
    {
      'id': 'DU123456',
      'name': 'Individual Paper Account',
      'type': 'INDIVIDUAL',
      'currency': 'USD',
    }
  ];

  /// Standard position list payload.
  static const List<Map<String, dynamic>> positions = [
    {
      'acctId': 'DU123456',
      'conid': 265598,
      'contractDesc': 'AAPL',
      'position': 100.0,
      'mktPrice': 150.0,
      'mktVal': 15000.0,
      'avgCost': 145.0,
    }
  ];

  /// Standard ticker updates payload.
  static const List<Map<String, dynamic>> tickers = [
    {
      'conid': 265598,
      'symbol': 'AAPL',
      'last': 150.25,
      'change': 0.50,
    }
  ];

  /// Standard execution history payload.
  static const List<Map<String, dynamic>> executionHistory = [
    {
      'executionId': 'exec_001',
      'orderId': '1001',
      'conid': 265598,
      'symbol': 'AAPL',
      'side': 'BUY',
      'price': 150.25,
      'quantity': 50.0,
      'time': '2026-08-19T10:00:00Z',
      'account': 'DU123456',
      'commission': 1.0,
      'exchange': 'NASDAQ',
    }
  ];

  /// Standard SSO validation payload.
  static const Map<String, dynamic> ssoValidateSuccess = {
    'SSOExpires': 86400000,
    'user_name': 'edemo',
    'user_id': 12345,
    'RESULT': true,
    'AUTH_TIME': 1700000000,
  };

  /// Standard logout payload.
  static const Map<String, dynamic> logoutSuccess = {
    'status': true,
    'message': 'Logged out successfully',
  };
}

/// Helper to build a mock HTTP client that simulates the IBKR Gateway endpoints.
class MockGatewayHttp {
  final Map<String, http.Response Function(http.Request)> _customRoutes = {};

  /// Registers a custom route response handler for the given [path].
  void registerRoute(
      String path, http.Response Function(http.Request) handler) {
    _customRoutes[path] = handler;
  }

  /// Builds a [MockClient] configured with default routes and any custom registered overrides.
  MockClient buildClient() {
    return MockClient((request) async {
      final path = request.url.path;

      // Check custom overrides first
      for (final route in _customRoutes.keys) {
        if (path.endsWith(route)) {
          return _customRoutes[route]!(request);
        }
      }

      // Default route handlers
      if (path.endsWith('/tickle')) {
        return http.Response(
          jsonEncode(IbMockPayloads.tickleSuccess),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.endsWith('/iserver/auth/status') ||
          path.endsWith('/iserver/reauthenticate')) {
        return http.Response(
          jsonEncode(IbMockPayloads.authStatusSuccess),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.endsWith('/sso/validate')) {
        return http.Response(
          jsonEncode(IbMockPayloads.ssoValidateSuccess),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.endsWith('/logout')) {
        return http.Response(
          jsonEncode(IbMockPayloads.logoutSuccess),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.endsWith('/iserver/accounts')) {
        return http.Response(
          jsonEncode(IbMockPayloads.accounts),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.contains('/iserver/reply/')) {
        return http.Response('{"status": "ok"}', 200,
            headers: {'content-type': 'application/json'});
      }

      return http.Response(
        '{"error": "Path not found: $path"}',
        404,
        headers: {'content-type': 'application/json'},
      );
    });
  }
}

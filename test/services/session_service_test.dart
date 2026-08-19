import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ib_trade_core/src/testing/mock_gateway.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('SessionService', () {
    late MockGatewayHttp mockGateway;
    late http.Client client;
    late SessionService service;

    setUp(() {
      mockGateway = MockGatewayHttp();
      client = mockGateway.buildClient();
      service = SessionService(
          client: client, baseUrl: 'https://localhost:5000/v1/api');
    });

    test('getAuthStatus should return valid AuthStatus', () async {
      final status = await service.getAuthStatus();
      expect(status.authenticated, isTrue);
      expect(status.connected, isTrue);
      expect(status.username, 'edemo');
    });

    test('tickle should return tickle response map', () async {
      final res = await service.tickle();
      expect(res['session'], isTrue);
      expect(res['authenticated'], isTrue);
    });

    test('reauthenticate should return AuthStatus', () async {
      final status = await service.reauthenticate();
      expect(status.authenticated, isTrue);
    });

    test('validateSso should return SsoValidationResult', () async {
      final sso = await service.validateSso();
      expect(sso.result, isTrue);
      expect(sso.userName, 'edemo');
      expect(sso.userId, 12345);
    });

    test('logout should return LogoutResponse', () async {
      final res = await service.logout();
      expect(res.status, isTrue);
    });

    test('should handle network failure gracefully', () async {
      final customMock = MockGatewayHttp();
      customMock.registerRoute('/iserver/auth/status',
          (req) => http.Response('Internal Server Error', 500));
      final failService = SessionService(
          client: customMock.buildClient(),
          baseUrl: 'https://localhost:5000/v1/api');

      final status = await failService.getAuthStatus();
      expect(status.authenticated, isFalse);
      expect(status.failReason, contains('500'));
    });
  });
}

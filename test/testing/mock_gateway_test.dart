import 'dart:convert';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:ib_trade_core/ib_trade_core_test.dart';
import 'package:test/test.dart';

void main() {
  group('MockGatewayHttp', () {
    test('should route standard paths to correct mock payloads', () async {
      final mockGateway = MockGatewayHttp();
      final client = mockGateway.buildClient();

      final tickleRes =
          await client.get(Uri.parse('https://gateway/v1/api/tickle'));
      expect(tickleRes.statusCode, equals(200));
      expect(jsonDecode(tickleRes.body), equals(IbMockPayloads.tickleSuccess));

      final authRes = await client
          .get(Uri.parse('https://gateway/v1/api/iserver/auth/status'));
      expect(authRes.statusCode, equals(200));
      expect(
          jsonDecode(authRes.body), equals(IbMockPayloads.authStatusSuccess));

      final acctsRes = await client
          .get(Uri.parse('https://gateway/v1/api/iserver/accounts'));
      expect(acctsRes.statusCode, equals(200));
      expect(jsonDecode(acctsRes.body), equals(IbMockPayloads.accounts));
    });

    test('should support registering custom path overrides', () async {
      final mockGateway = MockGatewayHttp();
      mockGateway.registerRoute('/tickle', (request) {
        return http.Response('{"custom_tickle": true}', 200);
      });
      mockGateway.registerRoute('/custom/path', (request) {
        return http.Response('{"custom_data": 42}', 201);
      });

      final client = mockGateway.buildClient();

      final tickleRes =
          await client.get(Uri.parse('https://gateway/v1/api/tickle'));
      expect(tickleRes.statusCode, equals(200));
      expect(jsonDecode(tickleRes.body), equals({'custom_tickle': true}));

      final customRes =
          await client.get(Uri.parse('https://gateway/v1/api/custom/path'));
      expect(customRes.statusCode, equals(201));
      expect(jsonDecode(customRes.body), equals({'custom_data': 42}));
    });

    test('should return 404 for unknown routes', () async {
      final mockGateway = MockGatewayHttp();
      final client = mockGateway.buildClient();

      final res = await client
          .get(Uri.parse('https://gateway/v1/api/unknown/endpoint'));
      expect(res.statusCode, equals(404));
      expect(jsonDecode(res.body),
          containsPair('error', contains('Path not found')));
    });
  });

  group('MockGatewayWebSocketServer', () {
    late MockGatewayWebSocketServer mockServer;

    setUp(() async {
      mockServer = MockGatewayWebSocketServer();
      await mockServer.start();
    });

    tearDown(() async {
      await mockServer.stop();
    });

    test('should receive tickles and broadcast messages to connected clients',
        () async {
      final clientSocket =
          await io.WebSocket.connect(mockServer.wsUri.toString());
      final receivedOnClient = [];

      final clientSub = clientSocket.listen((message) {
        receivedOnClient.add(message.toString());
      });

      clientSocket.add('tickle');

      final firstPing = await mockServer.pingStream.first;
      expect(firstPing, equals('tickle'));
      expect(mockServer.receivedPings, contains('tickle'));

      mockServer.broadcast('hello client');
      mockServer.broadcastJson({'event': 'update', 'data': 100});

      await Future.delayed(const Duration(milliseconds: 50));

      expect(receivedOnClient, contains('hello client'));
      expect(receivedOnClient,
          contains(jsonEncode({'event': 'update', 'data': 100})));

      await clientSub.cancel();
      await clientSocket.close();
    });
  });
}

import 'dart:async';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:test/test.dart';

void main() {
  group('IbWebSocketConnection', () {
    late io.HttpServer server;
    late int port;
    late Uri wsUrl;

    setUp(() async {
      server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
      port = server.port;
      wsUrl = Uri.parse('ws://localhost:$port/ws');
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('should connect, authenticate with cookies, send and receive messages',
        () async {
      final List<String> receivedOnServer = [];
      late String? cookieHeaderValue;

      server.listen((request) async {
        if (io.WebSocketTransformer.isUpgradeRequest(request)) {
          cookieHeaderValue = request.headers.value('cookie');
          final socket = await io.WebSocketTransformer.upgrade(request);
          socket.listen((data) {
            receivedOnServer.add(data.toString());
            if (data == 'hello from client') {
              socket.add('hello from server');
            }
          });
        }
      });

      final mockInner = MockClient((request) async {
        return http.Response('{}', 200,
            headers: {'set-cookie': 'session_token=secret123'});
      });
      final cookieClient = CookieClient(mockInner);
      await cookieClient.get(Uri.parse('https://localhost/auth'));

      final conn = IbWebSocketConnection(
        wsUrl,
        cookieClient: cookieClient,
        heartbeatInterval: const Duration(milliseconds: 100),
      );

      final stateHistory = <IbWebSocketState>[];
      conn.stateChanges.listen(stateHistory.add);

      await conn.connect();
      expect(conn.state, equals(IbWebSocketState.connected));
      expect(cookieHeaderValue, equals('session_token=secret123'));

      conn.send('hello from client');

      final serverMessage = await conn.messages.first;
      expect(serverMessage, equals('hello from server'));
      expect(receivedOnServer, contains('hello from client'));

      await conn.disconnect();
      await Future.delayed(Duration.zero); // Allow stream events to propagate

      expect(conn.state, equals(IbWebSocketState.disconnected));
      expect(stateHistory, contains(IbWebSocketState.connected));
      expect(stateHistory, contains(IbWebSocketState.disconnected));
    });

    test('should periodically transmit heartbeat (tickle) messages', () async {
      final List<String> receivedOnServer = [];

      server.listen((request) async {
        if (io.WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await io.WebSocketTransformer.upgrade(request);
          socket.listen((data) {
            receivedOnServer.add(data.toString());
          });
        }
      });

      final conn = IbWebSocketConnection(
        wsUrl,
        heartbeatInterval: const Duration(milliseconds: 30),
      );

      await conn.connect();

      await Future.delayed(const Duration(milliseconds: 80));
      expect(receivedOnServer, contains('tickle'));
      expect(receivedOnServer.where((msg) => msg == 'tickle').length,
          greaterThanOrEqualTo(2));

      await conn.disconnect();
    });

    test('should auto-reconnect with exponential backoff on server drop',
        () async {
      int connectionCount = 0;
      io.WebSocket? activeSocket;

      server.listen((request) async {
        if (io.WebSocketTransformer.isUpgradeRequest(request)) {
          connectionCount++;
          final socket = await io.WebSocketTransformer.upgrade(request);
          activeSocket = socket;
        }
      });

      final conn = IbWebSocketConnection(
        wsUrl,
        initialRetryDelay: const Duration(milliseconds: 20),
        maxRetryDelay: const Duration(milliseconds: 100),
        heartbeatInterval: const Duration(seconds: 10),
      );

      final stateHistory = <IbWebSocketState>[];
      conn.stateChanges.listen(stateHistory.add);

      await conn.connect();
      expect(conn.state, equals(IbWebSocketState.connected));
      expect(connectionCount, equals(1));

      // Wait until the server-side socket is actually captured and assigned
      for (int i = 0; i < 20; i++) {
        if (activeSocket != null) break;
        await Future.delayed(const Duration(milliseconds: 10));
      }
      expect(activeSocket, isNotNull);

      // Force close the server-side socket
      await activeSocket!.close();

      // Poll up to 500ms for connection count to hit 2 and state to be connected again
      for (int i = 0; i < 10; i++) {
        if (connectionCount == 2 && conn.state == IbWebSocketState.connected) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }

      expect(conn.state, equals(IbWebSocketState.connected));
      expect(connectionCount, equals(2));
      expect(stateHistory, contains(IbWebSocketState.reconnecting));

      await conn.disconnect();
    });

    test('should connect successfully with bypassSslVerification set to true',
        () async {
      server.listen((request) async {
        if (io.WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await io.WebSocketTransformer.upgrade(request);
          socket.listen((data) {});
        }
      });

      final conn = IbWebSocketConnection(
        wsUrl,
        bypassSslVerification: true,
      );

      await conn.connect();
      expect(conn.state, equals(IbWebSocketState.connected));

      await conn.disconnect();
    });
  });
}

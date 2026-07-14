import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
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

      if (path.endsWith('/iserver/auth/status')) {
        return http.Response(
          jsonEncode(IbMockPayloads.authStatusSuccess),
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

/// A local loopback mock WebSocket server helper.
class MockGatewayWebSocketServer {
  io.HttpServer? _server;
  final List<io.WebSocket> _activeSockets = [];
  final List<String> _receivedPings = [];

  final StreamController<String> _pingController =
      StreamController<String>.broadcast();

  /// Starts the mock WebSocket server on the local loopback using an ephemeral port.
  Future<void> start() async {
    _server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    _server!.listen((request) async {
      if (io.WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await io.WebSocketTransformer.upgrade(request);
        _activeSockets.add(socket);

        socket.listen(
          (message) {
            final msgStr = message.toString();
            if (msgStr == 'tickle') {
              _receivedPings.add(msgStr);
              _pingController.add(msgStr);
            }
          },
          onDone: () {
            _activeSockets.remove(socket);
          },
          onError: (_) {
            _activeSockets.remove(socket);
          },
        );
      }
    });
  }

  /// The port number the server is bound to.
  int get port {
    if (_server == null) {
      throw StateError('Server is not running. Call start() first.');
    }
    return _server!.port;
  }

  /// The base ws:// URI of the server.
  Uri get wsUri {
    return Uri.parse('ws://localhost:$port/v1/api/ws');
  }

  /// List of pings received by the server.
  List<String> get receivedPings => List.unmodifiable(_receivedPings);

  /// Stream that emits whenever a 'tickle' ping is received.
  Stream<String> get pingStream => _pingController.stream;

  /// Broadcasts a custom text message to all active WebSocket clients.
  void broadcast(String message) {
    for (final socket in _activeSockets) {
      socket.add(message);
    }
  }

  /// Broadcasts a JSON map as a text frame to all active clients.
  void broadcastJson(Map<String, dynamic> json) {
    broadcast(jsonEncode(json));
  }

  /// Stops the server and closes all active sockets.
  Future<void> stop() async {
    _pingController.close();
    for (final socket in List<io.WebSocket>.from(_activeSockets)) {
      await socket.close();
    }
    _activeSockets.clear();
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
  }
}

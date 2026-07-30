import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

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

import 'dart:async';

/// A stub implementation of MockGatewayWebSocketServer for platforms without dart:io.
class MockGatewayWebSocketServer {
  /// Stub start method.
  Future<void> start() {
    throw UnsupportedError(
        'MockGatewayWebSocketServer is only supported on VM/desktop platforms.');
  }

  /// Stub port getter.
  int get port {
    throw UnsupportedError(
        'MockGatewayWebSocketServer is only supported on VM/desktop platforms.');
  }

  /// Stub wsUri getter.
  Uri get wsUri {
    throw UnsupportedError(
        'MockGatewayWebSocketServer is only supported on VM/desktop platforms.');
  }

  /// Stub receivedPings getter.
  List<String> get receivedPings {
    throw UnsupportedError(
        'MockGatewayWebSocketServer is only supported on VM/desktop platforms.');
  }

  /// Stub pingStream getter.
  Stream<String> get pingStream {
    throw UnsupportedError(
        'MockGatewayWebSocketServer is only supported on VM/desktop platforms.');
  }

  /// Stub broadcast method.
  void broadcast(String message) {
    throw UnsupportedError(
        'MockGatewayWebSocketServer is only supported on VM/desktop platforms.');
  }

  /// Stub broadcastJson method.
  void broadcastJson(Map<String, dynamic> json) {
    throw UnsupportedError(
        'MockGatewayWebSocketServer is only supported on VM/desktop platforms.');
  }

  /// Stub stop method.
  Future<void> stop() {
    throw UnsupportedError(
        'MockGatewayWebSocketServer is only supported on VM/desktop platforms.');
  }
}

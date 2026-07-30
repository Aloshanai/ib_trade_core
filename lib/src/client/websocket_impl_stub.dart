import 'dart:async';

abstract class BaseWebSocketConnection {
  Stream<dynamic> get stream;
  void add(String data);
  Future<void> close();
}

Future<BaseWebSocketConnection> connectWebSocket(
  Uri uri, {
  Map<String, String>? headers,
  bool bypassSslVerification = false,
}) {
  throw UnsupportedError('Cannot connect to WebSocket without io or html libraries.');
}

import 'dart:async';
import 'dart:io' as io;
import 'websocket_impl_stub.dart';

class IoWebSocketConnection implements BaseWebSocketConnection {
  final io.WebSocket _socket;

  IoWebSocketConnection(this._socket);

  @override
  Stream<dynamic> get stream => _socket;

  @override
  void add(String data) => _socket.add(data);

  @override
  Future<void> close() => _socket.close();
}

Future<BaseWebSocketConnection> connectWebSocket(
  Uri uri, {
  Map<String, String>? headers,
  bool bypassSslVerification = false,
}) async {
  io.HttpClient? customClient;
  if (bypassSslVerification) {
    customClient = io.HttpClient()
      ..badCertificateCallback =
          (io.X509Certificate cert, String host, int port) => true;
  }

  final socket = await io.WebSocket.connect(
    uri.toString(),
    headers: headers,
    customClient: customClient,
  );
  return IoWebSocketConnection(socket);
}

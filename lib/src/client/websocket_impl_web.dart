import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'websocket_impl_stub.dart';

class WebWebSocketConnection implements BaseWebSocketConnection {
  final html.WebSocket _socket;
  final StreamController<dynamic> _controller = StreamController<dynamic>();

  WebWebSocketConnection(this._socket) {
    _socket.onMessage.listen((event) {
      _controller.add(event.data);
    });
    _socket.onError.listen((event) {
      _controller.addError(event);
    });
    _socket.onClose.listen((event) {
      _controller.close();
    });
  }

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  void add(String data) => _socket.send(data);

  @override
  Future<void> close() async {
    _socket.close();
    await _controller.close();
  }
}

Future<BaseWebSocketConnection> connectWebSocket(
  Uri uri, {
  Map<String, String>? headers,
  bool bypassSslVerification = false,
}) async {
  final socket = html.WebSocket(uri.toString());
  final completer = Completer<BaseWebSocketConnection>();
  
  StreamSubscription? openSubscription;
  StreamSubscription? errorSubscription;

  openSubscription = socket.onOpen.listen((_) {
    openSubscription?.cancel();
    errorSubscription?.cancel();
    completer.complete(WebWebSocketConnection(socket));
  });

  errorSubscription = socket.onError.listen((err) {
    openSubscription?.cancel();
    errorSubscription?.cancel();
    completer.completeError(err);
  });

  return completer.future;
}

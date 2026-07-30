export 'websocket_impl_stub.dart' show BaseWebSocketConnection;
export 'websocket_impl_stub.dart'
    if (dart.library.io) 'websocket_impl_io.dart'
    if (dart.library.html) 'websocket_impl_web.dart';

export 'http_client_creator_stub.dart'
    if (dart.library.io) 'http_client_creator_io.dart'
    if (dart.library.html) 'http_client_creator_web.dart';

import 'package:http/http.dart' as http;

http.Client createPlatformClient({bool bypassSslVerification = false}) {
  throw UnsupportedError('Cannot create HTTP client without io or html libraries.');
}

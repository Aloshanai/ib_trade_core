import 'package:http/http.dart' as http;

http.Client createPlatformClient({bool bypassSslVerification = false}) {
  return http.Client();
}

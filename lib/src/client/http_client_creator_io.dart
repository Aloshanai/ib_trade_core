import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createPlatformClient({bool bypassSslVerification = false}) {
  final ioClient = io.HttpClient();
  if (bypassSslVerification) {
    ioClient.badCertificateCallback =
        (io.X509Certificate cert, String host, int port) => true;
  }
  return IOClient(ioClient);
}

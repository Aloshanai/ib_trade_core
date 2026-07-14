import 'dart:io' as io;
import 'package:http/io_client.dart';

/// A custom HTTP client utilizing [io.HttpClient] to support bypassing
/// self-signed SSL certificate validation.
class HttpClient extends IOClient {
  /// Creates an [HttpClient] that wraps a standard [io.HttpClient].
  ///
  /// Set [bypassSslVerification] to true to ignore SSL certificate errors
  /// (common when connecting to a local IBKR Gateway with self-signed certs).
  HttpClient({bool bypassSslVerification = false})
      : super(
          _createIoClient(bypassSslVerification),
        );

  static io.HttpClient _createIoClient(bool bypassSslVerification) {
    final client = io.HttpClient();
    if (bypassSslVerification) {
      client.badCertificateCallback =
          (io.X509Certificate cert, String host, int port) => true;
    }
    return client;
  }
}

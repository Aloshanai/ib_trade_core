import 'package:http/http.dart' as http;
import 'http_client_creator.dart';

/// A custom HTTP client supporting SSL certificate verification bypass on VM/desktop platforms,
/// and standard browser HTTP requests on web platforms.
class HttpClient extends http.BaseClient {
  final http.Client _delegate;

  /// Creates an [HttpClient].
  ///
  /// Set [bypassSslVerification] to true to ignore SSL certificate errors
  /// (common when connecting to a local IBKR Gateway with self-signed certs).
  /// Note: SSL bypass only applies on VM/desktop platforms. On Web platforms,
  /// this is governed by browser trust policies.
  HttpClient({bool bypassSslVerification = false})
      : _delegate =
            createPlatformClient(bypassSslVerification: bypassSslVerification);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _delegate.send(request);
  }

  @override
  void close() {
    _delegate.close();
    super.close();
  }
}

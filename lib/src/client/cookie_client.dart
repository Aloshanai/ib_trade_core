import 'package:http/http.dart' as http;

/// A stateful HTTP client wrapper that maintains an in-memory cookie jar.
///
/// It intercepts outgoing requests to inject the `Cookie` header with stored cookies
/// and parses incoming `Set-Cookie` headers to keep the jar up to date.
class CookieClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _cookies = {};

  /// Creates a [CookieClient] wrapping the [_inner] HTTP client.
  CookieClient(this._inner);

  /// Returns an unmodifiable map of the currently stored cookies.
  Map<String, String> get cookies => Map.unmodifiable(_cookies);

  /// Clears all cookies from the in-memory jar.
  void clearCookies() {
    _cookies.clear();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_cookies.isNotEmpty) {
      final cookieString = _cookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');

      final existingCookie = request.headers['cookie'];
      if (existingCookie != null && existingCookie.isNotEmpty) {
        request.headers['cookie'] = '$existingCookie; $cookieString';
      } else {
        request.headers['cookie'] = cookieString;
      }
    }

    final response = await _inner.send(request);

    final setCookie = response.headers['set-cookie'];
    if (setCookie != null && setCookie.isNotEmpty) {
      _updateCookies(setCookie);
    }

    return response;
  }

  void _updateCookies(String setCookieHeader) {
    final cookiesList = _splitSetCookieHeader(setCookieHeader);
    for (final cookie in cookiesList) {
      final parts = cookie.split(';')[0].trim();
      final eqIdx = parts.indexOf('=');
      if (eqIdx != -1) {
        final name = parts.substring(0, eqIdx).trim();
        final value = parts.substring(eqIdx + 1).trim();
        if (name.isNotEmpty) {
          _cookies[name] = value;
        }
      }
    }
  }

  List<String> _splitSetCookieHeader(String header) {
    final List<String> cookies = [];
    int start = 0;
    for (int i = 0; i < header.length; i++) {
      if (header[i] == ',') {
        // Look ahead to make sure we don't split on a date comma
        // Date commas are typically inside "Expires=day, dd-mon-yyyy hh:mm:ss GMT"
        bool isDate = false;
        final remaining = header.substring(i + 1).trimLeft();
        final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
        for (final day in days) {
          if (remaining.toLowerCase().startsWith(day)) {
            isDate = true;
            break;
          }
        }
        if (!isDate) {
          cookies.add(header.substring(start, i).trim());
          start = i + 1;
        }
      }
    }
    if (start < header.length) {
      cookies.add(header.substring(start).trim());
    }
    return cookies;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

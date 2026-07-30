import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:test/test.dart';

void main() {
  group('CookieClient', () {
    test('should capture Set-Cookie from response and store it', () async {
      final mockInner = MockClient((request) async {
        return http.Response('{}', 200, headers: {
          'set-cookie': 'JSESSIONID=123456; Path=/; Secure; HttpOnly',
        });
      });

      final cookieClient = CookieClient(mockInner);

      // Before request, jar is empty
      expect(cookieClient.cookies, isEmpty);

      // Trigger request
      final response =
          await cookieClient.get(Uri.parse('https://localhost/api'));
      expect(response.statusCode, 200);

      // Cookie should be captured
      expect(cookieClient.cookies['JSESSIONID'], equals('123456'));
    });

    test('should inject stored cookies into subsequent requests', () async {
      late String? capturedCookieHeader;

      final cookieClientMock = CookieClient(MockClient((request) async {
        if (request.url.path == '/set') {
          return http.Response('{}', 200, headers: {
            'set-cookie': 'session=abc, token=xyz',
          });
        } else {
          capturedCookieHeader = request.headers['cookie'];
          return http.Response('{}', 200);
        }
      }));

      await cookieClientMock.get(Uri.parse('https://localhost/set'));
      expect(cookieClientMock.cookies['session'], equals('abc'));
      expect(cookieClientMock.cookies['token'], equals('xyz'));

      await cookieClientMock.get(Uri.parse('https://localhost/get'));
      expect(capturedCookieHeader, contains('session=abc'));
      expect(capturedCookieHeader, contains('token=xyz'));
    });

    test('should split multiple cookies correctly, ignoring date commas',
        () async {
      final mockInner = MockClient((request) async {
        return http.Response('{}', 200, headers: {
          'set-cookie':
              'REAS=deleted; expires=Thu, 01-Jan-1970 00:00:00 GMT; path=/; domain=localhost, JSESSIONID=abcdef; path=/; HttpOnly',
        });
      });

      final cookieClient = CookieClient(mockInner);
      await cookieClient.get(Uri.parse('https://localhost/api'));

      expect(cookieClient.cookies['REAS'], equals('deleted'));
      expect(cookieClient.cookies['JSESSIONID'], equals('abcdef'));
    });

    test('should handle day name cookie date split correctly for all day abbreviations', () async {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (final day in days) {
        final mockInner = MockClient((request) async {
          return http.Response('{}', 200, headers: {
            'set-cookie':
                'cookie_$day=value; expires=$day, 01-Jan-2030 00:00:00 GMT, session_$day=123',
          });
        });

        final cookieClient = CookieClient(mockInner);
        await cookieClient.get(Uri.parse('https://localhost/api'));

        expect(cookieClient.cookies['cookie_$day'], equals('value'));
        expect(cookieClient.cookies['session_$day'], equals('123'));
      }
    });

    test('clearCookies should remove all stored cookies', () async {
      final mockInner = MockClient((request) async {
        return http.Response('{}', 200, headers: {
          'set-cookie': 'session=123',
        });
      });

      final cookieClient = CookieClient(mockInner);
      await cookieClient.get(Uri.parse('https://localhost/api'));
      expect(cookieClient.cookies, isNotEmpty);

      cookieClient.clearCookies();
      expect(cookieClient.cookies, isEmpty);
    });
  });

  group('HttpClient', () {
    test('can be instantiated', () {
      final client = HttpClient();
      expect(client, isNotNull);
      client.close();
    });

    test('can be instantiated with SSL bypass', () {
      final client = HttpClient(bypassSslVerification: true);
      expect(client, isNotNull);
      client.close();
    });
  });
}

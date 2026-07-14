import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:test/test.dart';

void main() {
  group('IbException', () {
    test('should parse simple string payload', () {
      final exc = IbException.fromJson('Simple error message', 400);
      expect(exc.message, equals('Simple error message'));
      expect(exc.statusCode, equals(400));
      expect(exc.rawResponse, equals('Simple error message'));
      expect(exc.toString(), contains('(Status 400): Simple error message'));
    });

    test('should parse payload with "error" key as string', () {
      final exc = IbException.fromJson({'error': 'Unauthorized access'}, 401);
      expect(exc.message, equals('Unauthorized access'));
      expect(exc.statusCode, equals(401));
      expect(exc.toString(), contains('(Status 401): Unauthorized access'));
    });

    test('should parse payload with nested "error": {"message": "..."} object',
        () {
      final exc = IbException.fromJson({
        'error': {'message': 'Database offline'}
      }, 500);
      expect(exc.message, equals('Database offline'));
      expect(exc.statusCode, equals(500));
    });

    test('should parse payload with "errors" list', () {
      final exc = IbException.fromJson({
        'errors': ['First error', 'Second error']
      });
      expect(exc.message, equals('First error, Second error'));
      expect(exc.statusCode, isNull);
    });

    test('should parse payload with "message" key as string', () {
      final exc = IbException.fromJson({'message': 'Generic failure message'});
      expect(exc.message, equals('Generic failure message'));
    });

    test(
        'should fall back to raw string representation for unknown JSON shapes',
        () {
      final exc = IbException.fromJson({'some_key': 12345});
      expect(exc.message, contains('some_key'));
      expect(exc.message, contains('12345'));
    });

    test('should handle null payload gracefully', () {
      final exc = IbException.fromJson(null, 502);
      expect(exc.message, equals('Unknown error occurred'));
      expect(exc.statusCode, equals(502));
    });
  });

  group('AuthStatus', () {
    test('should parse successful auth status JSON correctly', () {
      final json = {
        'authenticated': true,
        'connected': true,
        'competing': false,
        'username': 'john_doe',
        'fail': ''
      };

      final status = AuthStatus.fromJson(json);
      expect(status.authenticated, isTrue);
      expect(status.connected, isTrue);
      expect(status.competing, isFalse);
      expect(status.username, equals('john_doe'));
      expect(status.failReason, equals(''));
    });

    test('should handle missing and null fields gracefully', () {
      final json = <String, dynamic>{};
      final status = AuthStatus.fromJson(json);

      expect(status.authenticated, isFalse);
      expect(status.connected, isFalse);
      expect(status.competing, isFalse);
      expect(status.username, isNull);
      expect(status.failReason, isNull);
    });

    test('should verify equality and hashcode', () {
      final s1 = AuthStatus(
        authenticated: true,
        connected: true,
        competing: false,
        username: 'user1',
        failReason: 'none',
      );
      final s2 = AuthStatus(
        authenticated: true,
        connected: true,
        competing: false,
        username: 'user1',
        failReason: 'none',
      );
      final s3 = AuthStatus(
        authenticated: false,
        connected: true,
        competing: false,
        username: 'user1',
        failReason: 'none',
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
    });
  });
}

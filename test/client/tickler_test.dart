import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:test/test.dart';

void main() {
  group('SessionTickler', () {
    test('should fire tickle immediately and then periodically', () async {
      int tickleCount = 0;
      late Uri capturedUri;

      final mockClient = MockClient((request) async {
        tickleCount++;
        capturedUri = request.url;
        return http.Response('{"session": true}', 200);
      });

      final tickler = SessionTickler(
        mockClient,
        Uri.parse('https://localhost:5000/v1/api/'),
        interval: const Duration(milliseconds: 50),
      );

      expect(tickler.isActive, isFalse);

      // Start tickler
      tickler.start();
      expect(tickler.isActive, isTrue);

      // Assert it fired immediately
      await Future.delayed(Duration.zero);
      expect(tickleCount, equals(1));
      expect(capturedUri.toString(),
          equals('https://localhost:5000/v1/api/tickle'));

      // Wait for two more intervals
      await Future.delayed(const Duration(milliseconds: 120));
      expect(tickleCount, greaterThanOrEqualTo(3));

      // Stop tickler
      tickler.stop();
      expect(tickler.isActive, isFalse);

      final countBeforeStop = tickleCount;
      // Wait to verify no more requests are sent
      await Future.delayed(const Duration(milliseconds: 100));
      expect(tickleCount, equals(countBeforeStop));
    });

    test('start() should be a no-op if already running', () async {
      int tickleCount = 0;
      final mockClient = MockClient((request) async {
        tickleCount++;
        return http.Response('{}', 200);
      });

      final tickler = SessionTickler(
        mockClient,
        Uri.parse('https://localhost:5000/v1/api/'),
        interval: const Duration(milliseconds: 100),
      );

      tickler.start();
      tickler.start(); // Second start

      await Future.delayed(Duration.zero);
      expect(tickleCount, equals(1));

      tickler.stop();
    });

    test('should handle request exception gracefully without crashing tickler',
        () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          throw Exception('Network failure');
        }
        return http.Response('{}', 200);
      });

      final tickler = SessionTickler(
        mockClient,
        Uri.parse('https://localhost:5000/v1/api/'),
        interval: const Duration(milliseconds: 50),
      );

      // Should not throw or crash on start even if first request fails
      expect(() => tickler.start(), returnsNormally);

      await Future.delayed(Duration.zero);
      expect(requestCount, equals(1));

      // Wait for the next tick to verify it still executes
      await Future.delayed(const Duration(milliseconds: 70));
      expect(requestCount, equals(2));

      tickler.stop();
    });
  });
}

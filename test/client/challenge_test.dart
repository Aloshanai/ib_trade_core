import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:test/test.dart';

class CustomChallengeResolver implements ChallengeResolver {
  final bool canRes;
  final bool responseValue;
  IbChallenge? lastChallenge;

  CustomChallengeResolver({required this.canRes, required this.responseValue});

  @override
  bool canResolve(IbChallenge challenge) {
    lastChallenge = challenge;
    return canRes;
  }

  @override
  Future<bool> resolve(IbChallenge challenge) async {
    return responseValue;
  }
}

void main() {
  group('IbChallenge', () {
    test('should parse from JSON with single message', () {
      final json = {
        'id': 'id123',
        'message': 'This is a warning message',
        'type': 'warning'
      };
      final challenge = IbChallenge.fromJson(json);
      expect(challenge.id, equals('id123'));
      expect(challenge.messages, equals(['This is a warning message']));
      expect(challenge.type, equals('warning'));
    });

    test('should parse from JSON with list of messages', () {
      final json = {
        'id': 'id456',
        'messages': ['Line 1 of details', 'Line 2 of details'],
        'type': 'question'
      };
      final challenge = IbChallenge.fromJson(json);
      expect(challenge.id, equals('id456'));
      expect(challenge.messages,
          equals(['Line 1 of details', 'Line 2 of details']));
      expect(challenge.type, equals('question'));
    });
  });

  group('ChallengeHandler', () {
    test('default registry should contain AutoConfirmChallengeResolver', () {
      final mockClient =
          MockClient((request) async => http.Response('{}', 200));
      final handler =
          ChallengeHandler(mockClient, Uri.parse('https://localhost/api/'));
      expect(handler.resolvers, hasLength(1));
      expect(handler.resolvers.first, isA<AutoConfirmChallengeResolver>());
    });

    test('should invoke custom resolver and submit confirmed status to gateway',
        () async {
      late String? capturedBody;
      late Uri capturedUri;

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedBody = request.body;
        return http.Response('{"status": "ok"}', 200);
      });

      final handler =
          ChallengeHandler(mockClient, Uri.parse('https://localhost/api/'));
      final customResolver =
          CustomChallengeResolver(canRes: true, responseValue: false);
      handler.registerResolver(customResolver);

      final challenge =
          IbChallenge(id: 'c_abc', messages: ['Risk warning'], type: 'warning');
      final result = await handler.handleChallenge(challenge);

      expect(result, isTrue);
      expect(customResolver.lastChallenge, equals(challenge));
      expect(capturedUri.toString(),
          equals('https://localhost/api/iserver/reply/c_abc'));
      expect(capturedBody, equals('{"confirmed": false}'));
    });

    test(
        'should fallback to auto-confirm if custom resolver rejects the challenge',
        () async {
      late String? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = request.body;
        return http.Response('{}', 200);
      });

      final handler =
          ChallengeHandler(mockClient, Uri.parse('https://localhost/api/'));
      final customResolver =
          CustomChallengeResolver(canRes: false, responseValue: false);
      handler.registerResolver(customResolver);

      final challenge =
          IbChallenge(id: 'c_xyz', messages: ['Risk warning'], type: 'warning');
      await handler.handleChallenge(challenge);

      expect(capturedBody, equals('{"confirmed": true}'));
    });

    test(
        'should throw IbException if no resolver is available to handle the challenge',
        () async {
      final mockClient =
          MockClient((request) async => http.Response('{}', 200));
      final handler =
          ChallengeHandler(mockClient, Uri.parse('https://localhost/api/'));

      for (final r in List<ChallengeResolver>.from(handler.resolvers)) {
        handler.unregisterResolver(r);
      }
      expect(handler.resolvers, isEmpty);

      final challenge = IbChallenge(
          id: 'c_no_resolver', messages: ['Warning'], type: 'warning');
      expect(
        () => handler.handleChallenge(challenge),
        throwsA(isA<IbException>().having((e) => e.message, 'message',
            contains('No challenge resolver found'))),
      );
    });

    test('should throw IbException if gateway returns non-200 status code',
        () async {
      final mockClient =
          MockClient((request) async => http.Response('Error reply', 400));
      final handler =
          ChallengeHandler(mockClient, Uri.parse('https://localhost/api/'));

      final challenge =
          IbChallenge(id: 'c_failed', messages: ['Warning'], type: 'warning');
      expect(
        () => handler.handleChallenge(challenge),
        throwsA(isA<IbException>()
            .having((e) => e.statusCode, 'statusCode', equals(400))),
      );
    });
  });
}

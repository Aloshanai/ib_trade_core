import 'dart:async';
import 'dart:convert';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:test/test.dart';

class MockWebSocketConnection implements IbWebSocketConnection {
  final StreamController<dynamic> _messageController =
      StreamController<dynamic>.broadcast();
  final List<String> sentMessages = [];

  void emit(dynamic msg) => _messageController.add(msg);

  @override
  Stream<dynamic> get messages => _messageController.stream;

  @override
  void send(String message) {
    sentMessages.add(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('StreamingService', () {
    late MockWebSocketConnection connection;
    late StreamingService service;

    setUp(() {
      connection = MockWebSocketConnection();
      service = StreamingService(connection);
    });

    tearDown(() async {
      await service.dispose();
    });

    test('subscribeQuotes and unsubscribeQuotes send proper WS commands', () {
      service.subscribeQuotes(265598);
      expect(connection.sentMessages.last, contains('smd+265598+'));

      service.unsubscribeQuotes(265598);
      expect(connection.sentMessages.last, contains('umd+265598+'));
    });

    test('should dispatch QuoteUpdateEvent on smd topic frame', () async {
      final expectation = expectLater(
        service.quoteStream,
        emits(predicate<QuoteUpdateEvent>(
            (e) => e.conid == 265598 && e.lastPrice == 150.25)),
      );

      connection.emit(jsonEncode({
        'topic': 'smd+265598',
        'conid': 265598,
        '31': '150.25',
        '84': '150.20',
        '86': '150.30',
      }));

      await expectation;
    });

    test('should dispatch AccountUpdateEvent on act frame', () async {
      final expectation = expectLater(
        service.accountStream,
        emits(predicate<AccountUpdateEvent>(
            (e) => e.accountId == 'DU123456' && e.key == 'NetLiquidation')),
      );

      connection.emit(jsonEncode({
        'topic': 'act',
        'acctId': 'DU123456',
        'key': 'NetLiquidation',
        'val': 100000.0,
        'currency': 'USD',
      }));

      await expectation;
    });

    test('should dispatch OrderUpdateEvent on or frame', () async {
      final expectation = expectLater(
        service.orderStream,
        emits(predicate<OrderUpdateEvent>(
            (e) => e.orderId == '1001' && e.status == 'Filled')),
      );

      connection.emit(jsonEncode({
        'topic': 'or',
        'orderId': '1001',
        'account': 'DU123456',
        'symbol': 'AAPL',
        'status': 'Filled',
        'filledQuantity': 100.0,
        'remainingQuantity': 0.0,
        'avgPrice': 150.0,
      }));

      await expectation;
    });
  });
}

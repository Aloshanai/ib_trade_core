import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ib_trade_core/src/testing/mock_gateway.dart';
import 'package:test/test.dart';

void main() {
  group('Execution & ExecutionHistory Models', () {
    test('Execution should parse correctly from JSON map', () {
      final json = IbMockPayloads.executionHistory.first;
      final exec = Execution.fromJson(json);

      expect(exec.executionId, 'exec_001');
      expect(exec.orderId, '1001');
      expect(exec.conid, 265598);
      expect(exec.symbol, 'AAPL');
      expect(exec.side, 'BUY');
      expect(exec.price, 150.25);
      expect(exec.quantity, 50.0);
      expect(exec.time, '2026-08-19T10:00:00Z');
      expect(exec.account, 'DU123456');
      expect(exec.commission, 1.0);
      expect(exec.exchange, 'NASDAQ');

      final serialized = exec.toJson();
      expect(serialized['executionId'], 'exec_001');
      expect(serialized['commission'], 1.0);
    });

    test('ExecutionHistory should parse list of executions', () {
      final history =
          ExecutionHistory.fromJson(IbMockPayloads.executionHistory);
      expect(history.executions.length, 1);
      expect(history.executions.first.symbol, 'AAPL');

      final map = history.toJson();
      expect(map['executions'], isA<List>());
    });

    test('ExecutionHistory should parse map wrapping execution list', () {
      final history = ExecutionHistory.fromJson({
        'executions': IbMockPayloads.executionHistory,
      });
      expect(history.executions.length, 1);
    });

    test('ExecutionHistory should handle empty or malformed JSON gracefully',
        () {
      final emptyHistory = ExecutionHistory.fromJson(null);
      expect(emptyHistory.executions, isEmpty);

      final malformed = Execution.fromJson({});
      expect(malformed.executionId, '');
      expect(malformed.conid, 0);
      expect(malformed.price, 0.0);
      expect(malformed.commission, isNull);
    });
  });
}

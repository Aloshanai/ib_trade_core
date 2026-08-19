import 'dart:async';
import 'dart:convert';
import '../client/websocket_connection.dart';
import '../models/market_data.dart';
import '../models/streaming.dart';

/// Service adapting WebSocket real-time data streaming (`smd`, `sbd`, `act`, `or`) for IBKR Client Portal API.
class StreamingService {
  final IbWebSocketConnection connection;

  final StreamController<QuoteUpdateEvent> _quoteController =
      StreamController<QuoteUpdateEvent>.broadcast();
  final StreamController<BookDepthUpdateEvent> _depthController =
      StreamController<BookDepthUpdateEvent>.broadcast();
  final StreamController<AccountUpdateEvent> _accountController =
      StreamController<AccountUpdateEvent>.broadcast();
  final StreamController<OrderUpdateEvent> _orderController =
      StreamController<OrderUpdateEvent>.broadcast();

  StreamSubscription? _messagesSubscription;

  /// Creates a [StreamingService] instance.
  StreamingService(this.connection) {
    _messagesSubscription = connection.messages.listen(_handleRawMessage);
  }

  /// Stream of real-time quote ticker updates (`smd`).
  Stream<QuoteUpdateEvent> get quoteStream => _quoteController.stream;

  /// Stream of market book depth updates (`sbd`).
  Stream<BookDepthUpdateEvent> get depthStream => _depthController.stream;

  /// Stream of real-time account summary & PnL updates (`act`).
  Stream<AccountUpdateEvent> get accountStream => _accountController.stream;

  /// Stream of real-time order status and execution updates (`or`).
  Stream<OrderUpdateEvent> get orderStream => _orderController.stream;

  void _handleRawMessage(dynamic raw) {
    if (raw is! String) return;
    final trimmed = raw.trim();
    if (trimmed == 'hb' || trimmed == 'tic') return; // keep-alive frames

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final topic =
            decoded['topic']?.toString() ?? decoded['type']?.toString() ?? '';
        if (topic.startsWith('smd+') || topic == 'smd') {
          _quoteController.add(QuoteUpdateEvent.fromJson(decoded));
        } else if (topic.startsWith('sbd+') || topic == 'sbd') {
          _depthController.add(BookDepthUpdateEvent.fromJson(decoded));
        } else if (topic == 'act' || topic.startsWith('act+')) {
          _accountController.add(AccountUpdateEvent.fromJson(decoded));
        } else if (topic == 'or' || topic.startsWith('or+')) {
          _orderController.add(OrderUpdateEvent.fromJson(decoded));
        }
      }
    } catch (_) {
      // Ignore non-json frames or invalid payloads
    }
  }

  /// Subscribes to real-time market data quotes for a contract ID (`smd+{conid}+{fields}`).
  void subscribeQuotes(int conid, {List<MarketDataField>? fields}) {
    final fieldStr = fields?.map((f) => f.code).join(',') ??
        '31,84,86,85,88,7295,70,71,7288';
    connection.send('smd+$conid+{"fields":["$fieldStr"]}');
  }

  /// Cancels real-time market data quote subscription (`umd+{conid}+{fields}`).
  void unsubscribeQuotes(int conid) {
    connection.send('umd+$conid+{}');
  }

  /// Subscribes to market book depth stream (`sbd+{conid}`).
  void subscribeBookDepth(int conid) {
    connection.send('sbd+$conid+{}');
  }

  /// Subscribes to real-time account updates (`sub act`).
  void subscribeAccountUpdates() {
    connection.send('sub act');
  }

  /// Subscribes to real-time order execution updates (`sub or`).
  void subscribeOrderUpdates() {
    connection.send('sub or');
  }

  /// Cancels subscriptions and disposes of resources.
  Future<void> dispose() async {
    await _messagesSubscription?.cancel();
    await _quoteController.close();
    await _depthController.close();
    await _accountController.close();
    await _orderController.close();
  }
}

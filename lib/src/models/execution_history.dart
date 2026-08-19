/// Represents an individual trade execution record.
class Execution {
  /// Unique identifier for the execution.
  final String executionId;

  /// Associated order ID.
  final String orderId;

  /// Contract identifier.
  final int conid;

  /// Financial instrument ticker symbol.
  final String symbol;

  /// Order side (e.g. 'BUY', 'SELL').
  final String side;

  /// Execution fill price.
  final double price;

  /// Execution fill quantity or size.
  final double quantity;

  /// Execution timestamp.
  final String time;

  /// Account ID for the trade.
  final String account;

  /// Commission charged for the execution, if available.
  final double? commission;

  /// Exchange where the execution occurred, if available.
  final String? exchange;

  /// Creates an [Execution] instance.
  Execution({
    required this.executionId,
    required this.orderId,
    required this.conid,
    required this.symbol,
    required this.side,
    required this.price,
    required this.quantity,
    required this.time,
    required this.account,
    this.commission,
    this.exchange,
  });

  /// Factory constructor to parse [Execution] from a JSON map.
  factory Execution.fromJson(Map<String, dynamic> json) {
    return Execution(
      executionId: (json['executionId'] ?? json['exec_id'] ?? json['id'] ?? '')
          .toString(),
      orderId: (json['orderId'] ?? json['order_id'] ?? json['acctId'] ?? '')
          .toString(),
      conid: json['conid'] is int
          ? json['conid'] as int
          : int.tryParse(json['conid']?.toString() ?? '0') ?? 0,
      symbol: (json['symbol'] ?? json['ticker'] ?? '').toString(),
      side: (json['side'] ?? json['action'] ?? '').toString(),
      price: (json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0),
      quantity: (json['quantity'] is num
          ? (json['quantity'] as num).toDouble()
          : json['size'] is num
              ? (json['size'] as num).toDouble()
              : double.tryParse(json['quantity']?.toString() ??
                      json['size']?.toString() ??
                      '0.0') ??
                  0.0),
      time: (json['time'] ?? json['executionTime'] ?? '').toString(),
      account:
          (json['account'] ?? json['acctId'] ?? json['accountNumber'] ?? '')
              .toString(),
      commission: json['commission'] != null
          ? (json['commission'] is num
              ? (json['commission'] as num).toDouble()
              : double.tryParse(json['commission'].toString()))
          : null,
      exchange: json['exchange']?.toString(),
    );
  }

  /// Converts [Execution] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'executionId': executionId,
      'orderId': orderId,
      'conid': conid,
      'symbol': symbol,
      'side': side,
      'price': price,
      'quantity': quantity,
      'time': time,
      'account': account,
      if (commission != null) 'commission': commission,
      if (exchange != null) 'exchange': exchange,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Execution &&
          runtimeType == other.runtimeType &&
          executionId == other.executionId &&
          orderId == other.orderId &&
          conid == other.conid &&
          symbol == other.symbol &&
          side == other.side &&
          price == other.price &&
          quantity == other.quantity &&
          time == other.time &&
          account == other.account &&
          commission == other.commission &&
          exchange == other.exchange;

  @override
  int get hashCode =>
      executionId.hashCode ^
      orderId.hashCode ^
      conid.hashCode ^
      symbol.hashCode ^
      side.hashCode ^
      price.hashCode ^
      quantity.hashCode ^
      time.hashCode ^
      account.hashCode ^
      commission.hashCode ^
      exchange.hashCode;

  @override
  String toString() {
    return 'Execution(executionId: $executionId, orderId: $orderId, conid: $conid, symbol: $symbol, side: $side, price: $price, quantity: $quantity, time: $time, account: $account, commission: $commission, exchange: $exchange)';
  }
}

/// Represents a collection / history of trade executions.
class ExecutionHistory {
  /// List of executions.
  final List<Execution> executions;

  /// Creates an [ExecutionHistory] instance.
  ExecutionHistory({required this.executions});

  /// Factory constructor to parse [ExecutionHistory] from JSON input.
  /// Accepts either a JSON List of execution objects or a JSON Map containing 'executions' or 'trades'.
  factory ExecutionHistory.fromJson(dynamic json) {
    if (json is List) {
      final list = json
          .whereType<Map<String, dynamic>>()
          .map((e) => Execution.fromJson(e))
          .toList();
      return ExecutionHistory(executions: list);
    } else if (json is Map<String, dynamic>) {
      final rawList = json['executions'] ?? json['trades'] ?? json['history'];
      if (rawList is List) {
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((e) => Execution.fromJson(e))
            .toList();
        return ExecutionHistory(executions: list);
      }
    }
    return ExecutionHistory(executions: const []);
  }

  /// Converts [ExecutionHistory] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'executions': executions.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionHistory &&
          runtimeType == other.runtimeType &&
          _listEquals(executions, other.executions);

  @override
  int get hashCode =>
      executions.fold(0, (prev, element) => prev ^ element.hashCode);

  @override
  String toString() => 'ExecutionHistory(executions: $executions)';
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

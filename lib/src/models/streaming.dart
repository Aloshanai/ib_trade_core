/// Real-time quote ticker update event (`smd`).
class QuoteUpdateEvent {
  final int conid;
  final double? lastPrice;
  final double? bidPrice;
  final double? askPrice;
  final double? bidSize;
  final double? askSize;
  final double? volume;
  final Map<String, dynamic> updatedFields;
  final Map<String, dynamic> raw;

  QuoteUpdateEvent({
    required this.conid,
    this.lastPrice,
    this.bidPrice,
    this.askPrice,
    this.bidSize,
    this.askSize,
    this.volume,
    required this.updatedFields,
    required this.raw,
  });

  factory QuoteUpdateEvent.fromJson(Map<String, dynamic> json) {
    double? d(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) {
        if (val.startsWith('C') || val.startsWith('H') || val.startsWith('L')) {
          return double.tryParse(val.substring(1));
        }
        return double.tryParse(val);
      }
      return null;
    }

    int c(dynamic val) =>
        val is int ? val : int.tryParse(val?.toString() ?? '0') ?? 0;

    return QuoteUpdateEvent(
      conid: c(json['conid'] ??
          json['conId'] ??
          json['topic']?.toString().replaceFirst('smd+', '')),
      lastPrice: d(json['31'] ?? json['last']),
      bidPrice: d(json['84'] ?? json['bid']),
      askPrice: d(json['86'] ?? json['ask']),
      bidSize: d(json['85'] ?? json['bidSize']),
      askSize: d(json['88'] ?? json['askSize']),
      volume: d(json['7295'] ?? json['volume']),
      updatedFields: json,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Real-time market book depth update event (`sbd`).
class BookDepthUpdateEvent {
  final int conid;
  final List<dynamic> bids;
  final List<dynamic> asks;
  final int time;
  final Map<String, dynamic> raw;

  BookDepthUpdateEvent({
    required this.conid,
    required this.bids,
    required this.asks,
    required this.time,
    required this.raw,
  });

  factory BookDepthUpdateEvent.fromJson(Map<String, dynamic> json) {
    int i(dynamic val) =>
        val is int ? val : int.tryParse(val?.toString() ?? '0') ?? 0;
    return BookDepthUpdateEvent(
      conid: i(json['conid'] ?? json['conId']),
      bids: json['bids'] is List ? json['bids'] as List : const [],
      asks: json['asks'] is List ? json['asks'] as List : const [],
      time: i(json['time'] ?? json['t']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Real-time account update event (`act`).
class AccountUpdateEvent {
  final String accountId;
  final String key;
  final dynamic value;
  final String currency;
  final Map<String, dynamic> raw;

  AccountUpdateEvent({
    required this.accountId,
    required this.key,
    required this.value,
    required this.currency,
    required this.raw,
  });

  factory AccountUpdateEvent.fromJson(Map<String, dynamic> json) {
    return AccountUpdateEvent(
      accountId: (json['acctId'] ?? json['account'] ?? '').toString(),
      key: (json['key'] ?? json['k'] ?? '').toString(),
      value: json['val'] ?? json['value'] ?? json['v'],
      currency: (json['currency'] ?? json['cur'] ?? 'USD').toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Real-time order execution / status update event (`or`).
class OrderUpdateEvent {
  final String orderId;
  final String account;
  final String symbol;
  final String status;
  final double filled;
  final double remaining;
  final double avgPrice;
  final Map<String, dynamic> raw;

  OrderUpdateEvent({
    required this.orderId,
    required this.account,
    required this.symbol,
    required this.status,
    required this.filled,
    required this.remaining,
    required this.avgPrice,
    required this.raw,
  });

  factory OrderUpdateEvent.fromJson(Map<String, dynamic> json) {
    double d(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '0.0') ?? 0.0;
    }

    return OrderUpdateEvent(
      orderId:
          (json['orderId'] ?? json['order_id'] ?? json['id'] ?? '').toString(),
      account: (json['account'] ?? json['acctId'] ?? '').toString(),
      symbol: (json['symbol'] ?? json['ticker'] ?? '').toString(),
      status: (json['orderStatus'] ?? json['status'] ?? '').toString(),
      filled: d(json['filledQuantity'] ?? json['filled']),
      remaining: d(json['remainingQuantity'] ?? json['remaining']),
      avgPrice: d(json['avgPrice'] ?? json['price']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

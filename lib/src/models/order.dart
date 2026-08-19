/// Order types supported by IBKR Client Portal API.
enum OrderType {
  lmt('LMT'),
  mkt('MKT'),
  stp('STP'),
  stpLmt('STP LMT'),
  trail('TRAIL');

  final String code;
  const OrderType(this.code);

  static OrderType fromString(String val) {
    final upper = val.toUpperCase().replaceAll(' ', '_');
    for (final type in OrderType.values) {
      if (type.code == val ||
          type.code == upper ||
          type.name.toUpperCase() == upper) {
        return type;
      }
    }
    return OrderType.lmt;
  }
}

/// Order side (BUY or SELL).
enum OrderSide {
  buy('BUY'),
  sell('SELL');

  final String code;
  const OrderSide(this.code);

  static OrderSide fromString(String val) {
    if (val.toUpperCase() == 'SELL') return OrderSide.sell;
    return OrderSide.buy;
  }
}

/// Time-in-force (TIF) order duration.
enum TimeInForce {
  day('DAY'),
  gtc('GTC'),
  ioc('IOC'),
  opg('OPG');

  final String code;
  const TimeInForce(this.code);

  static TimeInForce fromString(String val) {
    final upper = val.toUpperCase();
    for (final tif in TimeInForce.values) {
      if (tif.code == upper || tif.name.toUpperCase() == upper) return tif;
    }
    return TimeInForce.day;
  }
}

/// Request structure for placing or attaching orders.
class OrderRequest {
  final int conid;
  final String? secType;
  final String? cAccount;
  final OrderType orderType;
  final OrderSide side;
  final double quantity;
  final double? price;
  final double? auxPrice;
  final String? ticker;
  final TimeInForce tif;
  final bool outsideRth;
  final String? listingExchange;
  final String? origCustomerOrderId;
  final List<OrderRequest>? orders;

  OrderRequest({
    required this.conid,
    this.secType,
    this.cAccount,
    required this.orderType,
    required this.side,
    required this.quantity,
    this.price,
    this.auxPrice,
    this.ticker,
    this.tif = TimeInForce.day,
    this.outsideRth = false,
    this.listingExchange,
    this.origCustomerOrderId,
    this.orders,
  });

  Map<String, dynamic> toJson() => {
        'conid': conid,
        if (secType != null) 'secType': secType,
        if (cAccount != null) 'cAccount': cAccount,
        'orderType': orderType.code,
        'side': side.code,
        'quantity': quantity,
        if (price != null) 'price': price,
        if (auxPrice != null) 'auxPrice': auxPrice,
        if (ticker != null) 'ticker': ticker,
        'tif': tif.code,
        'outsideRTH': outsideRth,
        if (listingExchange != null) 'listingExchange': listingExchange,
        if (origCustomerOrderId != null)
          'origCustomerOrderId': origCustomerOrderId,
        if (orders != null && orders!.isNotEmpty)
          'orders': orders!.map((o) => o.toJson()).toList(),
      };
}

/// Response returned when placing, modifying, or replying to orders.
class OrderResponse {
  final String? orderId;
  final String? orderStatus;
  final String? localOrderId;
  final String? encryptMessage;
  final String? warningMessage;
  final String? replyId;
  final List<String> challengeMessages;
  final Map<String, dynamic> raw;

  OrderResponse({
    this.orderId,
    this.orderStatus,
    this.localOrderId,
    this.encryptMessage,
    this.warningMessage,
    this.replyId,
    this.challengeMessages = const [],
    required this.raw,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    List<String> extractMessages(dynamic item) {
      if (item is List) return item.map((e) => e.toString()).toList();
      if (item is String) return [item];
      return const [];
    }

    return OrderResponse(
      orderId: (json['order_id'] ?? json['orderId'] ?? json['id'])?.toString(),
      orderStatus:
          (json['order_status'] ?? json['orderStatus'] ?? json['status'])
              ?.toString(),
      localOrderId:
          (json['local_order_id'] ?? json['localOrderId'])?.toString(),
      encryptMessage: json['encrypt_message']?.toString(),
      warningMessage:
          json['warning_message']?.toString() ?? json['message']?.toString(),
      replyId: (json['id'] ?? json['reply_id'] ?? json['replyId'])?.toString(),
      challengeMessages: extractMessages(
          json['message'] ?? json['text'] ?? json['warning_message']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Preview / What-If order simulation metrics.
class OrderPreview {
  final double initMarginChange;
  final double maintMarginChange;
  final double equityWithLoan;
  final double commission;
  final double minCommission;
  final double maxCommission;
  final Map<String, dynamic> raw;

  OrderPreview({
    required this.initMarginChange,
    required this.maintMarginChange,
    required this.equityWithLoan,
    required this.commission,
    required this.minCommission,
    required this.maxCommission,
    required this.raw,
  });

  factory OrderPreview.fromJson(Map<String, dynamic> json) {
    double d(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is Map && val.containsKey('amount')) return d(val['amount']);
      return double.tryParse(val?.toString() ?? '0.0') ?? 0.0;
    }

    final amountMap = json['amount'] is Map ? json['amount'] as Map : json;
    return OrderPreview(
      initMarginChange:
          d(json['initMarginChange'] ?? amountMap['initMarginChange']),
      maintMarginChange:
          d(json['maintMarginChange'] ?? amountMap['maintMarginChange']),
      equityWithLoan: d(json['equityWithLoan'] ?? amountMap['equityWithLoan']),
      commission: d(json['commission'] ?? amountMap['commission']),
      minCommission: d(json['minCommission'] ?? amountMap['minCommission']),
      maxCommission: d(json['maxCommission'] ?? amountMap['maxCommission']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Status of an active or historical order.
class OrderStatus {
  final String orderId;
  final String status;
  final String account;
  final String symbol;
  final double filledQuantity;
  final double remainingQuantity;
  final double avgPrice;
  final String? whyHeld;
  final Map<String, dynamic> raw;

  OrderStatus({
    required this.orderId,
    required this.status,
    required this.account,
    required this.symbol,
    required this.filledQuantity,
    required this.remainingQuantity,
    required this.avgPrice,
    this.whyHeld,
    required this.raw,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    double d(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '0.0') ?? 0.0;
    }

    return OrderStatus(
      orderId:
          (json['orderId'] ?? json['order_id'] ?? json['id'] ?? '').toString(),
      status: (json['orderStatus'] ?? json['status'] ?? '').toString(),
      account: (json['account'] ?? json['acctId'] ?? '').toString(),
      symbol: (json['symbol'] ?? json['ticker'] ?? '').toString(),
      filledQuantity: d(json['filledQuantity'] ?? json['filled']),
      remainingQuantity: d(json['remainingQuantity'] ?? json['remaining']),
      avgPrice: d(json['avgPrice'] ?? json['price']),
      whyHeld: json['whyHeld']?.toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'status': status,
        'account': account,
        'symbol': symbol,
        'filledQuantity': filledQuantity,
        'remainingQuantity': remainingQuantity,
        'avgPrice': avgPrice,
        if (whyHeld != null) 'whyHeld': whyHeld,
      };
}

/// Parameters for modifying an existing open order.
class OrderModification {
  final double? price;
  final double? quantity;
  final OrderType? orderType;
  final TimeInForce? timeInForce;

  OrderModification({
    this.price,
    this.quantity,
    this.orderType,
    this.timeInForce,
  });

  Map<String, dynamic> toJson() => {
        if (price != null) 'price': price,
        if (quantity != null) 'quantity': quantity,
        if (orderType != null) 'orderType': orderType!.code,
        if (timeInForce != null) 'tif': timeInForce!.code,
      };
}

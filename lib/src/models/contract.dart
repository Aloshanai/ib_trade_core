/// Security types supported by IBKR.
enum SecurityType {
  stk('STK'),
  opt('OPT'),
  fut('FUT'),
  cash('CASH'),
  crypto('CRYPTO'),
  ind('IND');

  final String code;
  const SecurityType(this.code);

  static SecurityType fromString(String val) {
    final upper = val.toUpperCase();
    for (final type in SecurityType.values) {
      if (type.code == upper || type.name.toUpperCase() == upper) return type;
    }
    return SecurityType.stk;
  }
}

/// Search hit item returned from `/iserver/secdef/search`.
class ContractSearchHit {
  final int conid;
  final String symbol;
  final String companyHeader;
  final String companyName;
  final String description;
  final SecurityType secType;
  final String currency;
  final List<dynamic> sections;
  final Map<String, dynamic> raw;

  ContractSearchHit({
    required this.conid,
    required this.symbol,
    required this.companyHeader,
    required this.companyName,
    required this.description,
    required this.secType,
    required this.currency,
    required this.sections,
    required this.raw,
  });

  factory ContractSearchHit.fromJson(Map<String, dynamic> json) {
    return ContractSearchHit(
      conid: json['conid'] is int
          ? json['conid'] as int
          : int.tryParse(json['conid']?.toString() ?? '0') ?? 0,
      symbol: (json['symbol'] ?? json['ticker'] ?? '').toString(),
      companyHeader: (json['companyHeader'] ?? json['header'] ?? '').toString(),
      companyName: (json['companyName'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? json['desc'] ?? '').toString(),
      secType: SecurityType.fromString(json['secType']?.toString() ?? 'STK'),
      currency: (json['currency'] ?? 'USD').toString(),
      sections: json['sections'] is List ? json['sections'] as List : const [],
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Detailed security specifications.
class ContractDetails {
  final int conid;
  final String symbol;
  final String currency;
  final String exchange;
  final String primaryExchange;
  final String category;
  final String industry;
  final double minTick;
  final String tradingHours;
  final String timeZone;
  final Map<String, dynamic> raw;

  ContractDetails({
    required this.conid,
    required this.symbol,
    required this.currency,
    required this.exchange,
    required this.primaryExchange,
    required this.category,
    required this.industry,
    required this.minTick,
    required this.tradingHours,
    required this.timeZone,
    required this.raw,
  });

  factory ContractDetails.fromJson(Map<String, dynamic> json) {
    double d(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '0.0') ?? 0.0;
    }

    return ContractDetails(
      conid: json['conid'] is int
          ? json['conid'] as int
          : int.tryParse(json['conid']?.toString() ?? '0') ?? 0,
      symbol: (json['symbol'] ?? json['ticker'] ?? '').toString(),
      currency: (json['currency'] ?? 'USD').toString(),
      exchange: (json['exchange'] ?? json['listingExchange'] ?? '').toString(),
      primaryExchange:
          (json['primaryExchange'] ?? json['primary_exchange'] ?? '')
              .toString(),
      category: (json['category'] ?? '').toString(),
      industry: (json['industry'] ?? '').toString(),
      minTick: d(json['minTick'] ?? json['min_tick']),
      tradingHours:
          (json['tradingHours'] ?? json['trading_hours'] ?? '').toString(),
      timeZone: (json['timeZone'] ?? json['time_zone'] ?? '').toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Option chain strike grid details.
class OptionChainStrikes {
  final int underlyingConid;
  final List<String> expirationDates;
  final List<double> callStrikes;
  final List<double> putStrikes;
  final String? exchange;
  final Map<String, dynamic> raw;

  OptionChainStrikes({
    required this.underlyingConid,
    required this.expirationDates,
    required this.callStrikes,
    required this.putStrikes,
    this.exchange,
    required this.raw,
  });

  factory OptionChainStrikes.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic listVal) {
      if (listVal is List) return listVal.map((e) => e.toString()).toList();
      return const [];
    }

    List<double> parseDoubleList(dynamic listVal) {
      if (listVal is List) {
        return listVal
            .map((e) =>
                e is num ? e.toDouble() : double.tryParse(e.toString()) ?? 0.0)
            .toList();
      }
      return const [];
    }

    return OptionChainStrikes(
      underlyingConid: json['conid'] is int
          ? json['conid'] as int
          : int.tryParse(json['conid']?.toString() ?? '0') ?? 0,
      expirationDates:
          parseStringList(json['expirations'] ?? json['expirationDates']),
      callStrikes: parseDoubleList(
          json['callStrikes'] ?? json['call_strikes'] ?? json['strikes']),
      putStrikes: parseDoubleList(
          json['putStrikes'] ?? json['put_strikes'] ?? json['strikes']),
      exchange: json['exchange']?.toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Futures contract specification details.
class FuturesContractInfo {
  final int conid;
  final String symbol;
  final String expirationDate;
  final double multiplier;
  final int underlyingConid;
  final Map<String, dynamic> raw;

  FuturesContractInfo({
    required this.conid,
    required this.symbol,
    required this.expirationDate,
    required this.multiplier,
    required this.underlyingConid,
    required this.raw,
  });

  factory FuturesContractInfo.fromJson(Map<String, dynamic> json) {
    double d(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '1.0') ?? 1.0;
    }

    return FuturesContractInfo(
      conid: json['conid'] is int
          ? json['conid'] as int
          : int.tryParse(json['conid']?.toString() ?? '0') ?? 0,
      symbol: (json['symbol'] ?? '').toString(),
      expirationDate: (json['expirationDate'] ??
              json['expiration_date'] ??
              json['maturityDate'] ??
              '')
          .toString(),
      multiplier: d(json['multiplier']),
      underlyingConid: json['underlyingConid'] is int
          ? json['underlyingConid'] as int
          : int.tryParse(json['underlyingConid']?.toString() ?? '0') ?? 0,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

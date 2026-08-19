/// Represents an accessible IBKR trading account.
class AccountInfo {
  final String accountId;
  final String accountVan;
  final String accountTitle;
  final String type;
  final String currency;
  final String clearingStatus;
  final Map<String, dynamic> raw;

  AccountInfo({
    required this.accountId,
    required this.accountVan,
    required this.accountTitle,
    required this.type,
    required this.currency,
    required this.clearingStatus,
    required this.raw,
  });

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      accountId:
          (json['accountId'] ?? json['id'] ?? json['acctId'] ?? '').toString(),
      accountVan: (json['accountVan'] ?? json['van'] ?? '').toString(),
      accountTitle: (json['accountTitle'] ??
              json['title'] ??
              json['desc'] ??
              json['name'] ??
              '')
          .toString(),
      type: (json['type'] ?? json['typeDesc'] ?? '').toString(),
      currency: (json['currency'] ?? 'USD').toString(),
      clearingStatus:
          (json['clearingStatus'] ?? json['status'] ?? '').toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'accountVan': accountVan,
        'accountTitle': accountTitle,
        'type': type,
        'currency': currency,
        'clearingStatus': clearingStatus,
      };
}

/// Represents a sub-account structure.
class SubAccount {
  final String id;
  final String desc;
  final String category;

  SubAccount({
    required this.id,
    required this.desc,
    required this.category,
  });

  factory SubAccount.fromJson(Map<String, dynamic> json) {
    return SubAccount(
      id: (json['id'] ?? json['accountId'] ?? '').toString(),
      desc: (json['desc'] ?? json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'desc': desc,
        'category': category,
      };
}

/// Key metrics summary for an account.
class AccountSummary {
  final double netLiquidation;
  final double totalCashValue;
  final double buyingPower;
  final double grossPositionValue;
  final double initMarginReq;
  final double maintMarginReq;
  final Map<String, dynamic> raw;

  AccountSummary({
    required this.netLiquidation,
    required this.totalCashValue,
    required this.buyingPower,
    required this.grossPositionValue,
    required this.initMarginReq,
    required this.maintMarginReq,
    required this.raw,
  });

  factory AccountSummary.fromJson(Map<String, dynamic> json) {
    double extractDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is Map && val.containsKey('amount')) {
        return extractDouble(val['amount']);
      }
      if (val is Map && val.containsKey('val')) {
        return extractDouble(val['val']);
      }
      return double.tryParse(val?.toString() ?? '0.0') ?? 0.0;
    }

    return AccountSummary(
      netLiquidation: extractDouble(
          json['netLiquidation'] ?? json['netliquidation'] ?? json['nav']),
      totalCashValue: extractDouble(
          json['totalCashValue'] ?? json['totalcashvalue'] ?? json['cash']),
      buyingPower: extractDouble(json['buyingPower'] ?? json['buyingpower']),
      grossPositionValue: extractDouble(
          json['grossPositionValue'] ?? json['grosspositionvalue']),
      initMarginReq:
          extractDouble(json['initMarginReq'] ?? json['initmarginreq']),
      maintMarginReq:
          extractDouble(json['maintMarginReq'] ?? json['maintmarginreq']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => {
        'netLiquidation': netLiquidation,
        'totalCashValue': totalCashValue,
        'buyingPower': buyingPower,
        'grossPositionValue': grossPositionValue,
        'initMarginReq': initMarginReq,
        'maintMarginReq': maintMarginReq,
      };
}

/// Ledger cash breakdown entry per currency.
class LedgerEntry {
  final String currency;
  final double cashBalance;
  final double settledCash;
  final double unsettledCash;
  final double realizedPnl;
  final double unrealizedPnl;

  LedgerEntry({
    required this.currency,
    required this.cashBalance,
    required this.settledCash,
    required this.unsettledCash,
    required this.realizedPnl,
    required this.unrealizedPnl,
  });

  factory LedgerEntry.fromJson(String currency, Map<String, dynamic> json) {
    double d(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '0.0') ?? 0.0;
    }

    return LedgerEntry(
      currency: currency,
      cashBalance: d(json['cashbalance'] ?? json['cashBalance']),
      settledCash: d(json['settledcash'] ?? json['settledCash']),
      unsettledCash: d(json['unsettledcash'] ?? json['unsettledCash']),
      realizedPnl: d(json['realizedpnl'] ?? json['realizedPnl']),
      unrealizedPnl: d(json['unrealizedpnl'] ?? json['unrealizedPnl']),
    );
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'cashBalance': cashBalance,
        'settledCash': settledCash,
        'unsettledCash': unsettledCash,
        'realizedPnl': realizedPnl,
        'unrealizedPnl': unrealizedPnl,
      };
}

/// Open position record in portfolio.
class Position {
  final int conid;
  final String contractDescription;
  final double position;
  final double mktPrice;
  final double mktValue;
  final double avgCost;
  final double unrealizedPnl;
  final double realizedPnl;
  final String account;
  final Map<String, dynamic> raw;

  Position({
    required this.conid,
    required this.contractDescription,
    required this.position,
    required this.mktPrice,
    required this.mktValue,
    required this.avgCost,
    required this.unrealizedPnl,
    required this.realizedPnl,
    required this.account,
    required this.raw,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    double d(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '0.0') ?? 0.0;
    }

    return Position(
      conid: json['conid'] is int
          ? json['conid'] as int
          : int.tryParse(json['conid']?.toString() ?? '0') ?? 0,
      contractDescription:
          (json['contractDesc'] ?? json['ticker'] ?? json['symbol'] ?? '')
              .toString(),
      position: d(json['position'] ?? json['pos']),
      mktPrice: d(json['mktPrice'] ?? json['mktprice']),
      mktValue: d(json['mktVal'] ?? json['mktvalue'] ?? json['marketValue']),
      avgCost: d(json['avgCost'] ?? json['avgcost']),
      unrealizedPnl: d(json['unrealizedPnl'] ?? json['unrealizedpnl']),
      realizedPnl: d(json['realizedPnl'] ?? json['realizedpnl']),
      account:
          (json['acctId'] ?? json['account'] ?? json['accountNumber'] ?? '')
              .toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => {
        'conid': conid,
        'contractDescription': contractDescription,
        'position': position,
        'mktPrice': mktPrice,
        'mktValue': mktValue,
        'avgCost': avgCost,
        'unrealizedPnl': unrealizedPnl,
        'realizedPnl': realizedPnl,
        'account': account,
      };
}

/// Extended details for a specific position.
class PositionDetail {
  final Position position;
  final String? sector;
  final String? industry;
  final Map<String, dynamic> raw;

  PositionDetail({
    required this.position,
    this.sector,
    this.industry,
    required this.raw,
  });

  factory PositionDetail.fromJson(Map<String, dynamic> json) {
    return PositionDetail(
      position: Position.fromJson(json),
      sector: json['sector']?.toString(),
      industry: json['industry']?.toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => {
        ...position.toJson(),
        if (sector != null) 'sector': sector,
        if (industry != null) 'industry': industry,
      };
}

/// Asset allocation breakdown.
class PortfolioAllocation {
  final Map<String, double> assetClass;
  final Map<String, double> sector;
  final Map<String, double> group;

  PortfolioAllocation({
    required this.assetClass,
    required this.sector,
    required this.group,
  });

  factory PortfolioAllocation.fromJson(Map<String, dynamic> json) {
    Map<String, double> parseMap(dynamic mapVal) {
      if (mapVal is! Map) return {};
      final res = <String, double>{};
      mapVal.forEach((key, value) {
        if (value is num) {
          res[key.toString()] = value.toDouble();
        } else if (value is Map && value.containsKey('val')) {
          res[key.toString()] = double.tryParse(value['val'].toString()) ?? 0.0;
        } else {
          res[key.toString()] =
              double.tryParse(value?.toString() ?? '0.0') ?? 0.0;
        }
      });
      return res;
    }

    return PortfolioAllocation(
      assetClass: parseMap(json['assetClass'] ?? json['assetClassAllocation']),
      sector: parseMap(json['sector'] ?? json['sectorAllocation']),
      group: parseMap(json['group'] ?? json['groupAllocation']),
    );
  }

  Map<String, dynamic> toJson() => {
        'assetClass': assetClass,
        'sector': sector,
        'group': group,
      };
}

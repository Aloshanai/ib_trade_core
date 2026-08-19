/// Scanner parameters metadata returned by `/hmds/scanner/params`.
class ScannerParams {
  final List<dynamic> instrumentList;
  final List<dynamic> locationTree;
  final List<dynamic> scannerTypeList;
  final List<dynamic> filterList;
  final Map<String, dynamic> raw;

  ScannerParams({
    required this.instrumentList,
    required this.locationTree,
    required this.scannerTypeList,
    required this.filterList,
    required this.raw,
  });

  factory ScannerParams.fromJson(Map<String, dynamic> json) {
    List<dynamic> l(dynamic val) => val is List ? val : const [];
    return ScannerParams(
      instrumentList: l(json['instrument_list'] ?? json['instrumentList']),
      locationTree: l(json['location_tree'] ?? json['locationTree']),
      scannerTypeList: l(json['scanner_type_list'] ?? json['scannerTypeList']),
      filterList: l(json['filter_list'] ?? json['filterList']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Filter condition element for market scanner request.
class ScannerFilter {
  final String code;
  final dynamic value;

  ScannerFilter({required this.code, required this.value});

  Map<String, dynamic> toJson() => {'code': code, 'value': value};
}

/// Request query payload for running a market scan (`POST /hmds/scanner/run`).
class ScannerRequest {
  final String instrument;
  final String type;
  final String location;
  final List<ScannerFilter> filter;

  ScannerRequest({
    required this.instrument,
    required this.type,
    required this.location,
    this.filter = const [],
  });

  Map<String, dynamic> toJson() => {
        'instrument': instrument,
        'type': type,
        'location': location,
        'filter': filter.map((f) => f.toJson()).toList(),
      };
}

/// Individual item returned in scanner scan results.
class ScannerItem {
  final int rank;
  final int conid;
  final String symbol;
  final String companyName;
  final String distance;
  final String benchmark;
  final String projection;
  final Map<String, dynamic> raw;

  ScannerItem({
    required this.rank,
    required this.conid,
    required this.symbol,
    required this.companyName,
    required this.distance,
    required this.benchmark,
    required this.projection,
    required this.raw,
  });

  factory ScannerItem.fromJson(Map<String, dynamic> json) {
    int i(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '0') ?? 0;
    }

    return ScannerItem(
      rank: i(json['rank'] ?? json['row']),
      conid: i(json['conid'] ?? json['contractId']),
      symbol: (json['symbol'] ?? json['ticker'] ?? '').toString(),
      companyName:
          (json['companyName'] ?? json['company_name'] ?? json['name'] ?? '')
              .toString(),
      distance: (json['distance'] ?? '').toString(),
      benchmark: (json['benchmark'] ?? '').toString(),
      projection: (json['projection'] ?? '').toString(),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

/// Result envelope for market scan execution.
class ScannerResult {
  final int total;
  final String scanTime;
  final List<ScannerItem> items;

  ScannerResult({
    required this.total,
    required this.scanTime,
    required this.items,
  });

  factory ScannerResult.fromJson(dynamic json) {
    if (json is List) {
      final items = json
          .whereType<Map<String, dynamic>>()
          .map((e) => ScannerItem.fromJson(e))
          .toList();
      return ScannerResult(total: items.length, scanTime: '', items: items);
    } else if (json is Map<String, dynamic>) {
      final rawItems = json['items'] ?? json['contracts'] ?? json['ScanData'];
      final parsedItems = <ScannerItem>[];
      if (rawItems is List) {
        for (final item in rawItems) {
          if (item is Map<String, dynamic>) {
            parsedItems.add(ScannerItem.fromJson(item));
          }
        }
      }
      return ScannerResult(
        total: json['total'] is int ? json['total'] as int : parsedItems.length,
        scanTime: (json['scanTime'] ?? json['scan_time'] ?? '').toString(),
        items: parsedItems,
      );
    }
    return ScannerResult(total: 0, scanTime: '', items: const []);
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'scanTime': scanTime,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

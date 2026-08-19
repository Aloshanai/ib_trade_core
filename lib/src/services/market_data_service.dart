import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_data.dart';

/// Service adapting real-time snapshots and historical market data endpoints for IBKR Client Portal API.
class MarketDataService {
  final http.Client client;
  final String baseUrl;

  /// Creates a [MarketDataService] instance.
  MarketDataService({
    required this.client,
    required this.baseUrl,
  });

  String _cleanUrl(String endpoint) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$base$path';
  }

  /// Requests real-time market data snapshot (`GET /iserver/marketdata/snapshot`).
  Future<List<MarketSnapshot>> getMarketDataSnapshot(
    List<int> conids, {
    List<MarketDataField>? fields,
  }) async {
    final fieldCodes = fields?.map((f) => f.code).join(',') ??
        '31,84,86,85,88,7295,70,71,7288';
    final uri = Uri.parse(_cleanUrl('/iserver/marketdata/snapshot')).replace(
      queryParameters: {
        'conids': conids.join(','),
        'fields': fieldCodes,
      },
    );

    final response = await client.get(uri);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((json) => MarketSnapshot.fromJson(json))
            .toList();
      }
    }
    return const [];
  }

  /// Fetches historical OHLCV bar series (`GET /iserver/marketdata/history`).
  Future<HistoricalDataSeries> getHistoricalBars(
    int conid, {
    required BarPeriod period,
    required BarSize barSize,
    bool outsideRth = false,
    String priceType = 'TRADES',
  }) async {
    final uri = Uri.parse(_cleanUrl('/iserver/marketdata/history')).replace(
      queryParameters: {
        'conid': conid.toString(),
        'period': period.code,
        'bar': barSize.code,
        'outsideRth': outsideRth.toString(),
        'priceType': priceType,
      },
    );

    final response = await client.get(uri);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return HistoricalDataSeries.fromJson({
        'conid': conid,
        'period': period.code,
        'barSize': barSize.code,
        ...json,
      });
    }
    return HistoricalDataSeries.fromJson(
        {'conid': conid, 'period': period.code, 'barSize': barSize.code});
  }

  /// Cancels all market data snapshot subscriptions (`POST /iserver/marketdata/unsubscribeall`).
  Future<bool> unsubscribeAll() async {
    final response = await client
        .post(Uri.parse(_cleanUrl('/iserver/marketdata/unsubscribeall')));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['confirmed'] == true ||
          json['status'] == 'ok' ||
          json['status'] == true;
    }
    return false;
  }
}

import 'dart:convert';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ib_trade_core/src/testing/mock_gateway.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('MarketDataService', () {
    late MockGatewayHttp mockGateway;
    late http.Client client;
    late MarketDataService service;

    setUp(() {
      mockGateway = MockGatewayHttp();

      mockGateway.registerRoute(
          '/iserver/marketdata/snapshot',
          (req) => http.Response(
              jsonEncode([
                {
                  'conid': 265598,
                  '55': 'AAPL',
                  '31': '150.25',
                  '84': '150.20',
                  '86': '150.30',
                  '85': '10',
                  '88': '15',
                  '7295': '5000000',
                  '70': '152.00',
                  '71': '149.50',
                  '7288': '149.75',
                  '7282': '0.50',
                  '7283': '0.33',
                }
              ]),
              200));

      mockGateway.registerRoute(
          '/iserver/marketdata/history',
          (req) => http.Response(
              jsonEncode({
                'symbol': 'AAPL',
                'data': [
                  {
                    't': 1700000000,
                    'o': 150.0,
                    'h': 152.0,
                    'l': 149.5,
                    'c': 151.5,
                    'v': 10000.0
                  },
                  {
                    't': 1700086400,
                    'o': 151.5,
                    'h': 153.0,
                    'l': 151.0,
                    'c': 152.5,
                    'v': 12000.0
                  },
                ]
              }),
              200));

      mockGateway.registerRoute('/iserver/marketdata/unsubscribeall',
          (req) => http.Response(jsonEncode({'confirmed': true}), 200));

      client = mockGateway.buildClient();
      service = MarketDataService(
          client: client, baseUrl: 'https://localhost:5000/v1/api');
    });

    test('getMarketDataSnapshot should parse snapshot fields', () async {
      final snapshots = await service.getMarketDataSnapshot([265598]);
      expect(snapshots, hasLength(1));
      expect(snapshots.first.conid, 265598);
      expect(snapshots.first.symbol, 'AAPL');
      expect(snapshots.first.lastPrice, 150.25);
      expect(snapshots.first.bidPrice, 150.20);
      expect(snapshots.first.askPrice, 150.30);
    });

    test('getHistoricalBars should return OHLCV bar series', () async {
      final series = await service.getHistoricalBars(
        265598,
        period: BarPeriod.oneDay,
        barSize: BarSize.oneMin,
      );
      expect(series.conid, 265598);
      expect(series.bars, hasLength(2));
      expect(series.bars.first.open, 150.0);
      expect(series.bars.first.close, 151.5);
    });

    test('unsubscribeAll should return true when confirmed', () async {
      final result = await service.unsubscribeAll();
      expect(result, isTrue);
    });
  });
}

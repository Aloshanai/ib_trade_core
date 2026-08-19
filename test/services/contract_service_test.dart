import 'dart:convert';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ib_trade_core/src/testing/mock_gateway.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ContractService', () {
    late MockGatewayHttp mockGateway;
    late http.Client client;
    late ContractService service;

    setUp(() {
      mockGateway = MockGatewayHttp();

      mockGateway.registerRoute(
          '/iserver/secdef/search',
          (req) => http.Response(
              jsonEncode([
                {
                  'conid': 265598,
                  'symbol': 'AAPL',
                  'companyHeader': 'Apple Inc',
                  'companyName': 'Apple Inc',
                  'description': 'NASDAQ',
                  'secType': 'STK',
                  'currency': 'USD',
                  'sections': [],
                }
              ]),
              200));

      mockGateway.registerRoute(
          '/iserver/contract/265598/info',
          (req) => http.Response(
              jsonEncode({
                'conid': 265598,
                'symbol': 'AAPL',
                'currency': 'USD',
                'exchange': 'NASDAQ',
                'primaryExchange': 'NASDAQ',
                'category': 'Technology',
                'industry': 'Consumer Electronics',
                'minTick': 0.01,
                'tradingHours': '0930-1600',
                'timeZone': 'EST',
              }),
              200));

      mockGateway.registerRoute(
          '/iserver/secdef/strikes',
          (req) => http.Response(
              jsonEncode({
                'expirations': ['2026-09-18', '2026-10-16'],
                'callStrikes': [140.0, 150.0, 160.0],
                'putStrikes': [140.0, 150.0, 160.0],
              }),
              200));

      mockGateway.registerRoute(
          '/iserver/secdef/info',
          (req) => http.Response(
              jsonEncode([
                {
                  'conid': 495512572,
                  'symbol': 'ES',
                  'expirationDate': '2026-09-18',
                  'multiplier': 50.0,
                  'underlyingConid': 11004968,
                }
              ]),
              200));

      client = mockGateway.buildClient();
      service = ContractService(
          client: client, baseUrl: 'https://localhost:5000/v1/api');
    });

    test('searchContracts should return matching hits', () async {
      final hits = await service.searchContracts('AAPL');
      expect(hits, hasLength(1));
      expect(hits.first.conid, 265598);
      expect(hits.first.symbol, 'AAPL');
      expect(hits.first.secType, SecurityType.stk);
    });

    test('getContractInfo should return contract specifications', () async {
      final info = await service.getContractInfo(265598);
      expect(info.conid, 265598);
      expect(info.exchange, 'NASDAQ');
      expect(info.minTick, 0.01);
    });

    test('getOptionStrikes should return option chain strikes and expirations',
        () async {
      final strikes =
          await service.getOptionStrikes(265598, SecurityType.opt, 'SEP26');
      expect(strikes.underlyingConid, 265598);
      expect(strikes.expirationDates, contains('2026-09-18'));
      expect(strikes.callStrikes, contains(150.0));
    });

    test('getFuturesInfo should return futures specifications', () async {
      final fut = await service.getFuturesInfo(495512572);
      expect(fut.conid, 495512572);
      expect(fut.symbol, 'ES');
      expect(fut.multiplier, 50.0);
    });
  });
}

import 'dart:convert';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ib_trade_core/src/testing/mock_gateway.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ScannerService', () {
    late MockGatewayHttp mockGateway;
    late http.Client client;
    late ScannerService service;

    setUp(() {
      mockGateway = MockGatewayHttp();

      mockGateway.registerRoute(
          '/hmds/scanner/params',
          (req) => http.Response(
              jsonEncode({
                'instrument_list': [
                  {'name': 'Stock', 'type': 'STK'}
                ],
                'location_tree': [
                  {'name': 'US', 'type': 'STK.US'}
                ],
                'scanner_type_list': [
                  {'name': 'Top Gainers', 'type': 'TOP_PERC_GAIN'}
                ],
                'filter_list': [
                  {'name': 'Price Above', 'code': 'priceAbove'}
                ],
              }),
              200));

      mockGateway.registerRoute(
          '/hmds/scanner/run',
          (req) => http.Response(
              jsonEncode({
                'total': 1,
                'scanTime': '2026-08-19 10:00:00',
                'items': [
                  {
                    'rank': 1,
                    'conid': 265598,
                    'symbol': 'AAPL',
                    'companyName': 'Apple Inc',
                    'distance': '0.5%',
                    'benchmark': 'SPY',
                    'projection': 'Up',
                  }
                ]
              }),
              200));

      client = mockGateway.buildClient();
      service = ScannerService(
          client: client, baseUrl: 'https://localhost:5000/v1/api');
    });

    test('getScannerParams should return scanner metadata', () async {
      final params = await service.getScannerParams();
      expect(params.instrumentList, hasLength(1));
      expect(params.scannerTypeList, hasLength(1));
    });

    test('runScanner should execute market scan query', () async {
      final req = ScannerRequest(
        instrument: 'STK',
        type: 'TOP_PERC_GAIN',
        location: 'STK.US',
        filter: [ScannerFilter(code: 'priceAbove', value: 100.0)],
      );

      final result = await service.runScanner(req);
      expect(result.total, 1);
      expect(result.items, hasLength(1));
      expect(result.items.first.symbol, 'AAPL');
      expect(result.items.first.rank, 1);
    });
  });
}

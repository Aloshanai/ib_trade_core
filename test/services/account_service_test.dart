import 'dart:convert';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ib_trade_core/src/testing/mock_gateway.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('AccountService', () {
    late MockGatewayHttp mockGateway;
    late http.Client client;
    late AccountService service;

    setUp(() {
      mockGateway = MockGatewayHttp();
      mockGateway.registerRoute(
          '/portfolio/accounts',
          (req) => http.Response(
              jsonEncode([
                {
                  'accountId': 'DU123456',
                  'accountTitle': 'Paper Account',
                  'type': 'INDIVIDUAL',
                  'currency': 'USD',
                  'clearingStatus': 'O'
                }
              ]),
              200));
      mockGateway.registerRoute(
          '/portfolio/subaccounts',
          (req) => http.Response(
              jsonEncode([
                {
                  'id': 'DU123456',
                  'desc': 'Sub account 1',
                  'category': 'Trading'
                }
              ]),
              200));
      mockGateway.registerRoute(
          '/portfolio/DU123456/summary',
          (req) => http.Response(
              jsonEncode({
                'netLiquidation': {'amount': 100000.0},
                'totalCashValue': {'amount': 50000.0},
                'buyingPower': {'amount': 200000.0},
                'grossPositionValue': {'amount': 50000.0},
                'initMarginReq': {'amount': 10000.0},
                'maintMarginReq': {'amount': 8000.0},
              }),
              200));
      mockGateway.registerRoute(
          '/portfolio/DU123456/ledger',
          (req) => http.Response(
              jsonEncode({
                'USD': {
                  'cashbalance': 50000.0,
                  'settledcash': 50000.0,
                  'realizedpnl': 500.0,
                  'unrealizedpnl': 1200.0
                }
              }),
              200));
      mockGateway.registerRoute('/portfolio/DU123456/positions/0',
          (req) => http.Response(jsonEncode(IbMockPayloads.positions), 200));
      mockGateway.registerRoute(
          '/portfolio/DU123456/position/265598',
          (req) => http.Response(
              jsonEncode([
                {
                  ...IbMockPayloads.positions.first,
                  'sector': 'Technology',
                  'industry': 'Consumer Electronics'
                }
              ]),
              200));
      mockGateway.registerRoute(
          '/portfolio/DU123456/allocation',
          (req) => http.Response(
              jsonEncode({
                'assetClass': {'STK': 0.8, 'CASH': 0.2},
                'sector': {'Technology': 0.8},
                'group': {'US': 1.0}
              }),
              200));
      mockGateway.registerRoute(
          '/portfolio/allocation',
          (req) => http.Response(
              jsonEncode({
                'assetClass': {'STK': 0.8, 'CASH': 0.2},
                'sector': {'Technology': 0.8},
                'group': {'US': 1.0}
              }),
              200));

      client = mockGateway.buildClient();
      service = AccountService(
          client: client, baseUrl: 'https://localhost:5000/v1/api');
    });

    test('getAccounts should return list of accounts', () async {
      final accounts = await service.getAccounts();
      expect(accounts, hasLength(1));
      expect(accounts.first.accountId, 'DU123456');
    });

    test('getSubAccounts should return list of subaccounts', () async {
      final subAccounts = await service.getSubAccounts();
      expect(subAccounts, hasLength(1));
      expect(subAccounts.first.id, 'DU123456');
    });

    test('getAccountSummary should return parsed summary metrics', () async {
      final summary = await service.getAccountSummary('DU123456');
      expect(summary.netLiquidation, 100000.0);
      expect(summary.buyingPower, 200000.0);
    });

    test('getLedger should return currency ledger entries', () async {
      final ledger = await service.getLedger('DU123456');
      expect(ledger, hasLength(1));
      expect(ledger.first.currency, 'USD');
      expect(ledger.first.cashBalance, 50000.0);
    });

    test('getPositions should return open positions', () async {
      final positions = await service.getPositions('DU123456');
      expect(positions, hasLength(1));
      expect(positions.first.conid, 265598);
    });

    test('getPositionDetail should return extended position detail', () async {
      final detail = await service.getPositionDetail('DU123456', 265598);
      expect(detail.sector, 'Technology');
      expect(detail.position.conid, 265598);
    });

    test(
        'getAccountAllocation and getPortfolioAllocation should parse asset allocations',
        () async {
      final alloc = await service.getAccountAllocation('DU123456');
      expect(alloc.assetClass['STK'], 0.8);

      final multiAlloc = await service.getPortfolioAllocation(['DU123456']);
      expect(multiAlloc.assetClass['STK'], 0.8);
    });
  });
}

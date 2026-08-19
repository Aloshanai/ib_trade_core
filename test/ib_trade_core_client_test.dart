import 'dart:convert';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ib_trade_core/src/testing/mock_gateway.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('IbTradeCoreClient Facade & McpToolRegistryAdapter', () {
    late MockGatewayHttp mockGateway;
    late http.Client httpClient;
    late IbTradeCoreClient client;

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
          '/portfolio/DU123456/summary',
          (req) => http.Response(
              jsonEncode({
                'netLiquidation': {'amount': 100000.0},
                'buyingPower': {'amount': 200000.0},
              }),
              200));

      mockGateway.registerRoute(
          '/iserver/secdef/search',
          (req) => http.Response(
              jsonEncode([
                {
                  'conid': 265598,
                  'symbol': 'AAPL',
                  'companyHeader': 'Apple Inc',
                  'companyName': 'Apple Inc',
                  'secType': 'STK',
                  'currency': 'USD',
                  'sections': []
                }
              ]),
              200));

      mockGateway.registerRoute(
          '/iserver/marketdata/snapshot',
          (req) => http.Response(
              jsonEncode([
                {
                  'conid': 265598,
                  '55': 'AAPL',
                  '31': '150.25',
                  '84': '150.20',
                  '86': '150.30'
                }
              ]),
              200));

      mockGateway.registerRoute(
          '/iserver/account/orders',
          (req) => http.Response(
              jsonEncode({
                'orders': [
                  {
                    'orderId': '1001',
                    'orderStatus': 'Submitted',
                    'account': 'DU123456',
                    'symbol': 'AAPL',
                    'filledQuantity': 0.0,
                    'remainingQuantity': 100.0,
                    'avgPrice': 150.0
                  }
                ]
              }),
              200));

      httpClient = mockGateway.buildClient();
      const config = GatewayConfig(host: 'localhost', port: 5000, useSsl: true);
      client = IbTradeCoreClient(config: config, httpClient: httpClient);
    });

    tearDown(() async {
      await client.dispose();
    });

    test('Facade should unify all domain services', () async {
      final auth = await client.session.getAuthStatus();
      expect(auth.authenticated, isTrue);

      final accounts = await client.account.getAccounts();
      expect(accounts, hasLength(1));
      expect(accounts.first.accountId, 'DU123456');

      final search = await client.contracts.searchContracts('AAPL');
      expect(search.first.symbol, 'AAPL');

      final snapshot = await client.marketData.getMarketDataSnapshot([265598]);
      expect(snapshot.first.lastPrice, 150.25);

      final liveOrders = await client.orders.getLiveOrders();
      expect(liveOrders.first.orderId, '1001');
    });

    test('IbResult wrapper success and failure constructors', () {
      final successResult = IbResult<String>.success('Hello World');
      expect(successResult.isSuccess, isTrue);
      expect(successResult.data, 'Hello World');
      expect(successResult.statusCode, 200);

      final failResult =
          IbResult<String>.failure('Bad Request', statusCode: 400);
      expect(failResult.isSuccess, isFalse);
      expect(failResult.error, 'Bad Request');
      expect(failResult.statusCode, 400);
    });

    test(
        'McpToolRegistryAdapter should map and execute registered tool contracts',
        () async {
      final adapter = McpToolRegistryAdapter();
      expect(adapter.tools, isNotEmpty);

      final authTool = adapter.getTool('get_auth_status');
      expect(authTool, isNotNull);
      final authRes = await authTool!.handler(client, {});
      expect(authRes['authenticated'], isTrue);

      final accountsTool = adapter.getTool('get_accounts');
      expect(accountsTool, isNotNull);
      final accRes = await accountsTool!.handler(client, {}) as List;
      expect(accRes, hasLength(1));
      expect(accRes.first['accountId'], 'DU123456');

      final summaryTool = adapter.getTool('get_portfolio_summary');
      expect(summaryTool, isNotNull);
      final summaryRes =
          await summaryTool!.handler(client, {'accountId': 'DU123456'});
      expect(summaryRes['netLiquidation'], 100000.0);

      final searchTool = adapter.getTool('search_contracts');
      expect(searchTool, isNotNull);
      final searchRes =
          await searchTool!.handler(client, {'symbol': 'AAPL'}) as List;
      expect(searchRes.first['symbol'], 'AAPL');
    });
  });
}

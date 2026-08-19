import 'dart:convert';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ib_trade_core/src/testing/mock_gateway.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('OrderService', () {
    late MockGatewayHttp mockGateway;
    late http.Client client;
    late OrderService service;
    late bool challengeHandled;

    setUp(() {
      challengeHandled = false;
      mockGateway = MockGatewayHttp();

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

      mockGateway.registerRoute(
          '/iserver/account/DU123456/orders',
          (req) => http.Response(
              jsonEncode([
                {
                  'order_id': '1002',
                  'order_status': 'PreSubmitted',
                  'local_order_id': 'loc_1002'
                }
              ]),
              200));

      mockGateway.registerRoute(
          '/iserver/account/DU123456/orders/whatif',
          (req) => http.Response(
              jsonEncode({
                'initMarginChange': 1500.0,
                'maintMarginChange': 1000.0,
                'equityWithLoan': 98500.0,
                'commission': 1.0,
                'minCommission': 1.0,
                'maxCommission': 2.0,
              }),
              200));

      mockGateway.registerRoute('/iserver/account/DU123456/order/1001', (req) {
        if (req.method == 'POST') {
          return http.Response(
              jsonEncode({'order_id': '1001', 'order_status': 'Submitted'}),
              200);
        } else if (req.method == 'DELETE') {
          return http.Response(
              jsonEncode({'order_id': '1001', 'order_status': 'Cancelled'}),
              200);
        }
        return http.Response('Not found', 404);
      });

      mockGateway.registerRoute(
          '/iserver/account/order/status/1001',
          (req) => http.Response(
              jsonEncode({
                'orderId': '1001',
                'status': 'Filled',
                'account': 'DU123456',
                'symbol': 'AAPL',
                'filledQuantity': 100.0,
                'remainingQuantity': 0.0,
                'avgPrice': 150.0
              }),
              200));

      client = mockGateway.buildClient();
      final handler =
          ChallengeHandler(client, Uri.parse('https://localhost:5000/v1/api/'));
      service = OrderService(
        client: client,
        baseUrl: 'https://localhost:5000/v1/api',
        challengeHandler: handler,
      );
    });

    test('getLiveOrders should return active open orders', () async {
      final orders = await service.getLiveOrders();
      expect(orders, hasLength(1));
      expect(orders.first.orderId, '1001');
      expect(orders.first.symbol, 'AAPL');
    });

    test('placeOrders should submit single order', () async {
      final req = OrderRequest(
        conid: 265598,
        orderType: OrderType.LMT,
        side: OrderSide.BUY,
        quantity: 100.0,
        price: 150.0,
      );
      final responses = await service.placeOrders('DU123456', [req]);
      expect(responses, hasLength(1));
      expect(responses.first.orderId, '1002');
    });

    test('previewOrder should return margin impact', () async {
      final req = OrderRequest(
        conid: 265598,
        orderType: OrderType.LMT,
        side: OrderSide.BUY,
        quantity: 100.0,
        price: 150.0,
      );
      final preview = await service.previewOrder('DU123456', req);
      expect(preview.initMarginChange, 1500.0);
      expect(preview.commission, 1.0);
    });

    test('modifyOrder and cancelOrder should modify and cancel orders',
        () async {
      final modRes = await service.modifyOrder(
          'DU123456', '1001', OrderModification(price: 151.0));
      expect(modRes.orderId, '1001');

      final cancelRes = await service.cancelOrder('DU123456', '1001');
      expect(cancelRes.orderId, '1001');
      expect(cancelRes.orderStatus, 'Cancelled');
    });

    test('getOrderStatus should fetch status by orderId', () async {
      final status = await service.getOrderStatus('1001');
      expect(status.orderId, '1001');
      expect(status.status, 'Filled');
    });

    test(
        'placeOrders with challenge warning should trigger ChallengeHandler auto-reply',
        () async {
      mockGateway.registerRoute(
          '/iserver/account/DU123456/orders',
          (req) => http.Response(
              jsonEncode([
                {
                  'id': 'warn_123',
                  'message': ['Price exceeds 5% limit']
                }
              ]),
              200));

      final req = OrderRequest(
        conid: 265598,
        orderType: OrderType.LMT,
        side: OrderSide.BUY,
        quantity: 100.0,
        price: 200.0,
      );

      final res = await service.placeOrders('DU123456', [req]);
      expect(res.first.replyId, 'warn_123');
    });
  });
}

import 'dart:convert';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ib_trade_core/src/testing/mock_gateway.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('AlertService', () {
    late MockGatewayHttp mockGateway;
    late http.Client client;
    late AlertService service;

    setUp(() {
      mockGateway = MockGatewayHttp();

      mockGateway.registerRoute(
          '/iserver/account/alerts',
          (req) => http.Response(
              jsonEncode([
                {
                  'alertId': 501,
                  'alertName': 'AAPL High Price Alert',
                  'orderId': '2001',
                  'account': 'DU123456',
                  'alertActive': true,
                  'orderTime': '2026-08-19T10:00:00Z',
                }
              ]),
              200));

      mockGateway.registerRoute(
          '/iserver/account/alert',
          (req) => http.Response(
              jsonEncode({
                'status': 200,
                'success': true,
                'alert_id': 501,
              }),
              200));

      mockGateway.registerRoute(
          '/iserver/account/alert/activate',
          (req) => http.Response(
              jsonEncode({
                'status': 200,
                'success': true,
              }),
              200));

      mockGateway.registerRoute(
          '/iserver/account/alert/details/501',
          (req) => http.Response(
              jsonEncode({
                'alertId': 501,
                'alertName': 'AAPL High Price Alert',
                'account': 'DU123456',
                'conditions': [
                  {
                    'type': 1,
                    'conid': 265598,
                    'operator': '>=',
                    'value': 160.0,
                    'logicBind': 'a'
                  }
                ],
                'actions': [],
                'timeZone': 'EST',
              }),
              200));

      client = mockGateway.buildClient();
      service = AlertService(
          client: client, baseUrl: 'https://localhost:5000/v1/api');
    });

    test('getAlerts should return list of active alerts', () async {
      final alerts = await service.getAlerts('DU123456');
      expect(alerts, hasLength(1));
      expect(alerts.first.alertId, 501);
      expect(alerts.first.alertName, 'AAPL High Price Alert');
      expect(alerts.first.alertActive, isTrue);
    });

    test('createOrUpdateAlert should create price alert', () async {
      final req = CreateAlertRequest(
        alertName: 'AAPL High Price Alert',
        account: 'DU123456',
        conditions: [
          AlertCondition(type: 1, conid: 265598, operator: '>=', value: 160.0)
        ],
      );

      final success = await service.createOrUpdateAlert('DU123456', req);
      expect(success, isTrue);
    });

    test('toggleAlert and deleteAlert should update alert state', () async {
      final toggled = await service.toggleAlert('DU123456', 501, false);
      expect(toggled, isTrue);

      final deleted = await service.deleteAlert('DU123456', 501);
      expect(deleted, isTrue);
    });

    test('getAlertDetails should parse alert condition rules', () async {
      final details = await service.getAlertDetails(501);
      expect(details.alertId, 501);
      expect(details.conditions, hasLength(1));
      expect(details.conditions.first.conid, 265598);
      expect(details.conditions.first.value, 160.0);
    });
  });
}

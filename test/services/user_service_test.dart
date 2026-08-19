import 'dart:convert';
import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:ib_trade_core/src/testing/mock_gateway.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('UserService', () {
    late MockGatewayHttp mockGateway;
    late http.Client client;
    late UserService service;

    setUp(() {
      mockGateway = MockGatewayHttp();

      mockGateway.registerRoute(
          '/one/user',
          (req) => http.Response(
              jsonEncode({
                'userId': 998877,
                'userName': 'johndoe',
                'email': 'john@example.com',
                'isPaper': true,
                'features': {'options': true},
              }),
              200));

      mockGateway.registerRoute(
          '/fyi/notifications',
          (req) => http.Response(
              jsonEncode([
                {
                  'id': 'fyi_001',
                  'code': 'SYS_MAINT',
                  'title': 'Scheduled Maintenance',
                  'body': 'System will be updated at midnight.',
                  'timestamp': 1700000000,
                  'read': false,
                }
              ]),
              200));

      mockGateway.registerRoute(
          '/fyi/unreadnumber',
          (req) => http.Response(
              jsonEncode({
                'unreadNumber': 3,
              }),
              200));

      mockGateway.registerRoute('/fyi/settings', (req) {
        if (req.method == 'GET') {
          return http.Response(
              jsonEncode([
                {'type': 'SYS_MAINT', 'enabled': true, 'device': 'email'}
              ]),
              200);
        } else {
          return http.Response(
              jsonEncode({'status': 200, 'success': true}), 200);
        }
      });

      mockGateway.registerRoute(
          '/iserver/user/settings',
          (req) => http.Response(
              jsonEncode({
                'timeZone': 'EST',
                'language': 'en',
                'paperMode': true,
              }),
              200));

      client = mockGateway.buildClient();
      service =
          UserService(client: client, baseUrl: 'https://localhost:5000/v1/api');
    });

    test('getUserInfo should return user profile details', () async {
      final user = await service.getUserInfo();
      expect(user.userId, 998877);
      expect(user.userName, 'johndoe');
      expect(user.isPaper, isTrue);
    });

    test('getNotifications should return FYI bulletins', () async {
      final notifications = await service.getNotifications();
      expect(notifications, hasLength(1));
      expect(notifications.first.id, 'fyi_001');
      expect(notifications.first.code, 'SYS_MAINT');
      expect(notifications.first.read, isFalse);
    });

    test('getUnreadCount should return unread notification counter', () async {
      final unread = await service.getUnreadCount();
      expect(unread.unreadNumber, 3);
    });

    test('getFyiSettings and updateFyiSettings should manage settings',
        () async {
      final settings = await service.getFyiSettings();
      expect(settings, hasLength(1));
      expect(settings.first.type, 'SYS_MAINT');

      final updated = await service.updateFyiSettings(settings);
      expect(updated, isTrue);
    });

    test('getUserSettings should return user gateway settings', () async {
      final settings = await service.getUserSettings();
      expect(settings.timeZone, 'EST');
      expect(settings.paperMode, isTrue);
    });
  });
}

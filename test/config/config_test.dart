import 'package:ib_trade_core/ib_trade_core.dart';
import 'package:test/test.dart';

void main() {
  group('GatewayConfig', () {
    test('should construct with correct default values', () {
      const config = GatewayConfig();
      expect(config.host, equals('localhost'));
      expect(config.port, equals(5000));
      expect(config.useSsl, isTrue);
      expect(config.bypassSslVerification, isFalse);
      expect(config.tickleIntervalSeconds, equals(45));
      expect(config.connectionTimeoutSeconds, equals(10));
    });

    test('should load from environment map with custom keys', () {
      final env = {
        'IBKR_GATEWAY_HOST': '192.168.1.100',
        'ibkr_gateway_port': '9191',
        'IBKR_GATEWAY_USE_SSL': 'false',
        'IBKR_GATEWAY_BYPASS_SSL': 'true',
        'IBKR_GATEWAY_TICKLE_INTERVAL': '30',
        'IBKR_GATEWAY_TIMEOUT': '15',
      };

      final config = GatewayConfig.fromEnvironment(env);
      expect(config.host, equals('192.168.1.100'));
      expect(config.port, equals(9191));
      expect(config.useSsl, isFalse);
      expect(config.bypassSslVerification, isTrue);
      expect(config.tickleIntervalSeconds, equals(30));
      expect(config.connectionTimeoutSeconds, equals(15));
    });

    test('should fallback to defaults when environment map is empty', () {
      final config = GatewayConfig.fromEnvironment({});
      expect(config.host, equals('localhost'));
      expect(config.port, equals(5000));
      expect(config.useSsl, isTrue);
    });

    test('should construct from generic map', () {
      final map = {
        'host': 'gateway.local',
        'port': 4001,
        'useSsl': 'true',
        'bypassSslVerification': false,
        'tickleIntervalSeconds': '60',
        'connectionTimeoutSeconds': 5,
      };

      final config = GatewayConfig.fromMap(map);
      expect(config.host, equals('gateway.local'));
      expect(config.port, equals(4001));
      expect(config.useSsl, isTrue);
      expect(config.bypassSslVerification, isFalse);
      expect(config.tickleIntervalSeconds, equals(60));
      expect(config.connectionTimeoutSeconds, equals(5));
    });

    test('should generate correct HTTP and WS URIs depending on SSL status',
        () {
      const configSsl = GatewayConfig(host: 'myhost', port: 8080, useSsl: true);
      expect(configSsl.baseHttpUri.toString(),
          equals('https://myhost:8080/v1/api/'));
      expect(configSsl.baseWsUri.toString(),
          equals('wss://myhost:8080/v1/api/ws'));

      const configNoSsl =
          GatewayConfig(host: 'myhost', port: 8080, useSsl: false);
      expect(configNoSsl.baseHttpUri.toString(),
          equals('http://myhost:8080/v1/api/'));
      expect(configNoSsl.baseWsUri.toString(),
          equals('ws://myhost:8080/v1/api/ws'));
    });
  });
}

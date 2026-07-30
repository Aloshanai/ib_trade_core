import 'platform_env.dart';

/// Connection and session configuration settings for the IBKR Gateway client.
class GatewayConfig {
  /// The hostname of the Gateway (e.g. 'localhost').
  final String host;

  /// The port number of the Gateway (e.g. 5000).
  final int port;

  /// Whether to use SSL (HTTPS/WSS) for connections.
  final bool useSsl;

  /// Whether to bypass self-signed SSL certificate verification.
  final bool bypassSslVerification;

  /// Interval in seconds for periodic session tickling (keep-alive).
  final int tickleIntervalSeconds;

  /// Connection timeout in seconds.
  final int connectionTimeoutSeconds;

  /// Creates a [GatewayConfig] instance.
  const GatewayConfig({
    this.host = 'localhost',
    this.port = 5000,
    this.useSsl = true,
    this.bypassSslVerification = false,
    this.tickleIntervalSeconds = 45,
    this.connectionTimeoutSeconds = 10,
  });

  /// Factory constructor to load settings from environment variables.
  ///
  /// Expected variables (case-insensitive keys matched on env):
  /// - `IBKR_GATEWAY_HOST` (default: 'localhost')
  /// - `IBKR_GATEWAY_PORT` (default: 5000)
  /// - `IBKR_GATEWAY_USE_SSL` (default: true)
  /// - `IBKR_GATEWAY_BYPASS_SSL` (default: false)
  /// - `IBKR_GATEWAY_TICKLE_INTERVAL` (default: 45)
  /// - `IBKR_GATEWAY_TIMEOUT` (default: 10)
  factory GatewayConfig.fromEnvironment([Map<String, String>? env]) {
    final environment = env ?? getPlatformEnvironment();

    String getEnv(String key, String defaultValue) {
      return environment[key] ??
          environment[key.toUpperCase()] ??
          environment[key.toLowerCase()] ??
          defaultValue;
    }

    bool getEnvBool(String key, bool defaultValue) {
      final value = environment[key] ??
          environment[key.toUpperCase()] ??
          environment[key.toLowerCase()];
      if (value == null) return defaultValue;
      return value.toLowerCase() == 'true' || value == '1';
    }

    int getEnvInt(String key, int defaultValue) {
      final value = environment[key] ??
          environment[key.toUpperCase()] ??
          environment[key.toLowerCase()];
      if (value == null) return defaultValue;
      return int.tryParse(value) ?? defaultValue;
    }

    return GatewayConfig(
      host: getEnv('IBKR_GATEWAY_HOST', 'localhost'),
      port: getEnvInt('IBKR_GATEWAY_PORT', 5000),
      useSsl: getEnvBool('IBKR_GATEWAY_USE_SSL', true),
      bypassSslVerification: getEnvBool('IBKR_GATEWAY_BYPASS_SSL', false),
      tickleIntervalSeconds: getEnvInt('IBKR_GATEWAY_TICKLE_INTERVAL', 45),
      connectionTimeoutSeconds: getEnvInt('IBKR_GATEWAY_TIMEOUT', 10),
    );
  }

  /// Factory constructor to load settings from a generic Map structure.
  factory GatewayConfig.fromMap(Map<String, dynamic> map) {
    bool? parseBool(dynamic val) {
      if (val == null) return null;
      if (val is bool) return val;
      if (val is String) return val.toLowerCase() == 'true' || val == '1';
      return null;
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is String) return int.tryParse(val);
      return null;
    }

    return GatewayConfig(
      host: map['host']?.toString() ?? 'localhost',
      port: parseInt(map['port']) ?? 5000,
      useSsl: parseBool(map['useSsl']) ?? true,
      bypassSslVerification: parseBool(map['bypassSslVerification']) ?? false,
      tickleIntervalSeconds: parseInt(map['tickleIntervalSeconds']) ?? 45,
      connectionTimeoutSeconds: parseInt(map['connectionTimeoutSeconds']) ?? 10,
    );
  }

  /// Helper to convert the configuration to a base HTTP/HTTPS Uri.
  Uri get baseHttpUri {
    final scheme = useSsl ? 'https' : 'http';
    return Uri(scheme: scheme, host: host, port: port, path: '/v1/api/');
  }

  /// Helper to convert the configuration to a base WebSocket Uri.
  Uri get baseWsUri {
    final scheme = useSsl ? 'wss' : 'ws';
    return Uri(scheme: scheme, host: host, port: port, path: '/v1/api/ws');
  }

  @override
  String toString() {
    return 'GatewayConfig(host: $host, port: $port, useSsl: $useSsl, bypassSslVerification: $bypassSslVerification, tickleIntervalSeconds: $tickleIntervalSeconds, connectionTimeoutSeconds: $connectionTimeoutSeconds)';
  }
}

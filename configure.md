# Configuration Guide

This guide describes how to configure the connection and session settings for the `ib_trade_core` library using the [GatewayConfig](file:///c:/Users/Admin/Documents/GitHub/ib_trade_core/lib/src/config/gateway_config.dart) class.

## Overview

The `ib_trade_core` SDK uses [GatewayConfig](file:///c:/Users/Admin/Documents/GitHub/ib_trade_core/lib/src/config/gateway_config.dart) to define connection details (such as host, port, SSL usage, and timeout intervals) for communicating with the Interactive Brokers (IBKR) Client Portal Gateway API.

---

## GatewayConfig Properties

Below are the properties supported by `GatewayConfig`:

| Property | Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `host` | `String` | `'localhost'` | The hostname or IP address of the IBKR Gateway. |
| `port` | `int` | `5000` | The port number of the IBKR Gateway. |
| `useSsl` | `bool` | `true` | Whether to use SSL (`https` and `wss` protocols) for connections. |
| `bypassSslVerification` | `bool` | `false` | Set to `true` to bypass self-signed SSL certificate verification (useful for local development). |
| `tickleIntervalSeconds` | `int` | `45` | Interval in seconds for periodic session tickling (keep-alive). |
| `connectionTimeoutSeconds` | `int` | `10` | Timeout in seconds for gateway connections. |

---

## Initialization Approaches

There are three ways to instantiate a `GatewayConfig` in your Dart application:

### 1. In-Code Constructor
You can define settings directly in your code using the standard constructor:

```dart
import 'package:ib_trade_core/ib_trade_core.dart';

const config = GatewayConfig(
  host: 'gateway.internal.net',
  port: 5000,
  useSsl: true,
  bypassSslVerification: false,
  tickleIntervalSeconds: 30,
  connectionTimeoutSeconds: 15,
);
```

### 2. Environment Variables
You can load the configuration from environment variables (case-insensitive keys). This is highly useful for 12-factor apps and containerized environments.

```dart
// Loads from the platform environment (e.g. Platform.environment)
final config = GatewayConfig.fromEnvironment();

// Or pass a custom map:
final customEnv = {
  'IBKR_GATEWAY_HOST': '127.0.0.1',
  'IBKR_GATEWAY_PORT': '5000',
  'IBKR_GATEWAY_USE_SSL': 'false',
};
final configFromEnv = GatewayConfig.fromEnvironment(customEnv);
```

#### Supported Environment Variables
- `IBKR_GATEWAY_HOST` (e.g. `localhost`)
- `IBKR_GATEWAY_PORT` (e.g. `5000`)
- `IBKR_GATEWAY_USE_SSL` (e.g. `true`, `1`, `false`, `0`)
- `IBKR_GATEWAY_BYPASS_SSL` (e.g. `true`, `1`, `false`, `0`)
- `IBKR_GATEWAY_TICKLE_INTERVAL` (e.g. `45`)
- `IBKR_GATEWAY_TIMEOUT` (e.g. `10`)

### 3. From a Map
If you load configuration settings from a JSON file, YAML file, or database, you can construct the config using the `fromMap` factory:

```dart
final Map<String, dynamic> configMap = {
  'host': '10.0.0.5',
  'port': 5000,
  'useSsl': true,
  'bypassSslVerification': true,
  'tickleIntervalSeconds': 60,
  'connectionTimeoutSeconds': 10,
};

final config = GatewayConfig.fromMap(configMap);
```

---

## Derived Helpers

`GatewayConfig` exposes two getter properties to conveniently get base URIs with the correct protocols:

*   **`baseHttpUri`**: Generates a `Uri` object pointing to the HTTP/HTTPS API.
    *   Example with SSL: `https://<host>:<port>/v1/api/`
    *   Example without SSL: `http://<host>:<port>/v1/api/`
*   **`baseWsUri`**: Generates a `Uri` object pointing to the WebSocket API.
    *   Example with SSL: `wss://<host>:<port>/v1/api/ws`
    *   Example without SSL: `ws://<host>:<port>/v1/api/ws`

---

## Example Usage

Here is a simple example showing how `GatewayConfig` is used to configure the HTTP and WebSocket connections:

```dart
import 'package:ib_trade_core/ib_trade_core.dart';

void main() async {
  // 1. Initialize config
  const config = GatewayConfig(
    host: 'localhost',
    port: 5000,
    useSsl: false,
  );

  // 2. Initialize HTTP Client with cookie support
  final innerClient = HttpClient(bypassSslVerification: config.bypassSslVerification);
  final cookieClient = CookieClient(innerClient);

  // 3. Establish WebSocket connection
  final wsConnection = IbWebSocketConnection(
    config.baseWsUri, // Uses the helper baseWsUri
    cookieClient: cookieClient,
  );

  wsConnection.stateChanges.listen((state) {
    print('WebSocket State: $state');
  });

  await wsConnection.connect();
  
  // clean up when done
  await wsConnection.disconnect();
  cookieClient.close();
}
```

# ib_trade_core

The foundational Dart core SDK and adaptation layer for Interactive Brokers (IBKR) Client Portal Web API. 

`ib_trade_core` provides strongly-typed data models, session lifecycle management, automated cookie handling, compliance challenge resolvers, real-time WebSocket event dispatching, domain adaptation services, and a Model Context Protocol (MCP) tool contract adapter.

---

## Features

- 🔐 **Authentication & Session Management**: Automated session cookie management via `CookieClient`, keep-alive tickle background loop (`SessionTickler`), and SSO token validation.
- 🏢 **Domain Adaptation Services**:
  - `SessionService` - Session status, keep-alive, re-authentication, logout.
  - `AccountService` - Multi-account overview, portfolios, cash ledgers, positions, asset allocations.
  - `OrderService` - Place single, bracket, combo, or OCO orders, What-If margin previews, order modifications, cancellations, and compliance safety challenge handling.
  - `ContractService` - Financial contract search, security definitions, option strike chains, futures specifications.
  - `MarketDataService` - Real-time market snapshots, historical OHLCV bar series, data unsubscriptions.
  - `ScannerService` - Market scanner metadata parameters and mover/gainer scan queries.
  - `AlertService` - Account price/volume alerts creation, toggles, deletion, condition parsing.
  - `UserService` - Authenticated user profile, system bulletin notifications (FYIs), notification preferences.
  - `StreamingService` - Real-time WebSocket event dispatching for quotes (`smd`), depth (`sbd`), account PnL (`act`), and order status (`or`).
- 🤖 **MCP Tool Contract Adapter**: Seamless contract schema mappings via `McpToolRegistryAdapter` for Model Context Protocol integration (`ibkr_trade_mcp`).
- 🌐 **Cross-Platform**: Supports compilation on Desktop/VM and Web environments without `dart:io` platform leakage.

---

## Installation

Add `ib_trade_core` to your `pubspec.yaml`:

```yaml
dependencies:
  ib_trade_core: ^0.1.1
```

Or install via terminal:

```bash
dart pub add ib_trade_core
```

---

## Getting Started

### 1. Unified Client Facade Usage

```dart
import 'package:ib_trade_core/ib_trade_core.dart';

Future<void> main() async {
  // 1. Configure gateway parameters
  final config = GatewayConfig(
    host: 'localhost',
    port: 5000,
    useSsl: true,
    bypassSslVerification: true,
  );

  // 2. Initialize unified client
  final client = IbTradeCoreClient(config: config);

  // 3. Connect WebSocket and session keep-alive
  await client.connect();

  // 4. Query authentication status
  final auth = await client.session.getAuthStatus();
  print('Authenticated: ${auth.authenticated}');

  // 5. Fetch portfolio accounts & positions
  final accounts = await client.account.getAccounts();
  for (final acc in accounts) {
    print('Account: ${acc.accountId} (${acc.currency})');
    final positions = await client.account.getPositions(acc.accountId);
    for (final pos in positions) {
      print('  Position: ${pos.contractDescription} x ${pos.position}');
    }
  }

  // 6. Clean up resources
  await client.dispose();
}
```

### 2. Search Contracts & Market Data Snapshots

```dart
import 'package:ib_trade_core/ib_trade_core.dart';

Future<void> searchAndSnapshot(IbTradeCoreClient client) async {
  // Search equity contracts
  final hits = await client.contracts.searchContracts('AAPL', secType: SecurityType.stk);
  if (hits.isNotEmpty) {
    final conid = hits.first.conid;

    // Fetch real-time market data snapshot
    final snapshots = await client.marketData.getMarketDataSnapshot([conid]);
    final snap = snapshots.first;
    print('${snap.symbol} Last Price: \$${snap.lastPrice} (Bid: \$${snap.bidPrice} / Ask: \$${snap.askPrice})');
  }
}
```

### 3. Place Orders with Compliance Warning Challenge Handling

```dart
import 'package:ib_trade_core/ib_trade_core.dart';

Future<void> placeLimitOrder(IbTradeCoreClient client, String accountId) async {
  final order = OrderRequest(
    conid: 265598,
    orderType: OrderType.lmt,
    side: OrderSide.buy,
    quantity: 10.0,
    price: 150.0,
    tif: TimeInForce.day,
  );

  // Order submission automatically resolves safety warnings via ChallengeHandler
  final responses = await client.orders.placeOrders(accountId, [order]);
  for (final res in responses) {
    print('Order ID: ${res.orderId}, Status: ${res.orderStatus}');
  }
}
```

### 4. Real-Time Streaming Subscriptions

```dart
import 'package:ib_trade_core/ib_trade_core.dart';

void listenToStream(IbTradeCoreClient client) {
  // Listen to quote updates
  client.streaming.quoteStream.listen((event) {
    print('Quote Tick -> ConID: ${event.conid}, Last: ${event.lastPrice}');
  });

  // Subscribe to contract quotes
  client.streaming.subscribeQuotes(265598);
}
```

---

## Model Context Protocol (MCP) Integration

`ib_trade_core` provides `McpToolRegistryAdapter` to expose tool contract schemas and execution delegates for downstream MCP servers:

```dart
import 'package:ib_trade_core/ib_trade_core.dart';

void registerMcpTools(IbTradeCoreClient client) {
  final adapter = McpToolRegistryAdapter();
  for (final tool in adapter.tools) {
    print('MCP Tool registered: ${tool.name} - ${tool.description}');
  }
}
```

---

## License

Licensed under the [MIT License](file:///LICENSE).

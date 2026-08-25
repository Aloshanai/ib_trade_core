# ib_trade_core

The foundational Dart core SDK and adaptation layer for the Interactive Brokers (IBKR) Client Portal Web API.

`ib_trade_core` provides strongly-typed domain models, session lifecycle management, automated cookie handling, compliance challenge resolvers, real-time WebSocket event dispatching, domain adaptation services, and a Model Context Protocol (MCP) tool contract adapter.

---

## Features

- 🔐 **Authentication & Session Management**: Automated session cookie persistence via `CookieClient`, background session keep-alive loop (`SessionTickler`), and SSO token validation.
- 🏢 **Domain Adaptation Services**:
  - **SessionService**: Session health status checks, tickle keep-alive interval, re-authentication, and logout.
  - **AccountService**: Multi-account summaries, portfolio positioning, cash balances, ledgers, and asset allocations.
  - **OrderService**: Order placement (single, bracket, combo, OCO), What-If margin previews, order modifications, cancellations, and compliance safety challenge handling.
  - **ContractService**: Security definition lookup, contract search, option strike chains, and futures market specifications.
  - **MarketDataService**: Real-time market data snapshots, historical OHLCV bar series, and data unsubscriptions.
  - **ScannerService**: Market scanner parameters, market mover/gainer scan queries.
  - **AlertService**: Price and volume alert creation, toggles, deletion, and condition parsing.
  - **UserService**: Profile retrieval, system bulletin notifications (FYIs), and user preference management.
  - **StreamingService**: High-level WebSocket stream dispatcher for quotes (`smd`), depth (`sbd`), account PnL (`act`), and order status updates (`or`).
- 🤖 **MCP Tool Adapter**: Standardized tool definitions and schemas via `McpToolRegistryAdapter` for seamless integration with Model Context Protocol servers.
- 🌐 **Cross-Platform**: Compatible with Dart VM (Desktop/Server) and Web environments without platform-specific IO dependencies.

---

## Installation

Add `ib_trade_core` to your `pubspec.yaml`:

```yaml
dependencies:
  ib_trade_core: ^0.1.2
```

Or install via terminal:

```bash
dart pub add ib_trade_core
```

---

## Getting Started

`ib_trade_core` exposes `IbTradeCoreClient` as a unified facade for accessing all IBKR Client Portal services:

- **Client Configuration**: Initialize gateway settings (`GatewayConfig`) with host, port, SSL preference, and timeout parameters.
- **Connection & Session Lifecycle**: Call `client.connect()` to initialize WebSocket channels and background keep-alive pinging (`SessionTickler`).
- **Domain Service Execution**: Access sub-services directly on the client instance (`client.session`, `client.account`, `client.orders`, `client.contracts`, `client.marketData`, `client.streaming`, etc.).
- **Automatic Compliance Challenge Resolution**: Submit orders seamlessly while internal resolvers auto-acknowledge IBKR safety and risk disclaimers.
- **Real-Time Data Streaming**: Subscribe to live quote streams, order status updates, and account metrics over a single unified WebSocket connection.
- **Model Context Protocol Integration**: Register core capability tools into AI assistant workflows using `McpToolRegistryAdapter`.

For complete, runnable code examples, refer to the [example/example.dart](example/example.dart) file.

---

## License

Licensed under the [Apache 2.0 License](LICENSE).

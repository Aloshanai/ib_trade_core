import 'package:http/http.dart' as http;
import 'client/challenge_handler.dart';
import 'client/cookie_client.dart';
import 'client/session_tickler.dart';
import 'client/websocket_connection.dart';
import 'config/gateway_config.dart';
import 'services/account_service.dart';
import 'services/alert_service.dart';
import 'services/contract_service.dart';
import 'services/market_data_service.dart';
import 'services/order_service.dart';
import 'services/scanner_service.dart';
import 'services/session_service.dart';
import 'services/streaming_service.dart';
import 'services/user_service.dart';

/// Unified Client Facade serving as the main entry point for the IBKR Client Portal SDK and MCP Server.
class IbTradeCoreClient {
  final GatewayConfig config;
  final CookieClient _cookieClient;
  final SessionTickler? _tickler;
  final IbWebSocketConnection _wsConnection;
  final ChallengeHandler _challengeHandler;

  late final SessionService session;
  late final AccountService account;
  late final OrderService orders;
  late final ContractService contracts;
  late final MarketDataService marketData;
  late final ScannerService scanner;
  late final AlertService alerts;
  late final UserService user;
  late final StreamingService streaming;

  /// Creates an instance of [IbTradeCoreClient] with optional custom [httpClient] or [wsConnection].
  IbTradeCoreClient({
    required this.config,
    http.Client? httpClient,
    IbWebSocketConnection? wsConnection,
    SessionTickler? tickler,
  })  : _cookieClient = CookieClient(httpClient ?? http.Client()),
        _wsConnection = wsConnection ??
            IbWebSocketConnection(
              Uri.parse('${config.baseUrl.replaceAll('http', 'ws')}/ws'),
              bypassSslVerification: config.bypassSslVerification,
            ),
        _challengeHandler = ChallengeHandler(
          httpClient ?? http.Client(),
          Uri.parse(config.baseUrl),
        ),
        _tickler = tickler {
    session = SessionService(
        client: _cookieClient, baseUrl: config.baseUrl, tickler: _tickler);
    account = AccountService(client: _cookieClient, baseUrl: config.baseUrl);
    orders = OrderService(
        client: _cookieClient,
        baseUrl: config.baseUrl,
        challengeHandler: _challengeHandler);
    contracts = ContractService(client: _cookieClient, baseUrl: config.baseUrl);
    marketData =
        MarketDataService(client: _cookieClient, baseUrl: config.baseUrl);
    scanner = ScannerService(client: _cookieClient, baseUrl: config.baseUrl);
    alerts = AlertService(client: _cookieClient, baseUrl: config.baseUrl);
    user = UserService(client: _cookieClient, baseUrl: config.baseUrl);
    streaming = StreamingService(_wsConnection);
  }

  /// Establishes session authentication and WebSocket streaming connections.
  Future<void> connect() async {
    await _wsConnection.connect();
    _tickler?.start();
  }

  /// Disconnects active WebSocket stream and halts session tickler.
  Future<void> disconnect() async {
    _tickler?.stop();
    await _wsConnection.disconnect();
  }

  /// Cleans up resources.
  Future<void> dispose() async {
    await disconnect();
    await streaming.dispose();
    _cookieClient.close();
  }
}

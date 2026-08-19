// ignore_for_file: avoid_print
import 'package:ib_trade_core/ib_trade_core.dart';

void main() async {
  // 1. Configure Gateway Settings
  const config = GatewayConfig(
    host: 'localhost',
    port: 5000,
    useSsl: true,
    bypassSslVerification: true,
  );

  print('Configured Gateway Base URL: ${config.baseUrl}');

  // 2. Initialize Unified Client Facade
  final client = IbTradeCoreClient(config: config);

  // 3. Monitor WebSocket streaming events
  client.streaming.quoteStream.listen((event) {
    print('Real-Time Quote -> ConID: ${event.conid}, Last: ${event.lastPrice}');
  });

  // 4. Connect to Gateway & WebSocket
  print('Connecting to IBKR Gateway...');
  await client.connect();

  // 5. Query authentication status
  final authStatus = await client.session.getAuthStatus();
  print('Authentication Status: $authStatus');

  // 6. Search for financial contracts
  final hits =
      await client.contracts.searchContracts('AAPL', secType: SecurityType.stk);
  if (hits.isNotEmpty) {
    print('Found contract: ${hits.first.symbol} (conid: ${hits.first.conid})');
  }

  // 7. Cleanup & Disconnect
  await Future.delayed(const Duration(seconds: 2));
  print('Disconnecting...');
  await client.dispose();
}

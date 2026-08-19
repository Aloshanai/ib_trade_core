// ignore_for_file: avoid_print
import 'package:ib_trade_core/ib_trade_core.dart';

void main() async {
  // 1. Configure the Gateway Settings
  const config = GatewayConfig(
    host: 'localhost',
    port: 5000,
    useSsl: false, // Set to true if Gateway has SSL enabled
  );

  print('Configured Gateway: ${config.host}:${config.port}');

  // 2. Initialize the HTTP Client with Cookie support
  // Wrapping the custom HttpClient which handles platform-specific client creation.
  final innerClient =
      HttpClient(bypassSslVerification: config.bypassSslVerification);
  final cookieClient = CookieClient(innerClient);

  // 3. Establish WebSocket connection
  final wsUrl = Uri.parse('ws://${config.host}:${config.port}/v1/api/ws');
  final wsConnection = IbWebSocketConnection(
    wsUrl,
    cookieClient: cookieClient,
  );

  // Monitor WebSocket states
  wsConnection.stateChanges.listen((state) {
    print('WebSocket State changed: $state');
  });

  // Listen to messages
  wsConnection.messages.listen((message) {
    print('Received message: $message');
  });

  // Listen to errors
  wsConnection.errors.listen((error) {
    print('WebSocket error: $error');
  });

  // Connect to the WebSocket
  print('Connecting to $wsUrl...');
  await wsConnection.connect();

  // Close connection after some time (for demo purposes)
  await Future.delayed(const Duration(seconds: 5));
  print('Disconnecting...');
  await wsConnection.disconnect();
  cookieClient.close();
}

import 'dart:async';
import 'dart:math' as math;
import 'cookie_client.dart';
import 'websocket_impl.dart';

/// Connection states for the WebSocket connection.
enum IbWebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Manages the low-level WebSocket connection to the IBKR Client Portal Gateway.
///
/// Features automated cookie forwarding, periodic heartbeat tickling, and
/// auto-reconnection with exponential backoff.
class IbWebSocketConnection {
  final Uri _wsUrl;
  final CookieClient? _cookieClient;
  final bool _bypassSslVerification;
  final Duration _heartbeatInterval;
  final Duration _initialRetryDelay;
  final Duration _maxRetryDelay;
  final int _maxRetryAttempts;

  BaseWebSocketConnection? _socket;
  StreamSubscription? _socketSubscription;
  IbWebSocketState _state = IbWebSocketState.disconnected;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _retryAttempts = 0;
  bool _shouldReconnect = false;

  final StreamController<IbWebSocketState> _stateController =
      StreamController<IbWebSocketState>.broadcast();
  final StreamController<dynamic> _messageController =
      StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _errorController =
      StreamController<dynamic>.broadcast();

  /// Creates a connection manager for the given [_wsUrl].
  ///
  /// Optionally accepts a [_cookieClient] to forward session cookies,
  /// custom [_heartbeatInterval] (defaults to 45 seconds), and retry parameters
  /// for exponential backoff.
  IbWebSocketConnection(
    this._wsUrl, {
    CookieClient? cookieClient,
    bool bypassSslVerification = false,
    Duration heartbeatInterval = const Duration(seconds: 45),
    Duration initialRetryDelay = const Duration(seconds: 1),
    Duration maxRetryDelay = const Duration(seconds: 60),
    int maxRetryAttempts = 10,
  })  : _cookieClient = cookieClient,
        _bypassSslVerification = bypassSslVerification,
        _heartbeatInterval = heartbeatInterval,
        _initialRetryDelay = initialRetryDelay,
        _maxRetryDelay = maxRetryDelay,
        _maxRetryAttempts = maxRetryAttempts;

  /// Stream of connection state changes.
  Stream<IbWebSocketState> get stateChanges => _stateController.stream;

  /// Stream of incoming text or binary messages.
  Stream<dynamic> get messages => _messageController.stream;

  /// Stream of socket-level errors.
  Stream<dynamic> get errors => _errorController.stream;

  /// The current state of the connection.
  IbWebSocketState get state => _state;

  /// Starts the connection process.
  ///
  /// Attempts to establish a connection to the WebSocket endpoint.
  /// Sets up automatic reconnection if the connection fails.
  Future<void> connect() async {
    _shouldReconnect = true;
    _retryAttempts = 0;
    await _establishConnection();
  }

  /// Disconnects the socket and stops any reconnection loops or heartbeats.
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopHeartbeat();
    await _socketSubscription?.cancel();
    _socketSubscription = null;

    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }

    _updateState(IbWebSocketState.disconnected);
  }

  void _updateState(IbWebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  Future<void> _establishConnection() async {
    if (_state == IbWebSocketState.connected ||
        _state == IbWebSocketState.connecting) {
      return;
    }

    if (_retryAttempts > 0) {
      _updateState(IbWebSocketState.reconnecting);
    } else {
      _updateState(IbWebSocketState.connecting);
    }

    Map<String, String>? headers;
    if (_cookieClient != null && _cookieClient!.cookies.isNotEmpty) {
      final cookieString = _cookieClient!.cookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
      headers = {'Cookie': cookieString};
    }

    try {
      _socket = await connectWebSocket(
        _wsUrl,
        headers: headers,
        bypassSslVerification: _bypassSslVerification,
      );

      _updateState(IbWebSocketState.connected);
      _retryAttempts = 0;
      _startHeartbeat();
      _listenToSocket();
    } catch (e) {
      _errorController.add(e);
      _handleDisconnectOrError();
    }
  }

  void _listenToSocket() {
    if (_socket == null) return;

    _socketSubscription = _socket!.stream.listen(
      (message) {
        _messageController.add(message);
      },
      onError: (error) {
        _errorController.add(error);
        _handleDisconnectOrError();
      },
      onDone: () {
        _handleDisconnectOrError();
      },
      cancelOnError: true,
    );
  }

  void _handleDisconnectOrError() {
    _stopHeartbeat();
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socket = null;
    _updateState(IbWebSocketState.disconnected);

    if (_shouldReconnect && _retryAttempts < _maxRetryAttempts) {
      final delay = _calculateBackoffDelay();
      _retryAttempts++;
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () {
        if (_shouldReconnect) {
          _establishConnection();
        }
      });
    }
  }

  Duration _calculateBackoffDelay() {
    final double power = math.pow(2, _retryAttempts).toDouble();
    final delayMs = (_initialRetryDelay.inMilliseconds * power).round();
    final maxMs = _maxRetryDelay.inMilliseconds;
    return Duration(milliseconds: math.min(delayMs, maxMs));
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_socket != null && _state == IbWebSocketState.connected) {
        try {
          _socket!.add('tickle');
        } catch (e) {
          _errorController.add(e);
          _handleDisconnectOrError();
        }
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Sends a raw message over the WebSocket connection.
  void send(String message) {
    if (_socket != null && _state == IbWebSocketState.connected) {
      _socket!.add(message);
    } else {
      throw StateError('Cannot send message. WebSocket is not connected.');
    }
  }

  /// Closes the controllers when they are no longer needed.
  Future<void> close() async {
    await disconnect();
    await _stateController.close();
    await _messageController.close();
    await _errorController.close();
  }
}

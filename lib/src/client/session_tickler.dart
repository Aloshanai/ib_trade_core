import 'dart:async';
import 'package:http/http.dart' as http;

/// A session tickler that periodically pings the local gateway's `/tickle`
/// endpoint to keep the IBKR session active.
class SessionTickler {
  final http.Client _client;
  final Uri _baseUrl;
  final Duration _interval;

  Timer? _timer;
  bool _isActive = false;

  /// Creates a [SessionTickler] with the given [_client], [_baseUrl], and optional custom [_interval] (defaults to 45 seconds).
  SessionTickler(
    this._client,
    this._baseUrl, {
    Duration interval = const Duration(seconds: 45),
  }) : _interval = interval;

  /// Whether the tickler is currently active and running.
  bool get isActive => _isActive;

  /// Starts the periodic tickle loop.
  ///
  /// The first tickle request is fired immediately. If the tickler is already
  /// running, this call is a no-op.
  void start() {
    if (_isActive) return;
    _isActive = true;
    _tickle();
    _timer = Timer.periodic(_interval, (_) => _tickle());
  }

  /// Stops the periodic tickle loop.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
  }

  Future<void> _tickle() async {
    try {
      await _client.get(_baseUrl.resolve('tickle'));
    } catch (_) {
      // Gracefully catch network exceptions during background tickling
    }
  }
}

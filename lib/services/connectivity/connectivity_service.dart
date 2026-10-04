import 'dart:async';
import 'dart:io';
import 'package:vega_ai/core/utils/logger.dart';

/// Contract for network connectivity detection.
abstract class ConnectivityService {
  /// Whether the device currently has active network connectivity.
  Future<bool> get isConnected;

  /// Stream of network availability changes.
  Stream<bool> get onConnectivityChanged;

  /// Allows manual override for user-controlled offline mode.
  void setConnected(bool connected);

  void dispose();
}

/// Real connectivity service that periodically probes network state
/// and supports manual offline-mode override from the UI toggle.
class DefaultConnectivityService implements ConnectivityService {
  static const _logger = VegaLogger('ConnectivityService');
  final _controller = StreamController<bool>.broadcast();
  bool _lastKnownState = true;
  bool _manualOverride = false;
  bool _manualOffline = false;
  Timer? _pollTimer;

  DefaultConnectivityService({bool initialConnected = true})
      : _lastKnownState = initialConnected {
    _startPolling();
  }

  void _startPolling() {
    // Check connectivity every 15 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _probe());
    // Also do an immediate probe
    _probe();
  }

  Future<void> _probe() async {
    if (_manualOverride) return; // User explicitly set offline mode

    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateState(connected);
    } on SocketException {
      _updateState(false);
    } on TimeoutException {
      _updateState(false);
    } catch (e) {
      _logger.warning('Connectivity probe error: $e');
    }
  }

  void _updateState(bool connected) {
    if (_lastKnownState != connected) {
      _lastKnownState = connected;
      if (!_controller.isClosed) {
        _controller.add(connected);
      }
      _logger.info('Network state changed: ${connected ? "ONLINE" : "OFFLINE"}');
    }
  }

  @override
  Future<bool> get isConnected async {
    if (_manualOverride) return !_manualOffline;
    return _lastKnownState;
  }

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Allows toggling connectivity for the UI offline mode switch.
  /// When [connected] is explicitly set, it overrides real network probing.
  @override
  void setConnected(bool connected) {
    _manualOverride = true;
    _manualOffline = !connected;
    _updateState(connected);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.close();
  }
}

import 'dart:async';

/// Contract for network connectivity detection.
abstract class ConnectivityService {
  /// Whether the device currently has active network connectivity.
  Future<bool> get isConnected;

  /// Stream of network availability changes.
  Stream<bool> get onConnectivityChanged;

  void dispose();
}

/// In-memory and system connectivity implementation.
class DefaultConnectivityService implements ConnectivityService {
  final _controller = StreamController<bool>.broadcast();
  bool _mockIsConnected = true;

  DefaultConnectivityService({bool initialConnected = true}) : _mockIsConnected = initialConnected;

  @override
  Future<bool> get isConnected async => _mockIsConnected;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Allows toggling connectivity for testing or manual user offline mode.
  void setConnected(bool connected) {
    if (_mockIsConnected != connected) {
      _mockIsConnected = connected;
      _controller.add(connected);
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}

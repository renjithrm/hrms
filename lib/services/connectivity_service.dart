// lib/services/connectivity_service.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stacked/stacked.dart';

/// Tracks whether the device has a network. Used as a hint to start
/// syncing; the real test of reachability is the request itself.
class ConnectivityService with ListenableServiceMixin {
  /// Creates the service. [connectivity] exists for tests.
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _backOnline = StreamController<void>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  /// Whether any network interface is up.
  bool get isOnline => _isOnline;

  /// Emits each time the device goes from offline to online.
  Stream<void> get backOnline$ => _backOnline.stream;

  /// Reads the current state and starts listening for changes.
  Future<void> start() async {
    if (_subscription != null) return;
    _apply(await _connectivity.checkConnectivity());
    _subscription = _connectivity.onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == _isOnline) return;
    _isOnline = online;
    notifyListeners();
    if (online) _backOnline.add(null);
  }
}

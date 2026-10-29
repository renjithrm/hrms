// lib/services/app_lifecycle_service.dart

import 'dart:async';

import 'package:flutter/widgets.dart';

/// Turns app lifecycle changes into a stream, so ViewModels and services
/// can react to "app came back" without Flutter widget code.
class AppLifecycleService {
  final _resumed = StreamController<void>.broadcast();
  AppLifecycleListener? _listener;

  /// Emits each time the app returns to the foreground.
  Stream<void> get resumed$ => _resumed.stream;

  /// Starts listening. Call once the widgets binding exists.
  void start() {
    _listener ??= AppLifecycleListener(onResume: () => _resumed.add(null));
  }
}

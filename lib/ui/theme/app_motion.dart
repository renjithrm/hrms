// lib/ui/theme/app_motion.dart

import 'package:flutter/widgets.dart';

/// Motion tokens. Read them through [AppMotion.of] so every animation turns
/// off when the system's reduce-motion setting is on.
class AppMotion {
  const AppMotion._(this._enabled);

  final bool _enabled;

  /// Motion for the current context, disabled when the platform asks for
  /// reduced motion.
  static AppMotion of(BuildContext context) =>
      AppMotion._(!MediaQuery.disableAnimationsOf(context));

  /// Whether looping animations (pulse, spinner, shimmer) may run.
  bool get canLoop => _enabled;

  /// Colour and small state changes.
  Duration get fast => _scaled(const Duration(milliseconds: 150));

  /// Field errors appearing under a form field.
  Duration get fieldError => _scaled(const Duration(milliseconds: 180));

  /// Messages that expand under a field or calendar.
  Duration get reveal => _scaled(const Duration(milliseconds: 200));

  /// Default for content switches.
  Duration get base => _scaled(const Duration(milliseconds: 250));

  /// Larger movements, the slider spring, the shake.
  Duration get slow => _scaled(const Duration(milliseconds: 400));

  /// First sweep of the shift ring.
  Duration get ring => _scaled(const Duration(milliseconds: 900));

  /// Curve for state changes.
  static const Curve standard = Curves.easeOutCubic;

  /// Curve for confirmations such as the success tick.
  static const Curve emphasized = Curves.easeOutBack;

  Duration _scaled(Duration duration) => _enabled ? duration : Duration.zero;
}

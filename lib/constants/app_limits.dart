// lib/constants/app_limits.dart

/// Fixed tuning values, the same in every flavour.
abstract final class AppLimits {
  /// Positions less accurate than this are not trusted for the geofence.
  static const double maxLocationAccuracyMetres = 100;

  /// Per-request network timeout.
  static const Duration requestTimeout = Duration(seconds: 8);

  /// How long to wait for a GPS fix before reporting it unavailable.
  static const Duration locationTimeout = Duration(seconds: 10);
}

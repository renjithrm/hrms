// lib/models/location_failure.dart

/// Why no usable position could be read.
enum LocationFailure {
  /// Permission refused, but the app may ask again.
  denied,

  /// Permission permanently refused; only system settings can change it.
  deniedForever,

  /// The device's location services are switched off.
  serviceOff,

  /// No fix arrived in time.
  unavailable,
}

// lib/models/location_check.dart

import 'location_failure.dart';

/// Whether attendance is possible from where the person is, as shown on the
/// Today card before they try to check in.
sealed class LocationCheck {
  const LocationCheck();
}

/// A GPS fix is being read.
class LocationChecking extends LocationCheck {
  /// Creates the state.
  const LocationChecking();
}

/// Inside the office area.
class LocationInside extends LocationCheck {
  /// Creates the state.
  const LocationInside(
      {required this.distanceMetres, required this.accuracyMetres});

  /// Distance from the office centre.
  final double distanceMetres;

  /// Reported accuracy.
  final double accuracyMetres;
}

/// Outside the office area.
class LocationOutside extends LocationCheck {
  /// Creates the state.
  const LocationOutside(
      {required this.distanceMetres, required this.radiusMetres});

  /// Distance from the office centre.
  final double distanceMetres;

  /// Allowed radius.
  final double radiusMetres;
}

/// A position was read but is too imprecise to decide.
class LocationImprecise extends LocationCheck {
  /// Creates the state.
  const LocationImprecise(this.accuracyMetres);

  /// Reported accuracy.
  final double accuracyMetres;
}

/// No position: permission, location services or no fix.
class LocationBlocked extends LocationCheck {
  /// Creates the state.
  const LocationBlocked(this.reason);

  /// Why.
  final LocationFailure reason;
}

// lib/models/location_reading.dart

import 'geo_position.dart';
import 'location_failure.dart';

/// Result of asking the device where it is.
sealed class LocationReading {
  const LocationReading();
}

/// A position was read.
class LocationFix extends LocationReading {
  /// Creates a fix.
  const LocationFix(this.position);

  /// Where the device is.
  final GeoPosition position;
}

/// No position could be read.
class LocationUnreadable extends LocationReading {
  /// Creates a failure.
  const LocationUnreadable(this.reason);

  /// Why.
  final LocationFailure reason;
}

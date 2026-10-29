// lib/policies/geofence_policy.dart

import 'dart:math' as math;

import '../constants/app_limits.dart';
import '../models/geo_position.dart';
import '../models/geofence_result.dart';
import '../models/office_location.dart';

/// Decides whether a position counts as "at the office".
class GeofencePolicy {
  static const double _earthRadiusMetres = 6371000;

  /// Compares [position] with [office]. Positions less accurate than
  /// [maxAccuracyMetres] are reported as inaccurate rather than guessed.
  GeofenceResult check(
    GeoPosition position,
    OfficeLocation office, {
    double maxAccuracyMetres = AppLimits.maxLocationAccuracyMetres,
  }) {
    final distance = distanceMetres(
      position.latitude,
      position.longitude,
      office.latitude,
      office.longitude,
    );
    if (position.accuracyMetres > maxAccuracyMetres) {
      return GeofenceInaccurate(
        distance,
        accuracyMetres: position.accuracyMetres,
      );
    }
    if (distance <= office.radiusMetres) return GeofenceInside(distance);
    return GeofenceOutside(distance, radiusMetres: office.radiusMetres);
  }

  /// Great-circle distance between two coordinates (haversine formula).
  double distanceMetres(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _radians(lat2 - lat1);
    final dLng = _radians(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_radians(lat1)) *
            math.cos(_radians(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusMetres * math.asin(math.sqrt(a));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}

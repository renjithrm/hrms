// lib/models/geofence_result.dart

/// Outcome of comparing a position with the office area.
sealed class GeofenceResult {
  const GeofenceResult(this.distanceMetres);

  /// Distance from the office centre.
  final double distanceMetres;
}

/// The position is inside the allowed radius.
class GeofenceInside extends GeofenceResult {
  /// Creates an inside result.
  const GeofenceInside(super.distanceMetres);
}

/// The position is outside the allowed radius.
class GeofenceOutside extends GeofenceResult {
  /// Creates an outside result.
  const GeofenceOutside(super.distanceMetres, {required this.radiusMetres});

  /// The allowed radius, for the message.
  final double radiusMetres;
}

/// The position is too inaccurate to decide.
class GeofenceInaccurate extends GeofenceResult {
  /// Creates an inaccurate result.
  const GeofenceInaccurate(super.distanceMetres,
      {required this.accuracyMetres});

  /// Reported accuracy radius.
  final double accuracyMetres;
}

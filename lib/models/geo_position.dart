// lib/models/geo_position.dart

/// A device position, independent of the location plugin.
class GeoPosition {
  /// Creates a position.
  const GeoPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
  });

  /// Latitude in decimal degrees.
  final double latitude;

  /// Longitude in decimal degrees.
  final double longitude;

  /// Horizontal accuracy radius reported by the device.
  final double accuracyMetres;
}

// lib/models/office_location.dart

/// The office whose surroundings count as "at work".
class OfficeLocation {
  /// Creates an office location.
  const OfficeLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMetres,
  });

  /// Reads the shape returned by `GET /employee/me`.
  factory OfficeLocation.fromJson(Map<String, dynamic> json) => OfficeLocation(
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMetres: (json['radiusMetres'] as num).toDouble(),
      );

  /// Display name, for example "Infopark Phase 1".
  final String name;

  /// Latitude in decimal degrees.
  final double latitude;

  /// Longitude in decimal degrees.
  final double longitude;

  /// Radius within which attendance is allowed.
  final double radiusMetres;

  /// Serialises to the API shape.
  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMetres': radiusMetres,
      };
}

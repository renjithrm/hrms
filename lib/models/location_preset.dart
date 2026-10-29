// lib/models/location_preset.dart

/// Fake locations reviewers can pick on the developer settings screen.
enum LocationPreset {
  /// Use the real device GPS.
  deviceGps(null),

  /// Exactly at the office.
  atOffice(0),

  /// Inside the area, close to the 200 m edge.
  nearEdge(190),

  /// Well outside the area.
  outside(850),

  /// GPS is switched off or finds no fix.
  unavailable(null),

  /// Permission denied, but the app may ask again.
  permissionDenied(null),

  /// Permission permanently denied; only system settings can fix it.
  permissionBlocked(null);

  const LocationPreset(this.distanceMetres);

  /// Simulated distance north of the office, for position presets.
  final double? distanceMetres;
}

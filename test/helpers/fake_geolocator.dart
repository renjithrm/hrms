import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Scriptable stand-in for the platform location plugin.
class FakeGeolocator extends GeolocatorPlatform {
  /// Whether location services are on.
  bool isServiceEnabled = true;

  /// Permission returned by `checkPermission`.
  LocationPermission permission = LocationPermission.whileInUse;

  /// Permission the person grants when asked.
  LocationPermission permissionAfterRequest = LocationPermission.whileInUse;

  /// Whether a fix arrives; false simulates a timeout.
  bool hasFix = true;

  /// How many times the app asked for permission.
  int permissionRequests = 0;

  /// How many times app settings were opened.
  int appSettingsOpened = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => isServiceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    permission = permissionAfterRequest;
    return permission;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (!hasFix) throw TimeoutException('No fix');
    return Position(
      latitude: 10.0160,
      longitude: 76.3419,
      timestamp: DateTime.utc(2026, 10, 28, 3),
      accuracy: 14,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async => true;
}

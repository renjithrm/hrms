// lib/services/location_service.dart

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../app/app.locator.dart';
import '../constants/app_limits.dart';
import '../models/geo_position.dart';
import '../models/location_failure.dart';
import '../models/location_preset.dart';
import '../models/location_reading.dart';
import '../models/office_location.dart';
import 'dev_settings_service.dart';

/// Reads the device position, handling permission and location-service
/// states. In debug builds a developer-settings preset replaces the GPS.
class LocationService {
  /// Creates the service. [platform] and [simulatedDelay] exist for tests.
  LocationService({
    GeolocatorPlatform? platform,
    Duration simulatedDelay = const Duration(milliseconds: 700),
  })  : _platform = platform ?? GeolocatorPlatform.instance,
        _simulatedDelay = simulatedDelay;

  static const double _metresPerDegreeLatitude = 111194.93;

  final GeolocatorPlatform _platform;
  final Duration _simulatedDelay;
  final _devSettings = locator<DevSettingsService>();

  /// Reads the current position. Asks for permission first when it has not
  /// been refused for good and [askPermission] is true.
  ///
  /// [office] is only used to place simulated positions.
  Future<LocationReading> read(
    OfficeLocation office, {
    bool askPermission = true,
  }) async {
    final preset = _devSettings.activePreset;
    if (preset != null) return _simulate(preset, office);

    if (!await _platform.isLocationServiceEnabled()) {
      return const LocationUnreadable(LocationFailure.serviceOff);
    }
    var permission = await _platform.checkPermission();
    if (permission == LocationPermission.denied && askPermission) {
      permission = await _platform.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        return const LocationUnreadable(LocationFailure.denied);
      case LocationPermission.deniedForever:
        return const LocationUnreadable(LocationFailure.deniedForever);
      case LocationPermission.whileInUse:
      case LocationPermission.always:
      case LocationPermission.unableToDetermine:
        break;
    }

    try {
      final position = await _platform.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: AppLimits.locationTimeout,
        ),
      );
      return LocationFix(
        GeoPosition(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMetres: position.accuracy,
        ),
      );
    } on LocationServiceDisabledException {
      return const LocationUnreadable(LocationFailure.serviceOff);
    } on TimeoutException {
      return const LocationUnreadable(LocationFailure.unavailable);
    } on PermissionDeniedException {
      return const LocationUnreadable(LocationFailure.denied);
    }
  }

  /// Opens this app's page in system settings.
  Future<bool> openAppSettings() => _platform.openAppSettings();

  /// Opens the system location settings.
  Future<bool> openLocationSettings() => _platform.openLocationSettings();

  Future<LocationReading> _simulate(
    LocationPreset preset,
    OfficeLocation office,
  ) async {
    await Future<void>.delayed(_simulatedDelay);
    final distance = preset.distanceMetres;
    if (distance != null) {
      return LocationFix(
        GeoPosition(
          latitude: office.latitude + distance / _metresPerDegreeLatitude,
          longitude: office.longitude,
          accuracyMetres: 12,
        ),
      );
    }
    return LocationUnreadable(switch (preset) {
      LocationPreset.permissionDenied => LocationFailure.denied,
      LocationPreset.permissionBlocked => LocationFailure.deniedForever,
      _ => LocationFailure.unavailable,
    });
  }
}

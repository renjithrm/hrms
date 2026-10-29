import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/models/location_failure.dart';
import 'package:rebs_hrms/models/location_preset.dart';
import 'package:rebs_hrms/models/location_reading.dart';
import 'package:rebs_hrms/policies/geofence_policy.dart';
import 'package:rebs_hrms/services/location_service.dart';

import '../helpers/fake_geolocator.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_helpers.dart';

void main() {
  final office = testEmployee.office;

  group('LocationService -', () {
    late FakeGeolocator platform;

    setUp(() {
      registerServices();
      platform = FakeGeolocator();
    });
    tearDown(() => locator.reset());

    LocationService service() =>
        LocationService(platform: platform, simulatedDelay: Duration.zero);

    group('device GPS -', () {
      test('returns the position when allowed', () async {
        final reading = await service().read(office) as LocationFix;
        expect(reading.position.accuracyMetres, 14);
      });

      test('reports location services switched off', () async {
        platform.isServiceEnabled = false;
        final reading = await service().read(office) as LocationUnreadable;
        expect(reading.reason, LocationFailure.serviceOff);
      });

      test('asks for permission once, and reports a refusal', () async {
        platform
          ..permission = LocationPermission.denied
          ..permissionAfterRequest = LocationPermission.denied;
        final reading = await service().read(office) as LocationUnreadable;
        expect(reading.reason, LocationFailure.denied);
        expect(platform.permissionRequests, 1);
      });

      test('does not ask when told not to', () async {
        platform.permission = LocationPermission.denied;
        await service().read(office, askPermission: false);
        expect(platform.permissionRequests, 0);
      });

      test('never asks again after a permanent refusal', () async {
        platform.permission = LocationPermission.deniedForever;
        final reading = await service().read(office) as LocationUnreadable;
        expect(reading.reason, LocationFailure.deniedForever);
        expect(platform.permissionRequests, 0);
      });

      test('reports no fix within the time limit as unavailable', () async {
        platform.hasFix = false;
        final reading = await service().read(office) as LocationUnreadable;
        expect(reading.reason, LocationFailure.unavailable);
      });
    });

    group('developer presets -', () {
      void usePreset(LocationPreset preset) {
        final devSettings = getAndRegisterDevSettingsService();
        when(devSettings.activePreset).thenReturn(preset);
      }

      test('"outside" is about 850 m from the office', () async {
        usePreset(LocationPreset.outside);
        final reading = await service().read(office) as LocationFix;
        final distance = GeofencePolicy().distanceMetres(
          reading.position.latitude,
          reading.position.longitude,
          office.latitude,
          office.longitude,
        );
        expect(distance, closeTo(850, 1));
      });

      test('"permission blocked" never touches the platform', () async {
        usePreset(LocationPreset.permissionBlocked);
        platform.permission = LocationPermission.whileInUse;
        final reading = await service().read(office) as LocationUnreadable;
        expect(reading.reason, LocationFailure.deniedForever);
      });

      test('"GPS unavailable" reports unavailable', () async {
        usePreset(LocationPreset.unavailable);
        final reading = await service().read(office) as LocationUnreadable;
        expect(reading.reason, LocationFailure.unavailable);
      });
    });
  });
}

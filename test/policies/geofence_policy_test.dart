import 'package:flutter_test/flutter_test.dart';
import 'package:rebs_hrms/models/geo_position.dart';
import 'package:rebs_hrms/models/geofence_result.dart';
import 'package:rebs_hrms/models/office_location.dart';
import 'package:rebs_hrms/policies/geofence_policy.dart';

void main() {
  final policy = GeofencePolicy();
  const office = OfficeLocation(
    name: 'Infopark Phase 1',
    latitude: 10.0159,
    longitude: 76.3419,
    radiusMetres: 200,
  );
  // One degree of latitude is about 111,195 m on the policy's sphere.
  const metresPerDegree = 111194.93;

  GeoPosition northOfOffice(double metres, {double accuracy = 10}) =>
      GeoPosition(
        latitude: office.latitude + metres / metresPerDegree,
        longitude: office.longitude,
        accuracyMetres: accuracy,
      );

  group('GeofencePolicy -', () {
    test('199 m from the office is inside', () {
      final result = policy.check(northOfOffice(199), office);
      expect(result, isA<GeofenceInside>());
      expect(result.distanceMetres, closeTo(199, 0.5));
    });

    test('201 m from the office is outside', () {
      final result = policy.check(northOfOffice(201), office);
      expect(result, isA<GeofenceOutside>());
    });

    test('a position less accurate than 100 m is not trusted', () {
      final result = policy.check(northOfOffice(20, accuracy: 150), office);
      expect(result, isA<GeofenceInaccurate>());
    });

    test('distance between identical points is zero', () {
      expect(policy.distanceMetres(10, 76, 10, 76), 0);
    });
  });
}

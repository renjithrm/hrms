import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/constants/app_strings.dart';
import 'package:rebs_hrms/models/location_failure.dart';
import 'package:rebs_hrms/ui/bottom_sheets/location_permission/location_permission_sheet_model.dart';
import 'package:stacked_services/stacked_services.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('LocationPermissionSheetModel -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    test('permanently denied: opens app settings, then asks to re-read',
        () async {
      final location = getAndRegisterLocationService();
      when(location.openAppSettings()).thenAnswer((_) async => true);
      SheetResponse? response;

      final model = LocationPermissionSheetModel(LocationFailure.deniedForever);
      await model.onPrimary((r) => response = r);

      verify(location.openAppSettings()).called(1);
      expect(response?.confirmed, isTrue);
      expect(model.steps, hasLength(3));
      expect(model.primaryLabel, AppStrings.sheetOpenSettings);
    });

    test('location services off: opens location settings', () async {
      final location = getAndRegisterLocationService();
      when(location.openLocationSettings()).thenAnswer((_) async => true);

      await LocationPermissionSheetModel(LocationFailure.serviceOff)
          .onPrimary((_) {});

      verify(location.openLocationSettings()).called(1);
    });

    test('denied: no settings page, the caller asks for permission', () async {
      final location = getAndRegisterLocationService();
      SheetResponse? response;

      final model = LocationPermissionSheetModel(LocationFailure.denied);
      await model.onPrimary((r) => response = r);

      verifyZeroInteractions(location);
      expect(response?.confirmed, isTrue);
      expect(model.steps, isEmpty);
    });

    test('"Not now" closes without a re-read', () {
      SheetResponse? response;
      LocationPermissionSheetModel(LocationFailure.denied)
          .onDismiss((r) => response = r);
      expect(response?.confirmed, isFalse);
    });
  });
}

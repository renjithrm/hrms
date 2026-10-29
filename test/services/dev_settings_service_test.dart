import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/app/config/app_config.dart';
import 'package:rebs_hrms/app/config/dev_config.dart';
import 'package:rebs_hrms/app/config/prod_config.dart';
import 'package:rebs_hrms/exceptions/offline_exception.dart';
import 'package:rebs_hrms/models/location_preset.dart';
import 'package:rebs_hrms/services/dev_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DevSettingsService -', () {
    setUp(() {
      registerServices();
      SharedPreferences.setMockInitialValues({});
    });
    tearDown(() => locator.reset());

    test('restores the saved preset and scenario', () async {
      SharedPreferences.setMockInitialValues({
        'dev.location_preset': 'outside',
        'dev.mock_scenario': 'slow',
      });
      final service = DevSettingsService(isAvailable: true);
      await service.load();
      expect(service.preset, LocationPreset.outside);
      expect(service.scenario, 'slow');
    });

    test('device GPS means no simulated location', () async {
      final service = DevSettingsService(isAvailable: true);
      expect(service.activePreset, isNull);
      await service.setPreset(LocationPreset.atOffice);
      expect(service.activePreset, LocationPreset.atOffice);
    });

    test('presets are ignored when the screen is not available', () async {
      final service = DevSettingsService(isAvailable: false);
      await service.setPreset(LocationPreset.outside);
      expect(service.activePreset, isNull);
    });

    test('setScenario tells the server, then remembers it', () async {
      final api = getAndRegisterApiService();
      when(api.setMockScenario(any)).thenAnswer((_) async {});
      final service = DevSettingsService(isAvailable: true);

      await service.setScenario('server_error');

      verify(api.setMockScenario('server_error')).called(1);
      expect(service.scenario, 'server_error');
    });

    test('a scenario the server did not accept is not remembered', () async {
      final api = getAndRegisterApiService();
      when(api.setMockScenario(any)).thenThrow(const OfflineException());
      final service = DevSettingsService(isAvailable: true);

      await expectLater(
        service.setScenario('slow'),
        throwsA(isA<OfflineException>()),
      );
      expect(service.scenario, 'success');
    });

    test('resetMock returns to the success scenario', () async {
      final api = getAndRegisterApiService();
      when(api.setMockScenario(any)).thenAnswer((_) async {});
      when(api.resetMock()).thenAnswer((_) async {});
      final service = DevSettingsService(isAvailable: true);
      await service.setScenario('slow');

      await service.resetMock();

      expect(service.scenario, 'success');
    });

    test('clearToday clears the server first, then this phone', () async {
      final api = getAndRegisterApiService();
      final attendance = getAndRegisterAttendanceService();
      final sync = getAndRegisterSyncService();
      when(api.clearMockToday()).thenAnswer((_) async {});
      when(attendance.clearToday()).thenAnswer((_) async {});
      when(sync.reload()).thenAnswer((_) async {});

      await DevSettingsService(isAvailable: true).clearToday();

      verifyInOrder([
        api.clearMockToday(),
        attendance.clearToday(),
        sync.reload(),
      ]);
    });

    test('clearToday changes nothing here when the server fails', () async {
      final api = getAndRegisterApiService();
      final attendance = getAndRegisterAttendanceService();
      when(api.clearMockToday()).thenThrow(const OfflineException());

      await expectLater(
        DevSettingsService(isAvailable: true).clearToday(),
        throwsA(isA<OfflineException>()),
      );
      verifyNever(attendance.clearToday());
    });

    test('availability follows the flavour config', () {
      addTearDown(() => AppConfig.initialise(devConfig));

      AppConfig.initialise(devConfig);
      expect(DevSettingsService().isAvailable, isTrue);

      AppConfig.initialise(prodConfig);
      expect(DevSettingsService().isAvailable, isFalse);
    });
  });
}

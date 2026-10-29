import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rebs_hrms/app/app.locator.dart';
import 'package:rebs_hrms/constants/app_strings.dart';
import 'package:rebs_hrms/exceptions/offline_exception.dart';
import 'package:rebs_hrms/exceptions/server_exception.dart';
import 'package:rebs_hrms/models/location_preset.dart';
import 'package:rebs_hrms/ui/views/dev_settings/dev_settings_viewmodel.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DevSettingsViewModel -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());

    test('init reads the scenario from the server', () async {
      final devSettings = getAndRegisterDevSettingsService();
      when(devSettings.loadScenarioFromServer()).thenAnswer((_) async {});

      final model = DevSettingsViewModel();
      await model.init();

      verify(devSettings.loadScenarioFromServer()).called(1);
      expect(model.hasError, isFalse);
    });

    test('init shows how to start the mock API when it is down', () async {
      final devSettings = getAndRegisterDevSettingsService();
      when(devSettings.loadScenarioFromServer())
          .thenThrow(const OfflineException());

      final model = DevSettingsViewModel();
      await model.init();

      expect(model.hasError, isTrue);
      expect(model.isBusy, isFalse);
      expect(model.errorMessage, AppStrings.devMockUnreachable);
    });

    test('selecting a scenario confirms it with a snackbar', () async {
      final devSettings = getAndRegisterDevSettingsService();
      final snackbar = getAndRegisterSnackbarService();
      when(devSettings.setScenario(any)).thenAnswer((_) async {});

      await DevSettingsViewModel().selectScenario('slow');

      verify(devSettings.setScenario('slow')).called(1);
      verify(
        snackbar.showSnackbar(message: AppStrings.devScenarioSet('slow')),
      ).called(1);
    });

    test('selecting a preset stores it', () async {
      final devSettings = getAndRegisterDevSettingsService();
      when(devSettings.setPreset(any)).thenAnswer((_) async {});

      await DevSettingsViewModel().selectPreset(LocationPreset.outside);

      verify(devSettings.setPreset(LocationPreset.outside)).called(1);
    });

    test('office falls back to the build configuration', () {
      final model = DevSettingsViewModel();
      expect(model.officeLabel, contains('200 m'));
    });

    test('clearing today confirms it with a snackbar', () async {
      final devSettings = getAndRegisterDevSettingsService();
      final snackbar = getAndRegisterSnackbarService();
      when(devSettings.clearToday()).thenAnswer((_) async {});

      final model = DevSettingsViewModel();
      await model.clearToday();

      verify(devSettings.clearToday()).called(1);
      verify(
        snackbar.showSnackbar(message: AppStrings.devClearTodayDone),
      ).called(1);
      expect(model.hasError, isFalse);
    });

    test('clearing today with the mock API down shows the hint', () async {
      final devSettings = getAndRegisterDevSettingsService();
      when(devSettings.clearToday()).thenThrow(const OfflineException());

      final model = DevSettingsViewModel();
      await model.clearToday();

      expect(model.errorMessage, AppStrings.devMockUnreachable);
      expect(model.isBusy, isFalse);
    });

    test('a mock server without the endpoint says to restart it', () async {
      final devSettings = getAndRegisterDevSettingsService();
      when(devSettings.clearToday()).thenThrow(const ServerException(404));

      final model = DevSettingsViewModel();
      await model.clearToday();

      expect(model.errorMessage, AppStrings.devMockOutdated);
    });
  });
}

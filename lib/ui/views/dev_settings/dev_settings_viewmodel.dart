// lib/ui/views/dev_settings/dev_settings_viewmodel.dart

import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/config/app_config.dart';
import '../../../constants/app_strings.dart';
import '../../../exceptions/server_exception.dart';
import '../../../extensions/error_message_extension.dart';
import '../../../models/location_preset.dart';
import '../../../services/dev_settings_service.dart';
import '../../../services/employee_service.dart';
import '../../../services/logger_service.dart';

/// Lets reviewers fake the location and switch mock API scenarios.
class DevSettingsViewModel extends ReactiveViewModel {
  final _navigationService = locator<NavigationService>();
  final _snackbarService = locator<SnackbarService>();
  final _devSettings = locator<DevSettingsService>();
  final _employeeService = locator<EmployeeService>();
  final _logger = locator<LoggerService>();

  @override
  List<ListenableServiceMixin> get listenableServices =>
      [_devSettings, _employeeService];

  /// Presets in display order.
  List<LocationPreset> get presets => LocationPreset.values;

  /// Selected preset.
  LocationPreset get selectedPreset => _devSettings.preset;

  /// Scenario names in display order.
  List<String> get scenarios => DevSettingsService.scenarios;

  /// Scenario last confirmed by the server.
  String get selectedScenario => _devSettings.scenario;

  /// Message shown when a mock API action failed: restart it if it doesn't
  /// know the endpoint (404), otherwise start it.
  String? get errorMessage {
    if (!hasError) return null;
    final Object? error = modelError;
    if (error is ServerException && error.statusCode == 404) {
      return AppStrings.devMockOutdated;
    }
    return AppStrings.devMockUnreachable;
  }

  /// Office coordinates and radius, or a note that they are not loaded.
  String get officeLabel {
    final office = _employeeService.employee?.office;
    if (office == null) {
      final config = AppConfig.current;
      return '${config.officeLatitude}, ${config.officeLongitude} · '
          '${config.officeRadiusMetres.round()} m';
    }
    return '${office.latitude}, ${office.longitude} · '
        '${office.radiusMetres.round()} m';
  }

  /// Company timezone in use.
  String get timezoneLabel =>
      _employeeService.employee?.timezone ?? AppConfig.current.companyTimezone;

  /// API base URL in use.
  String get apiLabel => _devSettings.apiBaseUrl;

  /// Display label for [preset].
  String labelFor(LocationPreset preset) => switch (preset) {
        LocationPreset.deviceGps => AppStrings.devPresetDeviceGps,
        LocationPreset.atOffice => AppStrings.devPresetAtOffice,
        LocationPreset.nearEdge => AppStrings.devPresetNearEdge,
        LocationPreset.outside => AppStrings.devPresetOutside,
        LocationPreset.unavailable => AppStrings.devPresetUnavailable,
        LocationPreset.permissionDenied => AppStrings.devPresetDenied,
        LocationPreset.permissionBlocked => AppStrings.devPresetBlocked,
      };

  /// Reads the server's active scenario.
  Future<void> init() => _run(_devSettings.loadScenarioFromServer);

  /// Selects a location preset. Stored locally; no network needed.
  Future<void> selectPreset(LocationPreset? preset) async {
    if (preset == null) return;
    await _devSettings.setPreset(preset);
  }

  /// Switches the mock server's scenario.
  Future<void> selectScenario(String name) => _run(
        () => _devSettings.setScenario(name),
        success: AppStrings.devScenarioSet(name),
      );

  /// Restores the mock server's seed data.
  Future<void> resetMockData() =>
      _run(_devSettings.resetMock, success: AppStrings.devResetDone);

  /// Removes today's attendance here and on the mock server.
  Future<void> clearToday() =>
      _run(_devSettings.clearToday, success: AppStrings.devClearTodayDone);

  /// Returns to the previous screen.
  void onBackPressed() => _navigationService.back();

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    clearErrors();
    setBusy(true);
    try {
      await action();
      if (success != null) _snackbarService.showSnackbar(message: success);
    } catch (e, stackTrace) {
      _logger.error('Developer settings: ${e.userMessage}', e, stackTrace);
      setError(e);
    } finally {
      setBusy(false);
    }
  }
}

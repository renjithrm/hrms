// lib/services/dev_settings_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked/stacked.dart';

import '../app/app.locator.dart';
import '../app/config/app_config.dart';
import '../models/location_preset.dart';
import 'api_service.dart';
import 'attendance_service.dart';
import 'sync_service.dart';

/// Reviewer tools: a fake location and the mock API scenario. Available when
/// the flavour's `AppConfig.isDevSettingsEnabled` is true (dev); elsewhere
/// every setting is inert.
class DevSettingsService with ListenableServiceMixin {
  /// Creates the service. [isAvailable] exists for tests.
  DevSettingsService({bool? isAvailable})
      : isAvailable = isAvailable ?? AppConfig.current.isDevSettingsEnabled;

  /// Scenario names understood by the mock server.
  static const List<String> scenarios = [
    'success',
    'slow',
    'timeout_after_commit',
    'server_error',
    'attendance_conflict',
    'leave_rejected',
  ];

  static const String _presetKey = 'dev.location_preset';
  static const String _scenarioKey = 'dev.mock_scenario';

  final _api = locator<ApiService>();
  // Resolved on use: LocationService depends on this service, and
  // AttendanceService on LocationService.
  AttendanceService get _attendance => locator<AttendanceService>();
  SyncService get _sync => locator<SyncService>();

  /// Whether developer settings exist in this flavour.
  final bool isAvailable;

  LocationPreset _preset = LocationPreset.deviceGps;
  String _scenario = scenarios.first;

  /// Selected location preset.
  LocationPreset get preset => _preset;

  /// Preset that should replace the device GPS, or null to use the GPS.
  LocationPreset? get activePreset =>
      isAvailable && _preset != LocationPreset.deviceGps ? _preset : null;

  /// Scenario last confirmed by the mock server.
  String get scenario => _scenario;

  /// Base URL of the API, for display.
  String get apiBaseUrl => _api.baseUrl;

  /// Restores saved choices. Call once at startup.
  Future<void> load() async {
    if (!isAvailable) return;
    final prefs = await SharedPreferences.getInstance();
    _preset = LocationPreset.values.asNameMap()[prefs.getString(_presetKey)] ??
        LocationPreset.deviceGps;
    _scenario = prefs.getString(_scenarioKey) ?? scenarios.first;
    notifyListeners();
  }

  /// Reads the active scenario from the server, which may have restarted.
  Future<void> loadScenarioFromServer() async {
    final name = await _api.fetchMockScenario();
    await _saveScenario(name);
  }

  /// Selects a location preset.
  Future<void> setPreset(LocationPreset preset) async {
    _preset = preset;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_presetKey, preset.name);
  }

  /// Switches the mock server's scenario. Throws if the server refuses.
  Future<void> setScenario(String name) async {
    await _api.setMockScenario(name);
    await _saveScenario(name);
  }

  /// Restores the mock server's seed data and the `success` scenario.
  Future<void> resetMock() async {
    await _api.resetMock();
    await _saveScenario(scenarios.first);
  }

  /// Clears today's attendance on the mock server first, then on this
  /// phone, so the next refresh doesn't bring it back.
  Future<void> clearToday() async {
    await _api.clearMockToday();
    await _attendance.clearToday();
    await _sync.reload();
  }

  Future<void> _saveScenario(String name) async {
    _scenario = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scenarioKey, name);
  }
}

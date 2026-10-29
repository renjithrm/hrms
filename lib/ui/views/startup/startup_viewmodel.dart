// lib/ui/views/startup/startup_viewmodel.dart

import 'dart:async';

import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../extensions/error_message_extension.dart';
import '../../../services/app_lifecycle_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/dev_settings_service.dart';
import '../../../services/employee_service.dart';
import '../../../services/logger_service.dart';
import '../../../services/outbox_service.dart';
import '../../../services/sync_service.dart';

/// Opens the app from the local cache when possible, so it starts offline.
/// Only the very first launch needs the network.
class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _connectivityService = locator<ConnectivityService>();
  final _appLifecycleService = locator<AppLifecycleService>();
  final _devSettingsService = locator<DevSettingsService>();
  final _employeeService = locator<EmployeeService>();
  final _outboxService = locator<OutboxService>();
  final _syncService = locator<SyncService>();
  final _logger = locator<LoggerService>();

  /// Message for the error state, when the first launch fails.
  String? get errorMessage {
    final Object? error = modelError;
    return error?.userMessage;
  }

  /// Starts listeners, loads the employee and opens the main screen.
  Future<void> runStartupLogic() async {
    clearErrors();
    setBusy(true);
    try {
      await _connectivityService.start();
      _appLifecycleService.start();
      await _devSettingsService.load();
      // Sends interrupted by a killed app are retried, never lost.
      await _outboxService.resetStuckSyncing();
      // Sends whatever was saved offline, and keeps doing so on resume and
      // reconnect.
      await _syncService.start();

      final cached = await _employeeService.loadCached();
      if (cached != null) {
        // Open immediately; refresh quietly in the background.
        unawaited(_refreshInBackground());
      } else {
        await _employeeService.refresh();
      }
      await _navigationService.replaceWithMainView();
    } catch (e, stackTrace) {
      _logger.error('Startup', e, stackTrace);
      setError(e);
    } finally {
      setBusy(false);
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      await _employeeService.refresh();
    } catch (e, stackTrace) {
      // The cached copy keeps the app usable; screens show its age.
      _logger.error('Background employee refresh', e, stackTrace);
    }
  }
}

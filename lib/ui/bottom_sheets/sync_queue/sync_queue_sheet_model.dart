// lib/ui/bottom_sheets/sync_queue/sync_queue_sheet_model.dart

import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';

import '../../../app/app.locator.dart';
import '../../../constants/app_strings.dart';
import '../../../models/attendance_event.dart';
import '../../../models/attendance_event_type.dart';
import '../../../models/sync_state.dart';
import '../../../services/clock_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/logger_service.dart';
import '../../../services/sync_service.dart';

/// Screen G: what is on this phone and where each entry is on its way to
/// the server.
class SyncQueueSheetModel extends ReactiveViewModel {
  final _sync = locator<SyncService>();
  final _connectivity = locator<ConnectivityService>();
  final _clock = locator<ClockService>();
  final _logger = locator<LoggerService>();

  final _when = DateFormat('E d MMM, HH:mm');
  final _time = DateFormat('HH:mm');
  final Set<String> _revealed = {};

  @override
  List<ListenableServiceMixin> get listenableServices => [
        _sync,
        _connectivity,
      ];

  /// Timeline entries, oldest first.
  List<AttendanceEvent> get rows => _sync.queue;

  /// Whether a sync is running.
  bool get isSyncing => _sync.isSyncing;

  /// Whether "Sync now" can be pressed: something waits and no sync runs.
  bool get canSyncNow => !isSyncing && _sync.waitingCount > 0;

  /// "Sync now" or "Syncing…".
  String get syncButtonLabel =>
      isSyncing ? AppStrings.syncingNow : AppStrings.syncNow;

  /// One line under the title.
  String get subtitle {
    if (rows.isEmpty) return AppStrings.syncSheetEmpty;
    final waiting = _sync.waitingCount;
    if (waiting == 0) return AppStrings.syncSheetAllDone;
    if (!_connectivity.isOnline) return AppStrings.syncSheetOffline;
    return AppStrings.syncSheetWaiting(waiting);
  }

  /// "Check-in · Wed 28 Oct, 09:02".
  String titleOf(AttendanceEvent event) => AppStrings.eventTitle(
        event.type == AttendanceEventType.checkIn
            ? AppStrings.eventCheckIn
            : AppStrings.eventCheckOut,
        _when.format(_clock.toCompany(event.occurredAt)),
      );

  /// Where the entry is: waiting, retrying, sending, synced, or the
  /// server's reason for refusing it.
  String statusOf(AttendanceEvent event) => switch (event.status) {
        SyncState.pending => switch (event.nextAttemptAt) {
            final DateTime at when at.isAfter(_clock.nowUtc()) =>
              AppStrings.eventRetryAt(_time.format(_clock.toCompany(at))),
            _ => AppStrings.eventWaiting,
          },
        SyncState.syncing => AppStrings.eventSending,
        SyncState.synced => AppStrings.eventSynced,
        SyncState.rejected => event.lastError ?? AppStrings.eventRejected,
      };

  /// Whether the entry's event ID is shown.
  bool isRevealed(AttendanceEvent event) => _revealed.contains(event.eventId);

  /// Shows or hides the event ID (long-press), for support conversations.
  void toggleReveal(AttendanceEvent event) {
    if (!_revealed.remove(event.eventId)) _revealed.add(event.eventId);
    notifyListeners();
  }

  /// Sends everything waiting now, without waiting for the backoff.
  Future<void> syncNow() async {
    if (!canSyncNow) return;
    try {
      await _sync.syncNow(ignoreBackoff: true);
    } catch (e, stackTrace) {
      _logger.error('Sync now', e, stackTrace);
      setError(e);
    }
  }

  /// Removes a rejected entry from the list.
  Future<void> dismiss(AttendanceEvent event) async {
    if (event.status != SyncState.rejected) return;
    try {
      await _sync.dismiss(event.eventId);
    } catch (e, stackTrace) {
      _logger.error('Dismiss', e, stackTrace);
      setError(e);
    }
  }
}

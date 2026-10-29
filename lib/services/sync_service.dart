// lib/services/sync_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';
import 'package:stacked/stacked.dart';

import '../app/app.locator.dart';
import '../exceptions/api_exception.dart';
import '../extensions/error_message_extension.dart';
import '../models/attendance_event.dart';
import '../models/attendance_record.dart';
import '../models/sync_state.dart';
import '../models/sync_summary.dart';
import 'api_service.dart';
import 'app_lifecycle_service.dart';
import 'clock_service.dart';
import 'connectivity_service.dart';
import 'database_service.dart';
import 'logger_service.dart';
import 'outbox_service.dart';

/// Sends the outbox to the server.
///
/// - One sync at a time: a call while one runs makes it go round once more.
/// - Events go in `seq` order, and the run stops at the first event that
///   stays pending, so a check-out never overtakes its check-in.
/// - 200/201 (including an idempotent replay) → synced. 409/422 → rejected
///   with the server's reason, and the run moves on. Timeout, 5xx or
///   offline → pending, retried after an exponential backoff.
/// - Runs at start-up, on resume, when the network comes back, on pull to
///   refresh, from "Sync now", and when a backoff expires.
class SyncService with ListenableServiceMixin {
  final _api = locator<ApiService>();
  final _database = locator<DatabaseService>();
  final _outbox = locator<OutboxService>();
  final _clock = locator<ClockService>();
  final _connectivity = locator<ConnectivityService>();
  final _lifecycle = locator<AppLifecycleService>();
  final _logger = locator<LoggerService>();

  /// Wait before the first retry; doubles each attempt.
  static const Duration firstBackoff = Duration(seconds: 5);

  /// Longest wait between retries.
  static const Duration maxBackoff = Duration(minutes: 5);

  Future<void>? _running;
  bool _runAgain = false;
  bool _ignoreBackoffAgain = false;
  bool _isSyncing = false;
  Timer? _retryTimer;
  final List<StreamSubscription<void>> _subscriptions = [];

  List<AttendanceEvent> _queue = const [];
  int _waiting = 0;
  int _rejected = 0;

  /// Recent events for the sync timeline, oldest first.
  List<AttendanceEvent> get queue => _queue;

  /// Events not yet on the server.
  int get waitingCount => _waiting;

  /// Rejected events the person hasn't dismissed.
  int get rejectedCount => _rejected;

  /// Whether a sync is running.
  bool get isSyncing => _isSyncing;

  /// What the sync pill shows.
  SyncSummary get summary {
    if (_isSyncing) return const SyncInProgress();
    if (_rejected > 0) return SyncNeedsAttention(_rejected);
    if (_waiting > 0) return SyncWaiting(_waiting);
    if (!_connectivity.isOnline) return const SyncOffline();
    return const SyncAllSynced();
  }

  /// Loads the queue and starts the automatic triggers, then syncs once.
  Future<void> start() async {
    if (_subscriptions.isEmpty) {
      _subscriptions
        ..add(_connectivity.backOnline$.listen((_) => syncNow()))
        ..add(_lifecycle.resumed$.listen((_) => syncNow()));
    }
    await _reload();
    unawaited(syncNow());
  }

  /// Stops the triggers and any scheduled retry.
  Future<void> stop() async {
    _retryTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Sends everything that is due. With [ignoreBackoff] ("Sync now") events
  /// waiting for a retry go too. Completes when the queue is drained or
  /// blocked.
  Future<void> syncNow({bool ignoreBackoff = false}) {
    final running = _running;
    if (running != null) {
      _runAgain = true;
      _ignoreBackoffAgain |= ignoreBackoff;
      return running;
    }
    final run = _run(ignoreBackoff);
    _running = run;
    return run.whenComplete(() => _running = null);
  }

  /// Re-reads the queue, after the outbox was changed outside a sync.
  Future<void> reload() => _reload();

  /// Removes a rejected event from the list.
  Future<void> dismiss(String eventId) async {
    await _outbox.dismiss(eventId);
    await _reload();
  }

  Future<void> _run(bool ignoreBackoff) async {
    _isSyncing = true;
    notifyListeners();
    try {
      var force = ignoreBackoff;
      do {
        _runAgain = false;
        _ignoreBackoffAgain = false;
        await _drain(ignoreBackoff: force);
        force = _ignoreBackoffAgain;
      } while (_runAgain);
    } catch (e, stackTrace) {
      _logger.error('Sync', e, stackTrace);
    } finally {
      _isSyncing = false;
      await _reload();
    }
  }

  Future<void> _drain({required bool ignoreBackoff}) async {
    if (!_connectivity.isOnline) return;
    while (true) {
      final event = await _outbox.nextPending();
      if (event == null) return;
      final due = event.nextAttemptAt;
      if (!ignoreBackoff && due != null && due.isAfter(_clock.nowUtc())) {
        _scheduleRetry(due);
        return;
      }
      if (!await _send(event)) return;
      await _reload();
    }
  }

  // Returns false when the event stays pending and the run must stop.
  Future<bool> _send(AttendanceEvent event) async {
    final attempt = event.copyWith(
      status: SyncState.syncing,
      attempts: event.attempts + 1,
    );
    await _outbox.update(attempt);
    await _reload();
    try {
      final submission = await _api.submitAttendanceEvent(event);
      // Cache first: if the app dies before the status write, the event is
      // reset to pending at start-up and the server replays it.
      await _cache(submission.record);
      await _outbox.update(attempt.copyWith(status: SyncState.synced));
      return true;
    } on ApiException catch (e, stackTrace) {
      _logger.error('Send ${event.type.wireValue}', e, stackTrace);
      if (!e.isRetryable) {
        await _outbox.update(
          attempt.copyWith(
            status: SyncState.rejected,
            lastError: e.userMessage,
          ),
        );
        return true;
      }
      final retryAt = _clock.nowUtc().add(backoffFor(attempt.attempts));
      await _outbox.update(
        attempt.copyWith(status: SyncState.pending, nextAttemptAt: retryAt),
      );
      _scheduleRetry(retryAt);
      return false;
    }
  }

  /// Wait before retry number [attempts]: 5 s, 10 s, 20 s… up to 5 min.
  static Duration backoffFor(int attempts) {
    final seconds =
        firstBackoff.inSeconds * math.pow(2, math.max(0, attempts - 1));
    return Duration(seconds: math.min(seconds.toInt(), maxBackoff.inSeconds));
  }

  void _scheduleRetry(DateTime at) {
    _retryTimer?.cancel();
    final wait = at.difference(_clock.nowUtc());
    _retryTimer = Timer(wait.isNegative ? Duration.zero : wait, syncNow);
  }

  Future<void> _cache(AttendanceRecord record) => _database.db.insert(
        'attendance',
        {
          'work_date': record.workDate,
          'month': record.workDate.substring(0, 7),
          'json': jsonEncode(record.toJson()),
          'updated_at': _clock.nowUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> _reload() async {
    _queue = await _outbox.recentEvents();
    final counts = await _outbox.counts();
    _waiting = counts.waiting;
    _rejected = counts.rejected;
    notifyListeners();
  }
}

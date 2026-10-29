// lib/services/attendance_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:stacked/stacked.dart';
import 'package:uuid/uuid.dart';

import '../app/app.locator.dart';
import '../extensions/date_time_extensions.dart';
import '../models/attendance_day.dart';
import '../models/attendance_event.dart';
import '../models/attendance_event_type.dart';
import '../models/attendance_outcome.dart';
import '../models/attendance_record.dart';
import '../models/attendance_rule_violation.dart';
import '../models/geo_position.dart';
import '../models/geofence_result.dart';
import '../models/location_reading.dart';
import '../models/office_location.dart';
import '../models/sync_state.dart';
import '../policies/attendance_policy.dart';
import '../policies/geofence_policy.dart';
import 'api_service.dart';
import 'clock_service.dart';
import 'database_service.dart';
import 'location_service.dart';
import 'logger_service.dart';
import 'outbox_service.dart';
import 'sync_service.dart';

/// Today's attendance and recent history, merged from the server cache and
/// the device's outbox so the screen is right even offline. Also records
/// check-in and check-out.
class AttendanceService with ListenableServiceMixin {
  final _api = locator<ApiService>();
  final _database = locator<DatabaseService>();
  final _outbox = locator<OutboxService>();
  final _clock = locator<ClockService>();
  final _location = locator<LocationService>();
  final _geofence = locator<GeofencePolicy>();
  final _policy = locator<AttendancePolicy>();
  final _sync = locator<SyncService>();
  final _logger = locator<LoggerService>();
  final _uuid = const Uuid();

  /// Creates the service and keeps today's view in step with sync
  /// progress.
  AttendanceService() {
    _sync.addListener(_onSyncChanged);
  }

  // Check-in and check-out run one at a time, so a double tap can't race
  // past the rules.
  Future<void> _actions = Future.value();

  /// How many days the Today screen lists.
  static const int recentCount = 5;

  static const String _updatedKey = 'attendance_updated_at';

  AttendanceDay? _today;
  List<AttendanceDay> _recent = const [];
  DateTime? _lastUpdated;

  /// Today's attendance, or null before the first check-in.
  AttendanceDay? get today => _today;

  /// Latest days with attendance, newest first, today included.
  List<AttendanceDay> get recent => _recent;

  /// When the history was last refreshed from the server.
  DateTime? get lastUpdated => _lastUpdated;

  /// Whether any history has ever been downloaded.
  bool get hasCache => _lastUpdated != null;

  /// Loads what is stored on the device. Never touches the network.
  Future<void> loadCached() async {
    _lastUpdated = await _database.readTimestamp(_updatedKey);
    await _rebuild();
  }

  /// Downloads this month (and last month, early in a month) and replaces
  /// the cached copy. Throws the API's typed exception on failure.
  Future<void> refresh() async {
    final today = _clock.companyToday();
    final months = [today.isoMonth];
    final records = await _api.fetchAttendance(today.isoMonth);
    if (records.length < recentCount) {
      final previous = DateTime.utc(today.year, today.month - 1).isoMonth;
      months.add(previous);
      records.addAll(await _api.fetchAttendance(previous));
    }

    final now = _clock.nowUtc();
    await _store(months, records, now, alsoMarkRecent: true);
    _lastUpdated = now;
    await _rebuild();
  }

  /// One month as stored on the device: server records merged with local
  /// events, oldest first, and when the month was last downloaded (null if
  /// never). [month] is `yyyy-MM`. Never touches the network.
  Future<({List<AttendanceDay> days, DateTime? updatedAt})> cachedMonth(
    String month,
  ) async {
    final rows = await _database.db.query(
      'attendance',
      where: 'month = ?',
      whereArgs: [month],
    );
    final records = {
      for (final row in rows)
        row['work_date'] as String: AttendanceRecord.fromJson(
          jsonDecode(row['json'] as String) as Map<String, dynamic>,
        ),
    };
    final events = await _outbox.activeEventsInMonth(month);
    final dates = {...records.keys, ...events.map((e) => e.workDate)}.toList()
      ..sort();
    return (
      days: [
        for (final date in dates)
          _merge(
            date,
            records[date],
            events.where((e) => e.workDate == date).toList(),
          ),
      ],
      updatedAt: await _database.readTimestamp(_monthKey(month)),
    );
  }

  /// Downloads [month] (`yyyy-MM`) and replaces its cached copy, so it stays
  /// readable offline. Throws the API's typed exception on failure.
  Future<void> refreshMonth(String month) async {
    final records = await _api.fetchAttendance(month);
    await _store([month], records, _clock.nowUtc());
    await _rebuild();
  }

  /// Forgets today's attendance on this phone: its outbox events and the
  /// cached server record. Developer settings only, together with the mock
  /// server's `clear_today`.
  Future<void> clearToday() async {
    final today = _clock.companyToday().isoDate;
    await _outbox.deleteWorkDate(today);
    await _database.db.delete(
      'attendance',
      where: 'work_date = ?',
      whereArgs: [today],
    );
    await _rebuild();
  }

  static String _monthKey(String month) => 'attendance_month:$month';

  Future<void> _store(
    List<String> months,
    List<AttendanceRecord> records,
    DateTime now, {
    bool alsoMarkRecent = false,
  }) =>
      _database.db.transaction((txn) async {
        for (final month in months) {
          await txn.delete(
            'attendance',
            where: 'month = ?',
            whereArgs: [month],
          );
          await _database.writeTimestamp(txn, _monthKey(month), now);
        }
        for (final record in records) {
          await txn.insert('attendance', {
            'work_date': record.workDate,
            'month': record.workDate.substring(0, 7),
            'json': jsonEncode(record.toJson()),
            'updated_at': now.toIso8601String(),
          });
        }
        if (alsoMarkRecent) {
          await _database.writeTimestamp(txn, _updatedKey, now);
        }
      });

  void _onSyncChanged() {
    unawaited(
      _rebuild().catchError(
        (Object e, StackTrace stackTrace) =>
            _logger.error('Attendance rebuild', e, stackTrace),
      ),
    );
  }

  /// Checks in at [office]: fresh location → geofence → attendance rules →
  /// outbox, then asks [SyncService] to send it straight away.
  Future<AttendanceOutcome> checkIn(OfficeLocation office) =>
      _oneAtATime(() => _record(AttendanceEventType.checkIn, office));

  /// Checks out at [office], the same way as [checkIn].
  Future<AttendanceOutcome> checkOut(OfficeLocation office) =>
      _oneAtATime(() => _record(AttendanceEventType.checkOut, office));

  Future<T> _oneAtATime<T>(Future<T> Function() action) {
    final result = _actions.then((_) => action());
    _actions = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<AttendanceOutcome> _record(
    AttendanceEventType type,
    OfficeLocation office,
  ) async {
    final GeoPosition position;
    switch (await _location.read(office)) {
      case LocationUnreadable(:final reason):
        return AttendanceLocationFailed(reason);
      case LocationFix(position: final fix):
        position = fix;
    }
    final geofence = _geofence.check(position, office);
    if (geofence is! GeofenceInside) return AttendanceNotAtOffice(geofence);

    final now = _clock.nowUtc();
    final workDate = _clock.workDateOf(now);
    final violation = _policy.evaluate(
      action: type,
      serverRecord: (await _recordsFor([workDate]))[workDate],
      localEvents: await _outbox.activeEventsFor([workDate]),
    );
    if (violation != null) return AttendanceRefused(violation);

    final stored = await _outbox.enqueue(
      AttendanceEvent(
        eventId: _uuid.v4(),
        type: type,
        workDate: workDate,
        occurredAt: now,
        position: position,
      ),
    );
    if (stored == null) {
      return AttendanceRefused(
        type == AttendanceEventType.checkIn
            ? AttendanceRuleViolation.alreadyCheckedIn
            : AttendanceRuleViolation.alreadyCheckedOut,
      );
    }
    await _rebuild();

    // A fresh action is a good moment to retry anything already waiting,
    // so earlier events skip their backoff and keep their order.
    await _sync.syncNow(ignoreBackoff: true);
    final sent = await _outbox.activeEventsFor([workDate]);
    final isSynced = sent.any(
      (e) => e.eventId == stored.eventId && e.status == SyncState.synced,
    );
    return AttendanceRecorded(stored, isSynced: isSynced);
  }

  Future<void> _rebuild() async {
    final todayDate = _clock.companyToday().isoDate;
    final latest = await _database.db.query(
      'attendance',
      columns: ['work_date'],
      orderBy: 'work_date DESC',
      limit: recentCount,
    );
    final dates = <String>{
      todayDate,
      ...latest.map((row) => row['work_date'] as String),
      ...await _outbox.unsyncedWorkDates(),
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    final records = await _recordsFor(dates);
    final events = await _outbox.activeEventsFor(dates);
    final days = [
      for (final date in dates)
        _merge(
          date,
          records[date],
          events.where((e) => e.workDate == date).toList(),
        ),
    ];

    final todayDay = days.firstWhere((d) => d.workDate == todayDate);
    _today = todayDay.checkInAt == null ? null : todayDay;
    _recent = days.where((d) => d.checkInAt != null).take(recentCount).toList();
    notifyListeners();
  }

  Future<Map<String, AttendanceRecord>> _recordsFor(List<String> dates) async {
    final placeholders = List.filled(dates.length, '?').join(', ');
    final rows = await _database.db.query(
      'attendance',
      where: 'work_date IN ($placeholders)',
      whereArgs: dates,
    );
    return {
      for (final row in rows)
        row['work_date'] as String: AttendanceRecord.fromJson(
          jsonDecode(row['json'] as String) as Map<String, dynamic>,
        ),
    };
  }

  AttendanceDay _merge(
    String date,
    AttendanceRecord? record,
    List<AttendanceEvent> events,
  ) {
    AttendanceEvent? local(AttendanceEventType type) {
      for (final event in events) {
        if (event.type == type) return event;
      }
      return null;
    }

    final localIn = local(AttendanceEventType.checkIn);
    final localOut = local(AttendanceEventType.checkOut);
    final serverIn = record?.checkInAt;
    final serverOut = record?.checkOutAt;
    return AttendanceDay(
      workDate: date,
      checkInAt: serverIn ?? localIn?.occurredAt,
      checkInState: serverIn != null
          ? SyncState.synced
          : localIn?.status ?? SyncState.synced,
      checkOutAt: serverOut ?? localOut?.occurredAt,
      checkOutState: serverOut != null
          ? SyncState.synced
          : localOut?.status ?? SyncState.synced,
    );
  }
}

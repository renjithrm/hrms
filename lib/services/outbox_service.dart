// lib/services/outbox_service.dart

import 'package:sqflite/sqflite.dart';

import '../app/app.locator.dart';
import '../models/attendance_event.dart';
import '../models/sync_state.dart';
import 'database_service.dart';

/// Reads and writes the `outbox` table: attendance taken on this device,
/// in the order it must reach the server.
class OutboxService {
  final _database = locator<DatabaseService>();

  /// Stores [event] and returns it with its `seq`, or null when the day
  /// already has a live event of the same type. The unique index on
  /// `(work_date, type)` decides, so two racing calls can't both succeed.
  Future<AttendanceEvent?> enqueue(AttendanceEvent event) async {
    try {
      final seq = await _database.db.transaction(
        (txn) => txn.insert(
          'outbox',
          event.toRow(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        ),
      );
      return event.copyWith(seq: seq);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return null;
      rethrow;
    }
  }

  /// Oldest event still waiting to be sent, or null when none is.
  Future<AttendanceEvent?> nextPending() async {
    final rows = await _database.db.query(
      'outbox',
      where: 'status = ?',
      whereArgs: [SyncState.pending.wireValue],
      orderBy: 'seq',
      limit: 1,
    );
    return rows.isEmpty ? null : AttendanceEvent.fromRow(rows.first);
  }

  /// Writes the sync fields of [event] (status, attempts, retry time,
  /// error, dismissed), matched by event ID.
  Future<void> update(AttendanceEvent event) async {
    final row = event.toRow();
    await _database.db.update(
      'outbox',
      {
        for (final key in const [
          'status',
          'attempts',
          'next_attempt_at',
          'last_error',
          'dismissed',
        ])
          key: row[key],
      },
      where: 'event_id = ?',
      whereArgs: [event.eventId],
    );
  }

  /// Marks a rejected event as seen, so it leaves the sync list.
  Future<void> dismiss(String eventId) => _database.db.update(
        'outbox',
        {'dismissed': 1},
        where: 'event_id = ? AND status = ?',
        whereArgs: [eventId, SyncState.rejected.wireValue],
      );

  /// The latest [limit] events the person hasn't dismissed, oldest first,
  /// for the sync timeline.
  Future<List<AttendanceEvent>> recentEvents({int limit = 20}) async {
    final rows = await _database.db.query(
      'outbox',
      where: 'dismissed = 0',
      orderBy: 'seq DESC',
      limit: limit,
    );
    return rows.map(AttendanceEvent.fromRow).toList().reversed.toList();
  }

  /// How many events are waiting to be sent, and how many were rejected and
  /// not yet dismissed.
  Future<({int waiting, int rejected})> counts() async {
    final rows = await _database.db.rawQuery(
      'SELECT '
      'SUM(CASE WHEN status IN (?, ?) THEN 1 ELSE 0 END) AS waiting, '
      'SUM(CASE WHEN status = ? AND dismissed = 0 THEN 1 ELSE 0 END) '
      'AS rejected '
      'FROM outbox',
      [
        SyncState.pending.wireValue,
        SyncState.syncing.wireValue,
        SyncState.rejected.wireValue,
      ],
    );
    final row = rows.first;
    return (
      waiting: (row['waiting'] as int?) ?? 0,
      rejected: (row['rejected'] as int?) ?? 0,
    );
  }

  /// Deletes every event for [workDate]. Developer settings only.
  Future<int> deleteWorkDate(String workDate) => _database.db.delete(
        'outbox',
        where: 'work_date = ?',
        whereArgs: [workDate],
      );

  /// Puts events left in `SYNCING` by a killed app back to `PENDING`.
  /// Safe because the server deduplicates on the event ID. Call at startup,
  /// before anything syncs. Returns how many were reset.
  Future<int> resetStuckSyncing() => _database.db.update(
        'outbox',
        {'status': SyncState.pending.wireValue},
        where: 'status = ?',
        whereArgs: [SyncState.syncing.wireValue],
      );

  /// Events for the given work dates that the server hasn't rejected.
  Future<List<AttendanceEvent>> activeEventsFor(List<String> workDates) async {
    if (workDates.isEmpty) return const [];
    final placeholders = List.filled(workDates.length, '?').join(', ');
    final rows = await _database.db.query(
      'outbox',
      where: 'work_date IN ($placeholders) AND status != ?',
      whereArgs: [...workDates, SyncState.rejected.wireValue],
      orderBy: 'seq',
    );
    return rows.map(AttendanceEvent.fromRow).toList();
  }

  /// Events in [month] (`yyyy-MM`) that the server hasn't rejected.
  Future<List<AttendanceEvent>> activeEventsInMonth(String month) async {
    final rows = await _database.db.query(
      'outbox',
      where: 'work_date LIKE ? AND status != ?',
      whereArgs: ['$month-%', SyncState.rejected.wireValue],
      orderBy: 'seq',
    );
    return rows.map(AttendanceEvent.fromRow).toList();
  }

  /// Work dates that have local events not yet accepted by the server,
  /// newest first. Used so those days show even before the server has them.
  Future<List<String>> unsyncedWorkDates() async {
    final rows = await _database.db.query(
      'outbox',
      columns: ['work_date'],
      distinct: true,
      where: 'status IN (?, ?)',
      whereArgs: [SyncState.pending.wireValue, SyncState.syncing.wireValue],
      orderBy: 'work_date DESC',
    );
    return rows.map((row) => row['work_date'] as String).toList();
  }
}

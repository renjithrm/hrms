// lib/models/attendance_event.dart

import 'attendance_event_type.dart';
import 'geo_position.dart';
import 'sync_state.dart';

/// A check-in or check-out recorded on the device. Stored in the outbox
/// until the server accepts or rejects it.
class AttendanceEvent {
  /// Creates an event.
  const AttendanceEvent({
    this.seq,
    required this.eventId,
    required this.type,
    required this.workDate,
    required this.occurredAt,
    required this.position,
    this.status = SyncState.pending,
    this.attempts = 0,
    this.nextAttemptAt,
    this.lastError,
    this.isDismissed = false,
  });

  /// Reads an `outbox` table row.
  factory AttendanceEvent.fromRow(Map<String, Object?> row) => AttendanceEvent(
        seq: row['seq'] as int?,
        eventId: row['event_id'] as String,
        type: AttendanceEventType.fromWire(row['type'] as String),
        workDate: row['work_date'] as String,
        occurredAt: DateTime.parse(row['occurred_at'] as String),
        position: GeoPosition(
          latitude: row['lat'] as double,
          longitude: row['lng'] as double,
          accuracyMetres: row['accuracy_m'] as double,
        ),
        status: SyncState.fromWire(row['status'] as String),
        attempts: row['attempts'] as int,
        nextAttemptAt: row['next_attempt_at'] == null
            ? null
            : DateTime.parse(row['next_attempt_at'] as String),
        lastError: row['last_error'] as String?,
        isDismissed: (row['dismissed'] as int) == 1,
      );

  /// Send order, assigned by the database. Null before insertion.
  final int? seq;

  /// Client-generated UUID. Never changes, so the server can deduplicate
  /// retries of the same event.
  final String eventId;

  /// Check-in or check-out.
  final AttendanceEventType type;

  /// Company-timezone date the event belongs to, `yyyy-MM-dd`.
  final String workDate;

  /// Device time of the action, in UTC.
  final DateTime occurredAt;

  /// Where the action happened.
  final GeoPosition position;

  /// Sync progress.
  final SyncState status;

  /// Number of send attempts so far.
  final int attempts;

  /// Earliest time of the next retry, after a failed attempt.
  final DateTime? nextAttemptAt;

  /// Plain-language reason shown when the server rejects the event.
  final String? lastError;

  /// Whether the person cleared this rejected event from the sync list.
  final bool isDismissed;

  /// Returns a copy with the given fields replaced.
  AttendanceEvent copyWith({
    int? seq,
    SyncState? status,
    int? attempts,
    DateTime? nextAttemptAt,
    String? lastError,
    bool? isDismissed,
  }) =>
      AttendanceEvent(
        seq: seq ?? this.seq,
        eventId: eventId,
        type: type,
        workDate: workDate,
        occurredAt: occurredAt,
        position: position,
        status: status ?? this.status,
        attempts: attempts ?? this.attempts,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
        lastError: lastError ?? this.lastError,
        isDismissed: isDismissed ?? this.isDismissed,
      );

  /// Serialises to an `outbox` row. `seq` is left out so SQLite assigns it.
  Map<String, Object?> toRow() => {
        'event_id': eventId,
        'type': type.wireValue,
        'work_date': workDate,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy_m': position.accuracyMetres,
        'status': status.wireValue,
        'attempts': attempts,
        'next_attempt_at': nextAttemptAt?.toUtc().toIso8601String(),
        'last_error': lastError,
        'dismissed': isDismissed ? 1 : 0,
      };

  /// Body for `POST /attendance/events`.
  Map<String, dynamic> toApiJson() => {
        'eventId': eventId,
        'type': type.wireValue,
        'workDate': workDate,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracyMetres': position.accuracyMetres,
      };
}

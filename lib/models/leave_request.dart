// lib/models/leave_request.dart

import '../extensions/date_time_extensions.dart';
import 'leave_status.dart';
import 'leave_type.dart';

/// A leave application and its review status.
class LeaveRequest {
  /// Creates a request.
  const LeaveRequest({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.reviewerNote,
  });

  /// Reads the API shape.
  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
        id: json['id'] as String,
        type: LeaveType.fromWire(json['type'] as String),
        startDate: parseIsoDate(json['startDate'] as String),
        endDate: parseIsoDate(json['endDate'] as String),
        reason: json['reason'] as String,
        status: LeaveStatus.fromWire(json['status'] as String),
        reviewerNote: json['reviewerNote'] as String?,
      );

  /// Server ID.
  final String id;

  /// Casual or sick.
  final LeaveType type;

  /// First day of leave, as a UTC-midnight date.
  final DateTime startDate;

  /// Last day of leave, inclusive.
  final DateTime endDate;

  /// Reason given by the employee.
  final String reason;

  /// Review status.
  final LeaveStatus status;

  /// Manager's note, mainly for rejections.
  final String? reviewerNote;

  /// Calendar days requested; weekends and holidays count.
  int get days => startDate.daysUntil(endDate) + 1;

  /// Whether this request blocks other requests on the same dates.
  bool get blocksOverlap => status != LeaveStatus.rejected;

  /// Whether [start]–[end] shares at least one day with this request.
  bool overlaps(DateTime start, DateTime end) =>
      !start.dateOnly.isAfter(endDate) && !end.dateOnly.isBefore(startDate);

  /// Serialises to the API shape, also used for the local cache.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.wireValue,
        'startDate': startDate.isoDate,
        'endDate': endDate.isoDate,
        'reason': reason,
        'status': status.wireValue,
        'reviewerNote': reviewerNote,
      };
}

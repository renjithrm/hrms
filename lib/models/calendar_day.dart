// lib/models/calendar_day.dart

import 'attendance_day.dart';
import 'leave_request.dart';

/// How a day looks on the attendance calendar.
enum CalendarDayKind {
  /// Checked in, and the server has it.
  present,

  /// Checked in on this phone, not yet on the server.
  waiting,

  /// Approved leave.
  leave,

  /// Saturday or Sunday with no attendance.
  weekend,

  /// Today, not checked in yet.
  today,

  /// A past working day with no attendance.
  absent,

  /// Later this month.
  upcoming,
}

/// One cell of the month calendar.
class CalendarDay {
  /// Creates a day.
  const CalendarDay({
    required this.date,
    required this.kind,
    required this.isToday,
    this.attendance,
    this.leave,
  });

  /// The date, as a UTC-midnight value.
  final DateTime date;

  /// What to show.
  final CalendarDayKind kind;

  /// Whether this is the company's today.
  final bool isToday;

  /// Attendance for the day, if any.
  final AttendanceDay? attendance;

  /// Approved leave covering the day, if any.
  final LeaveRequest? leave;
}

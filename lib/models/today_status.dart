// lib/models/today_status.dart

import 'attendance_day.dart';

/// The three states of the working day shown on the Today card.
sealed class TodayStatus {
  const TodayStatus();

  /// Builds the status from today's merged [day], if any.
  factory TodayStatus.from(AttendanceDay? day) {
    final checkIn = day?.checkInAt;
    final checkOut = day?.checkOutAt;
    if (day == null || checkIn == null) return const TodayNotCheckedIn();
    if (checkOut == null) return TodayCheckedIn(day);
    return TodayCheckedOut(day);
  }
}

/// No check-in yet today.
class TodayNotCheckedIn extends TodayStatus {
  /// Creates the status.
  const TodayNotCheckedIn();
}

/// Checked in, not yet out.
class TodayCheckedIn extends TodayStatus {
  /// Creates the status.
  const TodayCheckedIn(this.day);

  /// Today's attendance.
  final AttendanceDay day;
}

/// Checked in and out; the day is complete.
class TodayCheckedOut extends TodayStatus {
  /// Creates the status.
  const TodayCheckedOut(this.day);

  /// Today's attendance.
  final AttendanceDay day;
}

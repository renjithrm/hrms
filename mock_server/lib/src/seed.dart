import 'dates.dart';
import 'mock_state.dart';

/// Fills [state] with realistic history relative to today, so the demo
/// looks right on any date.
void seed(MockState state) {
  state.records.clear();
  state.processedEvents.clear();
  state.leaveRequests.clear();
  state.nextLeaveId = 1001;

  final today = companyDate(state.now());
  DateTime day(int offset) => today.add(Duration(days: offset));

  void addLeave(
    String type,
    DateTime start,
    DateTime end,
    String reason,
    String status, [
    String? note,
  ]) {
    state.leaveRequests.add(
      LeaveRecord(
        id: 'L-${state.nextLeaveId++}',
        type: type,
        start: start,
        end: end,
        reason: reason,
        status: status,
        reviewerNote: note,
      ),
    );
  }

  addLeave('CASUAL', day(8), day(9), 'Family function in Thrissur', 'PENDING');
  addLeave('SICK', day(-14), day(-14), 'Viral fever', 'APPROVED');
  addLeave(
    'CASUAL',
    day(-55),
    day(-53),
    'Short trip home',
    'REJECTED',
    'Release week, please reschedule',
  );
  addLeave('CASUAL', day(-40), day(-39), 'Onam preparations', 'APPROVED');
  addLeave('SICK', day(-30), day(-30), 'Dental appointment', 'APPROVED');

  bool onLeave(DateTime date) => state.leaveRequests.any(
        (r) =>
            r.status == 'APPROVED' &&
            !date.isBefore(r.start) &&
            !date.isAfter(r.end),
      );

  // Weekday attendance from the start of last month up to yesterday.
  var date = DateTime.utc(today.year, today.month - 1, 1);
  while (date.isBefore(today)) {
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    if (!isWeekend && !onLeave(date)) {
      final inMinute = 28 + (date.day * 7) % 35; // 08:28 to 09:02
      final outMinute = 35 + (date.day * 11) % 35; // 17:35 to 18:09
      state.records[isoDate(date)] = DayRecord(
        isoDate(date),
        checkInAt: companyTime(date, 8, inMinute),
        checkOutAt: companyTime(date, 17, outMinute),
      );
    }
    date = date.add(const Duration(days: 1));
  }
}

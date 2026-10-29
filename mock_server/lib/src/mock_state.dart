import 'dates.dart';
import 'scenario.dart';

/// One working day of attendance.
class DayRecord {
  DayRecord(this.workDate, {this.checkInAt, this.checkOutAt});

  final String workDate;
  DateTime? checkInAt;
  DateTime? checkOutAt;

  Map<String, Object?> toJson() => {
        'workDate': workDate,
        'checkInAt': checkInAt?.toIso8601String(),
        'checkOutAt': checkOutAt?.toIso8601String(),
      };
}

/// A leave request as stored by the server.
class LeaveRecord {
  LeaveRecord({
    required this.id,
    required this.type,
    required this.start,
    required this.end,
    required this.reason,
    required this.status,
    this.reviewerNote,
  });

  final String id;
  final String type;
  final DateTime start;
  final DateTime end;
  final String reason;
  final String status;
  final String? reviewerNote;

  int get days => end.difference(start).inDays + 1;

  bool get blocksOverlap => status != 'REJECTED';

  bool overlaps(DateTime otherStart, DateTime otherEnd) =>
      !otherStart.isAfter(end) && !otherEnd.isBefore(start);

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type,
        'startDate': isoDate(start),
        'endDate': isoDate(end),
        'reason': reason,
        'status': status,
        'reviewerNote': reviewerNote,
      };
}

/// Everything the mock server remembers between requests.
class MockState {
  MockState({required this.now});

  /// Clock, injectable for tests.
  final DateTime Function() now;

  Scenario scenario = Scenario.success;

  final Map<String, Object?> employee = {
    'id': 'EMP-1042',
    'name': 'Anjali Nair',
    'department': 'Engineering',
    'office': {
      'name': 'Infopark Phase 1',
      'latitude': 10.0159,
      'longitude': 76.3419,
      'radiusMetres': 200,
    },
    'shift': {'start': '09:00', 'end': '18:00'},
    'timezone': companyTimezone,
  };

  /// Yearly entitlement per leave type.
  final Map<String, int> entitlements = {'CASUAL': 10, 'SICK': 6};

  /// Attendance keyed by work date.
  final Map<String, DayRecord> records = {};

  /// Responses already sent for each processed event ID, so a retry gets
  /// exactly the same answer instead of a second record.
  final Map<String, Map<String, Object?>> processedEvents = {};

  final List<LeaveRecord> leaveRequests = [];

  int nextLeaveId = 1001;

  double get officeLatitude =>
      ((employee['office'] as Map)['latitude'] as num).toDouble();
  double get officeLongitude =>
      ((employee['office'] as Map)['longitude'] as num).toDouble();
  double get officeRadius =>
      ((employee['office'] as Map)['radiusMetres'] as num).toDouble();

  /// Balance for [type]: entitlement minus approved and pending days.
  Map<String, Object?> balanceFor(String type) {
    var used = 0;
    var onHold = 0;
    for (final request in leaveRequests.where((r) => r.type == type)) {
      if (request.status == 'APPROVED') used += request.days;
      if (request.status == 'PENDING') onHold += request.days;
    }
    final entitlement = entitlements[type] ?? 0;
    return {
      'type': type,
      'entitlement': entitlement,
      'used': used,
      'onHold': onHold,
      'available': entitlement - used - onHold,
    };
  }
}

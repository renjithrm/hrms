import 'package:flutter_test/flutter_test.dart';
import 'package:rebs_hrms/models/leave_balance.dart';
import 'package:rebs_hrms/models/leave_input.dart';
import 'package:rebs_hrms/models/leave_request.dart';
import 'package:rebs_hrms/models/leave_rule_violation.dart';
import 'package:rebs_hrms/models/leave_status.dart';
import 'package:rebs_hrms/models/leave_type.dart';
import 'package:rebs_hrms/policies/leave_policy.dart';

void main() {
  final policy = LeavePolicy();
  final today = DateTime.utc(2026, 10, 28);
  const balances = [
    LeaveBalance(
      type: LeaveType.casual,
      entitlement: 10,
      used: 2,
      onHold: 2,
      available: 6,
    ),
    LeaveBalance(
      type: LeaveType.sick,
      entitlement: 6,
      used: 2,
      onHold: 0,
      available: 4,
    ),
  ];
  LeaveRequest request(int startDay, int endDay, LeaveStatus status) =>
      LeaveRequest(
        id: 'L-$startDay-${status.name}',
        type: LeaveType.casual,
        startDate: DateTime.utc(2026, 11, startDay),
        endDate: DateTime.utc(2026, 11, endDay),
        reason: 'Family function in Thrissur',
        status: status,
      );
  LeaveInput input(
    DateTime? start,
    DateTime? end, {
    LeaveType type = LeaveType.casual,
    String reason = 'Family function in Thrissur',
  }) =>
      LeaveInput(type: type, startDate: start, endDate: end, reason: reason);
  List<LeaveRuleViolation> validate(
    LeaveInput value, {
    List<LeaveRequest> existing = const [],
  }) =>
      policy.validate(
        value,
        today: today,
        balances: balances,
        existing: existing,
      );

  group('LeavePolicy -', () {
    group('overlapping dates (required test 4) -', () {
      final pending = request(5, 6, LeaveStatus.pending);

      test('a range overlapping a pending request is rejected', () {
        final result = validate(
          input(DateTime.utc(2026, 11, 4), DateTime.utc(2026, 11, 6)),
          existing: [pending],
        );
        expect(result.whereType<LeaveOverlaps>().single.existing, pending);
      });

      test('a range overlapping an approved request is rejected', () {
        final result = validate(
          input(DateTime.utc(2026, 11, 6), DateTime.utc(2026, 11, 8)),
          existing: [request(5, 6, LeaveStatus.approved)],
        );
        expect(result.whereType<LeaveOverlaps>(), hasLength(1));
      });

      test('a range touching but not sharing a day is allowed', () {
        final result = validate(
          input(DateTime.utc(2026, 11, 7), DateTime.utc(2026, 11, 9)),
          existing: [pending],
        );
        expect(result, isEmpty);
      });

      test('overlapping a rejected request is allowed', () {
        final result = validate(
          input(DateTime.utc(2026, 11, 5), DateTime.utc(2026, 11, 6)),
          existing: [request(5, 6, LeaveStatus.rejected)],
        );
        expect(result, isEmpty);
      });
    });

    test('a start date before the company today is rejected', () {
      final result = validate(
        input(DateTime.utc(2026, 10, 27), DateTime.utc(2026, 10, 29)),
      );
      expect(result, contains(isA<LeaveStartBeforeToday>()));
    });

    test('starting today is allowed', () {
      expect(validate(input(today, today)), isEmpty);
    });

    test('an end date before the start date is rejected', () {
      final result = validate(
        input(DateTime.utc(2026, 11, 9), DateTime.utc(2026, 11, 8)),
      );
      expect(result, contains(isA<LeaveEndBeforeStart>()));
    });

    test('a reason with fewer than 10 non-whitespace characters fails', () {
      final result = validate(
        input(today, today, reason: '  sick  day   '),
      );
      final violation = result.whereType<LeaveReasonTooShort>().single;
      expect(violation.count, 7);
    });

    test('more days than the balance is rejected', () {
      final result = validate(
        input(
          DateTime.utc(2026, 11, 2),
          DateTime.utc(2026, 11, 6),
          type: LeaveType.sick,
        ),
      );
      final violation = result.whereType<LeaveExceedsBalance>().single;
      expect(violation.requested, 5);
      expect(violation.available, 4);
    });

    test('missing dates are reported', () {
      expect(validate(input(null, null)), contains(isA<LeaveDatesMissing>()));
    });
  });
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rebs_hrms/exceptions/attendance_conflict_exception.dart';
import 'package:rebs_hrms/exceptions/offline_exception.dart';
import 'package:rebs_hrms/exceptions/request_timeout_exception.dart';
import 'package:rebs_hrms/exceptions/server_exception.dart';
import 'package:rebs_hrms/exceptions/validation_exception.dart';
import 'package:rebs_hrms/models/attendance_event.dart';
import 'package:rebs_hrms/models/attendance_event_type.dart';
import 'package:rebs_hrms/models/geo_position.dart';
import 'package:rebs_hrms/models/leave_input.dart';
import 'package:rebs_hrms/models/leave_type.dart';
import 'package:rebs_hrms/services/api_service.dart';

final _event = AttendanceEvent(
  eventId: 'evt-1',
  type: AttendanceEventType.checkIn,
  workDate: '2026-10-28',
  occurredAt: DateTime.utc(2026, 10, 28, 3, 2),
  position: const GeoPosition(
    latitude: 10.0159,
    longitude: 76.3419,
    accuracyMetres: 12,
  ),
);

http.Response _json(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

ApiService _api(MockClientHandler handler, {Duration? timeout}) => ApiService(
      client: MockClient(handler),
      baseUrl: 'http://test',
      timeout: timeout,
    );

void main() {
  group('ApiService -', () {
    test('parses the employee', () async {
      final api = _api(
        (_) async => _json({
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
          'timezone': 'Asia/Kolkata',
        }, 200),
      );
      final employee = await api.fetchEmployee();
      expect(employee.initials, 'AN');
      expect(employee.shift.length, const Duration(hours: 9));
    });

    test('sends the event ID as the idempotency key and reads a replay',
        () async {
      late http.Request sent;
      final api = _api((request) async {
        sent = request;
        return _json({
          'record': {
            'workDate': '2026-10-28',
            'checkInAt': '2026-10-28T03:02:00.000Z',
          },
          'replayed': true,
        }, 200);
      });
      final result = await api.submitAttendanceEvent(_event);
      expect(sent.headers['Idempotency-Key'], 'evt-1');
      expect(jsonDecode(sent.body)['eventId'], 'evt-1');
      expect(result.wasReplay, isTrue);
      expect(result.record.checkInAt, DateTime.utc(2026, 10, 28, 3, 2));
    });

    test('maps an attendance 409 to a non-retryable conflict', () async {
      final api = _api(
        (_) async => _json(
          {'code': 'ATTENDANCE_EXISTS', 'message': 'Already checked in'},
          409,
        ),
      );
      await expectLater(
        api.submitAttendanceEvent(_event),
        throwsA(
          isA<AttendanceConflictException>()
              .having((e) => e.code, 'code', 'ATTENDANCE_EXISTS')
              .having((e) => e.isRetryable, 'isRetryable', false),
        ),
      );
    });

    test('maps a leave 422 to field errors', () async {
      final api = _api(
        (_) async => _json({
          'code': 'VALIDATION_FAILED',
          'message': 'Falls in a team blackout period',
          'errors': [
            {'field': 'startDate', 'code': 'BLACKOUT', 'message': 'Blackout'},
          ],
        }, 422),
      );
      await expectLater(
        api.submitLeave(
          LeaveInput(
            type: LeaveType.sick,
            startDate: DateTime.utc(2026, 11, 2),
            endDate: DateTime.utc(2026, 11, 3),
            reason: 'Fever, doctor advised rest',
          ),
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.fieldErrors['startDate'],
            'startDate error',
            'Blackout',
          ),
        ),
      );
    });

    test('maps a 500 to a retryable server error', () async {
      final api = _api((_) async => _json({'message': 'boom'}, 500));
      await expectLater(
        api.fetchLeaveBalances(),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.isRetryable, 'isRetryable', true),
        ),
      );
    });

    test('maps a slow response to a timeout', () async {
      final api = _api(
        (_) => Completer<http.Response>().future,
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        api.fetchLeaveRequests(),
        throwsA(isA<RequestTimeoutException>()),
      );
    });

    test('maps a connection failure to offline', () async {
      final api = _api((_) async => throw http.ClientException('refused'));
      await expectLater(api.fetchEmployee(), throwsA(isA<OfflineException>()));
    });
  });
}

import 'dart:convert';

import 'package:rebs_mock_server/rebs_mock_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

// Wednesday 28 Oct 2026, 09:00 in India.
final _now = DateTime.utc(2026, 10, 28, 3, 30);

Future<(int, Map<String, dynamic>)> _call(
  MockApi api,
  String method,
  String path, [
  Map<String, Object?>? body,
]) async {
  final response = await api.handler(
    Request(
      method,
      Uri.parse('http://mock$path'),
      body: body == null ? null : jsonEncode(body),
    ),
  );
  return (
    response.statusCode,
    jsonDecode(await response.readAsString()) as Map<String, dynamic>,
  );
}

Map<String, Object?> _event(String id, String type, DateTime at) => {
      'eventId': id,
      'type': type,
      'occurredAt': at.toIso8601String(),
      'latitude': 10.0159,
      'longitude': 76.3419,
      'accuracyMetres': 12,
    };

void main() {
  late MockApi api;
  setUp(() => api = MockApi(now: () => _now, commitHold: Duration.zero));

  group('attendance events -', () {
    test('a retry with the same event ID returns the original record',
        () async {
      final event = _event('evt-1', 'CHECK_IN', _now);
      final (first, firstBody) =
          await _call(api, 'POST', '/attendance/events', event);
      final (second, secondBody) =
          await _call(api, 'POST', '/attendance/events', event);
      expect(first, 201);
      expect(second, 200);
      expect(secondBody['replayed'], isTrue);
      expect(secondBody['record'], firstBody['record']);
    });

    test('timeout_after_commit still stores exactly one check-in', () async {
      await _call(
          api, 'POST', '/__mock/scenario', {'name': 'timeout_after_commit'});
      final event = _event('evt-2', 'CHECK_IN', _now);
      await _call(api, 'POST', '/attendance/events', event);
      final (status, body) =
          await _call(api, 'POST', '/attendance/events', event);
      expect(status, 200);
      expect(body['replayed'], isTrue);
      expect(api.state.processedEvents, hasLength(1));
    });

    test('a different check-in on the same day gets 409', () async {
      await _call(
          api, 'POST', '/attendance/events', _event('a', 'CHECK_IN', _now));
      final (status, body) = await _call(
          api, 'POST', '/attendance/events', _event('b', 'CHECK_IN', _now));
      expect(status, 409);
      expect(body['code'], 'ATTENDANCE_EXISTS');
    });

    test('attendance_conflict refuses the first check-in', () async {
      await _call(
          api, 'POST', '/__mock/scenario', {'name': 'attendance_conflict'});
      final (status, _) = await _call(
          api, 'POST', '/attendance/events', _event('c', 'CHECK_IN', _now));
      expect(status, 409);
    });

    test('check-out without check-in gets 422', () async {
      final (status, body) = await _call(
          api, 'POST', '/attendance/events', _event('d', 'CHECK_OUT', _now));
      expect(status, 422);
      expect(body['code'], 'CHECK_OUT_BEFORE_CHECK_IN');
    });

    test('an event far from the office gets 422', () async {
      final event = _event('e', 'CHECK_IN', _now)..['latitude'] = 10.03;
      final (status, body) =
          await _call(api, 'POST', '/attendance/events', event);
      expect(status, 422);
      expect(body['code'], 'OUTSIDE_OFFICE');
    });
  });

  group('leave -', () {
    test('seeded balances subtract approved and pending days', () async {
      final (_, body) = await _call(api, 'GET', '/leave/balance');
      final casual = (body['balances'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((b) => b['type'] == 'CASUAL');
      expect(casual['available'], 6);
      expect(casual['onHold'], 2);
    });

    test('overlap with the pending request is refused', () async {
      final (status, body) = await _call(api, 'POST', '/leave/requests', {
        'type': 'CASUAL',
        'startDate': '2026-11-05',
        'endDate': '2026-11-06',
        'reason': 'Family wedding in Kochi',
      });
      expect(status, 422);
      expect((body['errors'] as List).first['code'], 'OVERLAPS');
    });

    test('leave_rejected refuses an otherwise valid request', () async {
      await _call(api, 'POST', '/__mock/scenario', {'name': 'leave_rejected'});
      final (status, body) = await _call(api, 'POST', '/leave/requests', {
        'type': 'SICK',
        'startDate': '2026-11-02',
        'endDate': '2026-11-03',
        'reason': 'Fever, doctor advised rest',
      });
      expect(status, 422);
      expect((body['errors'] as List).first['code'], 'BLACKOUT');
    });

    test('a valid request is created as pending', () async {
      final (status, body) = await _call(api, 'POST', '/leave/requests', {
        'type': 'CASUAL',
        'startDate': '2026-11-09',
        'endDate': '2026-11-11',
        'reason': 'Visiting grandparents',
      });
      expect(status, 201);
      expect((body['request'] as Map)['status'], 'PENDING');
    });
  });

  test('server_error returns 500 for API calls', () async {
    await _call(api, 'POST', '/__mock/scenario', {'name': 'server_error'});
    final (status, _) = await _call(api, 'GET', '/employee/me');
    expect(status, 500);
  });

  test('clear_today forgets only today, so check-in works again', () async {
    final at = _now.subtract(const Duration(minutes: 5));
    await _call(api, 'POST', '/attendance/events', _event('a', 'CHECK_IN', at));

    final (status, body) = await _call(api, 'POST', '/__mock/clear_today');
    expect(status, 200);
    expect(body['cleared'], '2026-10-28');

    final (_, month) = await _call(api, 'GET', '/attendance?month=2026-10');
    final dates = (month['records'] as List).map((r) => r['workDate']);
    expect(dates, isNot(contains('2026-10-28')));
    expect(dates, contains('2026-10-27'));

    final (again, _) = await _call(
      api,
      'POST',
      '/attendance/events',
      _event('a', 'CHECK_IN', at),
    );
    expect(again, 201);
  });

  test('reset restores seed data and the success scenario', () async {
    await _call(api, 'POST', '/__mock/scenario', {'name': 'slow'});
    final (_, body) = await _call(api, 'POST', '/__mock/reset');
    expect(body['name'], 'success');
  });
}

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'dates.dart';
import 'mock_state.dart';
import 'scenario.dart';
import 'seed.dart';

/// The mock REBS API. Validates everything the real server would, so the
/// app's error handling can be exercised for real.
class MockApi {
  MockApi({DateTime Function()? now, this.commitHold = _defaultHold})
      : state = MockState(now: now ?? DateTime.now) {
    seed(state);
  }

  static const Duration _defaultHold = Duration(seconds: 12);

  /// Server state, exposed for tests.
  final MockState state;

  /// How long `timeout_after_commit` holds the response. Longer than the
  /// app's 8 s request timeout.
  final Duration commitHold;

  /// Shelf handler with scenario behaviour applied.
  Handler get handler {
    final router = Router()
      ..get('/', (_) => _json(200, {'status': 'ok'}))
      ..get('/employee/me', (_) => _json(200, state.employee))
      ..get('/attendance', _attendance)
      ..post('/attendance/events', _attendanceEvent)
      ..get('/leave/balance', _leaveBalance)
      ..get('/leave/requests', _leaveRequests)
      ..post('/leave/requests', _submitLeave)
      ..get('/__mock/scenario', (_) => _json(200, _scenarioJson()))
      ..post('/__mock/scenario', _setScenario)
      ..post('/__mock/reset', _reset)
      ..post('/__mock/clear_today', _clearToday);
    return const Pipeline()
        .addMiddleware(_scenarioMiddleware())
        .addHandler(router.call);
  }

  Middleware _scenarioMiddleware() => (inner) => (request) async {
        if (request.url.path.startsWith('__mock')) return inner(request);
        await Future<void>.delayed(state.scenario.latency);
        if (state.scenario == Scenario.serverError) {
          return _json(500, {
            'code': 'SERVER_ERROR',
            'message': 'Simulated server error',
          });
        }
        return inner(request);
      };

  Response _attendance(Request request) {
    final month = request.url.queryParameters['month'];
    if (month == null || !RegExp(r'^\d{4}-\d{2}$').hasMatch(month)) {
      return _error(400, 'BAD_MONTH', 'Use ?month=YYYY-MM');
    }
    final records = state.records.values
        .where((r) => r.workDate.startsWith(month))
        .toList()
      ..sort((a, b) => b.workDate.compareTo(a.workDate));
    return _json(200, {
      'month': month,
      'records': records.map((r) => r.toJson()).toList(),
    });
  }

  Future<Response> _attendanceEvent(Request request) async {
    final body = await _readJson(request);
    if (body == null) return _error(400, 'BAD_JSON', 'Body must be JSON');

    final eventId =
        request.headers['idempotency-key'] ?? body['eventId'] as String?;
    final type = body['type'] as String?;
    final occurredAt = DateTime.tryParse(body['occurredAt'] as String? ?? '');
    final lat = (body['latitude'] as num?)?.toDouble();
    final lng = (body['longitude'] as num?)?.toDouble();
    final accuracy = (body['accuracyMetres'] as num?)?.toDouble();
    if (eventId == null ||
        (type != 'CHECK_IN' && type != 'CHECK_OUT') ||
        occurredAt == null ||
        lat == null ||
        lng == null ||
        accuracy == null) {
      return _error(400, 'BAD_EVENT', 'Missing or invalid event fields');
    }

    // Idempotency: the same event ID always gets the original answer.
    final previous = state.processedEvents[eventId];
    if (previous != null) {
      return _json(200, {'record': previous, 'replayed': true});
    }

    final now = state.now().toUtc();
    if (occurredAt.isAfter(now.add(const Duration(minutes: 2)))) {
      return _error(
          422, 'INVALID_TIMESTAMP', 'The event time is in the future.');
    }
    if (occurredAt.isBefore(now.subtract(const Duration(hours: 24)))) {
      return _error(422, 'STALE_EVENT',
          'Events older than 24 hours can no longer be recorded.');
    }
    if (accuracy > 100) {
      return _error(
          422, 'LOW_ACCURACY', 'The location was not accurate enough.');
    }
    final distance =
        _distanceMetres(lat, lng, state.officeLatitude, state.officeLongitude);
    if (distance > state.officeRadius) {
      return _error(422, 'OUTSIDE_OFFICE',
          'Recorded ${distance.round()} m from the office.');
    }

    // The server decides the work date, never the client.
    final workDate = isoDate(companyDate(occurredAt));
    final record =
        state.records.putIfAbsent(workDate, () => DayRecord(workDate));

    if (type == 'CHECK_IN') {
      if (state.scenario == Scenario.attendanceConflict &&
          record.checkInAt == null) {
        record.checkInAt = occurredAt.subtract(const Duration(minutes: 7));
      }
      if (record.checkInAt != null) {
        return _error(409, 'ATTENDANCE_EXISTS',
            'Attendance already exists for $workDate.');
      }
      record.checkInAt = occurredAt;
    } else {
      final checkIn = record.checkInAt;
      if (checkIn == null) {
        return _error(422, 'CHECK_OUT_BEFORE_CHECK_IN',
            'There is no check-in for $workDate.');
      }
      if (record.checkOutAt != null) {
        return _error(409, 'ATTENDANCE_EXISTS',
            'A check-out already exists for $workDate.');
      }
      if (!occurredAt.isAfter(checkIn)) {
        return _error(422, 'INVALID_ORDER', 'Check-out must follow check-in.');
      }
      record.checkOutAt = occurredAt;
    }

    final saved = record.toJson();
    state.processedEvents[eventId] = saved;
    if (state.scenario == Scenario.timeoutAfterCommit) {
      // Committed, but the client gives up before this answer arrives.
      await Future<void>.delayed(commitHold);
    }
    return _json(201, {'record': saved, 'replayed': false});
  }

  Response _leaveBalance(Request request) => _json(200, {
        'balances': state.entitlements.keys.map(state.balanceFor).toList(),
      });

  Response _leaveRequests(Request request) {
    final requests = [...state.leaveRequests]
      ..sort((a, b) => b.start.compareTo(a.start));
    return _json(200, {
      'requests': requests.map((r) => r.toJson()).toList(),
    });
  }

  Future<Response> _submitLeave(Request request) async {
    final body = await _readJson(request);
    if (body == null) return _error(400, 'BAD_JSON', 'Body must be JSON');

    final errors = <Map<String, String>>[];
    void fail(String field, String code, String message) =>
        errors.add({'field': field, 'code': code, 'message': message});

    final type = body['type'] as String?;
    final start = parseIsoDate(body['startDate'] as String?);
    final end = parseIsoDate(body['endDate'] as String?);
    final reason = (body['reason'] as String? ?? '').trim();
    final today = companyDate(state.now());

    if (!state.entitlements.containsKey(type)) {
      fail('type', 'INVALID_TYPE', 'Choose casual or sick leave.');
    }
    if (start == null) fail('startDate', 'REQUIRED', 'Choose a start date.');
    if (end == null) fail('endDate', 'REQUIRED', 'Choose an end date.');
    if (start != null && start.isBefore(today)) {
      fail('startDate', 'IN_PAST', 'Leave can start today at the earliest.');
    }
    if (start != null && end != null) {
      if (end.isBefore(start)) {
        fail('endDate', 'BEFORE_START', 'The end date is before the start.');
      } else {
        final days = end.difference(start).inDays + 1;
        if (type != null && state.entitlements.containsKey(type)) {
          final available = state.balanceFor(type)['available'] as int;
          if (days > available) {
            fail('endDate', 'EXCEEDS_BALANCE',
                '$days days requested, $available available.');
          }
        }
        final clash = state.leaveRequests
            .where((r) => r.blocksOverlap && r.overlaps(start, end));
        if (clash.isNotEmpty) {
          final other = clash.first;
          fail(
              'startDate',
              'OVERLAPS',
              'Overlaps ${other.id} (${isoDate(other.start)} to '
                  '${isoDate(other.end)}).');
        }
      }
    }
    if (reason.replaceAll(RegExp(r'\s'), '').length < 10) {
      fail('reason', 'TOO_SHORT', 'Give a reason of at least 10 characters.');
    }
    if (errors.isEmpty && state.scenario == Scenario.leaveRejected) {
      fail('startDate', 'BLACKOUT', 'Falls in a team blackout period.');
    }
    if (errors.isNotEmpty) {
      return _json(422, {
        'code': 'VALIDATION_FAILED',
        'message': errors.first['message'],
        'errors': errors,
      });
    }

    final created = LeaveRecord(
      id: 'L-${state.nextLeaveId++}',
      type: type!,
      start: start!,
      end: end!,
      reason: reason,
      status: 'PENDING',
    );
    state.leaveRequests.add(created);
    return _json(201, {'request': created.toJson()});
  }

  Future<Response> _setScenario(Request request) async {
    final body = await _readJson(request);
    final scenario = Scenario.fromWire(body?['name'] as String? ?? '');
    if (scenario == null) {
      return _error(400, 'UNKNOWN_SCENARIO',
          'Use one of: ${Scenario.values.map((s) => s.wireName).join(', ')}');
    }
    state.scenario = scenario;
    return _json(200, _scenarioJson());
  }

  Response _reset(Request request) {
    seed(state);
    state.scenario = Scenario.success;
    return _json(200, _scenarioJson());
  }

  /// Forgets today's attendance, including the event IDs that created it,
  /// so the app can check in again. Leaves every other day alone.
  Response _clearToday(Request request) {
    final today = isoDate(companyDate(state.now()));
    state.records.remove(today);
    state.processedEvents.removeWhere((_, saved) => saved['workDate'] == today);
    return _json(200, {'cleared': today});
  }

  Map<String, Object?> _scenarioJson() => {
        'name': state.scenario.wireName,
        'available': Scenario.values.map((s) => s.wireName).toList(),
      };

  Future<Map<String, dynamic>?> _readJson(Request request) async {
    try {
      final decoded = jsonDecode(await request.readAsString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static Response _json(int status, Object body) => Response(
        status,
        body: jsonEncode(body),
        headers: {'content-type': 'application/json'},
      );

  static Response _error(int status, String code, String message) =>
      _json(status, {'code': code, 'message': message});

  static double _distanceMetres(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * 6371000 * math.asin(math.sqrt(a));
  }
}

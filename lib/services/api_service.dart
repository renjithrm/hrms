// lib/services/api_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../app/config/app_config.dart';
import '../constants/app_limits.dart';
import '../exceptions/api_exception.dart';
import '../exceptions/attendance_conflict_exception.dart';
import '../exceptions/offline_exception.dart';
import '../exceptions/request_timeout_exception.dart';
import '../exceptions/server_exception.dart';
import '../exceptions/validation_exception.dart';
import '../models/attendance_event.dart';
import '../models/attendance_record.dart';
import '../models/employee.dart';
import '../models/leave_balance.dart';
import '../models/leave_input.dart';
import '../models/leave_request.dart';

/// Result of submitting an attendance event.
class AttendanceSubmission {
  /// Creates a submission result.
  const AttendanceSubmission({required this.record, required this.wasReplay});

  /// The day's record after the event was applied.
  final AttendanceRecord record;

  /// True when the server had already processed this event ID and returned
  /// the original result instead of applying it again.
  final bool wasReplay;
}

/// The only place that speaks HTTP. Maps responses to models and failures
/// to typed [ApiException]s; holds no state and makes no decisions.
class ApiService {
  /// Creates the service. [client], [baseUrl] and [timeout] exist for tests.
  ApiService({http.Client? client, String? baseUrl, Duration? timeout})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.current.apiBaseUrl,
        _timeout = timeout ?? AppLimits.requestTimeout;

  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  /// Base URL in use, shown on the developer settings screen.
  String get baseUrl => _baseUrl;

  /// `GET /employee/me`
  Future<Employee> fetchEmployee() async {
    final json = await _send('GET', '/employee/me') as Map<String, dynamic>;
    return Employee.fromJson(json);
  }

  /// `GET /attendance?month=YYYY-MM`
  Future<List<AttendanceRecord>> fetchAttendance(String month) async {
    final json = await _send('GET', '/attendance', query: {'month': month})
        as Map<String, dynamic>;
    return (json['records'] as List<dynamic>)
        .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /attendance/events`, idempotent on the event ID.
  Future<AttendanceSubmission> submitAttendanceEvent(
    AttendanceEvent event,
  ) async {
    final json = await _send(
      'POST',
      '/attendance/events',
      body: event.toApiJson(),
      headers: {'Idempotency-Key': event.eventId},
    ) as Map<String, dynamic>;
    return AttendanceSubmission(
      record: AttendanceRecord.fromJson(json['record'] as Map<String, dynamic>),
      wasReplay: json['replayed'] as bool? ?? false,
    );
  }

  /// `GET /leave/balance`
  Future<List<LeaveBalance>> fetchLeaveBalances() async {
    final json = await _send('GET', '/leave/balance') as Map<String, dynamic>;
    return (json['balances'] as List<dynamic>)
        .map((e) => LeaveBalance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /leave/requests`
  Future<List<LeaveRequest>> fetchLeaveRequests() async {
    final json = await _send('GET', '/leave/requests') as Map<String, dynamic>;
    return (json['requests'] as List<dynamic>)
        .map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /leave/requests`
  Future<LeaveRequest> submitLeave(LeaveInput input) async {
    final json = await _send(
      'POST',
      '/leave/requests',
      body: input.toApiJson(),
    ) as Map<String, dynamic>;
    return LeaveRequest.fromJson(json['request'] as Map<String, dynamic>);
  }

  /// `POST /__mock/scenario`, mock server only.
  Future<void> setMockScenario(String name) =>
      _send('POST', '/__mock/scenario', body: {'name': name});

  /// `GET /__mock/scenario`, mock server only.
  Future<String> fetchMockScenario() async {
    final json = await _send('GET', '/__mock/scenario') as Map<String, dynamic>;
    return json['name'] as String;
  }

  /// `POST /__mock/reset`, mock server only.
  Future<void> resetMock() => _send('POST', '/__mock/reset');

  /// `POST /__mock/clear_today`, mock server only: forgets today's
  /// attendance so a check-in can be tried again.
  Future<void> clearMockToday() => _send('POST', '/__mock/clear_today');

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    Map<String, String> headers = const {},
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers.addAll({
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        ...headers,
      });
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw RequestTimeoutException('$method $path timed out');
    } on SocketException catch (e) {
      throw OfflineException('$method $path: ${e.message}');
    } on http.ClientException catch (e) {
      throw OfflineException('$method $path: ${e.message}');
    }

    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw _errorFor(response.statusCode, decoded, '$method $path');
  }

  ApiException _errorFor(int status, Object? body, String request) {
    final json = body is Map<String, dynamic> ? body : const {};
    final code = json['code'] as String? ?? 'UNKNOWN';
    final message = json['message'] as String? ?? '$request failed';
    final isAttendance = request.contains('/attendance/events');

    if (isAttendance && (status == 409 || status == 422)) {
      return AttendanceConflictException(code: code, message: message);
    }
    if (status == 422) {
      final errors = <String, String>{};
      for (final item in json['errors'] as List<dynamic>? ?? const []) {
        final error = item as Map<String, dynamic>;
        errors[error['field'] as String] = error['message'] as String;
      }
      return ValidationException(message: message, fieldErrors: errors);
    }
    return ServerException(status, message);
  }
}

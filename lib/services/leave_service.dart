// lib/services/leave_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:stacked/stacked.dart';

import '../app/app.locator.dart';
import '../exceptions/offline_exception.dart';
import '../exceptions/validation_exception.dart';
import '../extensions/date_time_extensions.dart';
import '../models/leave_balance.dart';
import '../models/leave_input.dart';
import '../models/leave_request.dart';
import '../models/leave_type.dart';
import 'api_service.dart';
import 'clock_service.dart';
import 'connectivity_service.dart';
import 'database_service.dart';
import 'logger_service.dart';

/// Leave balances and requests, cached so they stay readable offline, and
/// submitting a new request (online only).
class LeaveService with ListenableServiceMixin {
  final _api = locator<ApiService>();
  final _database = locator<DatabaseService>();
  final _clock = locator<ClockService>();
  final _connectivity = locator<ConnectivityService>();
  final _logger = locator<LoggerService>();

  static const String _updatedKey = 'leave_updated_at';

  List<LeaveBalance> _balances = const [];
  List<LeaveRequest> _requests = const [];
  DateTime? _lastUpdated;

  /// Balance per leave type.
  List<LeaveBalance> get balances => _balances;

  /// Requests, newest start date first.
  List<LeaveRequest> get requests => _requests;

  /// When balances and requests were last refreshed from the server.
  DateTime? get lastUpdated => _lastUpdated;

  /// Whether leave data has ever been downloaded.
  bool get hasCache => _lastUpdated != null;

  /// Balance for [type], or null if the server sent none.
  LeaveBalance? balanceFor(LeaveType type) {
    for (final balance in _balances) {
      if (balance.type == type) return balance;
    }
    return null;
  }

  /// Loads what is stored on the device. Never touches the network.
  Future<void> loadCached() async {
    final balanceRows = await _database.db.query('leave_balance');
    final requestRows = await _database.db.query(
      'leave_requests',
      orderBy: 'start_date DESC',
    );
    _balances = balanceRows.map((row) => _decodeBalance(row)).toList();
    _requests = requestRows.map((row) => _decodeRequest(row)).toList();
    _lastUpdated = await _database.readTimestamp(_updatedKey);
    notifyListeners();
  }

  /// Downloads balances and requests and replaces the cache. Throws the
  /// API's typed exception on failure.
  Future<void> refresh() async {
    final results = await Future.wait([
      _api.fetchLeaveBalances(),
      _api.fetchLeaveRequests(),
    ]);
    final balances = results[0] as List<LeaveBalance>;
    final requests = (results[1] as List<LeaveRequest>)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final now = _clock.nowUtc();
    await _database.db.transaction((txn) async {
      await txn.delete('leave_balance');
      await txn.delete('leave_requests');
      for (final balance in balances) {
        await txn.insert('leave_balance', {
          'type': balance.type.wireValue,
          'json': jsonEncode(balance.toJson()),
          'updated_at': now.toIso8601String(),
        });
      }
      for (final request in requests) {
        await txn.insert('leave_requests', {
          'id': request.id,
          'start_date': request.startDate.isoDate,
          'status': request.status.wireValue,
          'json': jsonEncode(request.toJson()),
          'updated_at': now.toIso8601String(),
        });
      }
      await _database.writeTimestamp(txn, _updatedKey, now);
    });

    _balances = balances;
    _requests = requests;
    _lastUpdated = now;
    notifyListeners();
  }

  /// Sends a new request. Leave isn't queued offline: the server checks
  /// balances and overlaps at the moment of submission, so the person
  /// should see its answer straight away.
  ///
  /// Throws [OfflineException] without a request when offline, and the
  /// API's typed exception otherwise (a [ValidationException] carries the
  /// field errors). On success the request is cached first in the list and
  /// balances are refreshed in the background.
  Future<LeaveRequest> submit(LeaveInput input) async {
    if (!_connectivity.isOnline) throw const OfflineException();
    final created = await _api.submitLeave(input);
    final now = _clock.nowUtc();
    await _database.db.insert(
      'leave_requests',
      {
        'id': created.id,
        'start_date': created.startDate.isoDate,
        'status': created.status.wireValue,
        'json': jsonEncode(created.toJson()),
        'updated_at': now.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _requests = [created, ..._requests.where((r) => r.id != created.id)];
    notifyListeners();
    unawaited(_refreshQuietly());
    return created;
  }

  Future<void> _refreshQuietly() async {
    try {
      await refresh();
    } catch (e, stackTrace) {
      // The new request is already cached; balances update on next refresh.
      _logger.error('Leave refresh after submit', e, stackTrace);
    }
  }

  LeaveBalance _decodeBalance(Map<String, Object?> row) =>
      LeaveBalance.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );

  LeaveRequest _decodeRequest(Map<String, Object?> row) =>
      LeaveRequest.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      );
}

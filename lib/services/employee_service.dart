// lib/services/employee_service.dart

import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:stacked/stacked.dart';

import '../app/app.locator.dart';
import '../models/employee.dart';
import 'api_service.dart';
import 'clock_service.dart';
import 'database_service.dart';

/// The preconfigured employee and their office. Reads the local cache
/// first so the app opens offline, then refreshes from the API.
class EmployeeService with ListenableServiceMixin {
  final _api = locator<ApiService>();
  final _database = locator<DatabaseService>();
  final _clock = locator<ClockService>();

  Employee? _employee;
  DateTime? _lastUpdated;

  /// The employee, once loaded from cache or network.
  Employee? get employee => _employee;

  /// When the cached copy was last refreshed from the server.
  DateTime? get lastUpdated => _lastUpdated;

  /// Loads the cached employee, if any. Never touches the network.
  Future<Employee?> loadCached() async {
    final rows = await _database.db.query('employee', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.single;
    _apply(
      Employee.fromJson(
        jsonDecode(row['json'] as String) as Map<String, dynamic>,
      ),
      DateTime.parse(row['updated_at'] as String),
    );
    return _employee;
  }

  /// Fetches the employee from the API and replaces the cache.
  ///
  /// Throws the API's typed exception on failure; the cached copy stays.
  Future<Employee> refresh() async {
    final employee = await _api.fetchEmployee();
    final now = _clock.nowUtc();
    await _database.db.transaction((txn) async {
      await txn.delete('employee');
      await txn.insert(
        'employee',
        {
          'id': employee.id,
          'json': jsonEncode(employee.toJson()),
          'updated_at': now.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    _apply(employee, now);
    return employee;
  }

  void _apply(Employee employee, DateTime updatedAt) {
    _employee = employee;
    _lastUpdated = updatedAt;
    _clock.useTimezone(employee.timezone);
    notifyListeners();
  }
}

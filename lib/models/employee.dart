// lib/models/employee.dart

import 'office_location.dart';
import 'shift.dart';

/// The signed-in employee and their work configuration.
class Employee {
  /// Creates an employee.
  const Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.office,
    required this.shift,
    required this.timezone,
  });

  /// Reads the shape returned by `GET /employee/me`.
  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as String,
        name: json['name'] as String,
        department: json['department'] as String,
        office: OfficeLocation.fromJson(json['office'] as Map<String, dynamic>),
        shift: Shift.fromJson(json['shift'] as Map<String, dynamic>),
        timezone: json['timezone'] as String,
      );

  /// Employee ID, for example "EMP-1042".
  final String id;

  /// Full name.
  final String name;

  /// Department name.
  final String department;

  /// Office used for the geofence.
  final OfficeLocation office;

  /// Planned shift.
  final Shift shift;

  /// IANA timezone of the company working day.
  final String timezone;

  /// Initials for the avatar, for example "AN".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  /// Serialises to the API shape, also used for the local cache.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'department': department,
        'office': office.toJson(),
        'shift': shift.toJson(),
        'timezone': timezone,
      };
}

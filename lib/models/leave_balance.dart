// lib/models/leave_balance.dart

import 'leave_type.dart';

/// Yearly leave entitlement for one leave type.
class LeaveBalance {
  /// Creates a balance.
  const LeaveBalance({
    required this.type,
    required this.entitlement,
    required this.used,
    required this.onHold,
    required this.available,
  });

  /// Reads the API shape.
  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
        type: LeaveType.fromWire(json['type'] as String),
        entitlement: json['entitlement'] as int,
        used: json['used'] as int,
        onHold: json['onHold'] as int,
        available: json['available'] as int,
      );

  /// Leave type this balance is for.
  final LeaveType type;

  /// Days granted for the year.
  final int entitlement;

  /// Days taken in approved requests.
  final int used;

  /// Days held by pending requests.
  final int onHold;

  /// Days that can still be requested.
  final int available;

  /// Serialises to the API shape, also used for the local cache.
  Map<String, dynamic> toJson() => {
        'type': type.wireValue,
        'entitlement': entitlement,
        'used': used,
        'onHold': onHold,
        'available': available,
      };
}

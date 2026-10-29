// lib/models/leave_filter.dart

import 'leave_status.dart';

/// Status filter on the leave overview.
enum LeaveFilter {
  /// Every request.
  all(null),

  /// Waiting for review.
  pending(LeaveStatus.pending),

  /// Approved.
  approved(LeaveStatus.approved),

  /// Rejected.
  rejected(LeaveStatus.rejected);

  const LeaveFilter(this.status);

  /// Status the filter keeps, or null for all.
  final LeaveStatus? status;
}

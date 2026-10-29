// lib/ui/views/leave/components/leave_request_tile.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../../constants/app_colors.dart';
import '../../../../models/leave_request.dart';
import '../../../../models/leave_status.dart';
import '../../../tools/app_text_style.dart';
import '../../../tools/ui_helpers.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/common/status_tone.dart';
import '../leave_viewmodel.dart';

/// One request: start date, type and range, days and reason (or the
/// reviewer's note when rejected), and its status.
class LeaveRequestTile extends ViewModelWidget<LeaveViewModel> {
  /// Creates the tile for [request].
  const LeaveRequestTile({super.key, required this.request});

  /// The request.
  final LeaveRequest request;

  @override
  Widget build(BuildContext context, LeaveViewModel viewModel) {
    final (tone, icon) = switch (request.status) {
      LeaveStatus.pending => (StatusTone.warning, Icons.schedule_rounded),
      LeaveStatus.approved => (StatusTone.success, Icons.check_rounded),
      LeaveStatus.rejected => (StatusTone.danger, Icons.close_rounded),
    };
    final isRejected = request.status == LeaveStatus.rejected;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: Palette.brandSoft,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Text(
                viewModel.badgeOf(request),
                textAlign: TextAlign.center,
                style: AppTextStyle.chip.copyWith(color: Palette.brand),
              ),
            ),
            Gap.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(viewModel.titleOf(request),
                      style: AppTextStyle.bodyStrong),
                  Gap.v4,
                  Text(
                    viewModel.detailOf(request),
                    style: AppTextStyle.caption.copyWith(
                      color: isRejected ? Palette.danger : null,
                    ),
                  ),
                ],
              ),
            ),
            Gap.h8,
            StatusChip(
              label: viewModel.statusOf(request),
              tone: tone,
              icon: icon,
            ),
          ],
        ),
      ),
    );
  }
}

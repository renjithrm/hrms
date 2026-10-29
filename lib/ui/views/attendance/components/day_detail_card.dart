// lib/ui/views/attendance/components/day_detail_card.dart

import '../../../widgets/common/motion_size.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../../constants/app_strings.dart';
import '../../../../models/calendar_day.dart';
import '../../../theme/app_motion.dart';
import '../../../tools/app_text_style.dart';
import '../../../tools/ui_helpers.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/common/status_tone.dart';
import '../attendance_viewmodel.dart';

/// Detail for one day: status, times and time worked. Used for the
/// selected calendar day and for each row of the list view.
class DayDetailCard extends ViewModelWidget<AttendanceViewModel> {
  /// Creates the card for [day].
  const DayDetailCard({super.key, required this.day});

  /// The day to describe.
  final CalendarDay day;

  @override
  Widget build(BuildContext context, AttendanceViewModel viewModel) {
    final (tone, icon) = switch (day.kind) {
      CalendarDayKind.present => (StatusTone.success, Icons.check_rounded),
      CalendarDayKind.waiting => (StatusTone.warning, Icons.schedule_rounded),
      CalendarDayKind.leave => (StatusTone.info, Icons.beach_access_rounded),
      CalendarDayKind.absent => (StatusTone.neutral, Icons.remove_rounded),
      CalendarDayKind.weekend ||
      CalendarDayKind.today ||
      CalendarDayKind.upcoming =>
        (StatusTone.neutral, null),
    };
    final hasTimes = day.attendance?.checkInAt != null;
    return Card(
      child: MotionSize(
        duration: AppMotion.of(context).base,
        curve: AppMotion.standard,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      viewModel.dateLabelOf(day),
                      style: AppTextStyle.bodyStrong,
                    ),
                  ),
                  StatusChip(
                    label: viewModel.statusOf(day),
                    tone: tone,
                    icon: icon,
                  ),
                ],
              ),
              if (hasTimes) ...[
                Gap.v12,
                Row(
                  children: [
                    Expanded(
                      child: _Fact(
                        label: AppStrings.labelCheckedIn,
                        value: viewModel.checkInOf(day),
                      ),
                    ),
                    Expanded(
                      child: _Fact(
                        label: AppStrings.labelCheckedOut,
                        value: viewModel.checkOutOf(day),
                      ),
                    ),
                    Expanded(
                      child: _Fact(
                        label: AppStrings.labelWorked,
                        value: viewModel.workedOf(day),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyle.overline),
          Gap.v4,
          Text(value, style: AppTextStyle.bodyStrong),
        ],
      ),
    );
  }
}

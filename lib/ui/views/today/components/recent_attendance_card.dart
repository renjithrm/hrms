// lib/ui/views/today/components/recent_attendance_card.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_strings.dart';
import '../../../../models/attendance_day.dart';
import '../../../tools/app_text_style.dart';
import '../../../tools/ui_helpers.dart';
import '../../../widgets/common/state_view.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/common/status_tone.dart';
import '../today_viewmodel.dart';

/// The latest five days with attendance.
class RecentAttendanceCard extends ViewModelWidget<TodayViewModel> {
  /// Creates the card.
  const RecentAttendanceCard({super.key});

  @override
  Widget build(BuildContext context, TodayViewModel viewModel) {
    final days = viewModel.recentDays;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.recentHeading.toUpperCase(),
              style: AppTextStyle.overline,
            ),
            if (days.isEmpty)
              const StateView(
                icon: Icons.event_available_outlined,
                title: AppStrings.recentEmptyTitle,
                message: AppStrings.recentEmptyMessage,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: days.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Palette.line),
                itemBuilder: (_, index) => _DayRow(day: days[index]),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends ViewModelWidget<TodayViewModel> {
  const _DayRow({required this.day});

  final AttendanceDay day;

  @override
  Widget build(BuildContext context, TodayViewModel viewModel) {
    final isWaiting = day.isWaitingToSync;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          _DateTile(
            day: viewModel.dayNumberOf(day),
            weekday: viewModel.weekdayOf(day),
          ),
          Gap.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(viewModel.timeRangeOf(day),
                    style: AppTextStyle.bodyStrong),
                Text(viewModel.workedOf(day), style: AppTextStyle.caption),
              ],
            ),
          ),
          StatusChip(
            label: isWaiting ? AppStrings.chipWaiting : AppStrings.syncSynced,
            tone: isWaiting ? StatusTone.warning : StatusTone.success,
            icon: isWaiting ? Icons.schedule_rounded : Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.day, required this.weekday});

  final String day;
  final String weekday;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 40,
      decoration: const BoxDecoration(
        color: Palette.background,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(day, style: AppTextStyle.bodyStrong.copyWith(height: 1.1)),
          Text(
            weekday.toUpperCase(),
            style: AppTextStyle.overline.copyWith(fontSize: 9, height: 1.1),
          ),
        ],
      ),
    );
  }
}

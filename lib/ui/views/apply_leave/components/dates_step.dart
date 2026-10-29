// lib/ui/views/apply_leave/components/dates_step.dart

import '../../../widgets/common/motion_size.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_strings.dart';
import '../../../../models/leave_type.dart';
import '../../../theme/app_motion.dart';
import '../../../tools/app_text_style.dart';
import '../../../tools/ui_helpers.dart';
import '../../../widgets/common/leave_range_calendar.dart';
import '../apply_leave_viewmodel.dart';

/// Screen J: leave type, date range, and what is wrong with it if anything.
class DatesStep extends ViewModelWidget<ApplyLeaveViewModel> {
  /// Creates the step.
  const DatesStep({super.key});

  @override
  Widget build(BuildContext context, ApplyLeaveViewModel viewModel) {
    final error = viewModel.dateError;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              const Text(AppStrings.leaveTypeHeading,
                  style: AppTextStyle.heading),
              Gap.v8,
              Row(
                children: [
                  for (final (index, type) in viewModel.types.indexed) ...[
                    if (index > 0) Gap.h12,
                    Expanded(child: _TypeCard(type: type)),
                  ],
                ],
              ),
              Gap.v16,
              const Text(
                AppStrings.leaveDatesHeading,
                style: AppTextStyle.heading,
              ),
              Gap.v8,
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                  child: LeaveRangeCalendar(
                    month: viewModel.visibleMonth,
                    monthLabel: viewModel.monthLabel,
                    today: viewModel.today,
                    rangeStart: viewModel.rangeStart,
                    rangeEnd: viewModel.rangeEnd,
                    marks: viewModel.dayMarks,
                    isRangeInvalid: error != null,
                    onDayTapped: viewModel.onDayTapped,
                    dayLabel: viewModel.dayLabelOf,
                    onPreviousMonth: viewModel.canGoPreviousMonth
                        ? viewModel.previousMonth
                        : null,
                    onNextMonth: viewModel.nextMonth,
                  ),
                ),
              ),
              Gap.v12,
              const _DateMessage(),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    viewModel.canContinue ? viewModel.continueToReview : null,
                child: const Text(AppStrings.continueLabel),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends ViewModelWidget<ApplyLeaveViewModel> {
  const _TypeCard({required this.type});

  final LeaveType type;

  @override
  Widget build(BuildContext context, ApplyLeaveViewModel viewModel) {
    final isSelected = viewModel.type == type;
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => viewModel.selectType(type),
        child: AnimatedContainer(
          duration: AppMotion.of(context).fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? Palette.brandSoft : Palette.surface,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            border: Border.all(
              color: isSelected ? Palette.brand : Palette.line,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(type.label, style: AppTextStyle.bodyStrong),
                  ),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 18,
                    color: isSelected ? Palette.brand : Palette.inkMuted,
                  ),
                ],
              ),
              Gap.v4,
              Text(viewModel.availableOf(type), style: AppTextStyle.caption),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hint, summary or error under the calendar; expands and collapses.
class _DateMessage extends ViewModelWidget<ApplyLeaveViewModel> {
  const _DateMessage();

  @override
  Widget build(BuildContext context, ApplyLeaveViewModel viewModel) {
    final error = viewModel.dateError;
    final after = viewModel.balanceAfter;
    final motion = AppMotion.of(context);
    return MotionSize(
      duration: motion.reveal,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: motion.reveal,
        child: Semantics(
          key: ValueKey(error ?? viewModel.dateHint),
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                error == null
                    ? Icons.calendar_today_rounded
                    : Icons.error_outline_rounded,
                size: 16,
                color: error == null ? Palette.inkMuted : Palette.danger,
              ),
              Gap.h8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      error ?? viewModel.dateHint,
                      style: AppTextStyle.body.copyWith(
                        color: error == null ? Palette.ink : Palette.danger,
                      ),
                    ),
                    if (after != null) ...[
                      Gap.v4,
                      Text(after, style: AppTextStyle.caption),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

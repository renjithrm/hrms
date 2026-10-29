// lib/ui/views/attendance/components/month_calendar.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_strings.dart';
import '../../../../models/calendar_day.dart';
import '../../../theme/app_motion.dart';
import '../../../tools/app_text_style.dart';
import '../../../tools/ui_helpers.dart';
import '../../../widgets/common/status_tone.dart';
import '../attendance_viewmodel.dart';

/// The month as a Monday-first grid. Each day has a colour and a small
/// icon for its state; tapping one shows its detail below.
class MonthCalendar extends ViewModelWidget<AttendanceViewModel> {
  /// Creates the calendar.
  const MonthCalendar({super.key});

  @override
  Widget build(BuildContext context, AttendanceViewModel viewModel) {
    final days = viewModel.calendarDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (final initial in AppStrings.weekdayInitials)
                Expanded(
                  child: Center(
                    child: Text(initial, style: AppTextStyle.overline),
                  ),
                ),
            ],
          ),
        ),
        Gap.v8,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.leadingBlanks + days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final dayIndex = index - viewModel.leadingBlanks;
            if (dayIndex < 0) return const SizedBox.shrink();
            return _DayCell(day: days[dayIndex]);
          },
        ),
        Gap.v12,
        const _Legend(),
      ],
    );
  }
}

/// Colour and icon for a day kind, shared by the cell and the legend.
(StatusTone?, IconData?) _styleOf(CalendarDayKind kind) => switch (kind) {
      CalendarDayKind.present => (StatusTone.success, Icons.check_rounded),
      CalendarDayKind.waiting => (StatusTone.warning, Icons.schedule_rounded),
      CalendarDayKind.leave => (StatusTone.info, Icons.beach_access_rounded),
      CalendarDayKind.absent => (null, Icons.remove_rounded),
      CalendarDayKind.weekend ||
      CalendarDayKind.today ||
      CalendarDayKind.upcoming =>
        (null, null),
    };

class _DayCell extends ViewModelWidget<AttendanceViewModel> {
  const _DayCell({required this.day});

  final CalendarDay day;

  @override
  Widget build(BuildContext context, AttendanceViewModel viewModel) {
    final isSelected = viewModel.isSelected(day);
    final (tone, icon) = _styleOf(day.kind);
    final isQuiet = day.kind == CalendarDayKind.weekend ||
        day.kind == CalendarDayKind.upcoming;
    final foreground = isSelected
        ? Palette.onBrand
        : tone?.foreground ?? (isQuiet ? Palette.inkMuted : Palette.ink);
    return Semantics(
      button: true,
      selected: isSelected,
      label: viewModel.semanticsOf(day),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => viewModel.selectDay(day),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: AnimatedContainer(
          duration: AppMotion.of(context).fast,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            color: isSelected
                ? Palette.brand
                : tone?.background ?? Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: day.isToday && !isSelected
                ? Border.all(color: Palette.brand, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.date.day}',
                style: AppTextStyle.bodyStrong.copyWith(color: foreground),
              ),
              SizedBox(
                height: 12,
                child: icon == null
                    ? null
                    : Icon(icon, size: 11, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          for (final (kind, label) in const [
            (CalendarDayKind.present, AppStrings.dayPresent),
            (CalendarDayKind.waiting, AppStrings.dayWaiting),
            (CalendarDayKind.leave, AppStrings.dayLeave),
            (CalendarDayKind.absent, AppStrings.dayAbsent),
          ])
            _LegendItem(kind: kind, label: label),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.kind, required this.label});

  final CalendarDayKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (tone, icon) = _styleOf(kind);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: tone?.background ?? Palette.line,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: Icon(icon, size: 11, color: tone?.foreground ?? Palette.ink),
        ),
        Gap.h4,
        Text(label, style: AppTextStyle.caption),
      ],
    );
  }
}

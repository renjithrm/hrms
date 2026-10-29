// lib/ui/widgets/common/leave_range_calendar.dart

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../models/leave_day_mark.dart';
import '../../theme/app_motion.dart';
import '../../tools/app_text_style.dart';
import '../../tools/ui_helpers.dart';

/// A month calendar for choosing a leave range. Days before [today] can't
/// be picked; existing requests are drawn so an overlap is visible before
/// it becomes an error. Purely presentational: the caller decides what a
/// tap means.
class LeaveRangeCalendar extends StatelessWidget {
  /// Creates the calendar.
  const LeaveRangeCalendar({
    super.key,
    required this.month,
    required this.monthLabel,
    required this.today,
    required this.onDayTapped,
    required this.dayLabel,
    this.rangeStart,
    this.rangeEnd,
    this.marks = const {},
    this.isRangeInvalid = false,
    this.onPreviousMonth,
    this.onNextMonth,
  });

  /// First day of the month shown, UTC midnight.
  final DateTime month;

  /// "November 2026".
  final String monthLabel;

  /// The company's today, UTC midnight.
  final DateTime today;

  /// First chosen day.
  final DateTime? rangeStart;

  /// Last chosen day; null while only the start is chosen.
  final DateTime? rangeEnd;

  /// Existing requests by day.
  final Map<DateTime, LeaveDayMark> marks;

  /// Draws the range in the error colour.
  final bool isRangeInvalid;

  /// Called with the tapped day.
  final ValueChanged<DateTime> onDayTapped;

  /// Screen-reader label for a day.
  final String Function(DateTime date) dayLabel;

  /// Shows the previous month; null disables the button.
  final VoidCallback? onPreviousMonth;

  /// Shows the next month; null disables the button.
  final VoidCallback? onNextMonth;

  @override
  Widget build(BuildContext context) {
    final count = DateTime.utc(month.year, month.month + 1, 0).day;
    final blanks = month.weekday - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: AppStrings.previousMonth,
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.bodyStrong,
                ),
              ),
            ),
            IconButton(
              tooltip: AppStrings.nextMonth,
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
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
        Gap.v4,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: blanks + count,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
          ),
          itemBuilder: (context, index) {
            final day = index - blanks + 1;
            if (day < 1) return const SizedBox.shrink();
            return _Day(
              date: DateTime.utc(month.year, month.month, day),
              calendar: this,
            );
          },
        ),
        Gap.v8,
        const ExcludeSemantics(child: _Legend()),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.date, required this.calendar});

  final DateTime date;
  final LeaveRangeCalendar calendar;

  @override
  Widget build(BuildContext context) {
    final start = calendar.rangeStart;
    final end = calendar.rangeEnd ?? start;
    final isPast = date.isBefore(calendar.today);
    final isEdge = date == start || date == end;
    final isInside = start != null &&
        end != null &&
        date.isAfter(start) &&
        date.isBefore(end);
    final mark = calendar.marks[date];
    final strong = calendar.isRangeInvalid ? Palette.danger : Palette.brand;
    final soft =
        calendar.isRangeInvalid ? Palette.dangerSoft : Palette.brandSoft;

    final Color background;
    final Color foreground;
    if (isEdge) {
      background = strong;
      foreground = Palette.onBrand;
    } else if (isInside) {
      background = soft;
      foreground = strong;
    } else if (mark == LeaveDayMark.pending) {
      background = Palette.warningSoft;
      foreground = Palette.warning;
    } else if (mark == LeaveDayMark.approved) {
      background = Palette.infoSoft;
      foreground = Palette.info;
    } else {
      background = Colors.transparent;
      foreground = isPast ? Palette.line : Palette.ink;
    }

    return Semantics(
      button: !isPast,
      enabled: !isPast,
      selected: isEdge || isInside,
      label: calendar.dayLabel(date),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: isPast ? null : () => calendar.onDayTapped(date),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: AppMotion.of(context).fast,
            curve: AppMotion.standard,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: date == calendar.today && !isEdge
                  ? Border.all(color: Palette.brand, width: 1.5)
                  : null,
            ),
            child: Text(
              '${date.day}',
              style: AppTextStyle.bodyStrong.copyWith(color: foreground),
            ),
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
    return const Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _LegendItem(
          color: Palette.warningSoft,
          icon: Icons.schedule_rounded,
          iconColor: Palette.warning,
          label: AppStrings.calendarLegendPending,
        ),
        _LegendItem(
          color: Palette.infoSoft,
          icon: Icons.check_rounded,
          iconColor: Palette.info,
          label: AppStrings.calendarLegendApproved,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: Icon(icon, size: 11, color: iconColor),
        ),
        Gap.h4,
        Text(label, style: AppTextStyle.caption),
      ],
    );
  }
}

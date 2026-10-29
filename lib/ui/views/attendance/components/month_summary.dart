// lib/ui/views/attendance/components/month_summary.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../../constants/app_strings.dart';
import '../../../tools/app_text_style.dart';
import '../../../tools/ui_helpers.dart';
import '../attendance_viewmodel.dart';

/// Days present and the average day for the month.
class MonthSummary extends ViewModelWidget<AttendanceViewModel> {
  /// Creates the summary.
  const MonthSummary({super.key});

  @override
  Widget build(BuildContext context, AttendanceViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _Figure(
                label: AppStrings.summaryPresent,
                value: viewModel.presentLabel,
              ),
            ),
            Expanded(
              child: _Figure(
                label: AppStrings.summaryAverage,
                value: viewModel.averageDayLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

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
          Text(value, style: AppTextStyle.title),
        ],
      ),
    );
  }
}

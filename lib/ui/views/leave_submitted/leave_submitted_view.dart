// lib/ui/views/leave_submitted/leave_submitted_view.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../models/leave_request.dart';
import '../../tools/app_text_style.dart';
import '../../tools/ui_helpers.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/status_tone.dart';
import '../../widgets/common/success_tick.dart';
import 'leave_submitted_viewmodel.dart';

/// Screen L: the request was sent; what it was and the balance now.
class LeaveSubmittedView extends StackedView<LeaveSubmittedViewModel> {
  /// Creates the view for [request].
  const LeaveSubmittedView({super.key, required this.request});

  /// The request the server accepted.
  final LeaveRequest request;

  @override
  Widget builder(
    BuildContext context,
    LeaveSubmittedViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                children: [
                  const Center(child: SuccessTick()),
                  Gap.v16,
                  Semantics(
                    liveRegion: true,
                    child: const Text(
                      AppStrings.requestSentTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.title,
                    ),
                  ),
                  Gap.v8,
                  const Text(
                    AppStrings.requestSentMessage,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.body,
                  ),
                  Gap.v24,
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  viewModel.typeTitle,
                                  style: AppTextStyle.heading,
                                ),
                              ),
                              StatusChip(
                                label: viewModel.statusLabel,
                                tone: StatusTone.warning,
                                icon: Icons.schedule_rounded,
                              ),
                            ],
                          ),
                          Gap.v8,
                          _Row(
                            label: AppStrings.summaryDates,
                            value: viewModel.datesLabel,
                          ),
                          _Row(
                            label: AppStrings.summaryDaysLabel,
                            value: viewModel.daysLabel,
                          ),
                          _Row(
                            label: viewModel.leftLabel,
                            value: viewModel.leftValue,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: viewModel.backToLeave,
                  child: const Text(AppStrings.backToLeave),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  LeaveSubmittedViewModel viewModelBuilder(BuildContext context) =>
      LeaveSubmittedViewModel(request);
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Palette.line)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyle.caption)),
            Gap.h12,
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppTextStyle.bodyStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/ui/views/apply_leave/components/review_step.dart

import '../../../widgets/common/motion_size.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_strings.dart';
import '../../../theme/app_motion.dart';
import '../../../tools/app_text_style.dart';
import '../../../tools/ui_helpers.dart';
import '../apply_leave_viewmodel.dart';

/// Screen K: what will be requested, the reason, and Submit.
class ReviewStep extends ViewModelWidget<ApplyLeaveViewModel> {
  /// Creates the step.
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, ApplyLeaveViewModel viewModel) {
    final datesError = viewModel.serverDatesError;
    final submitError = viewModel.submitError;
    final motion = AppMotion.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              MotionSize(
                duration: motion.reveal,
                curve: AppMotion.standard,
                child: datesError == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ErrorBanner(
                          title: AppStrings.leaveNotAcceptedTitle,
                          message: datesError,
                        ),
                      ),
              ),
              const Text(AppStrings.reviewHeading, style: AppTextStyle.heading),
              Gap.v8,
              const _Summary(),
              Gap.v16,
              const _ReasonField(),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MotionSize(
                  duration: motion.reveal,
                  curve: AppMotion.standard,
                  child: submitError == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              submitError,
                              style: AppTextStyle.caption.copyWith(
                                color: Palette.danger,
                              ),
                            ),
                          ),
                        ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: viewModel.isSubmitting
                            ? null
                            : viewModel.changeDates,
                        child: const Text(AppStrings.changeDates),
                      ),
                    ),
                    Gap.h12,
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            viewModel.canSubmit ? viewModel.submit : null,
                        child: Text(viewModel.submitLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Palette.dangerSoft,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded, color: Palette.danger),
            Gap.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.bodyStrong.copyWith(
                      color: Palette.danger,
                    ),
                  ),
                  Gap.v4,
                  Text(message, style: AppTextStyle.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends ViewModelWidget<ApplyLeaveViewModel> {
  const _Summary();

  @override
  Widget build(BuildContext context, ApplyLeaveViewModel viewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            _SummaryRow(
              label: AppStrings.summaryType,
              value: viewModel.typeLabel,
            ),
            _SummaryRow(
              label: AppStrings.summaryDates,
              value: viewModel.datesLabel,
              isFlagged: viewModel.areDatesFlagged,
            ),
            _SummaryRow(
              label: AppStrings.summaryDaysLabel,
              value: viewModel.daysLabel,
            ),
            _SummaryRow(
              label: viewModel.leftAfterLabel,
              value: viewModel.leftAfterValue,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isFlagged = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isFlagged;
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
            if (isFlagged) ...[
              const Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: Palette.danger,
              ),
              Gap.h4,
            ],
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppTextStyle.bodyStrong.copyWith(
                  color: isFlagged ? Palette.danger : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonField extends ViewModelWidget<ApplyLeaveViewModel> {
  const _ReasonField();

  @override
  Widget build(BuildContext context, ApplyLeaveViewModel viewModel) {
    final error = viewModel.reasonError;
    final motion = AppMotion.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) viewModel.onReasonBlurred();
          },
          child: TextFormField(
            initialValue: viewModel.reason,
            onChanged: viewModel.onReasonChanged,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: AppStrings.reasonLabel,
              hintText: AppStrings.reasonHint,
              alignLabelWithHint: true,
              enabledBorder: error == null
                  ? null
                  : const OutlineInputBorder(
                      borderSide: BorderSide(color: Palette.danger),
                    ),
              focusedBorder: error == null
                  ? null
                  : const OutlineInputBorder(
                      borderSide: BorderSide(color: Palette.danger, width: 2),
                    ),
            ),
          ),
        ),
        Gap.v8,
        Row(
          children: [
            if (viewModel.isReasonValid) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: Palette.success,
              ),
              Gap.h4,
              Text(
                AppStrings.reasonOk,
                style: AppTextStyle.caption.copyWith(color: Palette.success),
              ),
              Gap.h8,
            ],
            Text(viewModel.reasonCountLabel, style: AppTextStyle.caption),
          ],
        ),
        MotionSize(
          duration: motion.fieldError,
          curve: AppMotion.standard,
          alignment: Alignment.topLeft,
          child: AnimatedSwitcher(
            duration: motion.fieldError,
            child: error == null
                ? const SizedBox(
                    key: ValueKey('helper'),
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        AppStrings.reasonHelper,
                        style: AppTextStyle.caption,
                      ),
                    ),
                  )
                : Padding(
                    key: ValueKey(error),
                    padding: const EdgeInsets.only(top: 4),
                    child: Semantics(
                      liveRegion: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: Palette.danger,
                          ),
                          Gap.h4,
                          Expanded(
                            child: Text(
                              error,
                              style: AppTextStyle.caption.copyWith(
                                color: Palette.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

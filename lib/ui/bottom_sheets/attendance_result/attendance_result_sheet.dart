// lib/ui/bottom_sheets/attendance_result/attendance_result_sheet.dart

import '../../widgets/common/sheet_surface.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../models/attendance_event_type.dart';
import '../../../models/attendance_result.dart';
import '../../tools/app_text_style.dart';
import '../../tools/ui_helpers.dart';
import '../../widgets/common/success_tick.dart';
import 'attendance_result_sheet_model.dart';

/// Screen C: confirms a check-in or check-out, says whether it reached the
/// server, and closes itself after four seconds. Expects an
/// [AttendanceResult] as `request.data`.
class AttendanceResultSheet extends StackedView<AttendanceResultSheetModel> {
  /// Creates the sheet.
  const AttendanceResultSheet({
    super.key,
    required this.completer,
    required this.request,
  });

  /// Closes the sheet with a response.
  final Function(SheetResponse response)? completer;

  /// Carries the [AttendanceResult] as `data`.
  final SheetRequest request;

  void _complete(SheetResponse response) => completer?.call(response);

  @override
  Widget builder(
    BuildContext context,
    AttendanceResultSheetModel viewModel,
    Widget? child,
  ) {
    final (tone, toneSoft) = viewModel.isSynced
        ? (Palette.success, Palette.successSoft)
        : (Palette.warning, Palette.warningSoft);
    return SheetSurface(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Palette.line,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
              ),
              Gap.v16,
              const Center(child: SuccessTick()),
              Gap.v12,
              Text(
                viewModel.title,
                textAlign: TextAlign.center,
                style: AppTextStyle.heading,
              ),
              Gap.v4,
              Text(
                viewModel.timeAndPlace,
                textAlign: TextAlign.center,
                style: AppTextStyle.caption,
              ),
              Gap.v16,
              DecoratedBox(
                decoration: BoxDecoration(
                  color: toneSoft,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        viewModel.isSynced
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_upload_outlined,
                        color: tone,
                      ),
                      Gap.h12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              viewModel.syncLabel,
                              style: AppTextStyle.bodyStrong.copyWith(
                                color: tone,
                              ),
                            ),
                            Text(
                              viewModel.syncDetail,
                              style: AppTextStyle.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Gap.v16,
              FilledButton(
                onPressed: () => viewModel.close(_complete),
                child: const Text(AppStrings.resultDone),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void onViewModelReady(AttendanceResultSheetModel viewModel) =>
      viewModel.startAutoClose(_complete);

  @override
  AttendanceResultSheetModel viewModelBuilder(BuildContext context) =>
      AttendanceResultSheetModel(
        request.data is AttendanceResult
            ? request.data as AttendanceResult
            : const AttendanceResult(
                type: AttendanceEventType.checkIn,
                timeLabel: AppStrings.timeMissing,
                placeLabel: '',
                isSynced: false,
              ),
      );
}

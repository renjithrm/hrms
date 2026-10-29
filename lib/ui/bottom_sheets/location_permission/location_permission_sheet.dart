// lib/ui/bottom_sheets/location_permission/location_permission_sheet.dart

import '../../widgets/common/sheet_surface.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../models/location_failure.dart';
import '../../tools/app_text_style.dart';
import '../../tools/ui_helpers.dart';
import 'location_permission_sheet_model.dart';

/// Screen F: why location is needed and how to turn it back on. Expects a
/// [LocationFailure] as `request.data`.
class LocationPermissionSheet
    extends StackedView<LocationPermissionSheetModel> {
  /// Creates the sheet.
  const LocationPermissionSheet({
    super.key,
    required this.completer,
    required this.request,
  });

  /// Closes the sheet with a response.
  final Function(SheetResponse response)? completer;

  /// Carries the [LocationFailure] as `data`.
  final SheetRequest request;

  @override
  Widget builder(
    BuildContext context,
    LocationPermissionSheetModel viewModel,
    Widget? child,
  ) {
    void complete(SheetResponse response) => completer?.call(response);
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
              const Center(child: _Badge()),
              Gap.v12,
              Text(
                viewModel.title,
                textAlign: TextAlign.center,
                style: AppTextStyle.heading,
              ),
              Gap.v8,
              const Text(
                AppStrings.sheetWhyLocation,
                textAlign: TextAlign.center,
                style: AppTextStyle.caption,
              ),
              if (viewModel.steps.isNotEmpty) ...[
                Gap.v16,
                for (final (index, step) in viewModel.steps.indexed)
                  _Step(number: index + 1, text: step),
              ],
              Gap.v16,
              FilledButton(
                onPressed: () => viewModel.onPrimary(complete),
                child: Text(viewModel.primaryLabel),
              ),
              Gap.v8,
              TextButton(
                onPressed: () => viewModel.onDismiss(complete),
                child: const Text(AppStrings.sheetNotNow),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  LocationPermissionSheetModel viewModelBuilder(BuildContext context) =>
      LocationPermissionSheetModel(
        request.data is LocationFailure
            ? request.data as LocationFailure
            : LocationFailure.unavailable,
      );
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.warningSoft,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Icon(
          Icons.location_disabled_rounded,
          color: Palette.warning,
          size: 28,
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Palette.brandSoft,
            child: Text(
              '$number',
              style: AppTextStyle.chip.copyWith(color: Palette.brand),
            ),
          ),
          Gap.h12,
          Expanded(child: Text(text, style: AppTextStyle.body)),
        ],
      ),
    );
  }
}

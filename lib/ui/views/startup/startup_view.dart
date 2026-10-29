// lib/ui/views/startup/startup_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../tools/app_text_style.dart';
import '../../tools/ui_helpers.dart';
import 'startup_viewmodel.dart';

/// Launch screen shown while local data loads. Shows an error with a retry
/// only when the first launch cannot reach the API.
class StartupView extends StackedView<StartupViewModel> {
  /// Creates the view.
  const StartupView({super.key});

  @override
  Widget builder(
    BuildContext context,
    StartupViewModel viewModel,
    Widget? child,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Palette.deep,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: viewModel.hasError
                  ? const _StartupError()
                  : const _StartupLoading(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  StartupViewModel viewModelBuilder(BuildContext context) => StartupViewModel();

  @override
  void onViewModelReady(StartupViewModel viewModel) => SchedulerBinding.instance
      .addPostFrameCallback((_) => viewModel.runStartupLogic());
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.appName,
          style: AppTextStyle.title.copyWith(color: Palette.onBrand),
        ),
        Gap.v16,
        const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            color: Palette.onBrand,
            strokeWidth: 2.5,
          ),
        ),
        Gap.v12,
        Text(
          AppStrings.loading,
          style: AppTextStyle.caption.copyWith(color: Palette.brandSoft),
        ),
      ],
    );
  }
}

class _StartupError extends ViewModelWidget<StartupViewModel> {
  const _StartupError();

  @override
  Widget build(BuildContext context, StartupViewModel viewModel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, color: Palette.onBrand, size: 40),
        Gap.v16,
        Text(
          AppStrings.startupFailedTitle,
          textAlign: TextAlign.center,
          style: AppTextStyle.title.copyWith(color: Palette.onBrand),
        ),
        Gap.v8,
        Text(
          viewModel.errorMessage ?? AppStrings.unexpectedError,
          textAlign: TextAlign.center,
          style: AppTextStyle.body.copyWith(color: Palette.brandSoft),
        ),
        Gap.v8,
        Text(
          AppStrings.startupFailedHint,
          textAlign: TextAlign.center,
          style: AppTextStyle.caption.copyWith(color: Palette.brandSoft),
        ),
        Gap.v24,
        FilledButton.icon(
          onPressed: viewModel.isBusy ? null : viewModel.runStartupLogic,
          style: FilledButton.styleFrom(
            backgroundColor: Palette.onBrand,
            foregroundColor: Palette.deep,
          ),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text(AppStrings.tryAgain),
        ),
      ],
    );
  }
}

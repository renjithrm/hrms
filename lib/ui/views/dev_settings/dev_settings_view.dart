// lib/ui/views/dev_settings/dev_settings_view.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../models/location_preset.dart';
import '../../tools/app_text_style.dart';
import '../../tools/ui_helpers.dart';
import '../../widgets/app_back_button.dart';
import 'dev_settings_viewmodel.dart';

/// Debug-only screen for faking the location and switching mock scenarios.
class DevSettingsView extends StackedView<DevSettingsViewModel> {
  /// Creates the view.
  const DevSettingsView({super.key});

  @override
  Widget builder(
    BuildContext context,
    DevSettingsViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(onPressed: viewModel.onBackPressed),
        title: const Text(AppStrings.devSettingsTitle),
        actions: const [_DebugBadge(), Gap.h16],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (viewModel.isBusy) const LinearProgressIndicator(),
          if (viewModel.errorMessage != null) ...[
            _ErrorBanner(message: viewModel.errorMessage ?? ''),
            Gap.v12,
          ],
          const _Section(
            title: AppStrings.devLocationHeading,
            child: _PresetList(),
          ),
          Gap.v12,
          const _Section(
            title: AppStrings.devScenarioHeading,
            child: _ScenarioPicker(),
          ),
          Gap.v12,
          const _Section(
            title: AppStrings.devConfigHeading,
            child: _ConfigRows(),
          ),
        ],
      ),
    );
  }

  @override
  DevSettingsViewModel viewModelBuilder(BuildContext context) =>
      DevSettingsViewModel();

  @override
  void onViewModelReady(DevSettingsViewModel viewModel) => viewModel.init();
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: AppTextStyle.overline),
            Gap.v8,
            child,
          ],
        ),
      ),
    );
  }
}

class _PresetList extends ViewModelWidget<DevSettingsViewModel> {
  const _PresetList();

  @override
  Widget build(BuildContext context, DevSettingsViewModel viewModel) {
    return RadioGroup<LocationPreset>(
      groupValue: viewModel.selectedPreset,
      onChanged: viewModel.selectPreset,
      child: Column(
        children: [
          for (final preset in viewModel.presets)
            RadioListTile<LocationPreset>(
              value: preset,
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: Palette.brand,
              title: Text(viewModel.labelFor(preset), style: AppTextStyle.body),
            ),
        ],
      ),
    );
  }
}

class _ScenarioPicker extends ViewModelWidget<DevSettingsViewModel> {
  const _ScenarioPicker();

  @override
  Widget build(BuildContext context, DevSettingsViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final name in viewModel.scenarios)
              ChoiceChip(
                label: Text(name),
                selected: name == viewModel.selectedScenario,
                selectedColor: Palette.ink,
                labelStyle: AppTextStyle.chip.copyWith(
                  color: name == viewModel.selectedScenario
                      ? Palette.onBrand
                      : Palette.inkMuted,
                ),
                showCheckmark: false,
                onSelected: viewModel.isBusy
                    ? null
                    : (_) => viewModel.selectScenario(name),
              ),
          ],
        ),
        Gap.v12,
        OutlinedButton.icon(
          onPressed: viewModel.isBusy ? null : viewModel.resetMockData,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text(AppStrings.devResetMock),
        ),
        Gap.v8,
        OutlinedButton.icon(
          onPressed: viewModel.isBusy ? null : viewModel.clearToday,
          icon: const Icon(Icons.event_busy_rounded),
          label: const Text(AppStrings.devClearToday),
        ),
        Gap.v4,
        const Text(AppStrings.devClearTodayHint, style: AppTextStyle.caption),
      ],
    );
  }
}

class _ConfigRows extends ViewModelWidget<DevSettingsViewModel> {
  const _ConfigRows();

  @override
  Widget build(BuildContext context, DevSettingsViewModel viewModel) {
    return Column(
      children: [
        _ConfigRow(label: AppStrings.devOffice, value: viewModel.officeLabel),
        _ConfigRow(
          label: AppStrings.devTimezone,
          value: viewModel.timezoneLabel,
        ),
        _ConfigRow(label: AppStrings.devApi, value: viewModel.apiLabel),
      ],
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: AppTextStyle.caption),
          Gap.h12,
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyle.caption.copyWith(color: Palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugBadge extends StatelessWidget {
  const _DebugBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Palette.line,
          borderRadius: BorderRadius.all(Radius.circular(99)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            AppStrings.devSettingsBadge,
            style: AppTextStyle.chip.copyWith(color: Palette.inkMuted),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Palette.dangerSoft,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Palette.danger, size: 18),
            Gap.h8,
            Expanded(
              child: Text(
                message,
                style: AppTextStyle.caption.copyWith(color: Palette.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

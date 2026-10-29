// lib/ui/views/today/components/today_status_card.dart

import '../../../widgets/common/motion_size.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_strings.dart';
import '../../../../models/location_check.dart';
import '../../../../models/location_failure.dart';
import '../../../../models/sync_state.dart';
import '../../../../models/today_status.dart';
import '../../../theme/app_motion.dart';
import '../../../tools/app_text_style.dart';
import '../../../tools/ui_helpers.dart';
import '../../../widgets/common/geofence_map.dart';
import '../../../widgets/common/location_status_tile.dart';
import '../../../widgets/common/motion_switcher.dart';
import '../../../widgets/common/shift_ring.dart';
import '../../../widgets/common/slide_to_confirm.dart';
import '../../../widgets/common/status_chip.dart';
import '../../../widgets/common/status_tone.dart';
import '../today_viewmodel.dart';

/// Today's status, whether attendance is possible from here, and the
/// slider that records it.
class TodayStatusCard extends ViewModelWidget<TodayViewModel> {
  /// Creates the card.
  const TodayStatusCard({super.key});

  @override
  Widget build(BuildContext context, TodayViewModel viewModel) {
    final status = viewModel.status;
    final (label, tone, icon) = switch (status) {
      TodayNotCheckedIn() => (
          AppStrings.statusNotCheckedIn,
          StatusTone.neutral,
          null,
        ),
      TodayCheckedIn() => (
          AppStrings.statusCheckedIn,
          StatusTone.info,
          Icons.schedule_rounded,
        ),
      TodayCheckedOut() => (
          AppStrings.statusCheckedOut,
          StatusTone.neutral,
          Icons.check_rounded,
        ),
    };

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.all(Radius.circular(18)),
        boxShadow: [
          BoxShadow(
              color: Palette.shadow, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    viewModel.dateLabel.toUpperCase(),
                    style: AppTextStyle.overline,
                  ),
                ),
                StatusChip(label: label, tone: tone, icon: icon),
              ],
            ),
            Gap.v8,
            MotionSwitcher(
              child: switch (status) {
                TodayNotCheckedIn() => const _ShiftLine(key: ValueKey('none')),
                TodayCheckedIn(:final day) => Column(
                    key: const ValueKey('in'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Times(
                        isCheckInWaiting: day.checkInState != SyncState.synced,
                      ),
                      Gap.v12,
                      Center(
                        child: ShiftRing(
                          progress: viewModel.shiftProgress,
                          value: viewModel.elapsedLabel,
                          caption: viewModel.ringCaption,
                        ),
                      ),
                    ],
                  ),
                TodayCheckedOut(:final day) => Column(
                    key: const ValueKey('out'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Times(
                        isCheckInWaiting: day.checkInState != SyncState.synced,
                        isCheckOutWaiting:
                            day.checkOutState != SyncState.synced,
                        showCheckOut: true,
                      ),
                      Gap.v12,
                      Text(
                        viewModel.workedTodayLabel,
                        style: AppTextStyle.bodyStrong.copyWith(
                          color: Palette.success,
                        ),
                      ),
                    ],
                  ),
              },
            ),
            // Location and slider leave together once the day is done.
            MotionSwitcher(
              child: viewModel.showSlider
                  ? const Column(
                      key: ValueKey('actions'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Gap.v12,
                        _Location(),
                        Gap.v12,
                        _Slider(),
                      ],
                    )
                  : const SizedBox(
                      key: ValueKey('done'),
                      width: double.infinity,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Location tile, with the schematic map when outside the office area.
class _Location extends ViewModelWidget<TodayViewModel> {
  const _Location();

  @override
  Widget build(BuildContext context, TodayViewModel viewModel) {
    final location = viewModel.location;
    final (tone, icon) = switch (location) {
      LocationChecking() => (StatusTone.info, Icons.my_location_rounded),
      LocationInside() => (StatusTone.success, Icons.place_rounded),
      LocationOutside() => (StatusTone.danger, Icons.wrong_location_rounded),
      LocationImprecise() => (StatusTone.warning, Icons.gps_not_fixed_rounded),
      LocationBlocked(:final reason) => switch (reason) {
          LocationFailure.unavailable => (
              StatusTone.warning,
              Icons.gps_off_rounded,
            ),
          _ => (StatusTone.warning, Icons.location_disabled_rounded),
        },
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MotionSize(
          duration: AppMotion.of(context).base,
          curve: AppMotion.standard,
          child: location is LocationOutside
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GeofenceMap(
                    distanceMetres: location.distanceMetres,
                    radiusMetres: location.radiusMetres,
                    officeLabel: AppStrings.mapOfficeLabel,
                    youLabel: AppStrings.mapYouLabel,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        LocationStatusTile(
          title: viewModel.locationTitle,
          detail: viewModel.locationDetail,
          tone: tone,
          icon: icon,
          isChecking: location is LocationChecking,
          actionLabel: viewModel.locationActionLabel,
          onAction: viewModel.onLocationAction,
        ),
      ],
    );
  }
}

/// Slide to check in or out, with the reason when the last try failed.
class _Slider extends ViewModelWidget<TodayViewModel> {
  const _Slider();

  @override
  Widget build(BuildContext context, TodayViewModel viewModel) {
    final message = viewModel.actionMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SlideToConfirm(
          label: viewModel.slideLabel,
          lockedLabel: AppStrings.slideLocked,
          isLocked: !viewModel.canSlide && !viewModel.isSubmitting,
          onConfirmed: viewModel.onSlideConfirmed,
          onLockedTap: viewModel.onLockedSlideTap,
        ),
        MotionSize(
          duration: AppMotion.of(context).base,
          curve: AppMotion.standard,
          child: message == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      message,
                      style: AppTextStyle.caption.copyWith(
                        color: Palette.danger,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ShiftLine extends ViewModelWidget<TodayViewModel> {
  const _ShiftLine({super.key});

  @override
  Widget build(BuildContext context, TodayViewModel viewModel) {
    return Row(
      children: [
        const Icon(Icons.schedule_rounded, size: 15, color: Palette.inkMuted),
        Gap.h8,
        Flexible(
          child: Text(viewModel.shiftLabel, style: AppTextStyle.caption),
        ),
      ],
    );
  }
}

class _Times extends ViewModelWidget<TodayViewModel> {
  const _Times({
    required this.isCheckInWaiting,
    this.isCheckOutWaiting = false,
    this.showCheckOut = false,
  });

  final bool isCheckInWaiting;
  final bool isCheckOutWaiting;
  final bool showCheckOut;

  @override
  Widget build(BuildContext context, TodayViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShiftLine(),
        Gap.v12,
        Row(
          children: [
            Expanded(
              child: _Fact(
                label: AppStrings.labelCheckedIn,
                value: viewModel.checkInLabel,
                isWaiting: isCheckInWaiting,
              ),
            ),
            Expanded(
              child: _Fact(
                label: AppStrings.labelCheckedOut,
                value: viewModel.checkOutLabel,
                isWaiting: isCheckOutWaiting,
                isVisible: showCheckOut,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    required this.isWaiting,
    this.isVisible = true,
  });

  final String label;
  final String value;
  final bool isWaiting;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyle.overline),
        Gap.v4,
        Row(
          children: [
            Text(
              isVisible ? value : AppStrings.timeMissing,
              style: AppTextStyle.bodyStrong.copyWith(fontSize: 16),
            ),
            if (isVisible) ...[
              Gap.h4,
              Icon(
                isWaiting
                    ? Icons.cloud_upload_outlined
                    : Icons.cloud_done_outlined,
                size: 14,
                color: isWaiting ? Palette.warning : Palette.success,
                semanticLabel:
                    isWaiting ? AppStrings.chipWaiting : AppStrings.syncSynced,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

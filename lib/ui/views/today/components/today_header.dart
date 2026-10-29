// lib/ui/views/today/components/today_header.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../../constants/app_colors.dart';
import '../../../tools/app_text_style.dart';
import '../../../tools/ui_helpers.dart';
import '../../../widgets/common/sync_pill.dart';
import '../today_viewmodel.dart';
import 'today_status_card.dart';

/// Dark header band with identity and sync state, and the Today card
/// overlapping its lower edge.
class TodayHeader extends ViewModelWidget<TodayViewModel> {
  /// Creates the header.
  const TodayHeader({super.key});

  // How far the Today card reaches up into the band.
  static const double _cardOverlap = 36;

  @override
  Widget build(BuildContext context, TodayViewModel viewModel) {
    final top = MediaQuery.paddingOf(context).top;
    // The band sizes itself to the profile row, so it fits any name length
    // or text size. A strip of band colour behind the card's top edge makes
    // the card overlap the band without a fixed height.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: Palette.deep,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, top + 16, 16, 20),
            child: const _Identity(),
          ),
        ),
        const Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _cardOverlap,
              child: ColoredBox(color: Palette.deep),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TodayStatusCard(),
            ),
          ],
        ),
      ],
    );
  }
}

class _Identity extends ViewModelWidget<TodayViewModel> {
  const _Identity();

  @override
  Widget build(BuildContext context, TodayViewModel viewModel) {
    return Row(
      children: [
        GestureDetector(
          onLongPress:
              viewModel.canOpenDevSettings ? viewModel.openDevSettings : null,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Palette.brand,
            child: Text(
              viewModel.initials,
              style: AppTextStyle.chip.copyWith(
                color: Palette.onBrand,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Gap.h12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.caption.copyWith(color: Palette.brandSoft),
              ),
              Text(
                viewModel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.heading.copyWith(color: Palette.onBrand),
              ),
              Text(
                viewModel.idAndDepartment,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.caption.copyWith(color: Palette.brandSoft),
              ),
            ],
          ),
        ),
        Gap.h8,
        SyncPill(
          summary: viewModel.syncSummary,
          isOnDarkBackground: true,
          onTap: viewModel.openSyncQueue,
        ),
      ],
    );
  }
}

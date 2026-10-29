// lib/ui/views/leave/leave_view.dart

import '../../widgets/common/motion_size.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../constants/app_strings.dart';
import '../../theme/app_motion.dart';
import '../../tools/app_text_style.dart';
import '../../tools/ui_helpers.dart';
import '../../widgets/common/stale_data_banner.dart';
import '../../widgets/common/state_view.dart';
import '../../widgets/common/status_tone.dart';
import '../../widgets/common/sync_pill.dart';
import 'components/leave_balances.dart';
import 'components/leave_filter_chips.dart';
import 'components/leave_request_tile.dart';
import 'leave_viewmodel.dart';

/// Screen I: balances, requests by status, and "Apply for leave".
class LeaveView extends StackedView<LeaveViewModel> {
  /// Creates the view.
  const LeaveView({super.key});

  @override
  Widget builder(
    BuildContext context,
    LeaveViewModel viewModel,
    Widget? child,
  ) {
    final requests = viewModel.requests;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: viewModel.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(child: _Header()),
                  ),
                  if (viewModel.showLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (viewModel.showFullError)
                    SliverToBoxAdapter(
                      child: StateView(
                        icon: Icons.cloud_off_rounded,
                        tone: StatusTone.danger,
                        title: AppStrings.leaveLoadFailedTitle,
                        message: viewModel.errorMessage,
                        actionLabel: AppStrings.tryAgain,
                        onAction: viewModel.refresh,
                      ),
                    )
                  else ...[
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                      sliver: SliverToBoxAdapter(child: _BalancesAndFilter()),
                    ),
                    if (viewModel.showEmptyList)
                      SliverToBoxAdapter(
                        child: StateView(
                          icon: Icons.event_note_rounded,
                          tone: StatusTone.neutral,
                          title: viewModel.emptyTitle,
                          message: AppStrings.leaveEmptyMessage,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList.builder(
                          itemCount: requests.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: LeaveRequestTile(request: requests[index]),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const _ApplyButton(),
        ],
      ),
    );
  }

  @override
  LeaveViewModel viewModelBuilder(BuildContext context) => LeaveViewModel();

  @override
  void onViewModelReady(LeaveViewModel viewModel) => viewModel.init();
}

class _Header extends ViewModelWidget<LeaveViewModel> {
  const _Header();

  @override
  Widget build(BuildContext context, LeaveViewModel viewModel) {
    final banner = viewModel.bannerMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(AppStrings.tabLeave, style: AppTextStyle.title),
            ),
            SyncPill(
              summary: viewModel.syncSummary,
              onTap: viewModel.openSyncQueue,
            ),
          ],
        ),
        MotionSize(
          duration: AppMotion.of(context).base,
          curve: AppMotion.standard,
          child: banner == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: StaleDataBanner(
                    message: banner,
                    tone: viewModel.isBannerAnError
                        ? StatusTone.danger
                        : StatusTone.warning,
                    actionLabel:
                        viewModel.isBannerAnError ? AppStrings.retry : null,
                    onAction: viewModel.refresh,
                  ),
                ),
        ),
        Gap.v12,
      ],
    );
  }
}

class _BalancesAndFilter extends StatelessWidget {
  const _BalancesAndFilter();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LeaveBalances(),
        Gap.v16,
        Text(AppStrings.leaveRequestsHeading, style: AppTextStyle.heading),
        Gap.v8,
        LeaveFilterChips(),
        Gap.v12,
      ],
    );
  }
}

/// Pinned below the list. Offline it is disabled and says why.
class _ApplyButton extends ViewModelWidget<LeaveViewModel> {
  const _ApplyButton();

  @override
  Widget build(BuildContext context, LeaveViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: viewModel.canApply ? viewModel.applyForLeave : null,
          icon: Icon(
            viewModel.canApply ? Icons.add_rounded : Icons.cloud_off_rounded,
          ),
          label: Text(viewModel.applyLabel),
        ),
      ),
    );
  }
}

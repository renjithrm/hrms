// lib/ui/views/today/today_view.dart

import '../../widgets/common/motion_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../../../constants/app_strings.dart';
import '../../theme/app_motion.dart';
import '../../tools/ui_helpers.dart';
import '../../widgets/common/stale_data_banner.dart';
import '../../widgets/common/state_view.dart';
import '../../widgets/common/status_tone.dart';
import 'components/leave_balance_card.dart';
import 'components/recent_attendance_card.dart';
import 'components/today_header.dart';
import 'components/today_skeleton.dart';
import 'today_viewmodel.dart';

/// Today tab: identity, status, leave left and recent attendance.
class TodayView extends StackedView<TodayViewModel> {
  /// Creates the view.
  const TodayView({super.key});

  @override
  Widget builder(
    BuildContext context,
    TodayViewModel viewModel,
    Widget? child,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: viewModel.showSkeleton
            ? const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: TodaySkeleton(),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const TodayHeader(),
                  if (viewModel.showFullError)
                    StateView(
                      icon: Icons.cloud_off_rounded,
                      tone: StatusTone.danger,
                      title: AppStrings.todayLoadFailedTitle,
                      message: viewModel.errorMessage,
                      actionLabel: AppStrings.tryAgain,
                      onAction: viewModel.refresh,
                    )
                  else
                    const _Body(),
                ],
              ),
      ),
    );
  }

  @override
  TodayViewModel viewModelBuilder(BuildContext context) => TodayViewModel();

  @override
  void onViewModelReady(TodayViewModel viewModel) => viewModel.init();
}

class _Body extends ViewModelWidget<TodayViewModel> {
  const _Body();

  @override
  Widget build(BuildContext context, TodayViewModel viewModel) {
    final banner = viewModel.bannerMessage;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MotionSize(
            duration: AppMotion.of(context).base,
            curve: AppMotion.standard,
            child: banner == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
          const LeaveBalanceCard(),
          Gap.v12,
          const RecentAttendanceCard(),
        ],
      ),
    );
  }
}

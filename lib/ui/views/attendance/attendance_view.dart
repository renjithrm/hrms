// lib/ui/views/attendance/attendance_view.dart

import '../../widgets/common/motion_size.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../constants/app_strings.dart';
import '../../../models/calendar_day.dart';
import '../../theme/app_motion.dart';
import '../../tools/app_text_style.dart';
import '../../tools/ui_helpers.dart';
import '../../widgets/common/motion_switcher.dart';
import '../../widgets/common/stale_data_banner.dart';
import '../../widgets/common/state_view.dart';
import '../../widgets/common/status_tone.dart';
import '../../widgets/common/sync_pill.dart';
import 'attendance_viewmodel.dart';
import 'components/day_detail_card.dart';
import 'components/month_calendar.dart';
import 'components/month_summary.dart';

/// Screen H: the month's attendance as a calendar or an accessible list.
class AttendanceView extends StackedView<AttendanceViewModel> {
  /// Creates the view.
  const AttendanceView({super.key});

  @override
  Widget builder(
    BuildContext context,
    AttendanceViewModel viewModel,
    Widget? child,
  ) {
    final listDays =
        viewModel.isListView ? viewModel.listDays : const <CalendarDay>[];
    return SafeArea(
      bottom: false,
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
                  title: AppStrings.monthLoadFailedTitle,
                  message: viewModel.errorMessage,
                  actionLabel: AppStrings.tryAgain,
                  onAction: viewModel.refresh,
                ),
              )
            else if (viewModel.isListView)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: listDays.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DayDetailCard(day: listDays[index]),
                  ),
                ),
              )
            else
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverToBoxAdapter(child: _CalendarBody()),
              ),
          ],
        ),
      ),
    );
  }

  @override
  AttendanceViewModel viewModelBuilder(BuildContext context) =>
      AttendanceViewModel();

  @override
  void onViewModelReady(AttendanceViewModel viewModel) => viewModel.init();
}

/// Title and sync pill, the stale-data banner, and the month switcher.
class _Header extends ViewModelWidget<AttendanceViewModel> {
  const _Header();

  @override
  Widget build(BuildContext context, AttendanceViewModel viewModel) {
    final banner = viewModel.bannerMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(AppStrings.tabAttendance, style: AppTextStyle.title),
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
        Gap.v8,
        Row(
          children: [
            IconButton(
              tooltip: AppStrings.previousMonth,
              onPressed: viewModel.previousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  viewModel.monthLabel,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.heading,
                ),
              ),
            ),
            IconButton(
              tooltip: AppStrings.nextMonth,
              onPressed: viewModel.canGoNext ? viewModel.nextMonth : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            IconButton(
              tooltip: viewModel.viewToggleLabel,
              onPressed: viewModel.toggleListView,
              icon: Icon(
                viewModel.isListView
                    ? Icons.calendar_month_rounded
                    : Icons.view_list_rounded,
              ),
            ),
          ],
        ),
        Gap.v8,
      ],
    );
  }
}

/// Calendar, then the summary (or the empty state), then the selected day.
class _CalendarBody extends ViewModelWidget<AttendanceViewModel> {
  const _CalendarBody();

  @override
  Widget build(BuildContext context, AttendanceViewModel viewModel) {
    final selected = viewModel.selectedDay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: MonthCalendar(),
          ),
        ),
        Gap.v12,
        if (viewModel.showEmpty)
          StateView(
            icon: Icons.event_available_rounded,
            tone: StatusTone.neutral,
            title: viewModel.emptyTitle,
            message: AppStrings.emptyMonthMessage,
          )
        else
          const MonthSummary(),
        if (selected != null) ...[
          Gap.v12,
          MotionSwitcher(
            child: DayDetailCard(
              key: ValueKey(selected.date),
              day: selected,
            ),
          ),
        ],
      ],
    );
  }
}

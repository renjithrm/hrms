// lib/ui/views/main/main_view.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../constants/app_strings.dart';
import '../../theme/app_motion.dart';
import '../attendance/attendance_view.dart';
import '../leave/leave_view.dart';
import '../today/today_view.dart';
import 'main_viewmodel.dart';

/// Tab shell. All three tabs stay alive so each keeps its scroll position
/// and state; switching cross-fades between them instead of cutting.
class MainView extends StackedView<MainViewModel> {
  /// Creates the view.
  const MainView({super.key});

  static const List<Widget> _tabs = [
    TodayView(),
    AttendanceView(),
    LeaveView(),
  ];

  @override
  Widget builder(
    BuildContext context,
    MainViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      body: Stack(
        children: [
          for (final (index, tab) in _tabs.indexed)
            _Tab(isActive: index == viewModel.currentIndex, child: tab),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: viewModel.currentIndex,
        onDestinationSelected: viewModel.selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: AppStrings.tabToday,
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: AppStrings.tabAttendance,
          ),
          NavigationDestination(
            icon: Icon(Icons.beach_access_outlined),
            selectedIcon: Icon(Icons.beach_access_rounded),
            label: AppStrings.tabLeave,
          ),
        ],
      ),
    );
  }

  @override
  MainViewModel viewModelBuilder(BuildContext context) => MainViewModel();
}

/// One tab: visible and interactive only while active. Inactive tabs stay
/// mounted but don't paint, take input, animate or reach screen readers.
///
/// Fade-through: the old tab fades out in the first half of the switch and
/// the new one fades in during the second half, so they never show on top
/// of each other.
class _Tab extends StatelessWidget {
  const _Tab({required this.isActive, required this.child});

  final bool isActive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The fade must sit outside TickerMode: a muted ticker would freeze the
    // fade-out and leave the old tab painted over the new one.
    return AnimatedOpacity(
      opacity: isActive ? 1 : 0,
      duration: AppMotion.of(context).base,
      curve: isActive
          ? const Interval(0.5, 1, curve: Curves.easeOut)
          : const Interval(0, 0.5, curve: Curves.easeIn),
      child: IgnorePointer(
        ignoring: !isActive,
        child: ExcludeSemantics(
          excluding: !isActive,
          child: TickerMode(enabled: isActive, child: child),
        ),
      ),
    );
  }
}

// lib/ui/views/apply_leave/apply_leave_view.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../constants/app_strings.dart';
import '../../../models/apply_leave_step.dart';
import '../../theme/app_motion.dart';
import '../../tools/app_text_style.dart';
import '../../widgets/app_back_button.dart';
import 'apply_leave_viewmodel.dart';
import 'components/dates_step.dart';
import 'components/review_step.dart';

/// Applying for leave: step 1 picks type and dates (screen J), step 2
/// reviews and submits (screen K). The steps slide horizontally.
class ApplyLeaveView extends StackedView<ApplyLeaveViewModel> {
  /// Creates the view.
  const ApplyLeaveView({super.key});

  @override
  Widget builder(
    BuildContext context,
    ApplyLeaveViewModel viewModel,
    Widget? child,
  ) {
    return PopScope(
      canPop: viewModel.step == ApplyLeaveStep.dates,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) viewModel.onBackPressed();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: AppBackButton(onPressed: viewModel.onBackPressed),
          title: const Text(AppStrings.applyForLeave),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(viewModel.stepLabel, style: AppTextStyle.caption),
              ),
            ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: AppMotion.of(context).base,
          switchInCurve: AppMotion.standard,
          switchOutCurve: AppMotion.standard,
          transitionBuilder: _slide,
          child: switch (viewModel.step) {
            ApplyLeaveStep.dates => const DatesStep(key: ValueKey('dates')),
            ApplyLeaveStep.review => const ReviewStep(key: ValueKey('review')),
          },
        ),
      ),
    );
  }

  // Step 2 enters from the right and leaves to the right; step 1 from the
  // left. With the reversed animation of the outgoing child, going forward
  // slides left and going back slides right.
  static Widget _slide(Widget child, Animation<double> animation) {
    final isReview = child.key == const ValueKey('review');
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(isReview ? 0.25 : -0.25, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  ApplyLeaveViewModel viewModelBuilder(BuildContext context) =>
      ApplyLeaveViewModel();
}

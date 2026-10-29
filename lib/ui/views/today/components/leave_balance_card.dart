// lib/ui/views/today/components/leave_balance_card.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../../constants/app_strings.dart';
import '../../../tools/app_text_style.dart';
import '../../../tools/ui_helpers.dart';
import '../../../widgets/common/balance_meter.dart';
import '../today_viewmodel.dart';

/// Leave days left per type.
class LeaveBalanceCard extends ViewModelWidget<TodayViewModel> {
  /// Creates the card.
  const LeaveBalanceCard({super.key});

  @override
  Widget build(BuildContext context, TodayViewModel viewModel) {
    final balances = viewModel.balances;
    if (balances.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.leaveAvailable.toUpperCase(),
              style: AppTextStyle.overline,
            ),
            Gap.v8,
            Row(
              children: [
                for (final (index, balance) in balances.indexed) ...[
                  if (index > 0) Gap.h16,
                  Expanded(
                    child: BalanceMeter(
                      label: balance.type.label,
                      available: balance.available,
                      total: balance.entitlement,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

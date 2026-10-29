// lib/ui/views/leave/components/leave_balances.dart

import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../../../../constants/app_colors.dart';
import '../../../tools/app_text_style.dart';
import '../../../tools/ui_helpers.dart';
import '../../../widgets/common/balance_meter.dart';
import '../leave_viewmodel.dart';

/// One card per leave type: days left of the yearly entitlement, and days
/// held by pending requests.
class LeaveBalances extends ViewModelWidget<LeaveViewModel> {
  /// Creates the balances.
  const LeaveBalances({super.key});

  @override
  Widget build(BuildContext context, LeaveViewModel viewModel) {
    final balances = viewModel.balances;
    if (balances.isEmpty) return const SizedBox.shrink();
    // Both cards take the taller one's height, even when only one has the
    // "on hold" line.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, balance) in balances.indexed) ...[
            if (index > 0) Gap.h12,
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BalanceMeter(
                        label: balance.type.label,
                        available: balance.available,
                        total: balance.entitlement,
                      ),
                      if (viewModel.onHoldOf(balance)
                          case final String held) ...[
                        Gap.v8,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.hourglass_top_rounded,
                              size: 13,
                              color: Palette.warning,
                            ),
                            Gap.h4,
                            Expanded(
                              child: Text(held, style: AppTextStyle.caption),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

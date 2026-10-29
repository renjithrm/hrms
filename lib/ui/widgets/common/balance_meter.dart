// lib/ui/widgets/common/balance_meter.dart

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../tools/app_text_style.dart';

/// Leave days left of a yearly total, with a bar that fills on first show.
class BalanceMeter extends StatelessWidget {
  /// Creates the meter.
  const BalanceMeter({
    super.key,
    required this.label,
    required this.available,
    required this.total,
  });

  /// Leave type, for example "Casual".
  final String label;

  /// Days that can still be requested.
  final int available;

  /// Yearly entitlement.
  final int total;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : (available / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$available',
                style: AppTextStyle.display.copyWith(fontSize: 22)),
            const SizedBox(width: 6),
            Text(label.toLowerCase(), style: AppTextStyle.caption),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: share),
            duration: AppMotion.of(context).slow * 1.75,
            curve: AppMotion.standard,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 5,
              color: Palette.brand,
              backgroundColor: Palette.line,
            ),
          ),
        ),
      ],
    );
  }
}

// lib/ui/widgets/common/status_chip.dart

import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../tools/app_text_style.dart';
import 'status_tone.dart';

/// Small rounded label with an icon, for attendance and leave states.
class StatusChip extends StatelessWidget {
  /// Creates a chip.
  const StatusChip({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  /// Word shown in the chip.
  final String label;

  /// Colour pair.
  final StatusTone tone;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.of(context).fast,
      curve: AppMotion.standard,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: const BorderRadius.all(Radius.circular(99)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tone.foreground),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: AppTextStyle.chip.copyWith(color: tone.foreground)),
        ],
      ),
    );
  }
}

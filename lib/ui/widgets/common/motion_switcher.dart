// lib/ui/widgets/common/motion_switcher.dart

import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import 'motion_size.dart';

/// Swaps [child] with a fade-through: the old content fades out quickly,
/// the new one fades in with a slight rise, and the space between them
/// resizes smoothly instead of jumping.
///
/// Both children are pinned to [alignment] (top-left by default) while they
/// overlap, so content doesn't shift sideways mid-swap. Give each child a
/// distinct key. With reduce motion the swap is instant.
class MotionSwitcher extends StatelessWidget {
  /// Creates the switcher.
  const MotionSwitcher({
    super.key,
    required this.child,
    this.duration,
    this.alignment = Alignment.topLeft,
  });

  /// Content; a new key starts a swap.
  final Widget child;

  /// Length of the swap; defaults to `AppMotion.base`.
  final Duration? duration;

  /// Where both children sit while they overlap.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final length = duration ?? AppMotion.of(context).base;
    return MotionSize(
      duration: length,
      curve: AppMotion.standard,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: length,
        reverseDuration: length * 0.6,
        // The new content waits for the old to mostly fade first.
        switchInCurve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: alignment,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: child,
      ),
    );
  }
}

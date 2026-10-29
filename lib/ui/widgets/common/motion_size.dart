// lib/ui/widgets/common/motion_size.dart

import 'package:flutter/widgets.dart';

/// [AnimatedSize] that steps aside when [duration] is zero.
///
/// `AppMotion` returns zero durations when reduce motion is on, and
/// `AnimatedSize` asserts if it finishes an animation synchronously during
/// layout. With a zero duration this simply lays out [child] at its size.
class MotionSize extends StatelessWidget {
  /// Creates the widget.
  const MotionSize({
    super.key,
    required this.duration,
    required this.child,
    this.curve = Curves.linear,
    this.alignment = Alignment.topCenter,
  });

  /// Length of the size change; zero for none.
  final Duration duration;

  /// Curve of the size change.
  final Curve curve;

  /// How the child is placed while the size changes. Top by default, so
  /// content stays put and only the bottom edge moves.
  final AlignmentGeometry alignment;

  /// Content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}

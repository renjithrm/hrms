// lib/ui/widgets/common/shift_ring.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../tools/app_text_style.dart';

/// How much of the shift has passed, as an arc around the elapsed time.
///
/// The arc sweeps in from zero the first time it is shown, then eases to
/// each new [progress] (which callers change once a minute).
class ShiftRing extends StatefulWidget {
  /// Creates the ring.
  const ShiftRing({
    super.key,
    required this.progress,
    required this.value,
    required this.caption,
    this.size = 132,
  });

  /// Share of the shift worked, 0 to 1. Values above 1 draw a full ring.
  final double progress;

  /// Large text in the middle, for example "3:12:45".
  final String value;

  /// Small text under [value], for example "of 9h shift".
  final String caption;

  /// Diameter.
  final double size;

  @override
  State<ShiftRing> createState() => _ShiftRingState();
}

class _ShiftRingState extends State<ShiftRing> {
  bool _hasSwept = false;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final duration = _hasSwept ? motion.slow : motion.ring;
    return Semantics(
      label: '${widget.value}, ${widget.caption}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.progress.clamp(0.0, 1.0)),
          duration: duration,
          curve: _hasSwept ? AppMotion.standard : Curves.easeInOutCubic,
          onEnd: () => _hasSwept = true,
          builder: (context, value, child) => CustomPaint(
            painter: _RingPainter(value),
            child: child,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.value,
                  style: AppTextStyle.title.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(widget.caption, style: AppTextStyle.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);

  final double progress;

  static const double _stroke = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final track = Paint()
      ..color = Palette.brandSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (progress <= 0) return;
    final arc = Paint()
      ..color = Palette.brand
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _stroke;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

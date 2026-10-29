// lib/ui/widgets/common/success_tick.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../theme/app_motion.dart';

/// Green disc that scales in (450 ms), then draws its tick (400 ms), with a
/// light haptic. Holds only animation state, a documented exception to the
/// stateless shared-widget rule; with reduce motion it appears complete.
class SuccessTick extends StatefulWidget {
  /// Creates the tick.
  const SuccessTick({super.key});

  @override
  State<SuccessTick> createState() => _SuccessTickState();
}

class _SuccessTickState extends State<SuccessTick>
    with SingleTickerProviderStateMixin {
  static const Duration _scaleIn = Duration(milliseconds: 450);
  static const Duration _draw = Duration(milliseconds: 400);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _scaleIn + _draw,
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 450 / 850, curve: AppMotion.emphasized),
  );
  late final Animation<double> _tick = CurvedAnimation(
    parent: _controller,
    curve: const Interval(450 / 850, 1, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    HapticFeedback.lightImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (AppMotion.of(context).canLoop) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Palette.successSoft,
          shape: BoxShape.circle,
        ),
        child: CustomPaint(painter: _TickPainter(_tick)),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.71, size.height * 0.38);
    final paint = Paint()
      ..color = Palette.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress.value),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TickPainter oldDelegate) => false;
}

// lib/ui/widgets/common/location_status_tile.dart

import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../tools/app_text_style.dart';
import 'status_tone.dart';

/// Shows whether attendance is possible from where the person is, before
/// they try. Pulses only while a GPS fix is being read.
class LocationStatusTile extends StatelessWidget {
  /// Creates the tile.
  const LocationStatusTile({
    super.key,
    required this.title,
    required this.detail,
    required this.tone,
    required this.icon,
    this.isChecking = false,
    this.actionLabel,
    this.onAction,
  });

  /// Main line, for example "You're at the office".
  final String title;

  /// Distance, accuracy or how to fix the problem.
  final String detail;

  /// Colour pair.
  final StatusTone tone;

  /// Leading icon.
  final IconData icon;

  /// Whether a fix is being read; animates the icon.
  final bool isChecking;

  /// Optional action label, such as "Update my location".
  final String? actionLabel;

  /// Action handler.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return AnimatedContainer(
      duration: AppMotion.of(context).base,
      curve: AppMotion.standard,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isChecking
                    ? _PulsingIcon(icon: icon, color: tone.foreground)
                    : Icon(icon, size: 20, color: tone.foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.bodyStrong.copyWith(
                          color: tone.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: AppTextStyle.caption.copyWith(
                          color: tone.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (label != null && onAction != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isChecking ? null : onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: tone.foreground,
                minimumSize: const Size.fromHeight(40),
                side: BorderSide(color: tone.foreground.withValues(alpha: 0.4)),
              ),
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: Text(label),
            ),
          ],
        ],
      ),
    );
  }
}

/// Holds only animation state, a documented exception to the stateless
/// shared-widget rule. Static when reduce motion is on.
class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.of(context).canLoop) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Transform.scale(
              scale: 1 + _controller.value * 1.4,
              child: Opacity(
                opacity: (1 - _controller.value) * 0.6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color, width: 2),
                  ),
                  child: const SizedBox.square(dimension: 20),
                ),
              ),
            ),
          ),
          Icon(widget.icon, size: 20, color: widget.color),
        ],
      ),
    );
  }
}

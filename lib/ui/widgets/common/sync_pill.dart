// lib/ui/widgets/common/sync_pill.dart

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../models/sync_summary.dart';
import '../../theme/app_motion.dart';
import '../../tools/app_text_style.dart';
import 'motion_switcher.dart';
import 'status_tone.dart';

/// Always-visible sync state. Crossfades between states; the icon spins
/// only while a sync is running.
class SyncPill extends StatelessWidget {
  /// Creates the pill.
  const SyncPill({
    super.key,
    required this.summary,
    this.isOnDarkBackground = false,
    this.onTap,
  });

  /// State to show.
  final SyncSummary summary;

  /// Use the translucent style for the dark header band.
  final bool isOnDarkBackground;

  /// Opens the sync sheet (stage 7).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon, tone) = switch (summary) {
      SyncAllSynced() => (
          AppStrings.syncSynced,
          Icons.cloud_done_outlined,
          StatusTone.success,
        ),
      SyncOffline() => (
          AppStrings.syncOffline,
          Icons.cloud_off_outlined,
          StatusTone.warning,
        ),
      SyncWaiting(:final count) => (
          AppStrings.syncWaiting(count),
          Icons.cloud_upload_outlined,
          StatusTone.warning,
        ),
      SyncInProgress() => (
          AppStrings.syncInProgress,
          Icons.sync_rounded,
          StatusTone.info,
        ),
      SyncNeedsAttention() => (
          AppStrings.syncNeedsAttention,
          Icons.error_outline_rounded,
          StatusTone.danger,
        ),
    };
    final isCalm = summary is SyncAllSynced;
    final background = isOnDarkBackground && isCalm
        ? Palette.onBrand.withValues(alpha: 0.14)
        : tone.background;
    final foreground =
        isOnDarkBackground && isCalm ? Palette.onBrand : tone.foreground;

    return Semantics(
      button: onTap != null,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        // Fades between states and eases the width change, anchored to the
        // right edge where the pill sits.
        child: MotionSwitcher(
          alignment: Alignment.centerRight,
          child: Container(
            key: ValueKey(label),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: background,
              borderRadius: const BorderRadius.all(Radius.circular(99)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                summary is SyncInProgress
                    ? _SpinningIcon(icon: icon, color: foreground)
                    : Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppTextStyle.chip.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Holds only animation state, a documented exception to the stateless
/// shared-widget rule. Stops when reduce motion is on.
class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
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
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, size: 14, color: widget.color),
    );
  }
}

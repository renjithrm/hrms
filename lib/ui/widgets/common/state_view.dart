// lib/ui/widgets/common/state_view.dart

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../tools/app_text_style.dart';
import '../../tools/ui_helpers.dart';
import 'status_tone.dart';

/// Centred message for empty and error states, with an optional action.
class StateView extends StatelessWidget {
  /// Creates the view.
  const StateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone = StatusTone.neutral,
    this.actionLabel,
    this.onAction,
  });

  /// Icon in the coloured circle.
  final IconData icon;

  /// One-line summary.
  final String title;

  /// What happened and what to do.
  final String message;

  /// Colour of the icon circle.
  final StatusTone tone;

  /// Label of the action button, if any.
  final String? actionLabel;

  /// Action handler; the button shows only when both are set.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: tone.background,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: tone.foreground, size: 24),
            ),
          ),
          Gap.v12,
          Text(title,
              textAlign: TextAlign.center, style: AppTextStyle.bodyStrong),
          Gap.v4,
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyle.caption.copyWith(color: Palette.inkMuted),
          ),
          if (label != null && onAction != null) ...[
            Gap.v16,
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(label),
            ),
          ],
        ],
      ),
    );
  }
}

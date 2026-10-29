// lib/ui/widgets/common/stale_data_banner.dart

import 'package:flutter/material.dart';

import '../../tools/app_text_style.dart';
import 'status_tone.dart';

/// Thin banner above cached content: offline, or a refresh that failed.
class StaleDataBanner extends StatelessWidget {
  /// Creates the banner.
  const StaleDataBanner({
    super.key,
    required this.message,
    required this.tone,
    this.actionLabel,
    this.onAction,
  });

  /// What the person is looking at, for example "Showing data from 17:40".
  final String message;

  /// Warning for offline, danger for a failed refresh.
  final StatusTone tone;

  /// Optional action, such as "Retry".
  final String? actionLabel;

  /// Action handler.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Icon(
              tone == StatusTone.danger
                  ? Icons.error_outline_rounded
                  : Icons.cloud_off_outlined,
              size: 16,
              color: tone.foreground,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyle.caption.copyWith(color: tone.foreground),
              ),
            ),
            if (label != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: tone.foreground),
                child: Text(label, style: AppTextStyle.chip),
              ),
          ],
        ),
      ),
    );
  }
}

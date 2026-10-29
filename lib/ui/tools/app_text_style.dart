// lib/ui/tools/app_text_style.dart

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Every text style used by the app. Use `.copyWith()` for one-off changes.
///
/// Times, durations and counts use tabular figures so digits line up and
/// the live timer does not jitter.
abstract final class AppTextStyle {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Large numbers: timer, balances.
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: Palette.ink,
    fontFeatures: _tabular,
  );

  /// Screen titles.
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: Palette.ink,
  );

  /// Sheet titles and card headings.
  static const TextStyle heading = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: Palette.ink,
  );

  /// Emphasised body text and list item titles.
  static const TextStyle bodyStrong = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: Palette.ink,
    fontFeatures: _tabular,
  );

  /// Default body text.
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: Palette.ink,
  );

  /// Secondary lines under titles.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: Palette.inkMuted,
    fontFeatures: _tabular,
  );

  /// Small uppercase labels above values.
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.6,
    color: Palette.inkMuted,
  );

  /// Chip and pill labels.
  static const TextStyle chip = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Button labels.
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}

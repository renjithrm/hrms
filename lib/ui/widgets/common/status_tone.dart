// lib/ui/widgets/common/status_tone.dart

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// Semantic colour pairs for chips, pills and banners. Always shown with an
/// icon and a word, never colour alone.
enum StatusTone {
  /// Synced, present, inside the office area.
  success(Palette.success, Palette.successSoft),

  /// Waiting to sync, pending, offline.
  warning(Palette.warning, Palette.warningSoft),

  /// Rejected, failed, outside the office area.
  danger(Palette.danger, Palette.dangerSoft),

  /// In progress, checking, on leave.
  info(Palette.info, Palette.infoSoft),

  /// No particular state.
  neutral(Palette.inkMuted, Palette.line);

  const StatusTone(this.foreground, this.background);

  /// Text and icon colour.
  final Color foreground;

  /// Fill colour.
  final Color background;
}

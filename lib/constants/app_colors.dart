// lib/constants/app_colors.dart

import 'package:flutter/material.dart';

/// Every colour used by the app. Widgets must reference these, never hex
/// values inline.
abstract final class Palette {
  /// Header band and the check-out slider.
  static const Color deep = Color(0xFF0B3F37);

  /// Primary brand colour: buttons, active states, check-in slider.
  static const Color brand = Color(0xFF0F6B5C);

  /// Tinted brand surface for selected chips and the active tab pill.
  static const Color brandSoft = Color(0xFFDCEFE9);

  /// Text and icons placed on [brand] or [deep].
  static const Color onBrand = Color(0xFFFFFFFF);

  /// Screen background.
  static const Color background = Color(0xFFF1F4F3);

  /// Card and sheet surface.
  static const Color surface = Color(0xFFFFFFFF);

  /// Primary text.
  static const Color ink = Color(0xFF12201B);

  /// Secondary text and inactive icons.
  static const Color inkMuted = Color(0xFF5F6D68);

  /// Dividers, borders and disabled fills.
  static const Color line = Color(0xFFE2E8E5);

  /// Synced, present, inside the geofence, success.
  static const Color success = Color(0xFF1A7442);

  /// Background for [success] chips and banners.
  static const Color successSoft = Color(0xFFDCF1E3);

  /// Waiting to sync, pending leave, offline.
  static const Color warning = Color(0xFFA8640A);

  /// Background for [warning] chips and banners.
  static const Color warningSoft = Color(0xFFFCEFD9);

  /// Rejected events, validation errors, outside the geofence.
  static const Color danger = Color(0xFFBF342A);

  /// Background for [danger] chips and banners.
  static const Color dangerSoft = Color(0xFFFDE4E1);

  /// In progress (syncing, checking location) and leave days.
  static const Color info = Color(0xFF2A5FB0);

  /// Background for [info] chips.
  static const Color infoSoft = Color(0xFFE1EAF8);

  /// Scrim behind bottom sheets.
  static const Color scrim = Color(0x7A08180F);

  /// Soft shadow under the Today card and floating buttons.
  static const Color shadow = Color(0x1F0B3F37);
}

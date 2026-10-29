// lib/ui/tools/ui_helpers.dart

import 'package:flutter/widgets.dart';

/// Spacing scale from the design system: 4, 8, 12, 16, 24.
abstract final class Gap {
  /// 4 px vertical gap.
  static const Widget v4 = SizedBox(height: 4);

  /// 8 px vertical gap.
  static const Widget v8 = SizedBox(height: 8);

  /// 12 px vertical gap.
  static const Widget v12 = SizedBox(height: 12);

  /// 16 px vertical gap.
  static const Widget v16 = SizedBox(height: 16);

  /// 24 px vertical gap.
  static const Widget v24 = SizedBox(height: 24);

  /// 4 px horizontal gap.
  static const Widget h4 = SizedBox(width: 4);

  /// 8 px horizontal gap.
  static const Widget h8 = SizedBox(width: 8);

  /// 12 px horizontal gap.
  static const Widget h12 = SizedBox(width: 12);

  /// 16 px horizontal gap.
  static const Widget h16 = SizedBox(width: 16);
}

/// Side padding for screen content.
const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);

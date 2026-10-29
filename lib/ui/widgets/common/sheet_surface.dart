// lib/ui/widgets/common/sheet_surface.dart

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

/// The background of every bottom sheet: the surface colour with rounded
/// top corners. Needed because `BottomSheetService` shows custom sheets on
/// a transparent layer that ignores the theme's bottom sheet colour.
class SheetSurface extends StatelessWidget {
  /// Creates the surface around [child].
  const SheetSurface({super.key, required this.child});

  /// Sheet content.
  final Widget child;

  /// Corner radius, matching the theme's bottom sheet shape.
  static const double radius = 26;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
      child: child,
    );
  }
}

// lib/ui/theme/app_theme.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../tools/app_text_style.dart';

/// Material 3 theme built from [Palette] and [AppTextStyle].
abstract final class AppTheme {
  /// The app's only theme; the brief does not require dark mode.
  static ThemeData get light {
    // Every slot is set from Palette. ColorScheme.fromSeed is not used
    // because it generates its own tones that the design never chose.
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Palette.brand,
      onPrimary: Palette.onBrand,
      primaryContainer: Palette.brandSoft,
      onPrimaryContainer: Palette.deep,
      secondary: Palette.deep,
      onSecondary: Palette.onBrand,
      secondaryContainer: Palette.brandSoft,
      onSecondaryContainer: Palette.deep,
      tertiary: Palette.info,
      onTertiary: Palette.onBrand,
      tertiaryContainer: Palette.infoSoft,
      onTertiaryContainer: Palette.info,
      error: Palette.danger,
      onError: Palette.onBrand,
      errorContainer: Palette.dangerSoft,
      onErrorContainer: Palette.danger,
      surface: Palette.surface,
      onSurface: Palette.ink,
      onSurfaceVariant: Palette.inkMuted,
      surfaceContainerLowest: Palette.surface,
      surfaceContainerLow: Palette.surface,
      surfaceContainer: Palette.background,
      surfaceContainerHigh: Palette.background,
      surfaceContainerHighest: Palette.line,
      outline: Palette.line,
      outlineVariant: Palette.line,
      shadow: Palette.shadow,
      scrim: Palette.scrim,
      inverseSurface: Palette.ink,
      onInverseSurface: Palette.surface,
      inversePrimary: Palette.brandSoft,
      // Same as the surface, so raised cards and sheets get no tint.
      surfaceTint: Palette.surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Palette.background,
      dividerColor: Palette.line,
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.background,
        foregroundColor: Palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyle.title,
      ),
      // Smooth page changes: fade-forward on Android, the native slide on
      // iOS (which also keeps the swipe-back gesture).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: const CardThemeData(
        color: Palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Palette.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Palette.brand,
          foregroundColor: Palette.onBrand,
          disabledBackgroundColor: Palette.line,
          disabledForegroundColor: Palette.inkMuted,
          minimumSize: const Size.fromHeight(48),
          textStyle: AppTextStyle.button,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.brand,
          minimumSize: const Size.fromHeight(48),
          textStyle: AppTextStyle.button,
          side: const BorderSide(color: Palette.line, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Palette.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Palette.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Palette.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Palette.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Palette.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Palette.danger, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Palette.surface,
        modalBarrierColor: Palette.scrim,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Palette.surface,
        indicatorColor: Palette.brandSoft,
        elevation: 0,
      ),
    );
  }
}

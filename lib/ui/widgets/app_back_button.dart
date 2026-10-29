// lib/ui/widgets/app_back_button.dart

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// The app's only back button. Pass the ViewModel's handler.
class AppBackButton extends StatelessWidget {
  /// Creates the button.
  const AppBackButton({super.key, required this.onPressed});

  /// Called on tap, usually `viewModel.onBackPressed`.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      color: Palette.ink,
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}

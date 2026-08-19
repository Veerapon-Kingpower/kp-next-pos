import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizing.dart';

/// Primary/secondary/destructive action buttons — the three action kinds
/// used throughout checkout, forms, and dialogs (see design.md's shared
/// component list). Sizing enforces the minimum touch target from
/// `AppSizing`.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return icon == null
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(AppSizing.controlHeight),
    );
    return icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon),
            label: Text(label),
          );
  }
}

class AppDestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AppDestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: AppColors.danger,
      minimumSize: const Size.fromHeight(AppSizing.controlHeight),
    );
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon),
            label: Text(label),
          );
  }
}

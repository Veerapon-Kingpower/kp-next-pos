import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizing.dart';
import '../../theme/app_spacing.dart';

/// Shared chrome for the mockup's overlay/side-panel screens (Discount &
/// promotion, Flight & passport capture, the flight date/time picker,
/// Lookups) — a title bar with a close action, plus "Esc to cancel/return"
/// (see docs/superpowers/specs/2026-08-27-pos-desktop-design.md). Callers
/// place this inside their own `showDialog`/overlay call; it owns only the
/// header chrome and the Escape-key binding, not the surrounding dialog
/// route.
class OverlayPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onClose;
  final double? width;

  const OverlayPanel({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
      child: Focus(
        autofocus: true,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.cornerRadiusMd),
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title, style: textTheme.titleMedium),
                      ),
                      IconButton(
                        key: const Key('overlayPanelCloseButton'),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/test_id.dart';
import 'handheld_scaffold.dart';
import 'handheld_tokens.dart';

/// Persistent bottom action bar (mockup screens 3–9, 12–20): one full-width
/// [primary] action, an optional [secondary] beside it (e.g. Cancel), and
/// an optional row of icon-over-label [items] below (Customer / Discount /
/// Save / More).
class HandheldActionBar extends StatelessWidget {
  final Widget? primary;
  final Widget? secondary;
  final List<HandheldBarItem> items;

  const HandheldActionBar({
    super.key,
    this.primary,
    this.secondary,
    this.items = const [],
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: HandheldContentWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (primary != null || secondary != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      if (primary != null) Expanded(child: primary!),
                      if (primary != null && secondary != null)
                        const SizedBox(width: 10),
                      ?secondary,
                    ],
                  ),
                ),
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [for (final item in items) Expanded(child: item)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 56 dp primary action. On light surfaces it is `goldDark` with white
/// text; with [onDark] (sign-in on `ink`) it is `gold` with `ink` text.
/// A null [onPressed] renders the disabled / inert state (handheld spec
/// decision 3).
class HandheldPrimaryButton extends StatelessWidget {
  final String id;
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool onDark;

  const HandheldPrimaryButton({
    super.key,
    required this.id,
    required this.label,
    this.icon,
    this.onPressed,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final background = !enabled
        ? (onDark ? Colors.white.withValues(alpha: 0.12) : AppColors.line)
        : (onDark ? AppColors.gold : AppColors.goldDark);
    final foreground = !enabled
        ? (onDark ? Colors.white.withValues(alpha: 0.5) : AppColors.mutedText)
        : (onDark ? AppColors.ink : Colors.white);

    return TestId(
      id,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: SizedBox(
          height: HandheldMetrics.primaryActionHeight,
          width: double.infinity,
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: foreground),
                    const SizedBox(width: 11),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 104×56 outlined secondary action (Cancel / Undo) beside a primary.
class HandheldSecondaryButton extends StatelessWidget {
  final String id;
  final String label;
  final VoidCallback? onPressed;
  final bool onDark;

  const HandheldSecondaryButton({
    super.key,
    required this.id,
    required this.label,
    this.onPressed,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? Colors.white : AppColors.textPrimary;
    return TestId(
      id,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: SizedBox(
          height: HandheldMetrics.primaryActionHeight,
          width: 104,
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
              side: BorderSide(
                color: onDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppColors.line,
              ),
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13.5, color: foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon-over-label shortcut in the action bar's lower row. A null
/// [onPressed] renders it greyed and inert.
class HandheldBarItem extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const HandheldBarItem({
    super.key,
    required this.id,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null ? AppColors.hintText : AppColors.goldDark;
    return TestId(
      id,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
          child: SizedBox(
            height: HandheldMetrics.primaryActionHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(height: 5),
                Text(label, style: TextStyle(fontSize: 10.5, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

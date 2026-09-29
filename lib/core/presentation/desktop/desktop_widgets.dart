import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/test_id.dart';
import 'desktop_tokens.dart';

/// White rounded panel with a gold caps [title] — the mockup's content
/// blocks ("Terminal identity", "Start a sale", "Peripherals" …).
class DesktopPanel extends StatelessWidget {
  final String? id;
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DesktopPanel({
    super.key,
    this.id,
    this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesktopMetrics.panelRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title!.toUpperCase(),
                      style: DesktopText.panelLabel,
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      ),
    );
    return id == null ? panel : TestId(id!, child: panel);
  }
}

/// Small rounded key label: `F2`, `ENTER`, `ESC`.
class DesktopHotkeyChip extends StatelessWidget {
  final String label;
  final bool onDark;

  const DesktopHotkeyChip(this.label, {super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.18) : AppColors.cream,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          color: onDark ? Colors.white : AppColors.goldMuted,
        ),
      ),
    );
  }
}

/// Large icon tile with title, subtitle and hotkey (Home: Sale F2 /
/// Registration F3 / Enquiry F4). A null [onTap] renders it inert.
class DesktopActionTile extends StatelessWidget {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? hotkey;
  final VoidCallback? onTap;

  const DesktopActionTile({
    super.key,
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hotkey,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return TestId(
      id,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesktopMetrics.panelRadius),
            side: const BorderSide(color: AppColors.line),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DesktopMetrics.panelRadius),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: 34,
                        color: enabled
                            ? AppColors.goldDark
                            : AppColors.hintText,
                      ),
                      const Spacer(),
                      if (hotkey != null) DesktopHotkeyChip(hotkey!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: DesktopText.sectionTitle),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText,
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

/// Desktop button. Primary is `goldDark` with white text; [secondary] is
/// outlined. Optional [hotkey] chip; null [onPressed] renders it inert.
class DesktopButton extends StatelessWidget {
  final String id;
  final String label;
  final IconData? icon;
  final String? hotkey;
  final VoidCallback? onPressed;
  final bool secondary;
  final double height;

  const DesktopButton({
    super.key,
    required this.id,
    required this.label,
    this.icon,
    this.hotkey,
    this.onPressed,
    this.secondary = false,
    this.height = DesktopMetrics.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final Color background;
    final Color foreground;
    if (secondary) {
      background = AppColors.surface;
      foreground = enabled ? AppColors.textPrimary : AppColors.hintText;
    } else {
      background = enabled ? AppColors.goldDark : AppColors.line;
      foreground = enabled ? Colors.white : AppColors.mutedText;
    }
    return TestId(
      id,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: SizedBox(
          height: height,
          child: Material(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
              side: secondary
                  ? const BorderSide(color: Color(0xFFD8DDE5))
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(9),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 16,
                        color: secondary && enabled
                            ? AppColors.goldDark
                            : foreground,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: secondary
                              ? FontWeight.w400
                              : FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                    ),
                    if (hotkey != null) ...[
                      const SizedBox(width: 10),
                      DesktopHotkeyChip(hotkey!, onDark: !secondary),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Caps label + big tabular value (KPI tiles on Home).
class DesktopKpi extends StatelessWidget {
  final String id;
  final String label;
  final String value;

  const DesktopKpi({
    super.key,
    required this.id,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: DesktopText.fieldLabel),
        const SizedBox(height: 6),
        TestId(id, child: Text(value, style: DesktopText.kpiValue)),
      ],
    );
  }
}

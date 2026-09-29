import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/test_id.dart';
import 'handheld_tokens.dart';

/// One option of a single-choice row (Percent / Amount / Promo, Collect /
/// Take, preset percentages). Selected options fill with ink ([dark]) or a
/// cream / goldDark outline; a null [onTap] renders it inert.
class HandheldChoiceChip extends StatelessWidget {
  final String id;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;

  /// Selected fill style: ink with white text (mode tabs) instead of the
  /// cream / goldDark outline (presets, pickup).
  final bool dark;

  const HandheldChoiceChip({
    super.key,
    required this.id,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.height = 44,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final Color background;
    final Color foreground;
    final BorderSide side;
    if (selected && dark) {
      background = AppColors.ink;
      foreground = Colors.white;
      side = BorderSide.none;
    } else if (selected) {
      background = AppColors.cream;
      foreground = AppColors.goldDark;
      side = const BorderSide(color: AppColors.goldDark, width: 2);
    } else {
      background = AppColors.surface;
      foreground = enabled ? AppColors.textPrimary : AppColors.hintText;
      side = const BorderSide(color: Color(0xFFD8DDE5));
    }

    return TestId(
      id,
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: side,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HandheldText.label.copyWith(
                        fontSize: 12.5,
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
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

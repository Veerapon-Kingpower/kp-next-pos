import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/test_id.dart';
import 'handheld_tokens.dart';

/// 84 dp icon-over-label shortcut tile (Home: Register / Sale / Checkout /
/// Enquiry). A null [onTap] renders it inert.
class HandheldTile extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const HandheldTile({
    super.key,
    required this.id,
    required this.icon,
    required this.label,
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
            borderRadius: BorderRadius.circular(HandheldMetrics.radius),
            side: const BorderSide(color: AppColors.line),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(HandheldMetrics.radius),
            child: SizedBox(
              height: HandheldMetrics.tileHeight,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: enabled ? AppColors.goldDark : AppColors.hintText,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HandheldText.label.copyWith(
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.mutedText,
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

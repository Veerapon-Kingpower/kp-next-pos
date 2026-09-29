import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/test_id.dart';
import 'handheld_tokens.dart';

/// Ink bar with a gold caption and one big number — "New line net" on the
/// Discount sheet, "Net amount" on Edit line (mockup screens 7, 14).
class HandheldNetBar extends StatelessWidget {
  final String id;
  final String label;
  final String value;

  const HandheldNetBar({
    super.key,
    required this.id,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      id,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(HandheldMetrics.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HandheldText.statValue.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

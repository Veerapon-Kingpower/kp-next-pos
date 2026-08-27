import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Step indicator for the mockup's Checkout/Payment wizard screens
/// ("Step 2 of 3", "Step 3 of 3") — see
/// docs/superpowers/specs/2026-08-27-pos-desktop-design.md.
class WizardStepBar extends StatelessWidget {
  final String title;
  final int currentStep;
  final int totalSteps;

  const WizardStepBar({
    super.key,
    required this.title,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: textTheme.titleMedium),
        Text(
          'Step $currentStep of $totalSteps',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

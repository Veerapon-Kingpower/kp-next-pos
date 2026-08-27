import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizing.dart';
import '../../theme/app_spacing.dart';

/// Gates `child` behind a "supervisor card required" placeholder — the
/// mockup's Settings screen locks terminal setup fields until authorised
/// (see docs/superpowers/specs/2026-08-27-pos-desktop-design.md, decision
/// 4). `onUnlock` is a stub for now: there's no supervisor-card
/// verification backend yet, so callers should show their own
/// `// TODO(pos-desktop): verify supervisor card` at the call site rather
/// than this widget inventing a fake check.
class SupervisorLockGate extends StatelessWidget {
  final bool locked;
  final VoidCallback onUnlock;
  final Widget child;

  const SupervisorLockGate({
    super.key,
    required this.locked,
    required this.onUnlock,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: AppSizing.iconSizeLarge,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Locked — supervisor card required',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              key: const Key('supervisorUnlockButton'),
              onPressed: onUnlock,
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}

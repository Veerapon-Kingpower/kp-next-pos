import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Desktop-only landing screen — screen 2 of the POS Desktop mockup ("Home —
/// shift, scan-to-start, hotkeys"). Placeholder for Phase 1: shift figures,
/// scan-to-start, and hotkey tiles land in a later phase (see
/// docs/superpowers/specs/2026-08-27-pos-desktop-design.md). Only reachable
/// at desktop width — see `HomePage`'s breakpoint-aware navigation.
class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text('Home dashboard — coming soon'),
      ),
    );
  }
}

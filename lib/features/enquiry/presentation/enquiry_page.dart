import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Transaction search — screen 10 of the POS Desktop mockup. Placeholder
/// for Phase 1: presentation-only per
/// docs/superpowers/specs/2026-08-27-pos-desktop-design.md's decision 4 —
/// the real search UI, local state, and (eventually) a backend usecase land
/// in a later phase once scoped. Only reachable at desktop width — see
/// `HomePage`'s breakpoint-aware navigation.
class EnquiryPage extends StatelessWidget {
  const EnquiryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text('Enquiry — coming soon'),
      ),
    );
  }
}

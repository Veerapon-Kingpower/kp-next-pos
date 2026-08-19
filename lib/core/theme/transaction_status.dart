import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The checkout state machine from design.md's "Explicit checkout state
/// machine" decision: draft, validating, awaiting-device, approved,
/// declined, cancelled, unresolved, finalizing, finalized, failed. A sale
/// cannot move to finalized from unresolved or failed.
enum TransactionStatus {
  draft,
  validating,
  awaitingDevice,
  approved,
  declined,
  cancelled,
  unresolved,
  finalizing,
  finalized,
  failed,
}

class TransactionStatusStyle {
  final Color color;
  final IconData icon;
  final String label;

  const TransactionStatusStyle({
    required this.color,
    required this.icon,
    required this.label,
  });
}

/// Per the `pos-sales-workflows` spec's requirement that "Payment, device,
/// validation, and error states SHALL include text or icon treatment in
/// addition to colour" — every status carries a distinct icon and label,
/// not just a colour, so colour-blind users and monochrome printouts can
/// still distinguish them.
extension TransactionStatusStyling on TransactionStatus {
  TransactionStatusStyle get style => switch (this) {
    TransactionStatus.draft => const TransactionStatusStyle(
      color: AppColors.neutral,
      icon: Icons.edit_note,
      label: 'Draft',
    ),
    TransactionStatus.validating => const TransactionStatusStyle(
      color: AppColors.info,
      icon: Icons.hourglass_top,
      label: 'Validating',
    ),
    TransactionStatus.awaitingDevice => const TransactionStatusStyle(
      color: AppColors.warning,
      icon: Icons.point_of_sale,
      label: 'Awaiting device',
    ),
    TransactionStatus.approved => const TransactionStatusStyle(
      color: AppColors.success,
      icon: Icons.check_circle,
      label: 'Approved',
    ),
    TransactionStatus.declined => const TransactionStatusStyle(
      color: AppColors.danger,
      icon: Icons.cancel,
      label: 'Declined',
    ),
    TransactionStatus.cancelled => const TransactionStatusStyle(
      color: AppColors.neutral,
      icon: Icons.block,
      label: 'Cancelled',
    ),
    TransactionStatus.unresolved => const TransactionStatusStyle(
      color: AppColors.warning,
      icon: Icons.warning_amber,
      label: 'Unresolved',
    ),
    TransactionStatus.finalizing => const TransactionStatusStyle(
      color: AppColors.info,
      icon: Icons.sync,
      label: 'Finalizing',
    ),
    TransactionStatus.finalized => const TransactionStatusStyle(
      color: AppColors.success,
      icon: Icons.task_alt,
      label: 'Finalized',
    ),
    TransactionStatus.failed => const TransactionStatusStyle(
      color: AppColors.danger,
      icon: Icons.error,
      label: 'Failed',
    ),
  };
}

import 'package:flutter/material.dart';

import '../../theme/transaction_status.dart';

/// Renders a [TransactionStatus] as an icon + label chip — the concrete
/// shared component backing the `pos-sales-workflows` spec's requirement
/// that payment/device/validation/error states never rely on colour alone.
class StatusChip extends StatelessWidget {
  final TransactionStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final style = status.style;
    return Chip(
      avatar: Icon(style.icon, color: style.color, size: 18),
      label: Text(style.label),
      side: BorderSide(color: style.color),
      backgroundColor: style.color.withValues(alpha: 0.08),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/presentation/handheld/handheld.dart';
import '../../../../../core/presentation/widgets/test_id.dart';
import '../../../../../core/theme/app_colors.dart';
import 'payment_models.dart';

/// Small caps label above a payment-screen block ("Method", "Tender
/// ledger", "Amounts").
class PaymentBlockLabel extends StatelessWidget {
  final String text;

  const PaymentBlockLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: HandheldText.overline.copyWith(color: AppColors.mutedText),
      ),
    );
  }
}

/// APPROVED / PENDING / DECLINED / VOIDED status text in its colour.
class TenderStatusLabel extends StatelessWidget {
  final TenderStatus status;

  const TenderStatusLabel(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TenderStatus.approved => AppColors.success,
      TenderStatus.pending => AppColors.warning,
      TenderStatus.declined => AppColors.danger,
      TenderStatus.voided => AppColors.neutral,
    };
    return Text(
      status.name.toUpperCase(),
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    );
  }
}

/// One tender in a ledger: method icon, title / reference, amount + status.
class TenderRow extends StatelessWidget {
  final String id;
  final Tender tender;
  final bool highlighted;
  final VoidCallback? onTap;

  const TenderRow({
    super.key,
    required this.id,
    required this.tender,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle =
        tender.reference ??
        (tender.method == TenderMethod.card ? 'Void on EDC terminal' : null);
    return TestId(
      id,
      child: Material(
        color: highlighted ? AppColors.cream : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
          side: BorderSide(
            color: highlighted ? AppColors.goldMuted : AppColors.line,
            width: highlighted ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(tender.method.icon, size: 20, color: AppColors.goldDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tender.title,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: HandheldText.bodySmall.copyWith(
                            fontSize: 10.5,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatBaht(tender.amount),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    TenderStatusLabel(tender.status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White rounded card used for the payment screens' content blocks.
class PaymentCard extends StatelessWidget {
  final String? id;
  final Widget child;

  const PaymentCard({super.key, this.id, required this.child});

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(HandheldMetrics.radius),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
    return id == null ? card : TestId(id!, child: card);
  }
}

/// Label / value row inside a [PaymentCard].
class PaymentValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? id;

  const PaymentValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.id,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    return id == null ? row : TestId(id!, child: row);
  }
}

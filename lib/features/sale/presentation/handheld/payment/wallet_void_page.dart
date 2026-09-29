import 'package:flutter/material.dart';

import '../../../../../core/presentation/handheld/handheld.dart';
import '../../../../../core/presentation/test_ids.dart';
import '../../../../../core/presentation/widgets/test_id.dart';
import '../../../../../core/theme/app_colors.dart';
import 'payment_models.dart';
import 'payment_widgets.dart';

/// Void a wallet payment (mockup screen 20): full amount only, a reason,
/// and manager approval before Void enables.
///
/// The reason is local state. Manager-card / PIN verification and the 2C2P
/// void call have no API yet, so approval and Void stay inert.
// TODO(pos-handheld): verify the manager card / PIN and call the 2C2P void.
class WalletVoidPage extends StatefulWidget {
  final Tender tender;

  const WalletVoidPage({super.key, required this.tender});

  @override
  State<WalletVoidPage> createState() => _WalletVoidPageState();
}

class _WalletVoidPageState extends State<WalletVoidPage> {
  static const _reasons = [
    'Customer cancelled purchase',
    'Wrong amount charged',
    'Duplicate charge',
    'Other',
  ];

  String _reason = _reasons.first;

  @override
  Widget build(BuildContext context) {
    final tender = widget.tender;
    final provider = tender.walletProvider?.label ?? 'wallet';
    final amount = formatBaht(tender.amount);

    return TestId(
      WalletIds.voidPage,
      child: HandheldScaffold(
        header: HandheldHeader(
          title: 'Void $provider payment',
          subtitle:
              'Cancels the full charge. The amount goes back to the '
              "customer's wallet.",
          leading: const BackButton(color: Colors.white),
          stats: [
            HandheldStat(
              id: 'wallet.voidHeaderAmount',
              label: 'Void',
              value: amount,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(HandheldMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaymentBlockLabel('Amount'),
              PaymentCard(
                id: WalletIds.voidAmount,
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Full payment only',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const PaymentBlockLabel('Reason'),
              TestId(
                WalletIds.voidReason,
                child: DropdownButtonFormField<String>(
                  initialValue: _reason,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  items: [
                    for (final reason in _reasons)
                      DropdownMenuItem(value: reason, child: Text(reason)),
                  ],
                  onChanged: (value) =>
                      setState(() => _reason = value ?? _reason),
                ),
              ),
              const SizedBox(height: 16),
              const PaymentBlockLabel('Manager approval'),
              TestId(
                WalletIds.managerApproval,
                child: Semantics(
                  button: true,
                  enabled: false,
                  child: Container(
                    height: HandheldMetrics.primaryActionHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        HandheldMetrics.radiusSm,
                      ),
                      border: Border.all(color: const Color(0xFFD8DDE5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: AppColors.hintText,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Manager card / PIN — not available yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF8EE),
                  borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
                  border: Border.all(color: const Color(0xFFF5E2C9)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Voiding reopens $amount on this bill. Take another '
                        'tender or cancel the bill before closing.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A5A16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Wallet QR tenders only. Card payments are voided on the EDC.',
                style: HandheldText.bodySmall,
              ),
            ],
          ),
        ),
        actionBar: HandheldActionBar(
          primary: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HandheldPrimaryButton(
                id: WalletIds.confirmVoidButton,
                label: 'Void $amount',
                icon: Icons.close,
              ),
              const SizedBox(height: 6),
              const Text(
                'Enabled after manager approval',
                style: TextStyle(fontSize: 11, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

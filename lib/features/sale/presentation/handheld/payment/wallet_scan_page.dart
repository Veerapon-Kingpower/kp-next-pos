import 'package:flutter/material.dart';

import '../../../../../core/presentation/handheld/handheld.dart';
import '../../../../../core/presentation/test_ids.dart';
import '../../../../../core/presentation/widgets/test_id.dart';
import '../../../../../core/theme/app_colors.dart';
import 'payment_models.dart';
import 'payment_widgets.dart';

/// Wallet · B scan C (mockup screen 18): scan the customer's payment code,
/// identify the wallet locally, then send the charge.
///
/// Scanning and wallet detection are real (local). Sending the charge,
/// polling for the customer's confirmation and "Show QR instead" (C scan B)
/// need the 2C2P integration, so the steps after "Code scanned" stay
/// pending and the send button is inert.
// TODO(pos-handheld): send / poll the charge through 2C2P and generate the
// C-scan-B QR once the payment API exists.
class WalletScanPage extends StatefulWidget {
  final double amount;

  const WalletScanPage({super.key, required this.amount});

  @override
  State<WalletScanPage> createState() => _WalletScanPageState();
}

class _WalletScanPageState extends State<WalletScanPage> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  String? _scanned;

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onScan(String value) {
    setState(() => _scanned = value.trim().isEmpty ? null : value.trim());
  }

  void _rescan() {
    setState(() => _scanned = null);
    _code.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final provider = _scanned == null ? null : detectWalletProvider(_scanned!);
    final detected = provider != null && provider != WalletProvider.unknown;

    return TestId(
      WalletIds.scanPage,
      child: HandheldScaffold(
        header: HandheldHeader(
          title: 'Scan customer code',
          subtitle: 'Wallet · B scan C',
          leading: const BackButton(color: Colors.white),
          trailing: TestId(
            WalletIds.showQrButton,
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                disabledForegroundColor: AppColors.gold.withValues(alpha: 0.6),
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Show QR'),
            ),
          ),
          stats: [
            HandheldStat(
              id: WalletIds.chargeAmount,
              label: 'Charge',
              value: formatBaht(widget.amount),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(HandheldMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PaymentCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Ask the customer to open their wallet and tap Pay. '
                      'Press either side trigger and aim at the barcode.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    const SizedBox(height: 12),
                    ScanField(
                      id: WalletIds.codeField,
                      controller: _code,
                      focusNode: _focus,
                      autofocus: true,
                      hintText: 'Scan payment code',
                      onSubmitted: _onScan,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (detected)
                TestId(
                  WalletIds.detectedCode,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2FBF7),
                      borderRadius: BorderRadius.circular(
                        HandheldMetrics.radius,
                      ),
                      border: Border.all(color: AppColors.online, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2, color: AppColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            maskPaymentCode(_scanned!),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${provider.label} detected',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F6947),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_scanned != null)
                const TestId(
                  WalletIds.unknownCode,
                  child: Text(
                    'Not a wallet payment code — ask the customer to show '
                    'the Pay barcode and scan again.',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              const SizedBox(height: 14),
              PaymentCard(
                child: Column(
                  children: [
                    _Step(
                      id: WalletIds.step('scanned'),
                      label: 'Code scanned',
                      done: detected,
                    ),
                    _Step(
                      id: WalletIds.step('sent'),
                      label: 'Charge sent',
                      done: false,
                    ),
                    _Step(
                      id: WalletIds.step('confirmed'),
                      label: 'Customer confirms',
                      done: false,
                    ),
                    _Step(
                      id: WalletIds.step('approved'),
                      label: 'Approved',
                      done: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sending wallet charges is not available yet on this device.',
                style: HandheldText.bodySmall,
              ),
            ],
          ),
        ),
        actionBar: HandheldActionBar(
          primary: HandheldPrimaryButton(
            id: WalletIds.sendChargeButton,
            label: 'Send charge ${formatBaht(widget.amount)}',
          ),
          secondary: HandheldSecondaryButton(
            id: WalletIds.cancelButton,
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          items: [
            HandheldBarItem(
              id: WalletIds.rescanButton,
              icon: Icons.refresh,
              label: 'Rescan',
              onPressed: _scanned == null ? null : _rescan,
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String id;
  final String label;
  final bool done;

  const _Step({required this.id, required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return TestId(
      id,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: done ? AppColors.success : AppColors.hintText,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: done ? AppColors.textPrimary : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/presentation/handheld/handheld.dart';
import '../../../../../core/presentation/test_ids.dart';
import '../../../../../core/presentation/widgets/test_id.dart';
import 'payment_models.dart';
import 'payment_widgets.dart';
import 'wallet_void_page.dart';

/// Payment · tenders with a wallet query (mockup screen 19): the bill's
/// tender ledger with the [focus] wallet tender highlighted, its 2C2P query
/// result, and Void.
///
/// The 2C2P query (settlement status, wallet txn id, payer, void window)
/// has no API yet, so the result block says so rather than showing
/// invented values.
// TODO(pos-handheld): call the 2C2P query / show query history once the
// payment API exists.
class WalletQueryPage extends StatelessWidget {
  final List<Tender> tenders;
  final Tender focus;

  const WalletQueryPage({
    super.key,
    required this.tenders,
    required this.focus,
  });

  @override
  Widget build(BuildContext context) {
    final approved = tenders.where((t) => t.isSettled).length;
    return TestId(
      WalletIds.queryPage,
      child: HandheldScaffold(
        header: HandheldHeader(
          title: 'Payment · tenders',
          subtitle:
              '${tenders.length} tender${tenders.length == 1 ? '' : 's'}'
              ' · $approved approved',
          leading: const BackButton(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(HandheldMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaymentBlockLabel('Tender ledger'),
              for (var i = 0; i < tenders.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                TenderRow(
                  id: PaymentIds.ledgerRow(i),
                  tender: tenders[i],
                  highlighted: identical(tenders[i], focus),
                ),
              ],
              const SizedBox(height: 16),
              PaymentCard(
                id: WalletIds.queryResult,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Query result',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PaymentValueRow(
                      label: 'Wallet',
                      value: focus.walletProvider?.label ?? focus.method.label,
                    ),
                    if (focus.reference != null)
                      PaymentValueRow(
                        label: '2C2P ref',
                        value: focus.reference!,
                      ),
                    PaymentValueRow(
                      label: 'Amount charged',
                      value: formatBaht(focus.amount),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Querying 2C2P for settlement status is not available '
                      'yet on this device.',
                      style: HandheldText.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionBar: HandheldActionBar(
          primary: HandheldPrimaryButton(
            id: WalletIds.voidButton,
            label: 'Void ${formatBaht(focus.amount)}',
            icon: Icons.close,
            onPressed: focus.isVoidableHere
                ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WalletVoidPage(tender: focus),
                    ),
                  )
                : null,
          ),
          items: const [
            HandheldBarItem(
              id: WalletIds.queryButton,
              icon: Icons.sync,
              label: 'Query 2C2P',
            ),
            HandheldBarItem(
              id: WalletIds.printButton,
              icon: Icons.print_outlined,
              label: 'Print',
            ),
          ],
        ),
      ),
    );
  }
}

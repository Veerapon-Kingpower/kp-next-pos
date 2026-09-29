import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/presentation/handheld/handheld.dart';
import '../../../../../core/presentation/test_ids.dart';
import '../../../../../core/presentation/widgets/test_id.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/currency.dart';
import '../../widgets/change_currency_screen.dart';
import 'payment_models.dart';
import 'payment_widgets.dart';
import 'wallet_query_page.dart';
import 'wallet_scan_page.dart';

/// Pushes the Payment page for [netPay], in the order's [currencyCode]
/// (legacy `CurrencyPay`).
Future<void> openPaymentPage(
  BuildContext context, {
  required double netPay,
  String currencyCode = 'THB',
  double rateToBaht = 1,
  Future<List<Currency>> Function()? loadCurrencies,
  ExchangeChange? exchangeChange,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PaymentPage(
        netPay: netPay,
        currencyCode: currencyCode,
        rateToBaht: rateToBaht,
        loadCurrencies: loadCurrencies,
        exchangeChange: exchangeChange,
      ),
    ),
  );
}

/// Payment · split tender (mockup screen 6): net pay / tendered /
/// remaining, method picker, amount to charge with presets, the tender
/// ledger, and Charge.
///
/// Method, amount and presets are local UI state, and remaining is
/// computed from approved [tenders]. Charging has no API yet: Wallet hands
/// off to the B-scan-C page (itself inert at "send charge"); card / cash /
/// UnionPay / e-Purse / voucher Charge is inert. Nothing is ever added to
/// the ledger without a real approval.
// TODO(pos-handheld): charge via EDC / sale engine / 2C2P, append tenders
// from real responses, and complete the sale when remaining hits zero.
class PaymentPage extends StatefulWidget {
  final double netPay;
  final List<Tender> tenders;

  /// The order's currency; amounts here are in it.
  final String currencyCode;

  /// Baht per one unit of [currencyCode] — the CHANGE screen works in baht.
  final double rateToBaht;

  /// Feed the CHANGE screen (legacy `ChangePage`); without them "Change in
  /// another currency" is inert.
  final Future<List<Currency>> Function()? loadCurrencies;
  final ExchangeChange? exchangeChange;

  const PaymentPage({
    super.key,
    required this.netPay,
    this.tenders = const [],
    this.currencyCode = 'THB',
    this.rateToBaht = 1,
    this.loadCurrencies,
    this.exchangeChange,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _amount = TextEditingController();
  final _cashReceived = TextEditingController();

  String _money(double value) => formatMoney(value, widget.currencyCode);
  TenderMethod _method = TenderMethod.card;

  double get _remaining {
    final value = widget.netPay - tenderedTotal(widget.tenders);
    return value < 0 ? 0 : value;
  }

  double get _chargeAmount => double.tryParse(_amount.text) ?? 0;

  @override
  void initState() {
    super.initState();
    _setAmount(_remaining);
    _amount.addListener(() => setState(() {}));
    _cashReceived.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _cashReceived.dispose();
    super.dispose();
  }

  // Cash received → applied to bill / change due (client-side, the same
  // `previewCashTender` as desktop), and change handed back in another
  // currency via the CHANGE screen (legacy `ChangePage`).
  List<Widget> _cashBlock() {
    final preview = previewCashTender(
      remaining: _remaining,
      tendered: double.tryParse(_cashReceived.text) ?? 0,
    );
    final canExchange =
        preview.change > 0 &&
        widget.loadCurrencies != null &&
        widget.exchangeChange != null;
    return [
      const SizedBox(height: 18),
      const PaymentBlockLabel('Cash received'),
      _AmountField(
        id: PaymentIds.cashReceivedField,
        controller: _cashReceived,
        currencyCode: widget.currencyCode,
      ),
      const SizedBox(height: 8),
      PaymentCard(
        child: Column(
          children: [
            PaymentValueRow(
              id: PaymentIds.cashApplied,
              label: 'Applied to bill',
              value: _money(preview.applied),
            ),
            PaymentValueRow(
              id: PaymentIds.cashChangeDue,
              label: 'Change due',
              value: _money(preview.change),
              valueColor: preview.change > 0 ? AppColors.success : null,
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      HandheldSecondaryButton(
        id: CurrencyIds.changeButton,
        label: 'Change in another currency',
        onPressed: canExchange
            ? () => showChangeCurrencyScreen(
                context,
                changeInBaht: preview.change * widget.rateToBaht,
                loadCurrencies: widget.loadCurrencies!,
                exchange: widget.exchangeChange!,
              )
            : null,
      ),
    ];
  }

  void _setAmount(double value) {
    final clamped = value.clamp(0, _remaining).toDouble();
    _amount.text = clamped.toStringAsFixed(2);
  }

  void _charge() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WalletScanPage(amount: _chargeAmount),
      ),
    );
  }

  void _openTender(Tender tender) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WalletQueryPage(tenders: widget.tenders, focus: tender),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenders = widget.tenders;
    final approved = tenders.where((t) => t.isSettled).length;
    final canCharge =
        _method == TenderMethod.wallet &&
        _chargeAmount > 0 &&
        _chargeAmount <= _remaining;

    return TestId(
      PaymentIds.page,
      child: HandheldScaffold(
        header: HandheldHeader(
          title: 'Payment',
          subtitle: tenders.isEmpty
              ? 'No tenders yet'
              : '${tenders.length} tender${tenders.length == 1 ? '' : 's'}'
                    ' · $approved approved',
          leading: const BackButton(color: Colors.white),
          stats: [
            HandheldStat(
              id: PaymentIds.netPay,
              label: 'Net pay',
              value: _money(widget.netPay),
            ),
            HandheldStat(
              id: PaymentIds.tendered,
              label: 'Tendered',
              value: _money(tenderedTotal(tenders)),
            ),
            HandheldStat(
              id: PaymentIds.remaining,
              label: 'Remaining',
              value: _money(_remaining),
              flex: 3,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(HandheldMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PaymentBlockLabel('Method'),
              _MethodGrid(
                selected: _method,
                onSelect: (m) => setState(() => _method = m),
              ),
              const SizedBox(height: 18),
              const PaymentBlockLabel('Amount to charge'),
              _AmountField(
                controller: _amount,
                currencyCode: widget.currencyCode,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _Preset(
                    id: PaymentIds.presetAllRemaining,
                    label: 'All remaining',
                    onTap: () => _setAmount(_remaining),
                  ),
                  _Preset(
                    id: PaymentIds.presetHalf,
                    label: 'Half',
                    onTap: () => _setAmount(_remaining / 2),
                  ),
                  _Preset(
                    id: PaymentIds.preset10000,
                    label: _money(10000),
                    onTap: () => _setAmount(10000),
                  ),
                  _Preset(
                    id: PaymentIds.preset20000,
                    label: _money(20000),
                    onTap: () => _setAmount(20000),
                  ),
                ],
              ),
              if (_method == TenderMethod.cash) ..._cashBlock(),
              const SizedBox(height: 18),
              const PaymentBlockLabel('Tender ledger'),
              TestId(
                PaymentIds.ledger,
                child: tenders.isEmpty
                    ? const TestId(
                        PaymentIds.ledgerEmpty,
                        child: PaymentCard(
                          child: Text(
                            'No tenders yet.',
                            style: HandheldText.bodySmall,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < tenders.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            TenderRow(
                              id: PaymentIds.ledgerRow(i),
                              tender: tenders[i],
                              onTap: tenders[i].method == TenderMethod.wallet
                                  ? () => _openTender(tenders[i])
                                  : null,
                            ),
                          ],
                        ],
                      ),
              ),
              if (_method != TenderMethod.wallet) ...[
                const SizedBox(height: 12),
                TestId(
                  PaymentIds.chargeNotice,
                  child: Text(
                    '${_method.label} charging is not available yet on this '
                    'device — it needs the EDC / payment integration.',
                    style: HandheldText.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
        actionBar: HandheldActionBar(
          primary: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HandheldPrimaryButton(
                id: PaymentIds.chargeButton,
                label: 'Charge ${_money(_chargeAmount)}',
                onPressed: canCharge ? _charge : null,
              ),
              const SizedBox(height: 6),
              const Text(
                'Complete sale unlocks when remaining hits ฿0.00',
                style: TextStyle(fontSize: 11.5, color: AppColors.mutedText),
              ),
            ],
          ),
          items: const [
            HandheldBarItem(
              id: PaymentIds.completeSaleButton,
              icon: Icons.check_circle_outline,
              label: 'Complete sale',
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodGrid extends StatelessWidget {
  final TenderMethod selected;
  final ValueChanged<TenderMethod> onSelect;

  const _MethodGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const methods = TenderMethod.values;
    Widget tile(TenderMethod method) {
      final isSelected = method == selected;
      return Expanded(
        child: TestId(
          PaymentIds.method(method.name),
          child: Semantics(
            button: true,
            selected: isSelected,
            inMutuallyExclusiveGroup: true,
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
                side: BorderSide(
                  color: isSelected ? AppColors.goldDark : AppColors.line,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () => onSelect(method),
                borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
                child: SizedBox(
                  height: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(method.icon, size: 18, color: AppColors.goldDark),
                      const SizedBox(height: 4),
                      Text(
                        method.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget row(Iterable<TenderMethod> items) => Row(
      children: [
        for (final (i, m) in items.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          tile(m),
        ],
      ],
    );

    return Column(
      children: [
        row(methods.take(3)),
        const SizedBox(height: 8),
        row(methods.skip(3)),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String currencyCode;
  final String id;

  const _AmountField({
    required this.controller,
    required this.currencyCode,
    this.id = PaymentIds.amountField,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      id,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(HandheldMetrics.radius),
          border: Border.all(color: AppColors.goldMuted, width: 2),
        ),
        child: Row(
          children: [
            Text(
              currencyCode == 'THB' ? '฿' : currencyCode,
              style: const TextStyle(fontSize: 16, color: AppColors.goldDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: HandheldText.displayTitle,
                decoration: const InputDecoration.collapsed(hintText: '0.00'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preset extends StatelessWidget {
  final String id;
  final String label;
  final VoidCallback onTap;

  const _Preset({required this.id, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TestId(
      id,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.info,
          minimumSize: const Size(48, 44),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12.5)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/handheld/handheld.dart'
    show formatAmount, formatBaht, formatMoney;
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/desktop_data_table.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/cart.dart';
import '../sale_cart_view_model.dart';
import '../sale_currency.dart';
import '../widgets/checkout_details.dart';
import '../widgets/leave_checkout_guard.dart';
import '../widgets/session_expiry_guard.dart';
import 'desktop_discount_overlay.dart';
import 'desktop_payment_page.dart';

/// Pushes the desktop Checkout step for the current cart.
Future<void> openDesktopCheckoutPage(
  BuildContext context, {
  required SaleCartViewModel viewModel,
  bool isAirportMpos = false,
  Future<void> Function()? onSignOut,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DesktopCheckoutPage(
        viewModel: viewModel,
        isAirportMpos: isAirportMpos,
        onSignOut: onSignOut,
      ),
    ),
  );
}

/// Desktop Checkout — final review before tender (POS Desktop mockup
/// screen 5, "Step 2 of 3"): a compact customer summary, the read-only
/// lines with their discounts, totals with the bill (special) discount and
/// its Bill discount editor, Gift with Purchase, signature (only when the
/// order requires one), Take payment → step 3 (Enter). VAT is not
/// available ("—").
class DesktopCheckoutPage extends StatefulWidget {
  final SaleCartViewModel viewModel;

  /// Legacy shows DFA / promoter / order date in the profile only here.
  final bool isAirportMpos;

  /// Legacy `signout()` once the sale is finished on Payment.
  final Future<void> Function()? onSignOut;

  const DesktopCheckoutPage({
    super.key,
    required this.viewModel,
    this.isAirportMpos = false,
    this.onSignOut,
  });

  @override
  State<DesktopCheckoutPage> createState() => _DesktopCheckoutPageState();
}

class _DesktopCheckoutPageState extends State<DesktopCheckoutPage> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleCartViewModel>(
      init: widget.viewModel,
      global: false,
      builder: (viewModel) => SessionExpiryGuard(
        viewModel: viewModel,
        onSignOut: widget.onSignOut,
        child: _build(context, viewModel),
      ),
    );
  }

  Widget _build(BuildContext context, SaleCartViewModel viewModel) {
    final lines = viewModel.cart?.items ?? const <CartItem>[];
    final total = lines.fold<double>(0, (s, l) => s + l.lineTotal);
    final units = lines.fold<int>(0, (s, l) => s + l.quantity);
    final netPay = orderNetPay(viewModel.cart);
    final currency = orderCurrency(viewModel.cart);
    void takePayment() {
      if (lines.isEmpty) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DesktopPaymentPage(
            netPay: netPay,
            currencyCode: currency,
            rateToBaht: orderRateToBaht(viewModel.cart),
            loadCurrencies: viewModel.listCurrencies,
            exchangeChange: viewModel.exchangeChange,
            viewModel: viewModel,
            onSignOut: widget.onSignOut,
          ),
        ),
      );
    }

    return LeaveCheckoutGuard(
      viewModel: viewModel,
      child: TestId(
        CheckoutIds.page,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): takePayment,
          },
          child: DesktopWizardFrame(
            title: 'Checkout',
            subtitle:
                '${lines.length} line${lines.length == 1 ? '' : 's'}'
                ' · $units unit${units == 1 ? '' : 's'}',
            step: 2,
            totalSteps: 3,
            escapeLabel: 'Esc to return to sale',
            body: Padding(
              padding: const EdgeInsets.all(DesktopMetrics.pagePadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sideWidth = constraints.maxWidth >= 1300
                      ? 520.0
                      : 400.0;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ReviewColumn(
                          lines: lines,
                          units: units,
                          summary: checkoutSummaryFacts(
                            viewModel,
                            isAirportMpos: widget.isAirportMpos,
                          ),
                          gifts:
                              viewModel.cart?.giftsWithPurchase ??
                              const <GiftWithPurchase>[],
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: sideWidth,
                        child: _AmountColumn(
                          total: total,
                          billing: viewModel.cart?.billing,
                          currencyError: viewModel.currencyError,
                          // Legacy CheckoutPage.changeCurrency().
                          onCurrency:
                              viewModel.shoppingCard.isEmpty || viewModel.isBusy
                              ? null
                              : () => changeOrderCurrency(context, viewModel),
                          hasLines: lines.isNotEmpty,
                          // Legacy Checkout → More → Discount.
                          onBillDiscount: lines.isEmpty || viewModel.isBusy
                              ? null
                              : () => showDesktopBillDiscountOverlay(
                                  context,
                                  viewModel: viewModel,
                                ),
                          onTakePayment: takePayment,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One compact strip of label-over-value cells, wrapping as needed — the
/// Checkout summary, kept short so the lines table gets the height.
class _SummaryStrip extends StatelessWidget {
  final List<CheckoutFact> facts;

  const _SummaryStrip(this.facts);

  @override
  Widget build(BuildContext context) {
    return DesktopPanel(
      id: CheckoutIds.customerCard,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Wrap(
        spacing: 32,
        runSpacing: 8,
        children: [
          for (final fact in facts)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fact.label.toUpperCase(), style: DesktopText.fieldLabel),
                const SizedBox(height: 2),
                Text(
                  fact.value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReviewColumn extends StatelessWidget {
  final List<CartItem> lines;
  final int units;
  final List<CheckoutFact> summary;
  final List<GiftWithPurchase> gifts;

  const _ReviewColumn({
    required this.lines,
    required this.units,
    required this.summary,
    required this.gifts,
  });

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(fontSize: 13, color: AppColors.mutedText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryStrip(summary),
        const SizedBox(height: 12),
        Expanded(
          child: DesktopPanel(
            title: '${lines.length} lines · $units units',
            trailing: const Text('Amounts in THB', style: muted),
            child: Expanded(
              child: TestId(
                DesktopPaymentIds.linesTable,
                child: SingleChildScrollView(
                  child: DesktopDataTable(
                    columns: const [
                      DesktopDataColumn(label: 'Item'),
                      DesktopDataColumn(label: 'Qty', align: TextAlign.right),
                      DesktopDataColumn(
                        label: 'Discount',
                        align: TextAlign.right,
                      ),
                      DesktopDataColumn(label: 'Net', align: TextAlign.right),
                    ],
                    rows: [
                      for (final l in lines)
                        [
                          Text(
                            l.articleName.isEmpty
                                ? l.articleCode
                                : l.articleName,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text('${l.quantity}', textAlign: TextAlign.right),
                          // `BillingAmount.DiscountAmount` of the line.
                          TestId(
                            CheckoutIds.lineDiscount(l.row),
                            child: Text(
                              l.discountAmount == 0
                                  ? '—'
                                  : formatAmount(-l.discountAmount),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: l.discountAmount == 0
                                    ? AppColors.hintText
                                    : AppColors.danger,
                              ),
                            ),
                          ),
                          Text(
                            formatAmount(l.lineTotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                    ],
                    emptyPlaceholder: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No lines on this bill.', style: muted),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (gifts.isNotEmpty) ...[
          const SizedBox(height: 12),
          DesktopPanel(
            id: CheckoutIds.gwpCard,
            title: 'Gift with Purchase',
            child: GiftWithPurchaseList(gifts: gifts),
          ),
        ],
      ],
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final double total;

  /// The sale engine's amounts in the order currency, when it sent them.
  final CartBilling? billing;
  final String? currencyError;
  final VoidCallback? onCurrency;
  final bool hasLines;
  final VoidCallback? onBillDiscount;
  final VoidCallback onTakePayment;

  const _AmountColumn({
    required this.total,
    required this.billing,
    required this.currencyError,
    required this.onCurrency,
    required this.hasLines,
    required this.onBillDiscount,
    required this.onTakePayment,
  });

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {String? id}) {
      final text = Text(
        value,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w500,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.mutedText,
                ),
              ),
            ),
            id == null ? text : TestId(id, child: text),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopPanel(
            id: CheckoutIds.amountsCard,
            title: 'Amount due',
            trailing: OrderCurrencyButton(billing: billing, onTap: onCurrency),
            child: Column(
              children: billing == null
                  ? [
                      row(
                        'Total',
                        formatAmount(total),
                        id: CheckoutIds.totalAmount,
                      ),
                      row('Line discounts', '—'),
                      row(
                        'Grand',
                        formatAmount(total),
                        id: CheckoutIds.grandAmount,
                      ),
                      row('Cash-D subsidy', '—'),
                      row('VAT (included)', '—'),
                    ]
                  : [
                      row(
                        'Total',
                        formatAmount(billing!.total),
                        id: CheckoutIds.totalAmount,
                      ),
                      row('Line discounts', formatAmount(billing!.discount)),
                      row(
                        'Grand',
                        formatAmount(billing!.grand),
                        id: CheckoutIds.grandAmount,
                      ),
                      row('Cash-D subsidy', formatAmount(billing!.cashD)),
                      row('VAT (included)', '—'),
                      row(
                        'Rate',
                        billing!.currencyRate.toStringAsFixed(5),
                        id: CurrencyIds.rate,
                      ),
                      const Divider(height: 20, color: AppColors.line),
                      TestId(
                        CheckoutIds.billDiscountRows,
                        child: Column(
                          children: [
                            for (final fact in billDiscountFacts(billing!))
                              row(fact.label, fact.value),
                          ],
                        ),
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 10),
          DesktopButton(
            id: CheckoutIds.billDiscountButton,
            label: 'Bill discount',
            icon: Icons.percent,
            secondary: true,
            height: 52,
            onPressed: onBillDiscount,
          ),
          if (currencyError != null)
            TestId(
              CurrencyIds.error,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  currencyError!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Same box as the Sale page's Net pay.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Net pay',
                  style: TextStyle(fontSize: 14, color: AppColors.gold),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: TestId(
                    CheckoutIds.netPay,
                    child: Text(
                      formatMoney(
                        billing?.netPay ?? total,
                        billing?.currencyCode ?? '',
                      ),
                      style: const TextStyle(
                        fontFamily: 'KingPowerHeadline',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                if (billing != null && !billing!.isBaht)
                  TestId(
                    CurrencyIds.netPayBase,
                    child: Text(
                      '= ${formatBaht(billing!.netPayBase)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DesktopButton(
            id: CheckoutIds.takePaymentButton,
            label: 'Take payment',
            icon: Icons.payments_outlined,
            hotkey: 'ENTER',
            height: 74,
            onPressed: hasLines ? onTakePayment : null,
          ),
        ],
      ),
    );
  }
}

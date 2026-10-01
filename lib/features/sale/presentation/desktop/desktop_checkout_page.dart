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
import '../handheld/payment/signature_page.dart';
import '../../domain/entities/cart.dart';
import '../sale_cart_view_model.dart';
import '../sale_currency.dart';
import '../widgets/checkout_details.dart';
import '../widgets/leave_checkout_guard.dart';
import 'desktop_discount_overlay.dart';
import 'desktop_payment_page.dart';

/// Pushes the desktop Checkout step for the current cart.
Future<void> openDesktopCheckoutPage(
  BuildContext context, {
  required SaleCartViewModel viewModel,
  bool isAirportMpos = false,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DesktopCheckoutPage(
        viewModel: viewModel,
        isAirportMpos: isAirportMpos,
      ),
    ),
  );
}

/// Desktop Checkout — final review before tender (POS Desktop mockup
/// screen 5, "Step 2 of 3"): customer, flight & passport, read-only lines,
/// blocking-flags panel, amount due, customer signature, Take payment.
///
/// Real: legacy Checkout's customer profile (customer, flight & passport,
/// sale), lines with their discounts, totals with the bill (special)
/// discount and its Bill discount editor, Gift with Purchase, signature
/// (only when the order requires one), Take payment → step 3 (Enter).
/// Not available, so reported as such: blocking flags (serial, CITES,
/// shipping address), VAT; Suspend and Print quote are inert.
// TODO(pos-desktop): real blocking-flags check (openspec 4.4 / 5.4);
// Suspend / Print quote.
class DesktopCheckoutPage extends StatefulWidget {
  final SaleCartViewModel viewModel;

  /// Legacy shows DFA / promoter / order date in the profile only here.
  final bool isAirportMpos;

  const DesktopCheckoutPage({
    super.key,
    required this.viewModel,
    this.isAirportMpos = false,
  });

  @override
  State<DesktopCheckoutPage> createState() => _DesktopCheckoutPageState();
}

class _DesktopCheckoutPageState extends State<DesktopCheckoutPage> {
  SignatureCapture? _signature;

  Future<void> _captureSignature(double netPay) async {
    final capture = await openSignaturePage(context, netPay: netPay);
    if (capture != null && mounted) setState(() => _signature = capture);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleCartViewModel>(
      init: widget.viewModel,
      global: false,
      builder: (viewModel) => _build(context, viewModel),
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
                          customer: checkoutCustomerFacts(viewModel),
                          trip: checkoutTripFacts(viewModel, DateTime.now()),
                          sale: checkoutSaleFacts(
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
                          // Legacy shows Signature only for such an order.
                          requireSignature:
                              viewModel.cart?.requireSignature ?? false,
                          signatureCaptured: _signature != null,
                          onSignature: () => _captureSignature(netPay),
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

/// Label over value, two per row — the Checkout details.
class _Facts extends StatelessWidget {
  final List<CheckoutFact> facts;

  const _Facts(this.facts);

  // Rows of two Expanded cells — no LayoutBuilder, as the Customer /
  // Flight panels sit in an IntrinsicHeight row.
  @override
  Widget build(BuildContext context) {
    Widget cell(CheckoutFact fact) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fact.label.toUpperCase(), style: DesktopText.fieldLabel),
        const SizedBox(height: 3),
        Text(
          fact.value,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < facts.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cell(facts[i])),
                const SizedBox(width: 16),
                Expanded(
                  child: i + 1 < facts.length
                      ? cell(facts[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReviewColumn extends StatelessWidget {
  final List<CartItem> lines;
  final int units;
  final List<CheckoutFact> customer;
  final List<CheckoutFact> trip;
  final List<CheckoutFact> sale;
  final List<GiftWithPurchase> gifts;

  const _ReviewColumn({
    required this.lines,
    required this.units,
    required this.customer,
    required this.trip,
    required this.sale,
    required this.gifts,
  });

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(fontSize: 13, color: AppColors.mutedText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DesktopPanel(
                  id: CheckoutIds.customerCard,
                  title: 'Customer',
                  child: _Facts(customer),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DesktopPanel(
                  id: DesktopPaymentIds.flightCard,
                  title: 'Flight & passport',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (trip.isEmpty)
                        const Text(
                          'No customer attached to this bill.',
                          style: muted,
                        )
                      else
                        TestId(CheckoutIds.tripCard, child: _Facts(trip)),
                      const Divider(height: 24, color: AppColors.line),
                      TestId(CheckoutIds.saleCard, child: _Facts(sale)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
  final bool requireSignature;
  final bool signatureCaptured;
  final VoidCallback onSignature;
  final VoidCallback onTakePayment;

  const _AmountColumn({
    required this.total,
    required this.billing,
    required this.currencyError,
    required this.onCurrency,
    required this.hasLines,
    required this.onBillDiscount,
    required this.requireSignature,
    required this.signatureCaptured,
    required this.onSignature,
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Net pay', style: TextStyle(color: AppColors.gold)),
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
                        fontSize: 56,
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
          if (requireSignature) ...[
            const SizedBox(height: 16),
            const Text('CUSTOMER SIGNATURE', style: DesktopText.fieldLabel),
            const SizedBox(height: 8),
            TestId(
              DesktopPaymentIds.signatureBox,
              child: Material(
                color: const Color(0xFFFBFCFD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFC3C9D2)),
                ),
                child: InkWell(
                  onTap: onSignature,
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 96,
                    child: Center(
                      child: Text(
                        signatureCaptured
                            ? 'Signature captured · not uploaded yet · tap to redo'
                            : 'Tap to capture the customer signature',
                        style: TextStyle(
                          fontSize: 13,
                          color: signatureCaptured
                              ? AppColors.success
                              : AppColors.mutedText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          DesktopButton(
            id: CheckoutIds.takePaymentButton,
            label: 'Take payment',
            icon: Icons.payments_outlined,
            hotkey: 'ENTER',
            height: 74,
            onPressed: hasLines ? onTakePayment : null,
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: DesktopButton(
                  id: CheckoutIds.suspendButton,
                  label: 'Suspend bill',
                  icon: Icons.assignment_turned_in_outlined,
                  secondary: true,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: DesktopButton(
                  id: CheckoutIds.printQuoteButton,
                  label: 'Print quote',
                  icon: Icons.print_outlined,
                  secondary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

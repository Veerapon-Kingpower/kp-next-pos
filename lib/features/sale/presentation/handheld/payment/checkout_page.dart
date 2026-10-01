import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/presentation/handheld/handheld.dart';
import '../../../../../core/presentation/test_ids.dart';
import '../../../../../core/presentation/widgets/test_id.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/cart_item.dart';
import '../../sale_cart_view_model.dart';
import '../../sale_currency.dart';
import '../../widgets/checkout_details.dart';
import '../../widgets/leave_checkout_guard.dart';
import '../discount_sheet.dart';
import 'payment_page.dart';
import 'payment_widgets.dart';
import 'signature_page.dart';

/// Pushes Checkout for the current cart.
Future<void> openCheckoutPage(
  BuildContext context, {
  required SaleCartViewModel viewModel,
  bool isAirportMpos = false,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          CheckoutPage(viewModel: viewModel, isAirportMpos: isAirportMpos),
    ),
  );
}

/// Checkout (mockup screen 5) — final review before tender.
///
/// A compact customer summary, totals with the bill (special) discount and
/// its Bill discount sheet, Gift with Purchase, signature (only when the
/// order requires one), and Take payment. VAT is not available ("—").
class CheckoutPage extends StatefulWidget {
  final SaleCartViewModel viewModel;

  /// Legacy shows DFA / promoter / order date in the profile only here.
  final bool isAirportMpos;

  const CheckoutPage({
    super.key,
    required this.viewModel,
    this.isAirportMpos = false,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
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
      builder: (viewModel) => LeaveCheckoutGuard(
        viewModel: viewModel,
        child: _build(context, viewModel),
      ),
    );
  }

  Widget _build(BuildContext context, SaleCartViewModel viewModel) {
    final lines = viewModel.cart?.items ?? const <CartItem>[];
    final billing = viewModel.cart?.billing;
    final total =
        billing?.total ?? lines.fold<double>(0, (sum, l) => sum + l.lineTotal);
    final netPay = orderNetPay(viewModel.cart);
    final currency = orderCurrency(viewModel.cart);
    final units = lines.fold<int>(0, (sum, l) => sum + l.quantity);
    final gifts = viewModel.cart?.giftsWithPurchase ?? const [];
    final requireSignature = viewModel.cart?.requireSignature ?? false;
    List<Widget> rows(List<CheckoutFact> facts) => [
      for (final fact in facts)
        PaymentValueRow(label: fact.label, value: fact.value),
    ];

    return TestId(
      CheckoutIds.page,
      child: HandheldScaffold(
        header: HandheldHeader(
          title: 'Checkout',
          subtitle:
              '${lines.length} line${lines.length == 1 ? '' : 's'}'
              ' · $units unit${units == 1 ? '' : 's'}',
          subtitleId: CheckoutIds.summaryLine,
          leading: const BackButton(color: Colors.white),
          stats: [
            HandheldStat(
              id: CheckoutIds.netPay,
              label: 'Net pay',
              value: formatMoney(netPay, currency),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(HandheldMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PaymentCard(
                id: CheckoutIds.customerCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PaymentBlockLabel('Customer'),
                    ...rows(
                      checkoutSummaryFacts(
                        viewModel,
                        isAirportMpos: widget.isAirportMpos,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PaymentCard(
                id: CheckoutIds.amountsCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: PaymentBlockLabel('Amounts')),
                        // Legacy CheckoutPage.changeCurrency().
                        OrderCurrencyButton(
                          billing: billing,
                          onTap:
                              viewModel.shoppingCard.isEmpty || viewModel.isBusy
                              ? null
                              : () => changeOrderCurrency(context, viewModel),
                        ),
                      ],
                    ),
                    PaymentValueRow(
                      id: CheckoutIds.totalAmount,
                      label: 'Total',
                      value: formatAmount(total),
                    ),
                    PaymentValueRow(
                      label: 'Discount',
                      value: billing == null
                          ? '—'
                          : formatAmount(billing.discount),
                    ),
                    PaymentValueRow(
                      id: CheckoutIds.grandAmount,
                      label: 'Grand',
                      value: formatAmount(billing?.grand ?? total),
                    ),
                    PaymentValueRow(
                      label: 'Cash-D subsidy',
                      value: billing == null
                          ? '—'
                          : formatAmount(billing.cashD),
                    ),
                    const PaymentValueRow(label: 'VAT (included)', value: '—'),
                    if (billing != null)
                      PaymentValueRow(
                        id: CurrencyIds.rate,
                        label: 'Rate',
                        value: billing.currencyRate.toStringAsFixed(5),
                      ),
                    if (billing != null && !billing.isBaht)
                      PaymentValueRow(
                        id: CurrencyIds.netPayBase,
                        label: 'Net pay in THB',
                        value: formatBaht(billing.netPayBase),
                      ),
                    if (billing != null)
                      TestId(
                        CheckoutIds.billDiscountRows,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: rows(billDiscountFacts(billing)),
                        ),
                      ),
                    if (viewModel.currencyError != null)
                      TestId(
                        CurrencyIds.error,
                        child: Text(
                          viewModel.currencyError!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Legacy Checkout → More → Discount.
              _ActionRow(
                id: CheckoutIds.billDiscountButton,
                icon: Icons.percent,
                title: 'Bill discount',
                subtitle: billing == null || billing.discountSpecial == 0
                    ? 'No bill discount'
                    : formatAmount(billing.discountSpecial),
                onTap: lines.isEmpty || viewModel.isBusy
                    ? null
                    : () =>
                          showBillDiscountSheet(context, viewModel: viewModel),
              ),
              if (gifts.isNotEmpty) ...[
                const SizedBox(height: 14),
                PaymentCard(
                  id: CheckoutIds.gwpCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PaymentBlockLabel('Gift with Purchase'),
                      GiftWithPurchaseList(gifts: gifts),
                    ],
                  ),
                ),
              ],
              // Legacy shows Signature only for such an order.
              if (requireSignature) ...[
                const SizedBox(height: 14),
                TestId(
                  CheckoutIds.signatureRow,
                  child: Material(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        HandheldMetrics.radius,
                      ),
                      side: const BorderSide(color: AppColors.line),
                    ),
                    child: InkWell(
                      onTap: () => _captureSignature(netPay),
                      borderRadius: BorderRadius.circular(
                        HandheldMetrics.radius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.draw_outlined,
                              color: AppColors.goldDark,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Customer signature',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    _signature == null
                                        ? 'Not captured'
                                        : 'Captured · not uploaded yet',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _signature == null
                                          ? AppColors.mutedText
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.mutedText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actionBar: HandheldActionBar(
          primary: HandheldPrimaryButton(
            id: CheckoutIds.takePaymentButton,
            label: 'Take payment',
            icon: Icons.payments_outlined,
            onPressed: lines.isEmpty
                ? null
                : () => openPaymentPage(
                    context,
                    netPay: netPay,
                    currencyCode: currency,
                    rateToBaht: orderRateToBaht(viewModel.cart),
                    loadCurrencies: viewModel.listCurrencies,
                    exchangeChange: viewModel.exchangeChange,
                    viewModel: viewModel,
                  ),
          ),
          items: const [],
        ),
      ),
    );
  }
}

/// A tappable card row — icon, title over subtitle, chevron.
class _ActionRow extends StatelessWidget {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      id,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HandheldMetrics.radius),
          side: const BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HandheldMetrics.radius),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.goldDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(subtitle, style: HandheldText.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.mutedText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

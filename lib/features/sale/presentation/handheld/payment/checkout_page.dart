import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/presentation/handheld/handheld.dart';
import '../../../../../core/presentation/test_ids.dart';
import '../../../../../core/presentation/widgets/test_id.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/cart_item.dart';
import '../../sale_cart_view_model.dart';
import '../../sale_currency.dart';
import 'payment_page.dart';
import 'payment_widgets.dart';
import 'signature_page.dart';

/// Pushes Checkout for the current cart.
Future<void> openCheckoutPage(
  BuildContext context, {
  required SaleCartViewModel viewModel,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => CheckoutPage(viewModel: viewModel)),
  );
}

/// Checkout (mockup screen 5) — final review before tender.
///
/// Real: line / unit counts and totals from the cart, the privilege picked
/// on Home, signature capture (local), and Take payment. Not available
/// yet, so shown as "—" or a notice rather than guessed: the pre-checkout
/// flag check (serial / address / flight), the attached customer's
/// profile + flight, discount / Cash-D subsidy / VAT breakdown, exchange
/// rate, Suspend and Print quote.
// TODO(pos-handheld): fill these from the sale engine's checkout response
// once it exists; wire Suspend / Print quote.
class CheckoutPage extends StatefulWidget {
  final SaleCartViewModel viewModel;

  const CheckoutPage({super.key, required this.viewModel});

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
      builder: (viewModel) => _build(context, viewModel),
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
    final privilege = viewModel.selectedPrivilege;
    final privilegeCode =
        privilege == null ||
            (privilege.typeCode.isEmpty && privilege.promoCode.isEmpty)
        ? null
        : '[${privilege.typeCode}]:${privilege.promoCode}';

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
              TestId(
                CheckoutIds.flagsNotice,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(
                      HandheldMetrics.radiusSm,
                    ),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.info),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pre-checkout checks (serial, delivery address, '
                          'flight) are not available yet — confirm them '
                          'with the customer.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PaymentCard(
                id: CheckoutIds.customerCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PaymentBlockLabel('Customer'),
                    if (privilege == null)
                      const Text(
                        'Walk-in · no customer attached',
                        style: HandheldText.bodySmall,
                      )
                    else
                      Row(
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            size: 18,
                            color: AppColors.goldDark,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  privilege.name.isEmpty
                                      ? 'Privilege'
                                      : privilege.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (privilegeCode != null)
                                  Text(
                                    privilegeCode,
                                    style: HandheldText.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ],
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
              TestId(
                CheckoutIds.signatureRow,
                child: Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(HandheldMetrics.radius),
                    side: const BorderSide(color: AppColors.line),
                  ),
                  child: InkWell(
                    onTap: () => _captureSignature(netPay),
                    borderRadius: BorderRadius.circular(HandheldMetrics.radius),
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
                  ),
          ),
          items: const [
            HandheldBarItem(
              id: CheckoutIds.suspendButton,
              icon: Icons.assignment_turned_in_outlined,
              label: 'Suspend',
            ),
            HandheldBarItem(
              id: CheckoutIds.printQuoteButton,
              icon: Icons.print_outlined,
              label: 'Print quote',
            ),
          ],
        ),
      ),
    );
  }
}

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
import 'desktop_payment_page.dart';

/// Pushes the desktop Checkout step for the current cart.
Future<void> openDesktopCheckoutPage(
  BuildContext context, {
  required SaleCartViewModel viewModel,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DesktopCheckoutPage(viewModel: viewModel),
    ),
  );
}

/// Desktop Checkout — final review before tender (POS Desktop mockup
/// screen 5, "Step 2 of 3"): customer, flight & passport, read-only lines,
/// blocking-flags panel, amount due, customer signature, Take payment.
///
/// Real: lines / units / totals from the cart, the selected privilege,
/// signature capture (local), Take payment → step 3 (Enter). Not available,
/// so reported as such rather than shown as cleared / invented: blocking
/// flags (serial, CITES, shipping address), linked flight & passport,
/// discount / Cash-D / VAT breakdown, FX rate; Suspend and Print quote
/// are inert.
// TODO(pos-desktop): real blocking-flags check and checkout totals
// (openspec 4.4 / 5.4); attach flight & passport; Suspend / Print quote.
class DesktopCheckoutPage extends StatefulWidget {
  final SaleCartViewModel viewModel;

  const DesktopCheckoutPage({super.key, required this.viewModel});

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

    return TestId(
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
                final sideWidth = constraints.maxWidth >= 1300 ? 520.0 : 400.0;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ReviewColumn(
                        lines: lines,
                        units: units,
                        privilegeName: viewModel.selectedPrivilege?.name,
                        privilegeCode: _code(viewModel),
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
    );
  }

  static String? _code(SaleCartViewModel viewModel) {
    final p = viewModel.selectedPrivilege;
    if (p == null || (p.typeCode.isEmpty && p.promoCode.isEmpty)) return null;
    return '[${p.typeCode}]:${p.promoCode}';
  }
}

class _ReviewColumn extends StatelessWidget {
  final List<CartItem> lines;
  final int units;
  final String? privilegeName;
  final String? privilegeCode;

  const _ReviewColumn({
    required this.lines,
    required this.units,
    required this.privilegeName,
    required this.privilegeCode,
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
                  child: privilegeName == null
                      ? const Text(
                          'Walk-in · no customer attached',
                          style: muted,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              privilegeName!.isEmpty
                                  ? 'Privilege'
                                  : privilegeName!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (privilegeCode != null)
                              Text(
                                privilegeCode!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.goldDark,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: DesktopPanel(
                  id: DesktopPaymentIds.flightCard,
                  title: 'Flight & passport',
                  child: Text(
                    'Linking a flight and passport to the bill is not '
                    'available yet.',
                    style: muted,
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
                          const Text(
                            '—',
                            textAlign: TextAlign.right,
                            style: TextStyle(color: AppColors.hintText),
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
        const SizedBox(height: 12),
        TestId(
          CheckoutIds.flagsNotice,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 17, color: AppColors.info),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Blocking-flag checks (serial number, CITES, shipping '
                    'address) are not available yet — confirm them with the '
                    'customer before taking payment.',
                    style: TextStyle(fontSize: 13.5, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ),
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
  final bool signatureCaptured;
  final VoidCallback onSignature;
  final VoidCallback onTakePayment;

  const _AmountColumn({
    required this.total,
    required this.billing,
    required this.currencyError,
    required this.onCurrency,
    required this.hasLines,
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
                    ],
            ),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/handheld/handheld.dart'
    show formatBaht, formatMoney;
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/currency.dart';
import '../handheld/payment/payment_models.dart';
import '../handheld/payment/payment_widgets.dart' show TenderRow;
import '../sale_cart_view_model.dart';
import '../widgets/change_currency_screen.dart';

class _Method {
  final String id;
  final String label;
  final String detail;
  final IconData icon;
  final LogicalKeyboardKey key;
  final String hotkey;

  const _Method(
    this.id,
    this.label,
    this.detail,
    this.icon,
    this.key,
    this.hotkey,
  );
}

const _methods = [
  _Method(
    'card',
    'Credit card',
    'Visa · Master · JCB',
    Icons.credit_card,
    LogicalKeyboardKey.f1,
    'F1',
  ),
  _Method(
    'cash',
    'Cash',
    'THB (other currencies need rates)',
    Icons.payments_outlined,
    LogicalKeyboardKey.f2,
    'F2',
  ),
  _Method(
    'unionPay',
    'UnionPay',
    'Card or QR',
    Icons.credit_card_outlined,
    LogicalKeyboardKey.f3,
    'F3',
  ),
  _Method(
    'wallet',
    'Wallet QR',
    'Alipay · WeChat Pay',
    Icons.qr_code_2,
    LogicalKeyboardKey.f4,
    'F4',
  ),
  _Method(
    'cashCard',
    'Cash card',
    'KP stored value',
    Icons.style_outlined,
    LogicalKeyboardKey.f5,
    'F5',
  ),
  _Method(
    'ePurse',
    'e-Purse',
    'Member balance',
    Icons.card_giftcard,
    LogicalKeyboardKey.f6,
    'F6',
  ),
  _Method(
    'voucher',
    'Voucher',
    'Gift or staff voucher',
    Icons.receipt_long_outlined,
    LogicalKeyboardKey.f7,
    'F7',
  ),
  _Method(
    'more',
    'More methods',
    '2C2P · bank transfer',
    Icons.more_horiz,
    LogicalKeyboardKey.f8,
    'F8',
  ),
];

/// Desktop Payment — split tender (POS Desktop mockup screen 6, "Step 3 of
/// 3"): method tiles (F1–F8), the selected method's panel (Cash: currency,
/// amount tendered with keypad and quick amounts, applied-to-bill and change
/// due), Net pay / Tendered / Remaining, the tender ledger and Complete sale.
///
/// Client-side and real: method selection, the tendered amount and the
/// applied / change preview (`previewCashTender`), remaining from approved
/// [tenders]. No tender is ever added without a real authorisation, so the
/// ledger stays empty today; Add tender, Open drawer, other currencies
/// (no rate table) and non-cash methods (EDC / 2C2P) are inert, and
/// Complete sale stays disabled.
// TODO(pos-desktop): tender authorisation (openspec 5.1 / 7.4), rate table,
// finalize transaction (openspec 5.4).
class DesktopPaymentPage extends StatefulWidget {
  final double netPay;
  final List<Tender> tenders;

  /// The order's currency — amounts here are in it (legacy `CurrencyPay`).
  final String currencyCode;

  /// Baht per one unit of [currencyCode], to hand change to the CHANGE
  /// screen in baht (legacy "Change Amount (THB)").
  final double rateToBaht;

  /// Feed the CHANGE screen (legacy `ChangePage`); without them the "Change
  /// in another currency" button is inert.
  final Future<List<Currency>> Function()? loadCurrencies;
  final ExchangeChange? exchangeChange;

  /// The sale's view model — makes Add cash tender real (legacy
  /// `PaymentFormPage`, `AddPaymentToOrder`) and feeds the ledger /
  /// remaining / change from the order.
  final SaleCartViewModel? viewModel;

  const DesktopPaymentPage({
    this.viewModel,
    super.key,
    required this.netPay,
    this.tenders = const [],
    this.currencyCode = 'THB',
    this.rateToBaht = 1,
    this.loadCurrencies,
    this.exchangeChange,
  });

  @override
  State<DesktopPaymentPage> createState() => _DesktopPaymentPageState();
}

class _DesktopPaymentPageState extends State<DesktopPaymentPage> {
  final _tendered = TextEditingController();
  String _method = 'cash';

  String _money(double value) => formatMoney(value, widget.currencyCode);

  /// Tenders passed in plus the order's own `OrderPayments`.
  List<Tender> get _tenders => [
    ...widget.tenders,
    ...tendersFromPayments(widget.viewModel?.cart?.payments ?? const []),
  ];

  /// The sale engine's `RemainingAmount` once it reports one.
  double get _remaining {
    final fromOrder = widget.viewModel?.cart?.remaining;
    final v = fromOrder ?? widget.netPay - tenderedTotal(_tenders);
    return v < 0 ? 0 : v;
  }

  double get _tenderedAmount => double.tryParse(_tendered.text) ?? 0;

  bool get _canAddCash {
    final viewModel = widget.viewModel;
    return viewModel != null &&
        _method == 'cash' &&
        _tenderedAmount > 0 &&
        _remaining > 0 &&
        !viewModel.isBusy;
  }

  // Legacy `PaymentFormPage` Save for cash (`AddPaymentToOrder`).
  Future<void> _addCash() async {
    if (!_canAddCash) return;
    if (await widget.viewModel!.payCash(_tenderedAmount)) _tendered.clear();
  }

  Future<String?> _saveExchange({
    required String currencyCode,
    required double amount,
  }) async {
    final viewModel = widget.viewModel!;
    final saved = await viewModel.saveChangeExchange(
      currencyCode: currencyCode,
      amount: amount,
    );
    return saved ? null : viewModel.paymentError;
  }

  @override
  void initState() {
    super.initState();
    _tendered.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tendered.dispose();
    super.dispose();
  }

  void _setTendered(double value) =>
      _tendered.text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  void _key(String key) {
    final text = _tendered.text;
    if (text.isEmpty && (key == '0' || key == '00')) return;
    _tendered.text = text + key;
  }

  void _backspace() {
    final text = _tendered.text;
    if (text.isNotEmpty) _tendered.text = text.substring(0, text.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    if (viewModel == null) return _build(context);
    return GetBuilder<SaleCartViewModel>(
      init: viewModel,
      global: false,
      builder: (_) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    return TestId(
      PaymentIds.page,
      child: CallbackShortcuts(
        bindings: {
          for (final m in _methods)
            SingleActivator(m.key): () => setState(() => _method = m.id),
          const SingleActivator(LogicalKeyboardKey.enter): _addCash,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _addCash,
        },
        child: DesktopWizardFrame(
          title: 'Payment',
          subtitle: 'Split tender',
          step: 3,
          totalSteps: 3,
          escapeLabel: 'Esc to return to checkout',
          body: Padding(
            padding: const EdgeInsets.all(DesktopMetrics.pagePadding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sideWidth = constraints.maxWidth >= 1300 ? 520.0 : 360.0;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'CHOOSE A METHOD',
                              style: DesktopText.fieldLabel,
                            ),
                            const SizedBox(height: 10),
                            _methodGrid(),
                            const SizedBox(height: 18),
                            TestId(
                              DesktopPaymentIds.detailPanel,
                              child: _method == 'cash'
                                  ? _cashPanel()
                                  : _unavailablePanel(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(width: sideWidth, child: _totalsColumn()),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodGrid() {
    Widget tile(_Method m) {
      final selected = m.id == _method;
      return Expanded(
        child: TestId(
          PaymentIds.method(m.id),
          child: Semantics(
            button: true,
            selected: selected,
            inMutuallyExclusiveGroup: true,
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: selected ? AppColors.goldDark : AppColors.line,
                  width: selected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () => setState(() => _method = m.id),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(m.icon, size: 24, color: AppColors.goldDark),
                          const Spacer(),
                          DesktopHotkeyChip(m.hotkey),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        m.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        m.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
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

    Widget row(Iterable<_Method> ms) => Row(
      children: [
        for (final (i, m) in ms.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          tile(m),
        ],
      ],
    );

    return Column(
      children: [
        row(_methods.take(4)),
        const SizedBox(height: 10),
        row(_methods.skip(4)),
      ],
    );
  }

  Widget _unavailablePanel() {
    final m = _methods.firstWhere((m) => m.id == _method);
    return DesktopPanel(
      title: m.label,
      child: Text(
        '${m.label} payments are not available yet on this station — they '
        'need the EDC / 2C2P payment integration.',
        style: const TextStyle(fontSize: 13.5, color: AppColors.mutedText),
      ),
    );
  }

  Widget _cashPanel() {
    final tendered = double.tryParse(_tendered.text) ?? 0;
    final preview = previewCashTender(
      remaining: _remaining,
      tendered: tendered,
    );
    // Once cash is recorded the order's own change due (baht) is what the
    // CHANGE screen works on, and its Save is real; before that it quotes
    // the preview only.
    final recordedChange = widget.viewModel?.cart?.change ?? 0;
    final changeInBaht = recordedChange > 0
        ? recordedChange
        : preview.change * widget.rateToBaht;

    Widget currency(String code, String note, {bool enabled = false}) {
      final selected = code == 'THB';
      return Expanded(
        child: TestId(
          DesktopPaymentIds.currency(code),
          child: Semantics(
            button: true,
            selected: selected,
            enabled: enabled,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: selected ? AppColors.cream : AppColors.surface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: selected
                      ? AppColors.goldDark
                      : const Color(0xFFD8DDE5),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.goldDark : AppColors.hintText,
                    ),
                  ),
                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget quick(String id, String label, double value) => TestId(
      id,
      child: OutlinedButton(
        onPressed: () => _setTendered(value),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
        child: Text(label),
      ),
    );

    return DesktopPanel(
      title: 'Cash · amount tendered',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('CURRENCY', style: DesktopText.fieldLabel),
                const SizedBox(height: 8),
                // TODO(pos-desktop): currency rate table → enable USD / EUR /
                // CNY / JPY with conversion.
                Row(
                  children: [
                    currency('THB', '฿ · base', enabled: true),
                    const SizedBox(width: 6),
                    currency('USD', 'rate n/a'),
                    const SizedBox(width: 6),
                    currency('EUR', 'rate n/a'),
                    const SizedBox(width: 6),
                    currency('CNY', 'rate n/a'),
                    const SizedBox(width: 6),
                    currency('JPY', 'rate n/a'),
                  ],
                ),
                const SizedBox(height: 14),
                TestId(
                  DesktopPaymentIds.tenderedField,
                  child: Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.goldMuted, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '฿',
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColors.goldDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _tendered,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            style: const TextStyle(
                              fontFamily: 'KingPowerHeadline',
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration.collapsed(
                              hintText: '0',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    quick(DesktopPaymentIds.exactChip, 'Exact', _remaining),
                    for (final v in const [1000, 5000, 10000, 30000])
                      quick(
                        DesktopPaymentIds.quick(v),
                        '฿${v >= 1000 ? '${v ~/ 1000},000' : v}',
                        v.toDouble(),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PreviewBox(
                        id: DesktopPaymentIds.appliedToBill,
                        label: 'Applied to bill',
                        value: _money(preview.applied),
                        note: 'capped at remaining balance',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PreviewBox(
                        id: DesktopPaymentIds.changeDue,
                        label: 'Change due',
                        value: _money(preview.change),
                        note: 'given in THB from drawer',
                        positive: true,
                      ),
                    ),
                  ],
                ),
                if (recordedChange > 0) ...[
                  const SizedBox(height: 10),
                  TestId(
                    PaymentIds.recordedChange,
                    child: Text(
                      'Change to give (recorded): ${formatBaht(recordedChange)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Legacy ChangePage: hand the change back in another
                // currency, quoted by the sale engine; saved once the cash
                // is recorded on the order.
                DesktopButton(
                  id: CurrencyIds.changeButton,
                  label: 'Change in another currency',
                  icon: Icons.currency_exchange,
                  secondary: true,
                  onPressed:
                      changeInBaht > 0 &&
                          widget.loadCurrencies != null &&
                          widget.exchangeChange != null
                      ? () => showChangeCurrencyScreen(
                          context,
                          changeInBaht: changeInBaht,
                          loadCurrencies: widget.loadCurrencies!,
                          exchange: widget.exchangeChange!,
                          onSave: recordedChange > 0 ? _saveExchange : null,
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                if (widget.viewModel == null)
                  const Text(
                    'Recording cash tenders is not available yet on this '
                    'station.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.mutedText,
                    ),
                  ),
                if (widget.viewModel?.paymentError != null)
                  TestId(
                    PaymentIds.paymentError,
                    child: Text(
                      widget.viewModel!.paymentError!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                const SizedBox(height: 8),
                // Legacy PaymentFormPage Save for cash.
                DesktopButton(
                  id: DesktopPaymentIds.addTenderButton,
                  label: 'Add cash tender',
                  hotkey: 'ENTER',
                  height: 60,
                  onPressed: _canAddCash ? _addCash : null,
                ),
                const SizedBox(height: 8),
                const DesktopButton(
                  id: DesktopPaymentIds.openDrawerButton,
                  label: 'Open drawer',
                  icon: Icons.point_of_sale,
                  secondary: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _Keypad(onKey: _key, onBackspace: _backspace),
        ],
      ),
    );
  }

  Widget _totalsColumn() {
    final tenders = _tenders;
    Widget amount(
      String label,
      String value,
      String id, {
      Color? color,
      double size = 22,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: TestId(
                id,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: size,
                    fontWeight: FontWeight.w500,
                    color: color ?? Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              amount('Net pay', _money(widget.netPay), PaymentIds.netPay),
              amount(
                'Tendered',
                _money(tenderedTotal(tenders)),
                PaymentIds.tendered,
                color: AppColors.onlineOnInk,
              ),
              const Divider(color: Color(0x33FFFFFF)),
              amount(
                'Remaining',
                _money(_remaining),
                PaymentIds.remaining,
                size: 40,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: DesktopPanel(
            id: PaymentIds.ledger,
            title: 'Tender ledger',
            child: tenders.isEmpty
                ? const TestId(
                    PaymentIds.ledgerEmpty,
                    child: Text(
                      'No tenders yet.',
                      style: TextStyle(color: AppColors.mutedText),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < tenders.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        TenderRow(
                          id: PaymentIds.ledgerRow(i),
                          tender: tenders[i],
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        const DesktopButton(
          id: PaymentIds.completeSaleButton,
          label: 'Complete sale',
          icon: Icons.check_circle_outline,
          height: 64,
        ),
        const SizedBox(height: 6),
        const Text(
          'Complete sale unlocks when remaining hits ฿0.00',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),
      ],
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final String id;
  final String label;
  final String value;
  final String note;
  final bool positive;

  const _PreviewBox({
    required this.id,
    required this.label,
    required this.value,
    required this.note,
    this.positive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = positive ? const Color(0xFF0F6947) : AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: positive ? const Color(0xFFE7F8F1) : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: positive ? const Color(0xFFCDEFE1) : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: DesktopText.fieldLabel.copyWith(color: color),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: TestId(
              id,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ),
          Text(
            note,
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;

  const _Keypad({required this.onKey, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    const keys = ['7', '8', '9', '4', '5', '6', '1', '2', '3', '0', '00'];
    Widget cell(Widget child, VoidCallback onTap, String id) => TestId(
      id,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE1E5EC)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 62, height: 56, child: Center(child: child)),
        ),
      ),
    );

    return SizedBox(
      width: 3 * 62 + 2 * 8,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final k in keys)
            cell(
              Text(
                k,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              () => onKey(k),
              DesktopPaymentIds.keypad(k),
            ),
          cell(
            const Icon(Icons.backspace_outlined, size: 18),
            onBackspace,
            DesktopPaymentIds.keypadBackspace,
          ),
        ],
      ),
    );
  }
}

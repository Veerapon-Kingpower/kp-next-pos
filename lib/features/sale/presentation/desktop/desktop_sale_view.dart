import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/handheld/handheld.dart'
    show formatAmount, formatBaht;
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customer/domain/entities/privilege.dart';
import '../../domain/entities/cart_item.dart';
import '../sale_cart_view_model.dart';
import 'desktop_checkout_page.dart';
import 'desktop_discount_overlay.dart';

/// Desktop Sale (POS Desktop mockup screens 3 + 4): scan row, Buying /
/// Basket tabs, the lines table and the permanent bill summary.
///
/// Real (`SaleCartViewModel`): scan-to-add with `qty*barcode`, qty change,
/// remove, line / unit totals, selected privilege. Keyboard: F6 discount,
/// F7 qty prefix, F8 remove, ↑↓ move the selection; the scan field keeps
/// focus. Shown as "—" or inert because the cart doesn't carry them yet
/// (desktop Phase 2 data-reality map): per-line discount and fulfilment,
/// Collect / Take grouping and cancelled lines on Basket, discount /
/// Cash-D / VAT breakdown, Lookup (F9), Freeze, Pickup, Print basket,
/// Claim check, Suspend. Take payment (F12) opens the 2c Checkout.
// TODO(pos-desktop): line discount / fulfilment /
// cancelled state once the order API carries them (openspec 4.4 / 5.2 /
// 6.1).
class DesktopSaleView extends StatefulWidget {
  final SaleCartViewModel viewModel;

  const DesktopSaleView({super.key, required this.viewModel});

  @override
  State<DesktopSaleView> createState() => _DesktopSaleViewState();
}

class _DesktopSaleViewState extends State<DesktopSaleView> {
  final _scan = TextEditingController();
  final _scanFocus = FocusNode();
  bool _basket = false;
  String? _selectedRow;

  @override
  void dispose() {
    _scan.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  List<CartItem> get _lines =>
      widget.viewModel.cart?.items ?? const <CartItem>[];

  int get _selectedIndex => _lines.indexWhere((l) => l.row == _selectedRow);

  double get _total => _lines.fold<double>(0, (s, l) => s + l.lineTotal);

  Future<void> _submitScan(String value) async {
    await widget.viewModel.scan(value);
    if (widget.viewModel.scanError == null) _scan.clear();
    _scanFocus.requestFocus();
  }

  void _qtyPrefix() {
    final text = _scan.text.trim();
    if (RegExp(r'^\d+$').hasMatch(text)) {
      _scan.text = '$text*';
      _scan.selection = TextSelection.collapsed(offset: _scan.text.length);
    }
    _scanFocus.requestFocus();
  }

  void _select(String row) {
    setState(() => _selectedRow = row);
    _scanFocus.requestFocus();
  }

  void _moveSelection(int delta) {
    if (_lines.isEmpty) return;
    final current = _selectedIndex;
    final next = current < 0
        ? 0
        : (current + delta).clamp(0, _lines.length - 1);
    setState(() => _selectedRow = _lines[next].row);
  }

  Future<void> _discountSelected() async {
    final index = _selectedIndex;
    if (index < 0) return;
    await showDesktopDiscountOverlay(
      context,
      line: _lines[index],
      lineNumber: index + 1,
      billNet: _total,
    );
    if (mounted) _scanFocus.requestFocus();
  }

  Future<void> _takePayment() async {
    if (_lines.isEmpty) return;
    await openDesktopCheckoutPage(context, viewModel: widget.viewModel);
    if (mounted) _scanFocus.requestFocus();
  }

  Future<void> _removeSelected() async {
    final index = _selectedIndex;
    if (index < 0) return;
    final line = _lines[index];
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Remove this line?',
      message: line.articleName.isEmpty ? line.articleCode : line.articleName,
      confirmLabel: 'Remove line',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await widget.viewModel.removeItem(line.row);
    if (!mounted) return;
    setState(() => _selectedRow = null);
    _scanFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleCartViewModel>(
      init: widget.viewModel,
      global: false,
      builder: (viewModel) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f6): _discountSelected,
          const SingleActivator(LogicalKeyboardKey.f7): _qtyPrefix,
          const SingleActivator(LogicalKeyboardKey.f8): _removeSelected,
          const SingleActivator(LogicalKeyboardKey.f12): _takePayment,
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              _moveSelection(1),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              _moveSelection(-1),
        },
        child: _build(viewModel),
      ),
    );
  }

  Widget _build(SaleCartViewModel viewModel) {
    final lines = _lines;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final summaryWidth = constraints.maxWidth >= 1500
              ? 472.0
              : constraints.maxWidth >= 1150
              ? 360.0
              : 320.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _scanRow(viewModel),
                    if (viewModel.scanError != null)
                      _Notice(
                        id: SaleIds.scanError,
                        icon: Icons.error_outline,
                        color: AppColors.danger,
                        text: viewModel.scanError!,
                      ),
                    if (viewModel.staleNotice != null)
                      _Notice(
                        id: SaleIds.staleNotice,
                        icon: Icons.warning_amber,
                        color: AppColors.warning,
                        text: viewModel.staleNotice!,
                      ),
                    const SizedBox(height: 16),
                    _tabs(lines.length),
                    if (_basket)
                      const _Notice(
                        id: SaleIds.basketNotice,
                        icon: Icons.info_outline,
                        color: AppColors.info,
                        text:
                            'Collect / Take grouping, claim checks and '
                            'cancelled lines are not available yet — all '
                            'lines are shown as scanned.',
                      ),
                    const SizedBox(height: 8),
                    Expanded(child: _table(viewModel, lines)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: summaryWidth,
                child: _Summary(
                  lines: lines,
                  total: _total,
                  privilege: viewModel.selectedPrivilege,
                  onTakePayment: lines.isEmpty ? null : _takePayment,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _scanRow(SaleCartViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: TestId(
            SaleIds.scanField,
            child: Container(
              height: DesktopMetrics.fieldHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.goldMuted, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 20,
                    color: AppColors.goldDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _scan,
                      focusNode: _scanFocus,
                      autofocus: true,
                      enabled: !viewModel.isBusy,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _submitScan,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Scan or type item code (qty*code)',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: AppColors.hintText,
                        ),
                      ),
                    ),
                  ),
                  if (viewModel.isBusy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const DesktopButton(
          id: DesktopSaleIds.lookupButton,
          label: 'Lookup',
          icon: Icons.search,
          hotkey: 'F9',
          secondary: true,
          height: DesktopMetrics.fieldHeight,
        ),
        const SizedBox(width: 12),
        DesktopButton(
          id: DesktopSaleIds.qtyButton,
          label: 'Qty ×',
          icon: Icons.calculate_outlined,
          hotkey: 'F7',
          secondary: true,
          height: DesktopMetrics.fieldHeight,
          onPressed: _qtyPrefix,
        ),
      ],
    );
  }

  Widget _tabs(int count) {
    Widget tab(String id, String label, bool basket) {
      final selected = _basket == basket;
      return TestId(
        id,
        child: Semantics(
          button: true,
          selected: selected,
          inMutuallyExclusiveGroup: true,
          child: InkWell(
            onTap: () {
              setState(() => _basket = basket);
              _scanFocus.requestFocus();
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppColors.goldDark : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? AppColors.ink : AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 22,
                    constraints: const BoxConstraints(minWidth: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.goldDark : AppColors.line,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(SaleIds.tabBuying, 'Buying', false),
        tab(SaleIds.tabBasket, 'Basket', true),
      ],
    );
  }

  Widget _table(SaleCartViewModel viewModel, List<CartItem> lines) {
    final hasSelection = _selectedIndex >= 0;
    return TestId(
      DesktopSaleIds.table,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Narrow (iPad landscape): drop the Discount / Fulfilment columns
          // — both are "—" until the order API carries them.
          final compact = constraints.maxWidth < 760;
          return _tableBody(viewModel, lines, hasSelection, compact);
        },
      ),
    );
  }

  Widget _tableBody(
    SaleCartViewModel viewModel,
    List<CartItem> lines,
    bool hasSelection,
    bool compact,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesktopMetrics.panelRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(compact: compact),
          Expanded(
            child: lines.isEmpty
                ? const TestId(
                    SaleIds.emptyState,
                    child: Center(
                      child: Text(
                        'Scan an item to start the bill — the field keeps '
                        'focus.',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (var i = 0; i < lines.length; i++)
                        _LineRow(
                          compact: compact,
                          number: i + 1,
                          line: lines[i],
                          selected: lines[i].row == _selectedRow,
                          busy: viewModel.isBusy,
                          onTap: () => _select(lines[i].row),
                          onQuantity: (q) => viewModel.updateQuantity(
                            row: lines[i].row,
                            quantity: q,
                          ),
                        ),
                    ],
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFBFC),
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DesktopButton(
                  id: SaleIds.discountButton,
                  label: _basket ? 'Edit discount' : 'Discount',
                  icon: Icons.percent,
                  hotkey: 'F6',
                  secondary: true,
                  height: 44,
                  onPressed: hasSelection ? _discountSelected : null,
                ),
                if (_basket) ...[
                  const DesktopButton(
                    id: DesktopSaleIds.printBasketButton,
                    label: 'Print basket',
                    icon: Icons.print_outlined,
                    secondary: true,
                    height: 44,
                  ),
                  const DesktopButton(
                    id: DesktopSaleIds.claimCheckButton,
                    label: 'Claim check',
                    icon: Icons.confirmation_number_outlined,
                    secondary: true,
                    height: 44,
                  ),
                ] else ...[
                  const DesktopButton(
                    id: DesktopSaleIds.freezeButton,
                    label: 'Freeze',
                    icon: Icons.ac_unit,
                    secondary: true,
                    height: 44,
                  ),
                  const DesktopButton(
                    id: DesktopSaleIds.pickupButton,
                    label: 'Pickup',
                    icon: Icons.flight_takeoff,
                    secondary: true,
                    height: 44,
                  ),
                ],
                DesktopButton(
                  id: DesktopSaleIds.removeButton,
                  label: _basket ? 'Cancel line' : 'Remove',
                  icon: Icons.delete_outline,
                  hotkey: 'F8',
                  secondary: true,
                  height: 44,
                  onPressed: hasSelection ? _removeSelected : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: TestId(
                    DesktopSaleIds.selectionHint,
                    child: Text(
                      hasSelection
                          ? 'Line ${_selectedIndex + 1} selected · ↑↓ to move'
                          : 'Select a line to discount or remove it',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _colFlex = [4, 40, 16, 14, 12, 14, 12];
const _compactFlex = [4, 38, 24, 14, 0, 16, 0];

class _HeaderRow extends StatelessWidget {
  final bool compact;

  const _HeaderRow({required this.compact});

  @override
  Widget build(BuildContext context) {
    const labels = [
      '#',
      'Item',
      'Qty',
      'Unit price',
      'Discount',
      'Net (THB)',
      'Fulfilment',
    ];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFC),
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            if (!compact || _compactFlex[i] > 0)
              Expanded(
                flex: compact ? _compactFlex[i] : _colFlex[i],
                child: Text(
                  labels[i],
                  textAlign: i >= 3 && i <= 5 ? TextAlign.end : TextAlign.start,
                  style: DesktopText.fieldLabel,
                ),
              ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final bool compact;
  final int number;
  final CartItem line;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;
  final ValueChanged<int> onQuantity;

  const _LineRow({
    required this.compact,
    required this.number,
    required this.line,
    required this.selected,
    required this.busy,
    required this.onTap,
    required this.onQuantity,
  });

  @override
  Widget build(BuildContext context) {
    const numbers = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
    return TestId(
      SaleIds.line(line.row),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? AppColors.cream : AppColors.surface,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: compact ? _compactFlex[0] : _colFlex[0],
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: selected
                            ? AppColors.goldDark
                            : AppColors.mutedText,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: compact ? _compactFlex[1] : _colFlex[1],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.articleName.isEmpty
                              ? line.articleCode
                              : line.articleName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          line.articleCode,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.goldMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: compact ? _compactFlex[2] : _colFlex[2],
                    // Shrinks slightly instead of overflowing when the
                    // table is narrow (e.g. 1280 wide next to the summary).
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TestId(
                          DesktopSaleIds.qtyDecrease(line.row),
                          child: IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            tooltip: 'Decrease quantity',
                            onPressed: busy || line.quantity <= 1
                                ? null
                                : () => onQuantity(line.quantity - 1),
                          ),
                        ),
                        Text(
                          '${line.quantity}',
                          style: numbers.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TestId(
                          DesktopSaleIds.qtyIncrease(line.row),
                          child: IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            tooltip: 'Increase quantity',
                            onPressed: busy
                                ? null
                                : () => onQuantity(line.quantity + 1),
                          ),
                        ),
                      ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: compact ? _compactFlex[3] : _colFlex[3],
                    child: Text(
                      formatAmount(line.unitPrice),
                      textAlign: TextAlign.end,
                      style: numbers.copyWith(fontSize: 15),
                    ),
                  ),
                  if (!compact)
                    Expanded(
                      flex: _colFlex[4],
                      child: const Text(
                        '—',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.hintText,
                        ),
                      ),
                    ),
                  Expanded(
                    flex: compact ? _compactFlex[5] : _colFlex[5],
                    child: Text(
                      formatAmount(line.lineTotal),
                      textAlign: TextAlign.end,
                      style: numbers.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A396E),
                      ),
                    ),
                  ),
                  if (!compact)
                    Expanded(
                      flex: _colFlex[6],
                      child: const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(
                          '—',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.hintText,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final List<CartItem> lines;
  final double total;
  final Privilege? privilege;
  final VoidCallback? onTakePayment;

  const _Summary({
    required this.lines,
    required this.total,
    required this.privilege,
    required this.onTakePayment,
  });

  @override
  Widget build(BuildContext context) {
    final units = lines.fold<int>(0, (s, l) => s + l.quantity);
    final code =
        privilege == null ||
            (privilege!.typeCode.isEmpty && privilege!.promoCode.isEmpty)
        ? null
        : '[${privilege!.typeCode}]:${privilege!.promoCode}';

    Widget tile(String label, String value, Color bg, {String? id}) {
      final text = Text(
        value,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      );
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: DesktopText.fieldLabel),
              const SizedBox(height: 4),
              id == null ? text : TestId(id, child: text),
            ],
          ),
        ),
      );
    }

    Widget amount(String label, String value, {String? id, Color? color}) {
      final text = Text(
        value,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.mutedText,
                ),
              ),
            ),
            id == null ? text : TestId(id, child: text),
          ],
        ),
      );
    }

    return TestId(
      DesktopSaleIds.summary,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(DesktopMetrics.panelRadius),
          border: Border.all(color: AppColors.line),
        ),
        // Scrolls on short screens (e.g. 1366×768 with a privilege);
        // otherwise the Spacer keeps Take payment at the bottom.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 32).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: IntrinsicHeight(
                child: _content(units, code, tile, amount),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    int units,
    String? code,
    Widget Function(String, String, Color, {String? id}) tile,
    Widget Function(String, String, {String? id, Color? color}) amount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text('Bill summary', style: DesktopText.sectionTitle),
            ),
            Text(
              'THB',
              style: TextStyle(fontSize: 12.5, color: AppColors.mutedText),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            tile(
              'Qty total',
              '$units',
              const Color(0xFFF3EBD9),
              id: DesktopSaleIds.qtyTotal,
            ),
            const SizedBox(width: 8),
            tile(
              'Lines',
              '${lines.length}',
              const Color(0xFFF2F4F7),
              id: DesktopSaleIds.lineCount,
            ),
            const SizedBox(width: 8),
            tile('Mode', 'Shopping', const Color(0xFFEAF1FA)),
          ],
        ),
        const SizedBox(height: 8),
        amount('Total', formatAmount(total)),
        amount('Discount', '—'),
        amount('Grand', formatAmount(total), id: DesktopSaleIds.grand),
        amount('Cash-D subsidy', '—'),
        const SizedBox(height: 8),
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
                  SaleIds.netPay,
                  child: Text(
                    formatBaht(total),
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
            ],
          ),
        ),
        if (privilege != null) ...[
          const SizedBox(height: 12),
          const Text('APPLIED PRIVILEGE', style: DesktopText.fieldLabel),
          const SizedBox(height: 6),
          TestId(
            SaleIds.privilege,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF0E8D8)),
              ),
              child: Row(
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
                          privilege!.name.isEmpty
                              ? 'Privilege'
                              : privilege!.name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (code != null)
                          Text(
                            code,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.goldDark,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const Spacer(),
        DesktopButton(
          id: SaleIds.checkoutButton,
          label: 'Take payment',
          icon: Icons.payments_outlined,
          hotkey: 'F12',
          height: 56,
          onPressed: onTakePayment,
        ),
        const SizedBox(height: 10),
        const DesktopButton(
          id: DesktopSaleIds.suspendButton,
          label: 'Suspend bill',
          icon: Icons.assignment_turned_in_outlined,
          secondary: true,
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final String id;
  final IconData icon;
  final Color color;
  final String text;

  const _Notice({
    required this.id,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TestId(
        id,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text, style: TextStyle(fontSize: 13, color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

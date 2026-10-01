import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/handheld/handheld.dart'
    show formatAmount, formatBaht, formatMoney;
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customer/domain/entities/privilege.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../sale_cart_view_model.dart';
import '../widgets/go_checkout.dart';
import '../widgets/leave_sale_prompt.dart';
import '../widgets/line_record_status.dart';
import 'desktop_checkout_page.dart';
import '../sale_currency.dart';
import '../widgets/applied_privilege_card.dart';
import '../widgets/privilege_picker.dart';
import 'desktop_discount_overlay.dart';
import 'desktop_edit_line_overlay.dart';

/// Desktop Sale (POS Desktop mockup screens 3 + 4): scan row, Buying /
/// Basket tabs, the lines table and the permanent bill summary.
///
/// Real (`SaleCartViewModel`): scan-to-add, qty change, remove, line /
/// unit totals, selected privilege, Edit line (qty / serial / Freeze /
/// Lock / Pickup). Keyboard: F6 discount, F7 edit, F8 remove, F9 search
/// the typed code, ↑↓ move the selection; the scan field keeps focus.
/// Shown as "—" or inert because the cart doesn't carry them yet (desktop
/// Phase 2 data-reality map): per-line fulfilment, Collect / Take grouping
/// and cancelled lines on Basket, discount / Cash-D / VAT breakdown,
/// Suspend. Take payment (F12) opens the 2c Checkout.
// TODO(pos-desktop): line discount / fulfilment /
// cancelled state once the order API carries them (openspec 4.4 / 5.2 /
// 6.1).
class DesktopSaleView extends StatefulWidget {
  final SaleCartViewModel viewModel;
  final bool isAirportMpos;

  /// Called once the cashier has left Sale (legacy back / Home) — the
  /// leave prompt has run and the shopping card is unlocked.
  final VoidCallback? onExit;

  /// Back to the customer lookup — Sale has no customer yet.
  final VoidCallback? onFindCustomer;

  /// Logs out — offered when leaving can't unlock the shopping card.
  final Future<void> Function()? onSignOut;

  const DesktopSaleView({
    super.key,
    required this.viewModel,
    this.isAirportMpos = false,
    this.onExit,
    this.onFindCustomer,
    this.onSignOut,
  });

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

  // The lines of the tab shown — Buying, or the saved order's Basket.
  List<CartItem> get _lines => widget.viewModel.linesFor(basket: _basket);

  // The whole order, for the bill summary and Take payment.
  List<CartItem> get _orderLines =>
      widget.viewModel.cart?.items ?? const <CartItem>[];

  int get _selectedIndex => _lines.indexWhere((l) => l.row == _selectedRow);

  double get _total => _orderLines.fold<double>(0, (s, l) => s + l.lineTotal);

  // Legacy `changeTab()`: the other tab's selection is dropped; the scan
  // field only works on Buying.
  void _showTab(bool basket) {
    setState(() {
      _basket = basket;
      _selectedRow = null;
    });
    widget.viewModel.clearSelection(basket: !basket);
    _scanFocus.requestFocus();
  }

  // Legacy Basket swipe "Cancel" / "Uncancel": confirm, then `cancel`.
  Future<void> _cancelSelected() async {
    final index = _selectedIndex;
    if (index < 0) return;
    final line = _lines[index];
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Cancel item',
      message: 'Do you want to cancel selected item',
      confirmLabel: 'Confirm',
      destructive: !line.isCancel,
    );
    if (!confirmed || !mounted) return;
    final error = await widget.viewModel.cancelBasketLine(line);
    if (!mounted) return;
    if (error != null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Oops !'),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    _scanFocus.requestFocus();
  }

  Future<void> _submitScan(String value) async {
    // The view model sends the ticked lines as `Rows`, as legacy does.
    await widget.viewModel.scan(value);
    if (widget.viewModel.scanError == null) _scan.clear();
    _scanFocus.requestFocus();
  }

  // Search (F9): the same as Enter in the scan field, for a code typed
  // by hand.
  void _searchTyped() {
    if (widget.viewModel.isBusy) return;
    _submitScan(_scan.text);
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

  // Legacy "Discount": the ticked lines of the tab; with none ticked, the
  // highlighted line.
  List<CartItem> get _discountLines {
    final ticked = widget.viewModel.selectedLines(basket: _basket);
    if (ticked.isNotEmpty) return ticked;
    final index = _selectedIndex;
    return index < 0 ? const [] : [_lines[index]];
  }

  String _hint(SaleCartViewModel viewModel, bool hasSelection) {
    final ticked = viewModel.selectedLines(basket: _basket).length;
    if (ticked > 0) {
      return '$ticked line${ticked == 1 ? '' : 's'} ticked for Discount';
    }
    return hasSelection
        ? 'Line ${_selectedIndex + 1} selected · ↑↓ to move'
        : 'Select a line to discount or remove it';
  }

  Future<void> _discountSelected() async {
    final lines = _discountLines;
    if (lines.isEmpty) return;
    await showDesktopDiscountOverlay(
      context,
      viewModel: widget.viewModel,
      lines: lines,
      title: lines.length == 1
          ? 'Discount · line ${_lines.indexOf(lines.single) + 1}'
          : 'Discount · ${lines.length} lines',
    );
    if (mounted) _scanFocus.requestFocus();
  }

  // Legacy `editDetail()`: Buying lines only — Basket has no Edit Detail.
  Future<void> _editSelected() async {
    final index = _selectedIndex;
    if (_basket || index < 0 || widget.viewModel.isBusy) return;
    await showDesktopEditLineOverlay(
      context,
      viewModel: widget.viewModel,
      line: _lines[index],
      title: 'Order item · line ${index + 1}',
      isAirportMpos: widget.isAirportMpos,
    );
    if (mounted) _scanFocus.requestFocus();
  }

  Future<void> _changeCurrency() async {
    await changeOrderCurrency(context, widget.viewModel);
    if (mounted) _scanFocus.requestFocus();
  }

  Future<void> _changePrivilege() async {
    await changeOrderPrivilege(context, widget.viewModel);
    if (mounted) _scanFocus.requestFocus();
  }

  Future<void> _saveOrder() async {
    await confirmSaveOrder(
      context,
      widget.viewModel,
      onSignOut: widget.onSignOut ?? () async {},
    );
    if (mounted) _scanFocus.requestFocus();
  }

  Future<void> _exit() async {
    final left = await confirmLeaveSale(
      context,
      widget.viewModel,
      isAirportMpos: widget.isAirportMpos,
      onSignOut: widget.onSignOut ?? () async {},
    );
    if (!mounted) return;
    if (left) {
      setState(() => _selectedRow = null);
      widget.onExit?.call();
    } else {
      _scanFocus.requestFocus();
    }
  }

  /// Legacy `goCheckout()`, offered only while the sale engine allows it
  /// ([SaleCartViewModel.canCheckout]).
  Future<void> _takePayment() async {
    if (!widget.viewModel.canCheckout || widget.viewModel.isBusy) return;
    final go = await confirmGoCheckout(
      context,
      widget.viewModel,
      onSignOut: widget.onSignOut ?? () async {},
    );
    if (!go || !mounted) return;
    await openDesktopCheckoutPage(
      context,
      viewModel: widget.viewModel,
      isAirportMpos: widget.isAirportMpos,
    );
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
          const SingleActivator(LogicalKeyboardKey.f7): _editSelected,
          const SingleActivator(LogicalKeyboardKey.f9): _searchTyped,
          const SingleActivator(LogicalKeyboardKey.f8): () =>
              _basket ? _cancelSelected() : _removeSelected(),
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
                    if (!viewModel.hasCustomer) _noCustomer(),
                    if (viewModel.scanError != null)
                      _Notice(
                        id: SaleIds.scanError,
                        icon: Icons.error_outline,
                        color: AppColors.danger,
                        text: viewModel.scanError!,
                      ),
                    if (viewModel.currencyError != null)
                      _Notice(
                        id: CurrencyIds.error,
                        icon: Icons.error_outline,
                        color: AppColors.danger,
                        text: viewModel.currencyError!,
                      ),
                    const SizedBox(height: 16),
                    _tabs(
                      buying: viewModel.linesFor(basket: false).length,
                      basket: viewModel.linesFor(basket: true).length,
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
                  lines: _orderLines,
                  total: _total,
                  privilege: viewModel.selectedPrivilege,
                  isMember: viewModel.isMember,
                  onChangePrivilege:
                      viewModel.privileges.isEmpty || viewModel.isBusy
                      ? null
                      : _changePrivilege,
                  onTakePayment: viewModel.canCheckout && !viewModel.isBusy
                      ? _takePayment
                      : null,
                  onExit: widget.onExit == null || viewModel.isBusy
                      ? null
                      : _exit,
                  onSaveOrder: viewModel.canSaveOrder && !viewModel.isBusy
                      ? _saveOrder
                      : null,
                  billing: viewModel.cart?.billing,
                  onCurrency: viewModel.shoppingCard.isEmpty || viewModel.isBusy
                      ? null
                      : _changeCurrency,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Legacy never opens Sale without a customer; point back to the lookup.
  Widget _noCustomer() => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TestId(
      SaleIds.noCustomerNotice,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.person_search, color: AppColors.info),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'No customer on this sale — find the customer first, '
                'then Start sale.',
              ),
            ),
            DesktopButton(
              id: SaleIds.findCustomerButton,
              label: 'Find customer',
              icon: Icons.person_search,
              secondary: true,
              height: 40,
              onPressed: widget.onFindCustomer,
            ),
          ],
        ),
      ),
    ),
  );

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
                      enabled:
                          !viewModel.isBusy &&
                          viewModel.hasCustomer &&
                          !_basket,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _submitScan,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration.collapsed(
                        hintText: !viewModel.hasCustomer
                            ? SaleCartViewModel.noCustomer
                            : _basket
                            ? 'Scanning adds to Buying — switch tab to scan'
                            : 'Scan or type item code',
                        hintStyle: const TextStyle(
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
        DesktopButton(
          id: DesktopSaleIds.searchButton,
          label: 'Search',
          icon: Icons.search,
          hotkey: 'F9',
          secondary: true,
          height: DesktopMetrics.fieldHeight,
          onPressed: viewModel.isBusy || !viewModel.hasCustomer || _basket
              ? null
              : _searchTyped,
        ),
      ],
    );
  }

  Widget _tabs({required int buying, required int basket}) {
    Widget tab(String id, String label, bool basket, int count) {
      final selected = _basket == basket;
      return TestId(
        id,
        child: Semantics(
          button: true,
          selected: selected,
          inMutuallyExclusiveGroup: true,
          child: InkWell(
            onTap: () => _showTab(basket),
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
        tab(SaleIds.tabBuying, 'Buying', false, buying),
        tab(SaleIds.tabBasket, 'Basket', true, basket),
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
          _HeaderRow(
            compact: compact,
            currency: viewModel.cart?.billing?.currencyCode ?? '',
            allSelected: viewModel.isAllSelected(basket: _basket),
            onSelectAll: lines.isEmpty
                ? null
                : () => viewModel.toggleSelectAll(basket: _basket),
          ),
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
                          // Basket lines keep their number on the saved order.
                          number: _basket && lines[i].lineNo > 0
                              ? lines[i].lineNo
                              : i + 1,
                          line: lines[i],
                          selected: lines[i].row == _selectedRow,
                          checked: viewModel.isSelected(lines[i].row),
                          busy: viewModel.isBusy,
                          onTap: () => _select(lines[i].row),
                          onCheck: () => viewModel.toggleSelected(lines[i].row),
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
                  onPressed: _discountLines.isEmpty ? null : _discountSelected,
                ),
                if (!_basket)
                  // Legacy Buying swipe "Edit Detail" — qty, serial,
                  // Freeze, Lock and Pickup in one place.
                  DesktopButton(
                    id: DesktopSaleIds.editLineButton,
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    hotkey: 'F7',
                    secondary: true,
                    height: 44,
                    onPressed: !hasSelection || viewModel.isBusy
                        ? null
                        : _editSelected,
                  ),
                DesktopButton(
                  id: DesktopSaleIds.removeButton,
                  label: !_basket
                      ? 'Remove'
                      : hasSelection && lines[_selectedIndex].isCancel
                      ? 'Uncancel line'
                      : 'Cancel line',
                  icon: _basket ? Icons.block : Icons.delete_outline,
                  hotkey: 'F8',
                  secondary: true,
                  height: 44,
                  onPressed: !hasSelection || viewModel.isBusy
                      ? null
                      : _basket
                      ? _cancelSelected
                      : _removeSelected,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: TestId(
                    DesktopSaleIds.selectionHint,
                    child: Text(
                      _hint(viewModel, hasSelection),
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

// `#` holds the line's select box (legacy `isSelected`) and its number.
const _colFlex = [8, 36, 16, 14, 12, 14, 12];
const _compactFlex = [9, 33, 24, 14, 0, 16, 0];

class _HeaderRow extends StatelessWidget {
  final bool compact;

  /// The order's currency; amounts follow it after a `change_currency`.
  final String currency;

  /// Legacy `checkAllItems()`: all lines of the tab selected, and the
  /// toggle.
  final bool allSelected;
  final VoidCallback? onSelectAll;

  const _HeaderRow({
    required this.compact,
    required this.currency,
    required this.allSelected,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final labels = [
      '#',
      'Item',
      'Qty',
      'Unit price',
      'Discount',
      'Net (${currency.isEmpty ? 'THB' : currency})',
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
                child: i == 0
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: TestId(
                          DesktopSaleIds.selectAll,
                          child: Checkbox(
                            value: allSelected,
                            onChanged: onSelectAll == null
                                ? null
                                : (_) => onSelectAll!(),
                          ),
                        ),
                      )
                    : Text(
                        labels[i],
                        textAlign: i >= 3 && i <= 5
                            ? TextAlign.end
                            : TextAlign.start,
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

  /// Legacy `isSelected` — what Discount and a scan apply to.
  final bool checked;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onCheck;
  final ValueChanged<int> onQuantity;

  const _LineRow({
    required this.compact,
    required this.number,
    required this.line,
    required this.selected,
    required this.checked,
    required this.busy,
    required this.onTap,
    required this.onCheck,
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
                    child: Row(
                      children: [
                        TestId(
                          DesktopSaleIds.lineCheck(line.row),
                          child: Checkbox(
                            value: checked,
                            onChanged: (_) => onCheck(),
                          ),
                        ),
                        Flexible(
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
                      ],
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
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            // Legacy strikes a cancelled Basket line through.
                            decoration: line.isCancel
                                ? TextDecoration.lineThrough
                                : null,
                            color: line.isCancel ? AppColors.mutedText : null,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                line.articleCode,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.goldMuted,
                                ),
                              ),
                            ),
                            if (line.isCancel)
                              _LineBadge(
                                id: DesktopSaleIds.lineCancelled(line.row),
                                label: 'Cancelled',
                                color: AppColors.danger,
                              ),
                            if (line.isFreeze)
                              _LineBadge(
                                id: DesktopSaleIds.lineFreeze(line.row),
                                label: 'Freeze',
                                color: AppColors.info,
                              ),
                            if (line.isLockDiscount)
                              _LineBadge(
                                id: DesktopSaleIds.lineLock(line.row),
                                label: 'Lock',
                                color: AppColors.warning,
                              ),
                            LineRecordStatus(line: line, size: 18),
                          ],
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
                              onPressed:
                                  busy || line.isBasket || line.quantity <= 1
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
                              // A saved (Basket) line's quantity isn't changed here.
                              onPressed: busy || line.isBasket
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
                      child: Text(
                        line.discountAmount == 0
                            ? '—'
                            : formatAmount(-line.discountAmount),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 15,
                          color: line.discountAmount == 0
                              ? AppColors.hintText
                              : AppColors.danger,
                          fontFeatures: const [FontFeature.tabularFigures()],
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
                      // Legacy `getTakeCollectStatus()`: T = Take, C = Collect.
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: TestId(
                          DesktopSaleIds.lineFulfilment(line.row),
                          child: Text(
                            switch (line.collectStatus) {
                              'T' => 'Take',
                              'C' => 'Collect',
                              _ => '—',
                            },
                            style: TextStyle(
                              fontSize: 15,
                              color: line.collectStatus.isEmpty
                                  ? AppColors.hintText
                                  : AppColors.textPrimary,
                            ),
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

  /// A member always sees the privilege row — "[No Privilege]" when none
  /// (legacy `sale.html`).
  final bool isMember;

  /// Legacy Sale's Privilege Selection; null (inert) without a list.
  final VoidCallback? onChangePrivilege;
  final VoidCallback? onTakePayment;
  final VoidCallback? onExit;
  final VoidCallback? onSaveOrder;

  /// The sale engine's own amounts, in the order's currency, when the order
  /// carries them; otherwise the summary sums the lines in baht.
  final CartBilling? billing;

  /// Opens the currency picker; null (inert) until a customer — and so a
  /// shopping card — is attached.
  final VoidCallback? onCurrency;

  const _Summary({
    required this.lines,
    required this.total,
    required this.privilege,
    required this.isMember,
    required this.onChangePrivilege,
    required this.onTakePayment,
    required this.onExit,
    required this.onSaveOrder,
    required this.billing,
    required this.onCurrency,
  });

  String _money(double value) =>
      formatMoney(value, billing?.currencyCode ?? '');

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
        Row(
          children: [
            const Expanded(
              child: Text('Bill summary', style: DesktopText.sectionTitle),
            ),
            // Legacy Sale header: order currency + rate, tap to change.
            OrderCurrencyButton(billing: billing, onTap: onCurrency),
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
            tile(
              'Mode',
              'Normal',
              const Color(0xFFEAF1FA),
              id: DesktopSaleIds.mode,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...billing == null
            ? [
                amount('Total', formatAmount(total)),
                amount('Discount', '—'),
                amount('Grand', formatAmount(total), id: DesktopSaleIds.grand),
                amount('Cash-D subsidy', '—'),
              ]
            : [
                amount('Total', formatAmount(billing!.total)),
                amount('Discount', formatAmount(billing!.discount)),
                amount(
                  'Grand',
                  formatAmount(billing!.grand),
                  id: DesktopSaleIds.grand,
                ),
                amount('Cash-D subsidy', formatAmount(billing!.cashD)),
                amount(
                  'Rate',
                  billing!.currencyRate.toStringAsFixed(5),
                  id: CurrencyIds.rate,
                ),
              ],
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
                    _money(billing?.netPay ?? total),
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
              if (billing != null && !billing!.isBaht) ...[
                const SizedBox(height: 4),
                TestId(
                  CurrencyIds.netPayBase,
                  child: Text(
                    '= ${formatBaht(billing!.netPayBase)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (privilege != null || isMember) ...[
          const SizedBox(height: 12),
          AppliedPrivilegeCard(
            privilege: privilege,
            canChange: isMember,
            onChange: onChangePrivilege,
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
        // Legacy Save Order (in place of the mockup's Suspend bill).
        DesktopButton(
          id: SaleIds.saveOrderButton,
          label: 'Save order',
          icon: Icons.assignment_turned_in_outlined,
          secondary: true,
          onPressed: onSaveOrder,
        ),
        const SizedBox(height: 10),
        DesktopButton(
          id: DesktopSaleIds.exitButton,
          label: 'Exit sale',
          icon: Icons.logout,
          secondary: true,
          onPressed: onExit,
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

/// A small status tag beside a line's code (Cancelled / Freeze / Lock).
class _LineBadge extends StatelessWidget {
  final String id;
  final String label;
  final Color color;

  const _LineBadge({
    required this.id,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: TestId(
        id,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

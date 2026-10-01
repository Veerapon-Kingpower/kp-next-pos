import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customer/domain/entities/privilege.dart';
import '../../domain/entities/cart_item.dart';
import '../sale_cart_view_model.dart';
import '../widgets/leave_sale_prompt.dart';
import '../sale_currency.dart';
import '../widgets/applied_privilege_card.dart';
import '../widgets/privilege_picker.dart';
import 'discount_sheet.dart';
import 'edit_line_page.dart';
import 'payment/checkout_page.dart';
import 'sale_order_type.dart';

/// Handheld Sale screen (mockup screens 3 / 4 / 16 / 17): order-type
/// header with the scan field and totals, Buying / Basket tabs, the cart
/// lines, and the persistent Checkout bar.
///
/// Real: scan-to-add, line totals / units / net pay summed from the cart,
/// edit qty, void (swipe left or Edit line), selected privilege.
/// Inert until their APIs exist (handheld spec decision 3): Checkout (H3),
/// Save / suspend, order-type switching, line discounts. Net pay is the sum
/// of line totals — the cart carries no discount / VAT breakdown yet.
class HandheldSaleView extends StatefulWidget {
  final SaleCartViewModel viewModel;
  final SaleOrderType orderType;
  final VoidCallback onExit;
  final VoidCallback onCustomer;

  /// Airport mPOS offers NORMAL / DEPOSIT instead of NORMAL / DELIVERY /
  /// Pre-order (legacy `setDefaultShopping`).
  final bool isAirportMpos;

  /// Logs out — after Save order (legacy `signout()`).
  final Future<void> Function()? onSignOut;

  const HandheldSaleView({
    super.key,
    required this.viewModel,
    required this.onExit,
    required this.onCustomer,
    this.orderType = SaleOrderType.normal,
    this.isAirportMpos = false,
    this.onSignOut,
  });

  @override
  State<HandheldSaleView> createState() => _HandheldSaleViewState();
}

class _HandheldSaleViewState extends State<HandheldSaleView> {
  final _scanController = TextEditingController();
  final _scanFocus = FocusNode();
  bool _showBasket = false;

  @override
  void dispose() {
    _scanController.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  // The scan field is disabled while busy, which drops its focus — take
  // it back so the next trigger scan lands there.
  void _refocusScan() {
    if (!mounted || _showBasket) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_showBasket) _scanFocus.requestFocus();
    });
  }

  Future<void> _scan(String value) async {
    await widget.viewModel.scan(value);
    if (widget.viewModel.scanError == null) _scanController.clear();
    _refocusScan();
  }

  Future<void> _openLine(CartItem line, int number) async {
    await openEditLinePage(
      context,
      viewModel: widget.viewModel,
      row: line.row,
      lineNumber: number,
      isAirportMpos: widget.isAirportMpos,
    );
    _refocusScan();
  }

  // Legacy `changeTab()`: the tab left behind loses its selection.
  void _showTab(bool basket) {
    setState(() => _showBasket = basket);
    widget.viewModel.clearSelection(basket: !basket);
    _refocusScan();
  }

  // Legacy Basket swipe "Cancel" / "Uncancel": confirm, then `cancel`.
  // Never lets Dismissible remove the row — the list rebuilds from the
  // returned order.
  Future<bool> _confirmCancel(CartItem line) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Cancel item',
      message: 'Do you want to cancel selected item',
      confirmLabel: 'Confirm',
      destructive: !line.isCancel,
    );
    if (!confirmed || !mounted) return false;
    final error = await widget.viewModel.cancelBasketLine(line);
    if (error != null && mounted) {
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
    return false;
  }

  void _openDiscount(CartItem line, int number) {
    showDiscountSheet(
      context,
      viewModel: widget.viewModel,
      lines: [line],
      title: 'Discount · line $number',
    );
  }

  // Legacy "Discount": the selected lines; with none selected, the last one.
  void _discountSelected(List<CartItem> lines) {
    final selected = widget.viewModel.selectedLines(basket: _showBasket);
    if (selected.length == 1) {
      _openDiscount(selected.single, lines.indexOf(selected.single) + 1);
    } else if (selected.isNotEmpty) {
      showDiscountSheet(
        context,
        viewModel: widget.viewModel,
        lines: selected,
        title: 'Discount · ${selected.length} lines',
      );
    } else {
      _openDiscount(lines.last, lines.length);
    }
  }

  Future<bool> _confirmVoid(CartItem line) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Void this line?',
      message: line.articleName.isEmpty ? line.articleCode : line.articleName,
      confirmLabel: 'Void line',
      destructive: true,
    );
    if (confirmed) await widget.viewModel.removeItem(line.row);
    // Never let Dismissible remove the row itself — the list rebuilds from
    // the cart the view-model returns, which is the source of truth.
    return false;
  }

  void _openMore() {
    showHandheldSheet<void>(
      context,
      id: SaleIds.moreSheet,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Order type', style: HandheldText.sectionTitle),
          const SizedBox(height: 4),
          const Text(
            'Other order types are not available yet.',
            style: HandheldText.bodySmall,
          ),
          const SizedBox(height: 12),
          // TODO(pos-handheld): enable Delivery / Pre-order / Deposit once
          // the sale engine accepts an order type (and pickup / delivery
          // details; Deposit also follows the AllowDeposit config).
          for (final type in SaleOrderType.optionsFor(
            isAirportMpos: widget.isAirportMpos,
          )) ...[
            HandheldChoiceChip(
              id: SaleIds.orderType(type.name),
              label: type.label,
              icon: type.icon,
              height: 48,
              selected: type == widget.orderType,
              onTap: type == widget.orderType
                  ? () => Navigator.of(sheetContext).pop()
                  : null,
            ),
            const SizedBox(height: 8),
          ],
          if (widget.viewModel.privileges.isNotEmpty) ...[
            const SizedBox(height: 4),
            HandheldChoiceChip(
              id: SaleIds.privilegeMoreButton,
              label: 'Privilege Selection',
              icon: Icons.card_giftcard,
              height: 48,
              selected: false,
              onTap: () {
                Navigator.of(sheetContext).pop();
                changeOrderPrivilege(context, widget.viewModel);
              },
            ),
            const SizedBox(height: 8),
          ],
          TextButton.icon(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              widget.onExit();
            },
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to Home'),
          ),
        ],
      ),
    );
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
    // The whole order for the totals; the tab's lines (Buying, or the
    // saved order's Basket) for the list.
    final orderLines = viewModel.cart?.items ?? const <CartItem>[];
    final lines = viewModel.linesFor(basket: _showBasket);
    final billing = viewModel.cart?.billing;
    final total =
        billing?.total ??
        orderLines.fold<double>(0, (sum, l) => sum + l.lineTotal);
    final netPay = orderNetPay(viewModel.cart);
    final currency = orderCurrency(viewModel.cart);
    final units = orderLines.fold<int>(0, (sum, l) => sum + l.quantity);

    return HandheldScaffold(
      fullWidthBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SaleHeader(
            orderType: widget.orderType,
            lineCount: orderLines.length,
            scanController: _scanController,
            scanFocus: _scanFocus,
            // Legacy: scanning only on the Buying tab.
            scanEnabled:
                !viewModel.isBusy && viewModel.hasCustomer && !_showBasket,
            onScan: _scan,
            onExit: widget.onExit,
            total: total,
            netPay: netPay,
            currency: currency,
            units: units,
            // Legacy Sale header's currency button.
            currencyButton: OrderCurrencyButton(
              billing: billing,
              onDark: true,
              onTap: viewModel.shoppingCard.isEmpty || viewModel.isBusy
                  ? null
                  : () => changeOrderCurrency(context, viewModel),
            ),
          ),
          _Tabs(
            buyingCount: viewModel.linesFor(basket: false).length,
            basketCount: viewModel.linesFor(basket: true).length,
            showBasket: _showBasket,
            onSelect: _showTab,
          ),
          if (viewModel.isBusy) const LinearProgressIndicator(minHeight: 2),
          if (viewModel.currencyError != null)
            TestId(
              CurrencyIds.error,
              child: _Banner(
                icon: Icons.error_outline,
                color: AppColors.danger,
                text: viewModel.currencyError!,
              ),
            ),
          Expanded(
            child: HandheldContentWidth(
              child: _LineList(
                lines: lines,
                basket: _showBasket,
                scanError: viewModel.scanError,
                privilege: viewModel.selectedPrivilege,
                isMember: viewModel.isMember,
                onChangePrivilege:
                    viewModel.privileges.isEmpty || viewModel.isBusy
                    ? null
                    : () => changeOrderPrivilege(context, viewModel),
                onOpen: _openLine,
                onDiscount: _openDiscount,
                isSelected: viewModel.isSelected,
                onToggleSelected: viewModel.toggleSelected,
                onFindCustomer: viewModel.hasCustomer
                    ? null
                    : widget.onCustomer,
                onConfirmVoid: _confirmVoid,
                onConfirmCancel: _confirmCancel,
              ),
            ),
          ),
        ],
      ),
      actionBar: HandheldActionBar(
        primary: HandheldPrimaryButton(
          id: SaleIds.checkoutButton,
          label: 'Checkout · ${formatMoney(netPay, currency)}',
          icon: Icons.payments_outlined,
          onPressed: orderLines.isEmpty
              ? null
              : () => openCheckoutPage(
                  context,
                  viewModel: viewModel,
                  isAirportMpos: widget.isAirportMpos,
                ),
        ),
        secondary: _showBasket
            ? HandheldSecondaryButton(
                id: SaleIds.backToBuyingButton,
                label: 'Buying',
                onPressed: () => _showTab(false),
              )
            : null,
        items: _showBasket
            ? const []
            : [
                HandheldBarItem(
                  id: SaleIds.customerButton,
                  icon: Icons.badge_outlined,
                  label: 'Customer',
                  onPressed: widget.onCustomer,
                ),
                HandheldBarItem(
                  id: SaleIds.discountButton,
                  icon: Icons.percent,
                  label: 'Discount',
                  onPressed: lines.isEmpty
                      ? null
                      : () => _discountSelected(lines),
                ),
                // Legacy Save Order.
                HandheldBarItem(
                  id: SaleIds.saveOrderButton,
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Save',
                  onPressed: viewModel.canSaveOrder && !viewModel.isBusy
                      ? () => confirmSaveOrder(
                          context,
                          viewModel,
                          onSignOut: widget.onSignOut ?? () async {},
                        )
                      : null,
                ),
                HandheldBarItem(
                  id: SaleIds.moreButton,
                  icon: Icons.more_horiz,
                  label: 'More',
                  onPressed: _openMore,
                ),
              ],
      ),
    );
  }
}

class _SaleHeader extends StatelessWidget {
  final SaleOrderType orderType;
  final int lineCount;
  final TextEditingController scanController;
  final FocusNode scanFocus;
  final bool scanEnabled;
  final ValueChanged<String> onScan;
  final VoidCallback onExit;
  final double total;
  final double netPay;
  final String currency;
  final int units;
  final Widget currencyButton;

  const _SaleHeader({
    required this.orderType,
    required this.lineCount,
    required this.scanController,
    required this.scanFocus,
    required this.scanEnabled,
    required this.onScan,
    required this.onExit,
    required this.total,
    required this.netPay,
    required this.currency,
    required this.units,
    required this.currencyButton,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.72);
    return TestId(
      SaleIds.header,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: orderType.header,
            child: SafeArea(
              bottom: false,
              child: HandheldContentWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 2, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          TestId(
                            SaleIds.backButton,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              tooltip: 'Back to Home',
                              onPressed: onExit,
                            ),
                          ),
                          Icon(orderType.icon, size: 18, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sale · ${orderType.label}',
                                  style: HandheldText.title.copyWith(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  lineCount == 0
                                      ? 'New bill'
                                      : '$lineCount line${lineCount == 1 ? '' : 's'}',
                                  style: TextStyle(fontSize: 11, color: muted),
                                ),
                              ],
                            ),
                          ),
                          currencyButton,
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: ScanField(
                          id: SaleIds.scanField,
                          controller: scanController,
                          focusNode: scanFocus,
                          // No autofocus: on a phone it would pop the
                          // on-screen keyboard over the basket.
                          keepFocusOnSubmit: true,
                          hintText: 'Scan or type item code',
                          onSubmitted: onScan,
                          enabled: scanEnabled,
                          searchButtonId: SaleIds.searchButton,
                          onDark: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ColoredBox(
            color: orderType.band,
            child: HandheldContentWidth(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TestId(
                      SaleIds.totalLine,
                      child: Text(
                        'Total ${currency == 'THB' ? formatAmount(total) : formatMoney(total, currency)} · '
                        '$units unit${units == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: muted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'Net pay',
                          style: TextStyle(color: Color(0xFFFFD98A)),
                        ),
                        const Spacer(),
                        Flexible(
                          flex: 4,
                          child: TestId(
                            SaleIds.netPay,
                            child: Text(
                              formatMoney(netPay, currency),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HandheldText.statValue.copyWith(
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int buyingCount;
  final int basketCount;
  final bool showBasket;
  final ValueChanged<bool> onSelect;

  const _Tabs({
    required this.buyingCount,
    required this.basketCount,
    required this.showBasket,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Widget tab(String id, String label, bool selected, bool basket) {
      final count = basket ? basketCount : buyingCount;
      return Expanded(
        child: TestId(
          id,
          child: Semantics(
            button: true,
            selected: selected,
            inMutuallyExclusiveGroup: true,
            child: InkWell(
              onTap: () => onSelect(basket),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? AppColors.goldDark : AppColors.line,
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: selected ? AppColors.ink : AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      constraints: const BoxConstraints(minWidth: 21),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.goldDark : AppColors.line,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
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

    // Buying: lines being bought now; Basket: the saved order's lines.
    return ColoredBox(
      color: AppColors.surface,
      child: HandheldContentWidth(
        child: Row(
          children: [
            tab(SaleIds.tabBuying, 'Buying', !showBasket, false),
            tab(SaleIds.tabBasket, 'Basket', showBasket, true),
          ],
        ),
      ),
    );
  }
}

class _LineList extends StatelessWidget {
  final List<CartItem> lines;
  final bool basket;
  final String? scanError;
  final Privilege? privilege;
  final bool isMember;
  final VoidCallback? onChangePrivilege;
  final void Function(CartItem line, int number) onOpen;
  final void Function(CartItem line, int number) onDiscount;
  final Future<bool> Function(CartItem line) onConfirmVoid;
  final Future<bool> Function(CartItem line) onConfirmCancel;
  final bool Function(String row) isSelected;
  final ValueChanged<String> onToggleSelected;

  /// Set when Sale has no customer (legacy never opens it that way): a
  /// notice leads back to the lookup on Home.
  final VoidCallback? onFindCustomer;

  const _LineList({
    required this.lines,
    required this.basket,
    required this.scanError,
    required this.privilege,
    required this.isMember,
    required this.onChangePrivilege,
    required this.onOpen,
    required this.onDiscount,
    required this.onConfirmVoid,
    required this.onConfirmCancel,
    required this.isSelected,
    required this.onToggleSelected,
    required this.onFindCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (onFindCustomer != null)
        TestId(
          SaleIds.noCustomerNotice,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Banner(
                  icon: Icons.person_search,
                  color: AppColors.info,
                  text:
                      'No customer on this sale — find the customer '
                      'first, then Start sale.',
                ),
                const SizedBox(height: 8),
                HandheldSecondaryButton(
                  id: SaleIds.findCustomerButton,
                  label: 'Find customer',
                  onPressed: onFindCustomer,
                ),
              ],
            ),
          ),
        ),
      if (scanError != null)
        TestId(
          SaleIds.scanError,
          child: _Banner(
            icon: Icons.error_outline,
            color: AppColors.danger,
            text: scanError!,
          ),
        ),
      if (privilege != null || isMember)
        AppliedPrivilegeCard(
          privilege: privilege,
          canChange: isMember,
          onChange: onChangePrivilege,
          compact: true,
        ),
      if (lines.isEmpty)
        const TestId(
          SaleIds.emptyState,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 40,
                  color: AppColors.hintText,
                ),
                SizedBox(height: 12),
                Text(
                  'Scan an item to start the bill.',
                  textAlign: TextAlign.center,
                  style: HandheldText.bodySmall,
                ),
              ],
            ),
          ),
        ),
      for (var i = 0; i < lines.length; i++)
        _LineTile(
          line: lines[i],
          // Basket lines keep their number on the saved order.
          number: basket && lines[i].lineNo > 0 ? lines[i].lineNo : i + 1,
          basket: basket,
          onOpen: onOpen,
          onDiscount: onDiscount,
          onConfirmVoid: basket ? onConfirmCancel : onConfirmVoid,
          selected: isSelected(lines[i].row),
          onToggleSelected: () => onToggleSelected(lines[i].row),
        ),
      if (lines.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            basket
                ? 'Tap to select · swipe left to cancel, right to discount'
                : 'Swipe a line left to void, right to discount',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
        ),
    ];

    return ColoredBox(
      color: AppColors.surface,
      child: ListView(padding: EdgeInsets.zero, children: children),
    );
  }
}

class _LineTile extends StatelessWidget {
  final CartItem line;
  final int number;

  /// A saved-order (Basket) line: tap selects it, swipe left cancels /
  /// un-cancels ([onConfirmVoid] is the cancel then), no edit page.
  final bool basket;
  final void Function(CartItem line, int number) onOpen;
  final void Function(CartItem line, int number) onDiscount;
  final Future<bool> Function(CartItem line) onConfirmVoid;

  /// Legacy `isSelected`: what Discount (and a scan) applies to. The number
  /// badge or a long press toggles it; a tap still opens the line.
  final bool selected;
  final VoidCallback onToggleSelected;

  const _LineTile({
    required this.line,
    required this.number,
    required this.basket,
    required this.onOpen,
    required this.onDiscount,
    required this.onConfirmVoid,
    required this.selected,
    required this.onToggleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final detail = line.quantity == 1
        ? '${line.articleCode} · Qty 1'
        : 'Qty ${line.quantity} × ${formatAmount(line.unitPrice)}';

    final tile = InkWell(
      onTap: basket ? onToggleSelected : () => onOpen(line, number),
      onLongPress: onToggleSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.cream : null,
          border: const Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TestId(
                  SaleIds.lineSelect(line.row),
                  child: Semantics(
                    selected: selected,
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onToggleSelected,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.goldDark
                              : AppColors.goldMuted,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                size: 15,
                                color: Colors.white,
                              )
                            : Text(
                                '$number',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    line.articleName.isEmpty
                        ? line.articleCode
                        : line.articleName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      // Legacy strikes a cancelled Basket line through.
                      decoration: line.isCancel
                          ? TextDecoration.lineThrough
                          : null,
                      color: line.isCancel ? AppColors.mutedText : null,
                    ),
                  ),
                ),
              ],
            ),
            if (_statuses.isNotEmpty) ...[
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Wrap(spacing: 6, runSpacing: 4, children: _statuses),
              ),
            ],
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.goldDark,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Text(
                    formatAmount(line.lineTotal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A396E),
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final content = Dismissible(
      key: ValueKey('dismiss-${line.row}'),
      background: const _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.goldDark,
        icon: Icons.percent,
        label: 'Discount',
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.danger,
        icon: basket ? Icons.block : Icons.delete_outline,
        label: !basket
            ? 'Void'
            : line.isCancel
            ? 'Uncancel'
            : 'Cancel',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onDiscount(line, number);
          return false;
        }
        return onConfirmVoid(line);
      },
      child: tile,
    );

    return TestId(SaleIds.line(line.row), child: content);
  }

  // Legacy Basket row: Take / Collect (`collect_status`), Freeze, Lock and
  // Cancelled.
  List<Widget> get _statuses => [
    if (line.collectStatus == 'T' || line.collectStatus == 'C')
      _StatusChip(
        id: SaleIds.lineFulfilment(line.row),
        label: line.collectStatus == 'T' ? 'Take' : 'Collect',
        color: AppColors.goldDark,
      ),
    if (line.isCancel)
      _StatusChip(
        id: SaleIds.lineCancelled(line.row),
        label: 'Cancelled',
        color: AppColors.danger,
      ),
    if (line.isFreeze)
      _StatusChip(
        id: SaleIds.lineFreeze(line.row),
        label: 'Freeze',
        color: AppColors.info,
      ),
    if (line.isLockDiscount)
      _StatusChip(
        id: SaleIds.lineLock(line.row),
        label: 'Lock',
        color: AppColors.warning,
      ),
  ];
}

class _SwipeBackground extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Banner({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, color: color)),
          ),
        ],
      ),
    );
  }
}

/// A small status tag on a line (Take / Collect / Cancelled / Freeze /
/// Lock).
class _StatusChip extends StatelessWidget {
  final String id;
  final String label;
  final Color color;

  const _StatusChip({
    required this.id,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
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
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

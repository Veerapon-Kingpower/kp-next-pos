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

  const HandheldSaleView({
    super.key,
    required this.viewModel,
    required this.onExit,
    required this.onCustomer,
    this.orderType = SaleOrderType.shopping,
  });

  @override
  State<HandheldSaleView> createState() => _HandheldSaleViewState();
}

class _HandheldSaleViewState extends State<HandheldSaleView> {
  final _scanController = TextEditingController();
  bool _showBasket = false;

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _scan(String value) async {
    await widget.viewModel.scan(value);
    if (widget.viewModel.scanError == null) _scanController.clear();
  }

  void _openLine(CartItem line, int number) {
    openEditLinePage(
      context,
      viewModel: widget.viewModel,
      row: line.row,
      lineNumber: number,
    );
  }

  void _openDiscount(CartItem line, int number) {
    showDiscountSheet(context, line: line, lineNumber: number);
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
            'Delivery and pre-order bills are not available yet.',
            style: HandheldText.bodySmall,
          ),
          const SizedBox(height: 12),
          // TODO(pos-handheld): enable Delivery / Pre-order once the sale
          // engine accepts an order type (and pickup / delivery details).
          for (final (type, id) in [
            (SaleOrderType.shopping, SaleIds.orderTypeShopping),
            (SaleOrderType.delivery, SaleIds.orderTypeDelivery),
            (SaleOrderType.preOrder, SaleIds.orderTypePreOrder),
          ]) ...[
            HandheldChoiceChip(
              id: id,
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
    final lines = viewModel.cart?.items ?? const <CartItem>[];
    final total = lines.fold<double>(0, (sum, l) => sum + l.lineTotal);
    final units = lines.fold<int>(0, (sum, l) => sum + l.quantity);

    return HandheldScaffold(
      fullWidthBody: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SaleHeader(
            orderType: widget.orderType,
            lineCount: lines.length,
            scanController: _scanController,
            scanEnabled: !viewModel.isBusy,
            onScan: _scan,
            onExit: widget.onExit,
            total: total,
            units: units,
          ),
          _Tabs(
            lineCount: lines.length,
            showBasket: _showBasket,
            onSelect: (basket) => setState(() => _showBasket = basket),
          ),
          if (viewModel.isBusy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: HandheldContentWidth(
              child: _LineList(
                lines: lines,
                basket: _showBasket,
                scanError: viewModel.scanError,
                staleNotice: viewModel.staleNotice,
                privilege: viewModel.selectedPrivilege,
                onOpen: _openLine,
                onDiscount: _openDiscount,
                onConfirmVoid: _confirmVoid,
              ),
            ),
          ),
        ],
      ),
      actionBar: HandheldActionBar(
        primary: HandheldPrimaryButton(
          id: SaleIds.checkoutButton,
          label: 'Checkout · ${formatBaht(total)}',
          icon: Icons.payments_outlined,
          onPressed: lines.isEmpty
              ? null
              : () => openCheckoutPage(context, viewModel: viewModel),
        ),
        secondary: _showBasket
            ? HandheldSecondaryButton(
                id: SaleIds.backToBuyingButton,
                label: 'Buying',
                onPressed: () => setState(() => _showBasket = false),
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
                      : () => _openDiscount(lines.last, lines.length),
                ),
                // TODO(pos-handheld): suspend / save bill needs an API.
                const HandheldBarItem(
                  id: SaleIds.saveButton,
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Save',
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
  final bool scanEnabled;
  final ValueChanged<String> onScan;
  final VoidCallback onExit;
  final double total;
  final int units;

  const _SaleHeader({
    required this.orderType,
    required this.lineCount,
    required this.scanController,
    required this.scanEnabled,
    required this.onScan,
    required this.onExit,
    required this.total,
    required this.units,
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
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: ScanField(
                          id: SaleIds.scanField,
                          controller: scanController,
                          hintText: 'Scan or type item code',
                          onSubmitted: onScan,
                          enabled: scanEnabled,
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
                        'Total ${formatAmount(total)} · $units unit${units == 1 ? '' : 's'}',
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
                              formatBaht(total),
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
  final int lineCount;
  final bool showBasket;
  final ValueChanged<bool> onSelect;

  const _Tabs({
    required this.lineCount,
    required this.showBasket,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Widget tab(String id, String label, bool selected, bool basket) => Expanded(
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
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
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
                      '$lineCount',
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? Colors.white : AppColors.textPrimary,
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

    // Both tabs count the same lines until the cart distinguishes
    // committed (Basket) from in-progress (Buying) lines.
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
  final String? staleNotice;
  final Privilege? privilege;
  final void Function(CartItem line, int number) onOpen;
  final void Function(CartItem line, int number) onDiscount;
  final Future<bool> Function(CartItem line) onConfirmVoid;

  const _LineList({
    required this.lines,
    required this.basket,
    required this.scanError,
    required this.staleNotice,
    required this.privilege,
    required this.onOpen,
    required this.onDiscount,
    required this.onConfirmVoid,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (scanError != null)
        TestId(
          SaleIds.scanError,
          child: _Banner(
            icon: Icons.error_outline,
            color: AppColors.danger,
            text: scanError!,
          ),
        ),
      if (staleNotice != null)
        TestId(
          SaleIds.staleNotice,
          child: _Banner(
            icon: Icons.warning_amber,
            color: AppColors.warning,
            text: staleNotice!,
          ),
        ),
      if (privilege != null) _PrivilegeRow(privilege: privilege!),
      if (basket)
        // TODO(pos-handheld): group by Collect (flight) / Take now and show
        // cancelled lines once the cart line carries fulfilment + status.
        const TestId(
          SaleIds.basketNotice,
          child: _Banner(
            icon: Icons.info_outline,
            color: AppColors.info,
            text:
                'Collect / Take grouping and cancelled lines are not '
                'available yet — all lines are shown as scanned.',
          ),
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
          number: i + 1,
          swipeable: !basket,
          onOpen: onOpen,
          onDiscount: onDiscount,
          onConfirmVoid: onConfirmVoid,
        ),
      if (!basket && lines.isNotEmpty)
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Swipe a line left to void, right to discount',
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
  final bool swipeable;
  final void Function(CartItem line, int number) onOpen;
  final void Function(CartItem line, int number) onDiscount;
  final Future<bool> Function(CartItem line) onConfirmVoid;

  const _LineTile({
    required this.line,
    required this.number,
    required this.swipeable,
    required this.onOpen,
    required this.onDiscount,
    required this.onConfirmVoid,
  });

  @override
  Widget build(BuildContext context) {
    final detail = line.quantity == 1
        ? '${line.articleCode} · Qty 1'
        : 'Qty ${line.quantity} × ${formatAmount(line.unitPrice)}';

    final tile = InkWell(
      onTap: () => onOpen(line, number),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 19,
                  height: 19,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.goldMuted,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
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

    final content = !swipeable
        ? tile
        : Dismissible(
            key: ValueKey('dismiss-${line.row}'),
            background: const _SwipeBackground(
              alignment: Alignment.centerLeft,
              color: AppColors.goldDark,
              icon: Icons.percent,
              label: 'Discount',
            ),
            secondaryBackground: const _SwipeBackground(
              alignment: Alignment.centerRight,
              color: AppColors.danger,
              icon: Icons.delete_outline,
              label: 'Void',
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

/// The privilege picked on Home before this sale — same
/// `[TypeCode]:PromoCode` display as the desktop Sale page.
class _PrivilegeRow extends StatelessWidget {
  final Privilege privilege;

  const _PrivilegeRow({required this.privilege});

  @override
  Widget build(BuildContext context) {
    final code = privilege.typeCode.isEmpty && privilege.promoCode.isEmpty
        ? ''
        : '[${privilege.typeCode}]:${privilege.promoCode}';
    return TestId(
      SaleIds.privilege,
      child: Container(
        color: AppColors.cream,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    privilege.name.isEmpty ? 'Privilege' : privilege.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (code.isNotEmpty)
                    Text(code, style: HandheldText.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

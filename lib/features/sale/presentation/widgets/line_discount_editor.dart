import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/desktop/desktop.dart'
    show DesktopButton, DesktopText;
import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/line_discount.dart';
import '../sale_cart_view_model.dart';
import '../sale_currency.dart';
import 'line_discount_form.dart';
import 'promotion_picker.dart';

/// Legacy's gates before the Discount page opens for [lines]: one locked
/// or frozen line can't be discounted (the Sale page's "Discount" action),
/// and `editDiscount()` needs any of the discount permissions.
Future<bool> ensureCanDiscount(
  BuildContext context,
  SaleCartViewModel viewModel,
  List<CartItem> lines,
) async {
  if (lines.isEmpty) return false;
  if (lines.length == 1 &&
      (lines.single.isLockDiscount || lines.single.isFreeze)) {
    await _alert(
      context,
      'Error',
      'Cannot apply discount. Please unlock or unfreeze item and retry.',
    );
    return false;
  }
  if (await viewModel.canDiscount()) return true;
  if (context.mounted) {
    await _alert(context, 'Oops !', SaleCartViewModel.noCurrencyPermission);
  }
  return false;
}

/// Ports legacy `DiscountPage` ("PROMOTION") for one line: scan a
/// promotion QR, or pick / type a promotion Code — the promotion master
/// fills Per. or THB — then Save (stay) or Save & Close. Below, the line's
/// figures and its applied discounts (tap to edit an overwritable one,
/// remove one, or Clear All). Every change goes to the sale engine and the
/// line re-renders from the returned order.
class LineDiscountEditor extends StatefulWidget {
  final SaleCartViewModel viewModel;

  /// The lines to discount: one opens the full page (line figures and its
  /// applied discounts); several (legacy `listItemsGuid`) only the form,
  /// closing once applied.
  final List<String> rows;

  /// Desktop: form and line detail side by side; handheld: stacked.
  final bool wide;

  /// The bill (special) discount — legacy Checkout → Discount
  /// (`SpecialDiscountPage`): the same form, sent with `ActionOrderPayment`,
  /// over the bill's figures and its discounts.
  final bool bill;

  const LineDiscountEditor({
    super.key,
    required this.viewModel,
    required this.rows,
    this.wide = false,
  }) : bill = false;

  const LineDiscountEditor.bill({
    super.key,
    required this.viewModel,
    this.wide = false,
  }) : rows = const [],
       bill = true;

  @override
  State<LineDiscountEditor> createState() => _LineDiscountEditorState();
}

class _LineDiscountEditorState extends State<LineDiscountEditor> {
  final _form = LineDiscountForm();
  final _scan = TextEditingController();
  final _codeFocus = FocusNode();
  final _percentFocus = FocusNode();
  final _amountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _form.addListener(_refresh);
    // Legacy `onBlurPromotionCode()`.
    _codeFocus.addListener(() {
      if (!_codeFocus.hasFocus) _lookUpCode();
    });
  }

  void _refresh() {
    // A cleared or reset form looks the next code up again.
    if (_form.code.text.isEmpty) _lookedUp = null;
    setState(() {});
  }

  @override
  void dispose() {
    _form
      ..removeListener(_refresh)
      ..dispose();
    _scan.dispose();
    _codeFocus.dispose();
    _percentFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  SaleCartViewModel get _vm => widget.viewModel;

  // One line, or the bill: the full page with its figures and discounts.
  bool get _single => widget.bill || widget.rows.length == 1;

  CartItem? get _line {
    for (final line in _vm.cart?.items ?? const <CartItem>[]) {
      if (line.row == widget.rows.first) return line;
    }
    return null;
  }

  // The code last sent to `GetPromotion` — Enter and leaving the field
  // both look up, but only once per code.
  String? _lookedUp;

  Future<void> _lookUpCode() async {
    final typed = _form.code.text.trim();
    if (typed.isEmpty || typed == _lookedUp) return;
    _lookedUp = typed;
    final error = await _form.lookUpCode(_vm);
    if (error != null) _lookedUp = null;
    if (error != null && mounted) await _alert(context, 'Error!', error);
  }

  Future<void> _pickPromotion() async {
    final query = _form.code.text.trim();
    _form.reset();
    final picked = await showPromotionPicker(
      context,
      viewModel: _vm,
      initialQuery: query,
    );
    if (picked == null) return;
    _lookedUp = picked.code;
    _form.applyPromotion(picked);
  }

  Future<void> _submitScan() async {
    final code = _scan.text.trim();
    if (code.isEmpty) return;
    final error = widget.bill
        ? await _vm.addBillDiscountByQrCode(code)
        : await _vm.addLineDiscountByQrCode(widget.rows, code);
    if (!mounted) return;
    _scan.clear();
    if (error != null) {
      await _alert(context, 'Error!', error);
    } else if (!_single) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save({required bool close}) async {
    final error = widget.bill
        ? await _vm.saveBillDiscount(_form.draft)
        : await _vm.saveLineDiscount(widget.rows, _form.draft);
    if (!mounted) return;
    if (error != null) {
      await _alert(context, 'Oops !', error);
      return;
    }
    _form.reset();
    // Several lines always close, as legacy does.
    if (close || !_single) Navigator.of(context).pop();
  }

  Future<void> _remove(LineDiscount discount) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Remove item(s)',
      message: 'Do you want to remove discount',
      confirmLabel: 'Confirm',
      destructive: true,
    );
    if (!confirmed) return;
    final error = widget.bill
        ? await _vm.removeBillDiscount(discount)
        : await _vm.removeLineDiscount(widget.rows.first, discount);
    _form.reset();
    if (error != null && mounted) await _alert(context, 'Error!', error);
  }

  Future<void> _clearAll() async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Confirm',
      message: 'Are you sure to clear all discount?',
      confirmLabel: 'OK',
    );
    if (!confirmed) return;
    final error = widget.bill
        ? await _vm.clearBillDiscounts()
        : await _vm.clearLineDiscounts(widget.rows);
    _form.reset();
    if (error != null && mounted) await _alert(context, 'Error!', error);
  }

  Future<void> _edit(LineDiscount discount) async {
    final refusal = _form.toggleEdit(discount);
    if (refusal != null) await _alert(context, 'Oops !', refusal);
  }

  // Quick-set chips fill Per. the same way typing does.
  List<int> get _presets =>
      widget.wide ? const [3, 5, 7, 10, 15, 20] : const [3, 5, 7, 10];

  // Per. vs THB: the tapped one clears the other and takes the cursor.
  void _select({required bool percent}) {
    _form.select(percent: percent);
    final focus = percent ? _percentFocus : _amountFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focus.requestFocus();
    });
  }

  void _setPreset(int percent) {
    _select(percent: true);
    _form.percent.text = '$percent';
    _form.percentChanged(_form.percent.text);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleCartViewModel>(
      init: _vm,
      global: false,
      builder: (vm) {
        final busy = vm.isBusy;
        if (!_single) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _entry(busy),
              const SizedBox(height: 18),
              _actions(busy),
            ],
          );
        }
        final line = widget.bill ? null : _line;
        if (!widget.bill && line == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('This line is no longer on the order.'),
          );
        }
        final lineCount = vm.cart?.items.length ?? 0;
        final subtitle = Text(
          widget.bill
              ? 'Whole bill · $lineCount line${lineCount == 1 ? '' : 's'}'
              : '${line!.articleName.isEmpty ? line.articleCode : line.articleName}'
                    ' · ${line.articleCode}',
          style: TextStyle(
            fontSize: widget.wide ? 13 : 11.5,
            color: AppColors.mutedText,
          ),
        );
        final detail = widget.bill ? _billDetail(vm) : _detail(line!);
        if (!widget.wide) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              subtitle,
              const SizedBox(height: 14),
              _entry(busy),
              const SizedBox(height: 16),
              detail,
              const SizedBox(height: 16),
              _actions(busy),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            subtitle,
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _entry(busy)),
                const SizedBox(width: 28),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      detail,
                      const SizedBox(height: 16),
                      _actions(busy),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Scan + currency, the promotion Code, then Per. / THB as the big entry
  /// boxes with quick-set percent chips.
  Widget _entry(bool busy) {
    final wide = widget.wide;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ScanField(
                id: DiscountIds.scanField,
                controller: _scan,
                enabled: !busy,
                hintText: 'Scan or type promotion QR',
                onSubmitted: (_) => _submitScan(),
              ),
            ),
            const SizedBox(width: 8),
            // Legacy Discount page header: the order's currency.
            SizedBox(
              width: wide ? 110 : 84,
              child: HandheldChoiceChip(
                id: DiscountIds.currencyButton,
                icon: Icons.currency_exchange,
                label: orderCurrency(_vm.cart),
                selected: false,
                height: HandheldMetrics.scanFieldHeight,
                onTap: busy ? null : () => changeOrderCurrency(context, _vm),
              ),
            ),
          ],
        ),
        SizedBox(height: wide ? 18 : 14),
        const Text('PROMOTION CODE', style: DesktopText.fieldLabel),
        const SizedBox(height: 8),
        _codeBox(busy),
        if (_form.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          TestId(
            DiscountIds.promotionName,
            child: Text(
              _form.description,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.goldDark,
              ),
            ),
          ),
        ],
        SizedBox(height: wide ? 18 : 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ValueBox(
                id: DiscountIds.percentField,
                label: 'DISCOUNT PERCENT',
                hint: 'Percent disc.',
                suffix: '%',
                max: 100,
                controller: _form.percent,
                enabled: _form.canEditPercent,
                active: _form.isPercent && _form.percent.text.isNotEmpty,
                wide: wide,
                onChanged: _form.percentChanged,
                focusNode: _percentFocus,
                onSelect: busy ? null : () => _select(percent: true),
              ),
            ),
            SizedBox(width: wide ? 14 : 10),
            Expanded(
              child: _ValueBox(
                id: DiscountIds.amountField,
                label: 'DISCOUNT AMOUNT (THB)',
                hint: 'Cash disc.',
                suffix: '฿',
                controller: _form.amount,
                enabled: _form.canEditAmount,
                active: !_form.isPercent && _form.amount.text.isNotEmpty,
                wide: wide,
                onChanged: _form.amountChanged,
                focusNode: _amountFocus,
                onSelect: busy ? null : () => _select(percent: false),
              ),
            ),
          ],
        ),
        if (_form.canEditPercent) ...[
          const SizedBox(height: 14),
          const Text('QUICK SET', style: DesktopText.fieldLabel),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _presets.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: HandheldChoiceChip(
                    id: DiscountIds.preset(_presets[i]),
                    label: '${_presets[i]}%',
                    selected: _form.percent.text == '${_presets[i]}',
                    onTap: busy ? null : () => _setPreset(_presets[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _codeBox(bool busy) {
    return Container(
      height: widget.wide ? 60 : 54,
      padding: const EdgeInsets.only(left: 18, right: 6),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldMuted, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: TestId(
              DiscountIds.codeField,
              child: TextField(
                controller: _form.code,
                focusNode: _codeFocus,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _lookUpCode(),
                style: TextStyle(
                  fontFamily: 'KingPowerHeadline',
                  fontSize: widget.wide ? 24 : 20,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: 'Type promotion code',
                  hintStyle: TextStyle(
                    fontSize: widget.wide ? 18 : 16,
                    color: AppColors.hintText,
                  ),
                ),
              ),
            ),
          ),
          if (_form.code.text.isNotEmpty)
            TestId(
              DiscountIds.codeClearButton,
              child: IconButton(
                icon: const Icon(Icons.cancel, size: 18),
                color: AppColors.mutedText,
                tooltip: 'Clear',
                onPressed: _form.reset,
              ),
            ),
          TestId(
            DiscountIds.codeSearchButton,
            child: IconButton(
              icon: const Icon(Icons.search),
              color: AppColors.goldDark,
              tooltip: 'Promotions',
              onPressed: busy ? null : _pickPromotion,
            ),
          ),
        ],
      ),
    );
  }

  /// The line preview panel: the line's figures from the sale engine, its
  /// net on the ink bar, and the discounts already applied.
  Widget _detail(CartItem line) {
    final wide = widget.wide;
    final max = line.maxPercentDiscount;
    Widget row(String label, String value, {Color? color}) => Padding(
      padding: EdgeInsets.symmetric(vertical: wide ? 5 : 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: wide ? 14 : 12.5,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: wide ? 17 : 14,
                fontWeight: FontWeight.w500,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
    final gross = line.unitPrice * line.quantity;

    return Container(
      padding: EdgeInsets.all(wide ? 20 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('LINE PREVIEW', style: DesktopText.fieldLabel),
          const SizedBox(height: 8),
          TestId(
            DiscountIds.lineDetail,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row('Item Code', line.articleCode),
                row('Description', line.articleName),
                row('Price', formatAmount(line.unitPrice)),
                row('Qty', '${line.quantity}'),
                row('Amount', formatAmount(gross)),
                row(
                  'Discount',
                  line.discountAmount == 0
                      ? '—'
                      : formatAmount(-line.discountAmount),
                  color: line.discountAmount == 0 ? null : AppColors.danger,
                ),
                row(
                  'Max Disc',
                  max == null || max == 0 ? '-' : '${max.toStringAsFixed(0)}%',
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _NetBar(value: formatBaht(line.lineTotal), wide: wide),
          ..._discounts(line.discounts),
        ],
      ),
    );
  }

  /// The bill preview: legacy Checkout's discount figures (`(%)Discount`,
  /// `Baht Disc.`, `Promotion`), the net pay, and the bill's discounts.
  Widget _billDetail(SaleCartViewModel vm) {
    final wide = widget.wide;
    final billing = vm.cart?.billing;
    Widget row(String label, String value, {Color? color}) => Padding(
      padding: EdgeInsets.symmetric(vertical: wide ? 5 : 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: wide ? 14 : 12.5,
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: wide ? 17 : 14,
                fontWeight: FontWeight.w500,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
    final special = billing?.discountSpecial ?? 0;
    final promotion = billing == null || billing.promotionCode.isEmpty
        ? '—'
        : '${billing.promotionCode} | ${billing.promotionName}';

    return Container(
      padding: EdgeInsets.all(wide ? 20 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('BILL PREVIEW', style: DesktopText.fieldLabel),
          const SizedBox(height: 8),
          TestId(
            DiscountIds.lineDetail,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row('Subtotal', formatAmount(billing?.grand ?? 0)),
                row(
                  '(%)Discount',
                  '${_trim(billing?.percentDiscountSpecial ?? 0)}%',
                ),
                row(
                  'Baht Disc.',
                  special == 0 ? '—' : formatAmount(-special),
                  color: special == 0 ? null : AppColors.danger,
                ),
                row('Promotion', promotion),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _NetBar(value: formatBaht(orderNetPay(vm.cart)), wide: wide),
          ..._discounts(vm.cart?.billDiscounts ?? const []),
        ],
      ),
    );
  }

  // The applied discounts (tap to edit, remove one, or Clear All).
  List<Widget> _discounts(List<LineDiscount> discounts) => [
    if (discounts.isNotEmpty) ...[
      const SizedBox(height: 16),
      Row(
        children: [
          const Expanded(
            child: Text('PROMOTION & DISCOUNT', style: DesktopText.fieldLabel),
          ),
          TestId(
            DiscountIds.clearAllButton,
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: _clearAll,
              child: const Text('Clear All'),
            ),
          ),
        ],
      ),
      TestId(
        DiscountIds.discountList,
        child: Column(
          children: [
            for (var i = 0; i < discounts.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _discountRow(i, discounts[i]),
            ],
          ],
        ),
      ),
    ],
  ];

  Widget _discountRow(int index, LineDiscount discount) {
    final value = discount.isPercent
        ? '${_trim(discount.percent)} %'
        : formatAmount(discount.amount);
    final selected = _form.editing?.guid == discount.guid;
    return TestId(
      DiscountIds.discountRow(index),
      child: Material(
        color: selected ? AppColors.cream : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? AppColors.goldDark : const Color(0xFFD8DDE5),
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _edit(discount),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discount.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldDark,
                        ),
                      ),
                      if (discount.code.isNotEmpty)
                        Text(
                          discount.code,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.mutedText,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (discount.isPercent && discount.calculatedAmount != null)
                      Text(
                        formatAmount(discount.calculatedAmount!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedText,
                        ),
                      ),
                  ],
                ),
                TestId(
                  DiscountIds.discountRemove(index),
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                    ),
                    tooltip: 'Remove',
                    onPressed: () => _remove(discount),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Save (stay) / Save & Close, as legacy; Cancel closes without saving.
  Widget _actions(bool busy) {
    final canSave = _form.canSave && !busy;
    final saveLabel = _form.editing == null ? 'Save' : 'Update';
    void cancel() => Navigator.of(context).pop();

    if (widget.wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopButton(
            id: DiscountIds.saveCloseButton,
            label: 'Save & Close',
            hotkey: 'ENTER',
            height: 64,
            onPressed: canSave ? () => _save(close: true) : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DesktopButton(
                  id: DiscountIds.saveButton,
                  label: saveLabel,
                  secondary: true,
                  onPressed: canSave ? () => _save(close: false) : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DesktopButton(
                  id: DiscountIds.cancelButton,
                  label: 'Cancel',
                  secondary: true,
                  onPressed: cancel,
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HandheldPrimaryButton(
          id: DiscountIds.saveCloseButton,
          label: 'Save & Close',
          onPressed: canSave ? () => _save(close: true) : null,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _OutlineButton(
                id: DiscountIds.saveButton,
                label: saveLabel,
                onPressed: canSave ? () => _save(close: false) : null,
              ),
            ),
            const SizedBox(width: 10),
            HandheldSecondaryButton(
              id: DiscountIds.cancelButton,
              label: 'Cancel',
              onPressed: cancel,
            ),
          ],
        ),
      ],
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

/// The big cream entry box (`10 %`, `500 ฿`) — Per. or THB. A locked one
/// greys out; the one driving the discount keeps the gold border.
class _ValueBox extends StatelessWidget {
  final String id;
  final String label;
  final String hint;
  final String suffix;
  final TextEditingController controller;
  final bool enabled;
  final bool active;
  final bool wide;
  final ValueChanged<String> onChanged;
  final FocusNode focusNode;

  /// Tapping the box, even while it's locked.
  final VoidCallback? onSelect;

  /// Rejects a keystroke that would take the value above it.
  final double? max;

  const _ValueBox({
    required this.id,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.controller,
    required this.enabled,
    required this.active,
    required this.wide,
    required this.onChanged,
    required this.focusNode,
    this.onSelect,
    this.max,
  });

  @override
  Widget build(BuildContext context) {
    final size = wide ? 40.0 : 28.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DesktopText.fieldLabel,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSelect,
          child: Container(
            height: wide ? 88 : 68,
            padding: EdgeInsets.symmetric(horizontal: wide ? 20 : 14),
            decoration: BoxDecoration(
              color: enabled ? AppColors.cream : const Color(0xFFF1F2F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !enabled
                    ? const Color(0xFFD8DDE5)
                    : active
                    ? AppColors.goldDark
                    : AppColors.goldMuted,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TestId(
                    id,
                    child: TextField(
                      controller: controller,
                      enabled: enabled,
                      focusNode: focusNode,
                      onTap: onSelect,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        if (max != null)
                          TextInputFormatter.withFunction(
                            (old, next) =>
                                (double.tryParse(next.text) ?? 0) > max!
                                ? old
                                : next,
                          ),
                      ],
                      onChanged: onChanged,
                      style: TextStyle(
                        fontFamily: 'KingPowerHeadline',
                        fontSize: size,
                        fontWeight: FontWeight.w700,
                        color: enabled ? AppColors.ink : AppColors.mutedText,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: hint,
                        hintStyle: TextStyle(
                          fontSize: wide ? 18 : 14,
                          color: AppColors.hintText,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  suffix,
                  style: TextStyle(
                    fontSize: wide ? 28 : 22,
                    color: enabled ? AppColors.goldDark : AppColors.hintText,
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

/// Ink "Net Amount" bar — the line's net from the sale engine.
class _NetBar extends StatelessWidget {
  final String value;
  final bool wide;

  const _NetBar({required this.value, required this.wide});

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return HandheldNetBar(
        id: DiscountIds.netPreview,
        label: 'Net Amount',
        value: value,
      );
    }
    return TestId(
      DiscountIds.netPreview,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Net Amount',
              style: TextStyle(fontSize: 13, color: AppColors.gold),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'KingPowerHeadline',
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 56 dp gold-outlined action beside Cancel (Save that keeps the sheet
/// open).
class _OutlineButton extends StatelessWidget {
  final String id;
  final String label;
  final VoidCallback? onPressed;

  const _OutlineButton({required this.id, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return TestId(
      id,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: SizedBox(
          height: HandheldMetrics.primaryActionHeight,
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
              side: BorderSide(
                color: enabled ? AppColors.goldDark : AppColors.line,
              ),
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: enabled ? AppColors.goldDark : AppColors.mutedText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _alert(BuildContext context, String title, String message) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

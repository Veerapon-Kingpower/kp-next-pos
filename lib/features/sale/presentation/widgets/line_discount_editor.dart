import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/handheld/money_format.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/line_discount.dart';
import '../../domain/entities/promotion.dart';
import '../sale_cart_view_model.dart';
import '../sale_currency.dart';
import 'line_discount_form.dart';

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

  const LineDiscountEditor({
    super.key,
    required this.viewModel,
    required this.rows,
    this.wide = false,
  });

  @override
  State<LineDiscountEditor> createState() => _LineDiscountEditorState();
}

class _LineDiscountEditorState extends State<LineDiscountEditor> {
  final _form = LineDiscountForm();
  final _scan = TextEditingController();
  final _codeFocus = FocusNode();

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
    super.dispose();
  }

  SaleCartViewModel get _vm => widget.viewModel;

  bool get _single => widget.rows.length == 1;

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
    final error = await _vm.addLineDiscountByQrCode(widget.rows, code);
    if (!mounted) return;
    _scan.clear();
    if (error != null) {
      await _alert(context, 'Error!', error);
    } else if (!_single) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _save({required bool close}) async {
    final error = await _vm.saveLineDiscount(widget.rows, _form.draft);
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
    final error = await _vm.removeLineDiscount(widget.rows.first, discount);
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
    final error = await _vm.clearLineDiscounts(widget.rows);
    _form.reset();
    if (error != null && mounted) await _alert(context, 'Error!', error);
  }

  Future<void> _edit(LineDiscount discount) async {
    final refusal = _form.toggleEdit(discount);
    if (refusal != null) await _alert(context, 'Oops !', refusal);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleCartViewModel>(
      init: _vm,
      global: false,
      builder: (vm) {
        if (!_single) return _entry(vm.isBusy);
        final line = _line;
        if (line == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('This line is no longer on the order.'),
          );
        }
        final form = _entry(vm.isBusy);
        final detail = _detail(line);
        if (!widget.wide) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [form, const SizedBox(height: 16), detail],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: form),
            const SizedBox(width: 28),
            Expanded(flex: 2, child: detail),
          ],
        );
      },
    );
  }

  Widget _entry(bool busy) {
    InputDecoration decoration(String hint, {Widget? suffix}) =>
        InputDecoration(
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: suffix,
        );
    Widget clearButton(String id, VoidCallback onPressed) => TestId(
      id,
      child: IconButton(
        icon: const Icon(Icons.cancel, size: 18),
        tooltip: 'Clear',
        onPressed: onPressed,
      ),
    );
    final numbers = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
    const label = TextStyle(fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TestId(
                DiscountIds.scanField,
                child: TextField(
                  controller: _scan,
                  enabled: !busy,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitScan(),
                  decoration: decoration(
                    'Scan or type promotion code',
                    suffix: const Icon(Icons.qr_code_scanner),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Legacy Discount page header: the order's currency.
            TestId(
              DiscountIds.currencyButton,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.currency_exchange, size: 18),
                label: Text(orderCurrency(_vm.cart)),
                onPressed: busy
                    ? null
                    : () => changeOrderCurrency(context, _vm),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const SizedBox(width: 56, child: Text('Code', style: label)),
            Expanded(
              child: TestId(
                DiscountIds.codeField,
                child: TextField(
                  controller: _form.code,
                  focusNode: _codeFocus,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _lookUpCode(),
                  decoration: decoration(
                    'type promotion code',
                    suffix: _form.code.text.isEmpty
                        ? null
                        : clearButton(DiscountIds.codeClearButton, _form.reset),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TestId(
              DiscountIds.codeSearchButton,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.search),
                tooltip: 'Promotions',
                onPressed: busy ? null : _pickPromotion,
              ),
            ),
          ],
        ),
        if (_form.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: TestId(
              DiscountIds.promotionName,
              child: Text(
                _form.description,
                style: const TextStyle(color: AppColors.goldDark),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 56, child: Text('Per.', style: label)),
            Expanded(
              child: TestId(
                DiscountIds.percentField,
                child: TextField(
                  controller: _form.percent,
                  enabled: _form.canEditPercent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: numbers,
                  onChanged: _form.percentChanged,
                  decoration: decoration('Percent disc.'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('THB', style: label),
            const SizedBox(width: 8),
            Expanded(
              child: TestId(
                DiscountIds.amountField,
                child: TextField(
                  controller: _form.amount,
                  enabled: _form.canEditAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: numbers,
                  onChanged: _form.amountChanged,
                  decoration: decoration('Cash disc.'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: TestId(
                DiscountIds.saveButton,
                child: AppPrimaryButton(
                  label: _form.editing == null ? 'Save' : 'Update',
                  onPressed: _form.canSave && !busy
                      ? () => _save(close: false)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TestId(
                DiscountIds.saveCloseButton,
                child: AppPrimaryButton(
                  label: 'Save & Close',
                  onPressed: _form.canSave && !busy
                      ? () => _save(close: true)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detail(CartItem line) {
    final max = line.maxPercentDiscount;
    Widget row(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.mutedText)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
    final gross = line.unitPrice * line.quantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TestId(
          DiscountIds.lineDetail,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row('Item Code', line.articleCode),
              row('Description', line.articleName),
              row('Price', formatAmount(line.unitPrice)),
              row('Amount', formatAmount(gross)),
              row('Discount', formatAmount(line.discountAmount)),
              row(
                'Max Disc',
                max == null || max == 0 ? '-' : '${max.toStringAsFixed(0)}%',
                color: AppColors.danger,
              ),
              row('Net Amount', formatAmount(line.lineTotal)),
            ],
          ),
        ),
        if (line.discounts.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            color: AppColors.cream,
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Promotion & Discount',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TestId(
                  DiscountIds.clearAllButton,
                  child: TextButton(
                    onPressed: _clearAll,
                    child: const Text('Clear All'),
                  ),
                ),
              ],
            ),
          ),
          TestId(
            DiscountIds.discountList,
            child: Column(
              children: [
                for (var i = 0; i < line.discounts.length; i++)
                  _discountRow(i, line.discounts[i]),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _discountRow(int index, LineDiscount discount) {
    final value = discount.isPercent
        ? '${_trim(discount.percent)} %'
        : formatAmount(discount.amount);
    return TestId(
      DiscountIds.discountRow(index),
      child: ListTile(
        dense: true,
        selected: _form.editing?.guid == discount.guid,
        onTap: () => _edit(discount),
        title: Text(
          discount.description,
          style: const TextStyle(color: AppColors.goldDark),
        ),
        subtitle: Text(discount.code),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (discount.isPercent && discount.calculatedAmount != null)
                  Text(
                    formatAmount(discount.calculatedAmount!),
                    style: const TextStyle(fontSize: 11),
                  ),
              ],
            ),
            TestId(
              DiscountIds.discountRemove(index),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                tooltip: 'Remove',
                onPressed: () => _remove(discount),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

/// Legacy `PromotionPickerPage`: the branch's promotion master
/// (`GetPromotionList`), re-queried as the cashier types; tapping one picks
/// it.
Future<Promotion?> showPromotionPicker(
  BuildContext context, {
  required SaleCartViewModel viewModel,
  String initialQuery = '',
}) {
  return showDialog<Promotion>(
    context: context,
    builder: (_) =>
        _PromotionPicker(viewModel: viewModel, initialQuery: initialQuery),
  );
}

class _PromotionPicker extends StatefulWidget {
  final SaleCartViewModel viewModel;
  final String initialQuery;

  const _PromotionPicker({required this.viewModel, required this.initialQuery});

  @override
  State<_PromotionPicker> createState() => _PromotionPickerState();
}

class _PromotionPickerState extends State<_PromotionPicker> {
  late final _query = TextEditingController(text: widget.initialQuery);
  late Future<List<Promotion>> _promotions = _load(widget.initialQuery);
  Timer? _debounce;

  Future<List<Promotion>> _load(String query) =>
      widget.viewModel.searchPromotions(query.trim());

  void _changed(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _promotions = _load(query));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TestId(
      DiscountIds.picker,
      child: AlertDialog(
        title: const Text('PROMOTIONS'),
        content: SizedBox(
          width: 520,
          height: 420,
          child: Column(
            children: [
              TestId(
                DiscountIds.pickerSearch,
                child: TextField(
                  controller: _query,
                  autofocus: true,
                  onChanged: _changed,
                  decoration: const InputDecoration(
                    hintText: 'Type to search promotion',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<Promotion>>(
                  future: _promotions,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Can not get promotions list from server'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final promotions = snapshot.data!;
                    if (promotions.isEmpty) {
                      return const Center(child: Text('No promotions'));
                    }
                    return ListView.builder(
                      itemCount: promotions.length,
                      itemBuilder: (context, i) {
                        final p = promotions[i];
                        return TestId(
                          DiscountIds.pickerRow(p.code),
                          child: ListTile(
                            dense: true,
                            title: Text('${p.code} : ${p.name}'),
                            onTap: () => Navigator.of(context).pop(p),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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

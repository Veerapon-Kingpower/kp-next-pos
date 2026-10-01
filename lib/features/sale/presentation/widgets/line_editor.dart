import 'package:flutter/material.dart';

import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/line_edit.dart';
import '../sale_cart_view_model.dart';

/// The unsaved values of legacy `EditSalePage` ("ORDER ITEM") for one
/// line: qty, Freeze, Lock, Collect / Take and serial. Shared by the
/// handheld Edit line page and the desktop Edit line overlay.
class LineEditDraft extends ChangeNotifier {
  LineEditDraft(CartItem line) {
    reset(line);
    serial.addListener(notifyListeners);
  }

  late CartItem _base;
  late int _quantity;
  late bool _isFreeze;
  late bool _isLockDiscount;
  late String _collectStatus;
  final serial = TextEditingController();

  int get quantity => _quantity;
  bool get isFreeze => _isFreeze;
  bool get isLockDiscount => _isLockDiscount;
  String get collectStatus => _collectStatus;

  set quantity(int value) => _set(() => _quantity = value);
  set isFreeze(bool value) => _set(() => _isFreeze = value);
  set isLockDiscount(bool value) => _set(() => _isLockDiscount = value);
  set collectStatus(String value) => _set(() => _collectStatus = value);

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }

  /// Legacy `initState()` / `undoAllChange()`: back to [line] as saved.
  void reset(CartItem line) {
    _base = line;
    _quantity = line.quantity;
    _isFreeze = line.isFreeze;
    _isLockDiscount = line.isLockDiscount;
    _collectStatus = line.collectStatus;
    serial.text = line.serialNo;
    notifyListeners();
  }

  void undo() => reset(_base);

  /// Legacy `isValueChanged` — enables Undo.
  bool get isChanged =>
      _quantity != _base.quantity ||
      _isFreeze != _base.isFreeze ||
      _isLockDiscount != _base.isLockDiscount ||
      _collectStatus != _base.collectStatus ||
      serial.text.trim() != _base.serialNo;

  LineEdit get edit => LineEdit(
    quantity: _quantity,
    isFreeze: _isFreeze,
    isLockDiscount: _isLockDiscount,
    collectStatus: _collectStatus,
    serialNo: serial.text.trim(),
  );

  @override
  void dispose() {
    serial.dispose();
    super.dispose();
  }
}

/// Legacy `saveItem()`: sends every value of [draft] for [line] — always,
/// changed or not, as legacy's Save does. A warning is shown and the
/// returned line kept; an error ("Error Code: …") is shown and the draft
/// undone. True once saved (with or without warning).
Future<bool> saveLineEdit(
  BuildContext context,
  SaleCartViewModel viewModel,
  CartItem line,
  LineEditDraft draft,
) async {
  final result = await viewModel.editLine(line.row, draft.edit);
  if (!context.mounted) return false;
  if (result.error != null) {
    await _alert(context, 'Error', result.error!);
    draft.undo();
    return false;
  }
  final saved = _lineIn(viewModel, line.row);
  if (saved != null) draft.reset(saved);
  if (result.warning != null && context.mounted) {
    await _alert(context, 'Warning !', result.warning!);
  }
  return true;
}

/// Legacy `setPickupMode()`: needs `actTake`.
Future<void> pickLinePickup(
  BuildContext context,
  SaleCartViewModel viewModel,
  LineEditDraft draft,
  String mode,
) async {
  if (await viewModel.canTakeOrUntake()) {
    draft.collectStatus = mode;
  } else if (context.mounted) {
    await _alert(context, 'Oops !', SaleCartViewModel.noCurrencyPermission);
  }
}

/// Legacy `onSubmit()` on the Serial No field: a long scan is a barcode,
/// replaced by the article's serial.
Future<void> resolveLineSerial(
  SaleCartViewModel viewModel,
  LineEditDraft draft,
) async {
  final scanned = draft.serial.text.trim();
  if (scanned.isEmpty) return;
  final serial = await viewModel.resolveSerial(scanned);
  if (serial != null) draft.serial.text = serial;
}

CartItem? _lineIn(SaleCartViewModel viewModel, String row) {
  for (final item in viewModel.cart?.items ?? const <CartItem>[]) {
    if (item.row == row) return item;
  }
  return null;
}

Future<void> _alert(BuildContext context, String title, String message) =>
    showDialog<void>(
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

/// Legacy `EditSalePage`'s fields for [line]: code and description, serial
/// (only when the article requires one), qty, the line's figures, Freeze,
/// Lock and — off airport mPOS — Collect / Take.
class LineEditFields extends StatelessWidget {
  final SaleCartViewModel viewModel;
  final CartItem line;
  final LineEditDraft draft;
  final bool showPickup;

  const LineEditFields({
    super.key,
    required this.viewModel,
    required this.line,
    required this.draft,
    required this.showPickup,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final quantity = draft.quantity;
    final amount = line.unitPrice * quantity;
    // The saved net until the qty changes; then a preview.
    final net = quantity == line.quantity
        ? line.lineTotal
        : amount - line.discountAmount;
    final maxDisc = line.maxPercentDiscount;
    final busy = viewModel.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Block(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Caption('Item code'),
              Text(line.articleCode, style: _strong),
              const SizedBox(height: 8),
              const _Caption('Description'),
              Text(
                line.articleName.isEmpty ? '—' : line.articleName,
                style: _strong,
              ),
            ],
          ),
        ),
        if (line.requireSerial)
          _Block(
            color: const Color(0xFFFDF8EE),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Caption('Serial number'),
                const SizedBox(height: 6),
                TestId(
                  EditLineIds.serialField,
                  child: TextField(
                    controller: draft.serial,
                    enabled: !busy,
                    onSubmitted: (_) => resolveLineSerial(viewModel, draft),
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.qr_code_scanner, size: 16),
                      hintText: 'Serial No',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        _Block(
          child: Row(
            children: [
              const Expanded(child: _Caption('Qty')),
              _Stepper(
                quantity: quantity,
                onDecrease: quantity > 1
                    ? () => draft.quantity = quantity - 1
                    : null,
                onIncrease: () => draft.quantity = quantity + 1,
              ),
            ],
          ),
        ),
        _Block(
          child: Column(
            children: [
              _AmountRow(label: 'Price', value: formatAmount(line.unitPrice)),
              TestId(
                EditLineIds.amount,
                child: _AmountRow(label: 'Amount', value: formatAmount(amount)),
              ),
              _AmountRow(
                label: 'Discount',
                value: formatAmount(line.discountAmount),
              ),
              _AmountRow(
                label: 'Max disc',
                value: maxDisc == null || maxDisc == 0
                    ? '-'
                    : '${maxDisc.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: HandheldNetBar(
            id: EditLineIds.netAmount,
            label: 'Net amount',
            value: formatBaht(net),
          ),
        ),
        _SwitchRow(
          id: EditLineIds.freezeSwitch,
          icon: Icons.ac_unit,
          label: 'Freeze',
          value: draft.isFreeze,
          onChanged: busy ? null : (v) => draft.isFreeze = v,
        ),
        _SwitchRow(
          id: EditLineIds.lockDiscountSwitch,
          icon: Icons.lock_outline,
          label: 'Lock',
          value: draft.isLockDiscount,
          onChanged: busy ? null : (v) => draft.isLockDiscount = v,
        ),
        if (line.cites.isNotEmpty) ...[
          const _GroupHeader('Cites information'),
          TestId(
            EditLineIds.cites,
            child: _Block(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Legacy prints the type as the constant "CIT".
                  const Text('Cites type : CIT', style: _strong),
                  Text('Permit No : ${line.citesPermitNo}', style: _strong),
                ],
              ),
            ),
          ),
        ],
        if (line.vasItems.isNotEmpty) ...[
          _GroupHeader(
            'VAS information [${line.vasItems.fold<num>(0, (s, v) => s + v.totalRequireQty)}]',
          ),
          for (var i = 0; i < line.vasItems.length; i++)
            TestId(
              EditLineIds.vas(i),
              child: _Block(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Article : ${line.vasItems[i].articleCode}',
                      style: _strong,
                    ),
                    Text(
                      'Name : ${line.vasItems[i].articleName}',
                      style: _strong,
                    ),
                    _AmountRow(
                      label: 'Require QTY',
                      value: '${line.vasItems[i].totalRequireQty}',
                    ),
                    _AmountRow(
                      label: 'Exist QTY',
                      value: '${line.vasItems[i].existQty}',
                    ),
                    _AmountRow(
                      label: 'Remaining QTY',
                      value: '${line.vasItems[i].remainQty}',
                    ),
                  ],
                ),
              ),
            ),
        ],
        if (showPickup) ...[
          const _GroupHeader('Pickup'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: HandheldChoiceChip(
                    id: EditLineIds.pickupCollect,
                    label: 'Collect',
                    icon: Icons.flight_takeoff,
                    selected: draft.collectStatus == 'C',
                    height: 54,
                    onTap: busy
                        ? null
                        : () => pickLinePickup(context, viewModel, draft, 'C'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HandheldChoiceChip(
                    id: EditLineIds.pickupTake,
                    label: 'Take',
                    icon: Icons.shopping_bag_outlined,
                    selected: draft.collectStatus == 'T',
                    height: 54,
                    onTap: busy
                        ? null
                        : () => pickLinePickup(context, viewModel, draft, 'T'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

const _strong = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700);

class _Block extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _Block({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: const Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: child,
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  final String text;

  const _Caption(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: HandheldText.bodySmall.copyWith(fontSize: 12));
}

class _GroupHeader extends StatelessWidget {
  final String text;

  const _GroupHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAFBFC),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Text(
        text.toUpperCase(),
        style: HandheldText.overline.copyWith(color: AppColors.goldDark),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;

  const _AmountRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: _Caption(label)),
          Text(value, style: _strong.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  const _Stepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD8DDE5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TestId(
            EditLineIds.qtyDecrease,
            child: IconButton(
              icon: const Icon(Icons.remove),
              color: AppColors.goldDark,
              tooltip: 'Decrease quantity',
              onPressed: onDecrease,
            ),
          ),
          SizedBox(
            width: 48,
            child: TestId(
              EditLineIds.qtyValue,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: HandheldText.statValue.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          TestId(
            EditLineIds.qtyIncrease,
            child: IconButton(
              icon: const Icon(Icons.add),
              color: AppColors.goldDark,
              tooltip: 'Increase quantity',
              onPressed: onIncrease,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchRow({
    required this.id,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Block(
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.mutedText),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: _strong)),
          TestId(
            id,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

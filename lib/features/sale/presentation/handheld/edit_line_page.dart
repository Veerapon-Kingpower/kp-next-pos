import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';
import '../sale_cart_view_model.dart';

/// Pushes the Edit line page for cart [row].
Future<void> openEditLinePage(
  BuildContext context, {
  required SaleCartViewModel viewModel,
  required String row,
  required int lineNumber,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          EditLinePage(viewModel: viewModel, row: row, lineNumber: lineNumber),
    ),
  );
}

/// Edit line · Order item (mockup screen 14). Quantity is real
/// ([SaleCartViewModel.updateQuantity]), as is voiding the line.
///
/// Serial capture, Freeze, Lock discount and Collect / Take pickup are
/// shown but inert — the cart has no fields or APIs for them yet
/// (openspec tasks 5.2 / 6.1). The mockup's CITES and VAS blocks are left
/// out entirely: they describe per-article data the app doesn't receive,
/// so there is nothing honest to show.
// TODO(pos-handheld): wire serial / freeze / lock / pickup once the cart
// line model carries them; add CITES / VAS when the article API returns
// them.
class EditLinePage extends StatefulWidget {
  final SaleCartViewModel viewModel;
  final String row;
  final int lineNumber;

  const EditLinePage({
    super.key,
    required this.viewModel,
    required this.row,
    required this.lineNumber,
  });

  @override
  State<EditLinePage> createState() => _EditLinePageState();
}

class _EditLinePageState extends State<EditLinePage> {
  int? _quantity;

  CartItem? get _line {
    final items = widget.viewModel.cart?.items ?? const <CartItem>[];
    for (final item in items) {
      if (item.row == widget.row) return item;
    }
    return null;
  }

  Future<bool> _save(CartItem line) async {
    final quantity = _quantity ?? line.quantity;
    if (quantity == line.quantity) return true;
    await widget.viewModel.updateQuantity(row: line.row, quantity: quantity);
    if (!mounted) return false;
    setState(() => _quantity = null);
    return widget.viewModel.scanError == null;
  }

  Future<void> _saveAndClose(CartItem line) async {
    final ok = await _save(line);
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _void(CartItem line) async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Void this line?',
      message: line.articleName.isEmpty ? line.articleCode : line.articleName,
      confirmLabel: 'Void line',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await widget.viewModel.removeItem(line.row);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleCartViewModel>(
      init: widget.viewModel,
      global: false,
      builder: (viewModel) {
        final line = _line;
        if (line == null) {
          // Removed elsewhere (or voided here) — nothing left to edit.
          return const Scaffold(body: SizedBox.shrink());
        }
        return _buildPage(context, viewModel, line);
      },
    );
  }

  Widget _buildPage(
    BuildContext context,
    SaleCartViewModel viewModel,
    CartItem line,
  ) {
    final quantity = _quantity ?? line.quantity;
    final amount = line.unitPrice * quantity;
    final busy = viewModel.isBusy;

    return TestId(
      EditLineIds.page,
      child: HandheldScaffold(
        header: _EditLineHeader(
          lineNumber: widget.lineNumber,
          onUndo: () => setState(() => _quantity = null),
          onSave: busy ? null : () => _save(line),
          onSaveClose: busy ? null : () => _saveAndClose(line),
        ),
        backgroundColor: AppColors.surface,
        body: SingleChildScrollView(
          child: Column(
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
              _Block(
                color: const Color(0xFFFDF8EE),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Caption('Serial number'),
                    const SizedBox(height: 6),
                    TestId(
                      EditLineIds.serialField,
                      child: const TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(Icons.qr_code_scanner, size: 16),
                          hintText: 'Serial capture not available yet',
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
                          ? () => setState(() => _quantity = quantity - 1)
                          : null,
                      onIncrease: () =>
                          setState(() => _quantity = quantity + 1),
                    ),
                  ],
                ),
              ),
              _Block(
                child: Column(
                  children: [
                    _AmountRow(
                      label: 'Price',
                      value: formatAmount(line.unitPrice),
                    ),
                    TestId(
                      EditLineIds.amount,
                      child: _AmountRow(
                        label: 'Amount',
                        value: formatAmount(amount),
                      ),
                    ),
                    const _AmountRow(label: 'Discount', value: '—'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: HandheldNetBar(
                  id: EditLineIds.netAmount,
                  label: 'Net amount',
                  value: formatBaht(amount),
                ),
              ),
              const _InertSwitchRow(
                id: EditLineIds.freezeSwitch,
                icon: Icons.ac_unit,
                label: 'Freeze',
              ),
              const _InertSwitchRow(
                id: EditLineIds.lockDiscountSwitch,
                icon: Icons.lock_outline,
                label: 'Lock discount',
              ),
              const _GroupHeader('Pickup'),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: HandheldChoiceChip(
                        id: EditLineIds.pickupCollect,
                        label: 'Collect',
                        icon: Icons.flight_takeoff,
                        selected: false,
                        height: 54,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: HandheldChoiceChip(
                        id: EditLineIds.pickupTake,
                        label: 'Take',
                        icon: Icons.shopping_bag_outlined,
                        selected: false,
                        height: 54,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: TestId(
                  EditLineIds.voidButton,
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : () => _void(line),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Void line'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      minimumSize: const Size.fromHeight(
                        HandheldMetrics.primaryActionHeight,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _strong = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700);

class _EditLineHeader extends StatelessWidget {
  final int lineNumber;
  final VoidCallback onUndo;
  final VoidCallback? onSave;
  final VoidCallback? onSaveClose;

  const _EditLineHeader({
    required this.lineNumber,
    required this.onUndo,
    required this.onSave,
    required this.onSaveClose,
  });

  @override
  Widget build(BuildContext context) {
    Widget outlined(
      String id,
      String label,
      VoidCallback? onTap, {
      IconData? icon,
    }) => Expanded(
      child: TestId(
        id,
        child: SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: icon == null
                ? const SizedBox.shrink()
                : Icon(icon, size: 14, color: AppColors.gold),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ),
      ),
    );

    return ColoredBox(
      color: AppColors.ink,
      child: SafeArea(
        bottom: false,
        child: HandheldContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const BackButton(color: Colors.white),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order item',
                            style: HandheldText.title.copyWith(
                              fontSize: 17,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Line $lineNumber',
                            style: HandheldText.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      outlined(
                        EditLineIds.undoButton,
                        'Undo',
                        onUndo,
                        icon: Icons.undo,
                      ),
                      const SizedBox(width: 8),
                      outlined(EditLineIds.saveButton, 'Save', onSave),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TestId(
                          EditLineIds.saveCloseButton,
                          child: SizedBox(
                            height: 44,
                            child: FilledButton(
                              onPressed: onSaveClose,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.ink,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: const Text(
                                'Save & close',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

class _InertSwitchRow extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;

  const _InertSwitchRow({
    required this.id,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return _Block(
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.mutedText),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: _strong)),
          TestId(id, child: const Switch(value: false, onChanged: null)),
        ],
      ),
    );
  }
}

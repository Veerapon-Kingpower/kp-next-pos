import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';

enum DiscountMode { percent, amount, promo }

/// Opens the per-line Discount sheet (mockup screen 7) — a bottom sheet on
/// phones, a dialog on tablets.
Future<void> showDiscountSheet(
  BuildContext context, {
  required CartItem line,
  required int lineNumber,
}) {
  return showHandheldSheet<void>(
    context,
    id: DiscountIds.sheet,
    builder: (_) => DiscountSheet(line: line, lineNumber: lineNumber),
  );
}

/// Percent / Amount / Promo entry with presets and a client-side "new line
/// net" preview.
///
/// Apply is inert: the cart has no discount API yet (openspec task 4.4 /
/// 5.2), and the per-article ceiling + supervisor override from the mockup
/// ("max 10% for this article") come from the sale engine, so neither is
/// shown rather than guessed.
// TODO(pos-handheld): wire Apply to a line-discount use case and show the
// article's max discount / supervisor-scan warning once the sale engine
// returns them.
class DiscountSheet extends StatefulWidget {
  final CartItem line;
  final int lineNumber;

  const DiscountSheet({
    super.key,
    required this.line,
    required this.lineNumber,
  });

  @override
  State<DiscountSheet> createState() => _DiscountSheetState();
}

class _DiscountSheetState extends State<DiscountSheet> {
  static const _presets = [3, 5, 7, 10];

  final _value = TextEditingController();
  DiscountMode _mode = DiscountMode.percent;

  @override
  void initState() {
    super.initState();
    _value.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _setMode(DiscountMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _value.clear();
    });
  }

  double get _net {
    final total = widget.line.lineTotal;
    final entered = double.tryParse(_value.text) ?? 0;
    switch (_mode) {
      case DiscountMode.percent:
        final percent = entered.clamp(0, 100);
        return total * (1 - percent / 100);
      case DiscountMode.amount:
        return total - entered.clamp(0, total);
      case DiscountMode.promo:
        // Promo value is decided by the sale engine when applied.
        return total;
    }
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.percent, size: 19, color: AppColors.goldDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discount · line ${widget.lineNumber}',
                      style: HandheldText.title.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      line.articleName.isEmpty
                          ? line.articleCode
                          : line.articleName,
                      style: HandheldText.bodySmall.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              TestId(
                DiscountIds.closeButton,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final (mode, id, label) in [
                (DiscountMode.percent, DiscountIds.modePercent, 'Percent'),
                (DiscountMode.amount, DiscountIds.modeAmount, 'Amount'),
                (DiscountMode.promo, DiscountIds.modePromo, 'Promo'),
              ]) ...[
                if (mode != DiscountMode.percent) const SizedBox(width: 8),
                Expanded(
                  child: HandheldChoiceChip(
                    id: id,
                    label: label,
                    dark: true,
                    height: 40,
                    selected: _mode == mode,
                    onTap: () => _setMode(mode),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _ValueBox(controller: _value, mode: _mode),
          if (_mode == DiscountMode.percent) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < _presets.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: HandheldChoiceChip(
                      id: DiscountIds.preset(_presets[i]),
                      label: '${_presets[i]}%',
                      selected: _value.text == '${_presets[i]}',
                      onTap: () => _value.text = '${_presets[i]}',
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),
          HandheldNetBar(
            id: DiscountIds.netPreview,
            label: 'New line net',
            value: formatBaht(_net),
          ),
          const SizedBox(height: 10),
          const Text(
            'Applying discounts is not available yet on this device.',
            style: HandheldText.bodySmall,
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: HandheldPrimaryButton(
                  id: DiscountIds.applyButton,
                  label: 'Apply',
                ),
              ),
              SizedBox(width: 10),
              _CancelButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton();

  @override
  Widget build(BuildContext context) {
    return HandheldSecondaryButton(
      id: DiscountIds.cancelButton,
      label: 'Cancel',
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

/// The big 76 dp entry box: `10 %`, `6,200 ฿`, or a promo code.
class _ValueBox extends StatelessWidget {
  final TextEditingController controller;
  final DiscountMode mode;

  const _ValueBox({required this.controller, required this.mode});

  @override
  Widget build(BuildContext context) {
    final isPromo = mode == DiscountMode.promo;
    final suffix = switch (mode) {
      DiscountMode.percent => '%',
      DiscountMode.amount => '฿',
      DiscountMode.promo => '',
    };
    return TestId(
      DiscountIds.valueField,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(HandheldMetrics.radius),
          border: Border.all(color: AppColors.goldMuted, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: isPromo
                    ? TextInputType.text
                    : const TextInputType.numberWithOptions(decimal: true),
                textCapitalization: isPromo
                    ? TextCapitalization.characters
                    : TextCapitalization.none,
                inputFormatters: isPromo
                    ? null
                    : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                style: HandheldText.displayTitle.copyWith(
                  fontSize: isPromo ? 22 : 34,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: isPromo ? 'Promo code' : '0',
                  hintStyle: HandheldText.displayTitle.copyWith(
                    fontSize: isPromo ? 22 : 34,
                    color: AppColors.hintText,
                  ),
                ),
              ),
            ),
            if (suffix.isNotEmpty)
              Text(
                suffix,
                style: const TextStyle(fontSize: 22, color: AppColors.goldDark),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/handheld/handheld.dart'
    show HandheldChoiceChip, formatAmount, formatBaht;
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/overlay_panel.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';
import '../discount_math.dart';

/// Opens the desktop Discount & promotion overlay (POS Desktop mockup
/// screen 7) over the sale — never a route change of its own.
Future<void> showDesktopDiscountOverlay(
  BuildContext context, {
  required CartItem line,
  required int lineNumber,
  required double billNet,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.55),
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(40),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: TestId(
          DiscountIds.sheet,
          child: OverlayPanel(
            title: 'Discount · line $lineNumber',
            onClose: () => Navigator.of(dialogContext).pop(),
            child: _DiscountOverlayBody(line: line, billNet: billNet),
          ),
        ),
      ),
    ),
  );
}

/// Percent / Amount / New price / Promotion code with quick-set chips and
/// a live line + bill preview, all computed client-side by
/// [previewLineDiscount].
///
/// Apply is inert: the cart has no line-discount API and the per-article
/// ceiling ("max 10%"), tobacco lock, supervisor override and eligible
/// promotions all come from the sale engine — none of which the app
/// receives yet, so none are shown or guessed.
// TODO(pos-desktop): apply via a line-discount use case (openspec 4.4 /
// 5.2); show the article ceiling, supervisor gate above it, the tobacco
// lock and eligible promotions once the sale engine returns them.
class _DiscountOverlayBody extends StatefulWidget {
  final CartItem line;
  final double billNet;

  const _DiscountOverlayBody({required this.line, required this.billNet});

  @override
  State<_DiscountOverlayBody> createState() => _DiscountOverlayBodyState();
}

enum _Mode { percent, amount, newPrice, promo }

class _DiscountOverlayBodyState extends State<_DiscountOverlayBody> {
  static const _presets = [3, 5, 7, 10, 15, 20];

  final _value = TextEditingController();
  _Mode _mode = _Mode.percent;

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

  DiscountPreview get _preview {
    final entered = double.tryParse(_value.text);
    final kind = switch (_mode) {
      _Mode.percent => DiscountKind.percent,
      _Mode.amount => DiscountKind.amount,
      _Mode.newPrice => DiscountKind.newPrice,
      _Mode.promo => DiscountKind.amount,
    };
    // Promotion value is decided by the sale engine; new price with no
    // entry means "unchanged".
    final value = _mode == _Mode.promo
        ? 0.0
        : entered ?? (_mode == _Mode.newPrice ? widget.line.unitPrice : 0.0);
    return previewLineDiscount(
      unitPrice: widget.line.unitPrice,
      quantity: widget.line.quantity,
      kind: kind,
      value: value,
    );
  }

  void _setMode(_Mode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    _value.clear();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final preview = _preview;
    final billAfter = widget.billNet - preview.discount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${line.articleName.isEmpty ? line.articleCode : line.articleName}'
            ' · ${line.articleCode}',
            style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _entryColumn()),
                const SizedBox(width: 28),
                Expanded(flex: 2, child: _previewColumn(preview, billAfter)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryColumn() {
    final isPromo = _mode == _Mode.promo;
    final suffix = switch (_mode) {
      _Mode.percent => '%',
      _Mode.amount || _Mode.newPrice => '฿',
      _Mode.promo => '',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final (mode, id, label) in [
              (_Mode.percent, DiscountIds.modePercent, 'Percent'),
              (_Mode.amount, DiscountIds.modeAmount, 'Amount'),
              (_Mode.newPrice, DiscountIds.modeNewPrice, 'New price'),
              (_Mode.promo, DiscountIds.modePromo, 'Promotion code'),
            ]) ...[
              if (mode != _Mode.percent) const SizedBox(width: 8),
              Expanded(
                child: HandheldChoiceChip(
                  id: id,
                  label: label,
                  dark: true,
                  height: 44,
                  selected: _mode == mode,
                  onTap: () => _setMode(mode),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Text(switch (_mode) {
          _Mode.percent => 'DISCOUNT PERCENT',
          _Mode.amount => 'DISCOUNT AMOUNT (THB)',
          _Mode.newPrice => 'NEW UNIT PRICE (THB)',
          _Mode.promo => 'PROMOTION CODE',
        }, style: DesktopText.fieldLabel),
        const SizedBox(height: 8),
        TestId(
          DiscountIds.valueField,
          child: Container(
            height: 88,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.goldMuted, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _value,
                    autofocus: true,
                    keyboardType: isPromo
                        ? TextInputType.text
                        : const TextInputType.numberWithOptions(decimal: true),
                    textCapitalization: isPromo
                        ? TextCapitalization.characters
                        : TextCapitalization.none,
                    inputFormatters: isPromo
                        ? null
                        : [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                    style: TextStyle(
                      fontFamily: 'KingPowerHeadline',
                      fontSize: isPromo ? 28 : 44,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: isPromo ? 'Code' : '0',
                      hintStyle: TextStyle(
                        fontSize: isPromo ? 28 : 44,
                        color: AppColors.hintText,
                      ),
                    ),
                  ),
                ),
                if (suffix.isNotEmpty)
                  Text(
                    suffix,
                    style: const TextStyle(
                      fontSize: 28,
                      color: AppColors.goldDark,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_mode == _Mode.percent) ...[
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
                    selected: _value.text == '${_presets[i]}',
                    onTap: () => _value.text = '${_presets[i]}',
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 18),
        const Text('AVAILABLE PROMOTIONS', style: DesktopText.fieldLabel),
        const SizedBox(height: 8),
        const TestId(
          DiscountIds.promotions,
          child: Text(
            'Promotion eligibility and discount ceilings are not available '
            'yet — the sale engine applies them at checkout.',
            style: TextStyle(fontSize: 13, color: AppColors.mutedText),
          ),
        ),
      ],
    );
  }

  Widget _previewColumn(DiscountPreview preview, double billAfter) {
    final line = widget.line;
    Widget row(String label, String value, {String? id, Color? color}) {
      final text = Text(
        value,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w500,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedText,
                ),
              ),
            ),
            id == null ? text : TestId(id, child: text),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('LINE PREVIEW', style: DesktopText.fieldLabel),
          const SizedBox(height: 8),
          row('Unit price', formatAmount(line.unitPrice)),
          row('Qty', '${line.quantity}'),
          row(
            'Discount ${preview.percent == 0 ? '' : '${_trim(preview.percent)}%'}'
                .trim(),
            preview.discount == 0 ? '—' : formatAmount(-preview.discount),
            id: DiscountIds.lineDiscount,
            color: preview.discount == 0 ? null : AppColors.danger,
          ),
          const SizedBox(height: 12),
          _NetBar(value: formatBaht(preview.net)),
          const SizedBox(height: 12),
          TestId(
            DiscountIds.billDelta,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Bill net pay would move from ${formatBaht(widget.billNet)} '
                'to ${formatBaht(billAfter)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF1A396E),
                ),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),
          const Text(
            'Applying discounts is not available yet on this station.',
            style: TextStyle(fontSize: 12.5, color: AppColors.mutedText),
          ),
          const SizedBox(height: 10),
          const DesktopButton(
            id: DiscountIds.applyButton,
            label: 'Apply discount',
            hotkey: 'ENTER',
            height: 64,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DesktopButton(
                  id: DiscountIds.clearButton,
                  label: 'Clear',
                  secondary: true,
                  onPressed: _value.clear,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DesktopButton(
                  id: DiscountIds.cancelButton,
                  label: 'Cancel',
                  secondary: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

/// Ink "New line net" bar at desktop scale.
class _NetBar extends StatelessWidget {
  final String value;

  const _NetBar({required this.value});

  @override
  Widget build(BuildContext context) {
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
              'New line net',
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

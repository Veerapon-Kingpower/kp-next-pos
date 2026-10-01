import 'package:flutter/material.dart';

import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/overlay_panel.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';
import '../sale_cart_view_model.dart';
import '../widgets/line_discount_editor.dart';

/// Opens the desktop Discount overlay for one line over the sale — the
/// legacy Discount ("PROMOTION") page ([LineDiscountEditor]), form and
/// line detail side by side.
Future<void> showDesktopDiscountOverlay(
  BuildContext context, {
  required SaleCartViewModel viewModel,
  required List<CartItem> lines,
  required String title,
}) async {
  if (!await ensureCanDiscount(context, viewModel, lines)) return;
  if (!context.mounted) return;
  await _show(
    context,
    title: title,
    editor: LineDiscountEditor(
      viewModel: viewModel,
      rows: [for (final line in lines) line.row],
      wide: true,
    ),
  );
}

/// The bill (special) discount — legacy Checkout → More → Discount
/// (`SpecialDiscountPage`); no permission gate, as legacy.
Future<void> showDesktopBillDiscountOverlay(
  BuildContext context, {
  required SaleCartViewModel viewModel,
}) => _show(
  context,
  title: 'Bill discount',
  editor: LineDiscountEditor.bill(viewModel: viewModel, wide: true),
);

Future<void> _show(
  BuildContext context, {
  required String title,
  required Widget editor,
}) async {
  await showDialog<void>(
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
            title: title,
            onClose: () => Navigator.of(dialogContext).pop(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: editor,
            ),
          ),
        ),
      ),
    ),
  );
}

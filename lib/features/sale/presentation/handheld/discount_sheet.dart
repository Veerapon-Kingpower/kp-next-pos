import 'package:flutter/material.dart';

import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';
import '../sale_cart_view_model.dart';
import '../widgets/line_discount_editor.dart';

/// Opens the per-line Discount sheet — a bottom sheet on phones, a dialog
/// on tablets — hosting the legacy Discount ("PROMOTION") page
/// ([LineDiscountEditor]), stacked.
Future<void> showDiscountSheet(
  BuildContext context, {
  required SaleCartViewModel viewModel,
  required List<CartItem> lines,
  required String title,
}) async {
  if (!await ensureCanDiscount(context, viewModel, lines)) return;
  if (!context.mounted) return;
  await showHandheldSheet<void>(
    context,
    id: DiscountIds.sheet,
    builder: (sheetContext) => SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.percent, size: 19, color: AppColors.goldDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: HandheldText.title.copyWith(fontSize: 18),
                ),
              ),
              TestId(
                DiscountIds.closeButton,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LineDiscountEditor(
            viewModel: viewModel,
            rows: [for (final line in lines) line.row],
          ),
        ],
      ),
    ),
  );
}

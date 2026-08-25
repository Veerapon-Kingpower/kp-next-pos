import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/widgets/search_scan_input.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizing.dart';
import '../../../../core/theme/app_spacing.dart';
import '../sale_cart_view_model.dart';

/// Sale barcode-entry field — wraps [SearchScanInput] with the sale
/// feature's scan-to-cart behaviour: parses `qty*barcode` quick-entry
/// syntax, looks up the article, adds it to the cart, and surfaces a
/// scan-format or lookup error as text (per the pos-sales-workflows spec's
/// requirement that error states never rely on colour alone).
class BarcodeScanField extends StatefulWidget {
  final SaleCartViewModel viewModel;

  const BarcodeScanField({super.key, required this.viewModel});

  @override
  State<BarcodeScanField> createState() => _BarcodeScanFieldState();
}

class _BarcodeScanFieldState extends State<BarcodeScanField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    await widget.viewModel.scan(value);
    if (widget.viewModel.scanError == null) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleCartViewModel>(
      init: widget.viewModel,
      global: false,
      builder: (viewModel) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchScanInput(
            controller: _controller,
            hintText: 'Scan or type barcode (e.g. 5*8850012345678)',
            onSubmitted: viewModel.isBusy ? null : _submit,
          ),
          if (viewModel.scanError != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              viewModel.scanError!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ],
          if (viewModel.staleNotice != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber,
                  size: AppSizing.iconSize,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                    viewModel.staleNotice!,
                    style: const TextStyle(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ],
          if (viewModel.cart != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text('${viewModel.cart!.itemCount} item(s) in cart'),
          ],
        ],
      ),
    );
  }
}

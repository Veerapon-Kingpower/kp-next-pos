import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../sale_cart_view_model.dart';
import 'barcode_scan_field.dart';
import 'cart_list.dart';

/// POS Sale tab body: barcode scan-to-cart entry plus the current cart —
/// one of the three primary nav destinations per design.md's nav scope
/// (Customers is the tab shown by default on landing, including right
/// after login; see `home_page.dart`).
class SalePage extends StatelessWidget {
  final SaleCartViewModel viewModel;

  const SalePage({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(child: BarcodeScanField(viewModel: viewModel)),
              const SizedBox(height: AppSpacing.lg),
              CartList(viewModel: viewModel),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../customer/domain/entities/privilege.dart';
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
    final privilege = viewModel.selectedPrivilege;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (privilege != null) ...[
                AppCard(child: _SelectedPrivilegeRow(privilege: privilege)),
                const SizedBox(height: AppSpacing.lg),
              ],
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

/// The privilege chosen on the Customers tab before this sale started, kept
/// visible here so the cashier can see what's active. Same
/// `[TypeCode]:PromoCode` persistent-display format as legacy's
/// `sale.html:138-141` and the customer search card's own privilege row.
class _SelectedPrivilegeRow extends StatelessWidget {
  final Privilege privilege;

  const _SelectedPrivilegeRow({required this.privilege});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final code = privilege.typeCode.isEmpty && privilege.promoCode.isEmpty
        ? ''
        : '[${privilege.typeCode}]:${privilege.promoCode}';

    return Row(
      children: [
        const Icon(Icons.card_giftcard, color: AppColors.goldAccent),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                privilege.name.isEmpty ? 'Privilege' : privilege.name,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (code.isNotEmpty)
                Text(
                  code,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

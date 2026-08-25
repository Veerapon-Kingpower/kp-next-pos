import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/presentation/widgets/empty_state_view.dart';
import '../../../../core/theme/app_spacing.dart';
import '../sale_cart_view_model.dart';
import 'cart_item_tile.dart';

/// Renders the current cart's line items, wired to
/// [SaleCartViewModel.updateQuantity]/[SaleCartViewModel.removeItem].
class CartList extends StatelessWidget {
  final SaleCartViewModel viewModel;

  const CartList({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleCartViewModel>(
      init: viewModel,
      global: false,
      builder: (viewModel) {
        final items = viewModel.cart?.items ?? const [];
        if (items.isEmpty) {
          return const EmptyStateView(
            message: 'Cart is empty. Scan an item to add it.',
            icon: Icons.shopping_cart_outlined,
          );
        }
        return Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: CartItemTile(
                    item: item,
                    onQuantityChanged: (quantity) => viewModel.updateQuantity(
                      row: item.row,
                      quantity: quantity,
                    ),
                    onRemove: () => viewModel.removeItem(item.row),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

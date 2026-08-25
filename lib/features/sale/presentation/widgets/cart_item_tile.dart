import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/cart_item.dart';

/// Cart line-item row: name, price, quantity +/- adjusters, and a trash
/// icon to remove the row. [CartItem]'s fields are a mock mapping pending
/// real `OrderDetails` field confirmation (see `cart_item.dart`).
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.articleName.isEmpty
                      ? item.articleCode
                      : item.articleName,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '฿${item.lineTotal.toStringAsFixed(2)}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: 'Decrease quantity',
            onPressed: () => onQuantityChanged(item.quantity - 1),
          ),
          Text('${item.quantity}', style: textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Increase quantity',
            onPressed: () => onQuantityChanged(item.quantity + 1),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Remove item',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

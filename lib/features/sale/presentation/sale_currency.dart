import 'package:flutter/material.dart';

import '../../../core/presentation/test_ids.dart';
import '../../../core/presentation/widgets/test_id.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/entities/cart.dart';
import 'sale_cart_view_model.dart';
import 'widgets/currency_picker.dart';

/// The order's currency code — `THB` until the sale engine reports another.
String orderCurrency(Cart? cart) {
  final code = cart?.billing?.currencyCode ?? '';
  return code.isEmpty ? 'THB' : code;
}

/// Net pay in the order's currency: the sale engine's own figure when the
/// order carries one, otherwise the sum of the line totals.
double orderNetPay(Cart? cart) {
  final billing = cart?.billing;
  if (billing != null) return billing.netPay;
  return (cart?.items ?? const []).fold<double>(0, (s, l) => s + l.lineTotal);
}

/// Baht per one unit of the order's currency (1 for a baht order).
double orderRateToBaht(Cart? cart) {
  final billing = cart?.billing;
  if (billing == null || billing.isBaht || billing.currencyRate <= 0) {
    return 1;
  }
  return billing.currencyRate;
}

/// Legacy `SalePage` / `CheckoutPage.changeCurrency()`: the `actCurrency`
/// permission first ("Oops !" otherwise), then the picker; a different pick
/// goes to the sale engine, which reprices the whole order.
Future<void> changeOrderCurrency(
  BuildContext context,
  SaleCartViewModel viewModel,
) async {
  if (!await viewModel.canChangeCurrency()) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oops !'),
        content: const Text(SaleCartViewModel.noCurrencyPermission),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }
  if (!context.mounted) return;
  final current = orderCurrency(viewModel.cart);
  final picked = await showCurrencyPicker(
    context,
    load: viewModel.listCurrencies,
    current: current,
  );
  if (picked != null && picked != current) {
    await viewModel.changeCurrency(picked);
  }
}

/// Legacy's header currency button: the order currency and, once the sale
/// engine has priced the order, its rate. Null [onTap] renders it inert
/// (no shopping card attached yet).
class OrderCurrencyButton extends StatelessWidget {
  final CartBilling? billing;
  final VoidCallback? onTap;
  final bool onDark;

  const OrderCurrencyButton({
    super.key,
    required this.billing,
    required this.onTap,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final code = billing == null || billing!.currencyCode.isEmpty
        ? 'THB'
        : billing!.currencyCode;
    final enabled = onTap != null;
    final strong = onDark ? Colors.white : AppColors.goldDark;
    final soft = onDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.mutedText;
    return Tooltip(
      message: enabled
          ? 'Change currency'
          : 'Attach a customer to change the currency',
      child: TestId(
        CurrencyIds.orderButton,
        child: Semantics(
          button: true,
          enabled: enabled,
          child: Material(
            color: onDark
                ? Colors.white.withValues(alpha: 0.14)
                : AppColors.cream,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 36),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: strong,
                        ),
                      ),
                      if (billing != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          billing!.currencyRate.toStringAsFixed(5),
                          style: TextStyle(
                            fontSize: 12,
                            color: soft,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Icon(
                        Icons.currency_exchange,
                        size: 14,
                        color: enabled ? strong : soft,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

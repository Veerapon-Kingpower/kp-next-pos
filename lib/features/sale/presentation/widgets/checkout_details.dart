import 'package:flutter/material.dart';

import '../../../../core/presentation/handheld/handheld.dart'
    show formatAmount, formatCarat, formatEPurse;
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cart.dart';
import '../sale_cart_view_model.dart';

/// One label / value row of the Checkout details.
typedef CheckoutFact = ({String label, String value});

String _or(String value) => value.trim().isEmpty ? '—' : value.trim();

/// What Checkout keeps of legacy's customer profile — only what the
/// cashier needs at payment, so the lines get the room: who the bill is
/// for, the shopping card and order, a member's privilege, Carat and
/// e-Purse and, on airport mPOS, the order's DFA and promoter. The rest of
/// the profile (type, nationality, passport, flight, pickup, cashier, mPOS)
/// stays on the Customer page.
List<CheckoutFact> checkoutSummaryFacts(
  SaleCartViewModel vm, {
  required bool isAirportMpos,
}) {
  final person = vm.customer?.person;
  final privilege = vm.selectedPrivilege;
  final cart = vm.cart;
  return [
    if (person != null) (label: 'Customer', value: _or(person.englishName)),
    (label: 'Shopping card', value: _or(vm.shoppingCard)),
    (label: 'Order no', value: _or(cart?.orderNo ?? '')),
    // A member always shows the privilege the bill is priced with — "None"
    // when they went on without one.
    if (vm.isMember || privilege != null)
      (
        label: 'Privilege',
        value: privilege == null
            ? 'None'
            : [
                privilege.name,
                if (privilege.typeCode.isNotEmpty ||
                    privilege.promoCode.isNotEmpty)
                  '[${privilege.typeCode}]:${privilege.promoCode}',
              ].where((s) => s.isNotEmpty).join(' · '),
      ),
    // A member's wallets (the CARAT / CASHW balances), as on the Customer
    // page; "—" when the member has no such wallet.
    if (vm.isMember && person != null) ...[
      (label: 'Carat', value: formatCarat(person.caratBalance)),
      (label: 'e-Purse', value: formatEPurse(person.ePurseBalance)),
    ],
    if (isAirportMpos) ...[
      (label: 'DFA', value: _or(cart?.dfa ?? '')),
      (label: 'Promoter', value: _or(cart?.promoter ?? '')),
    ],
  ];
}

/// Legacy Checkout's bill-discount rows: `(%)Discount`, `Baht Disc.`,
/// `Promotion` (`Code | Desc`).
List<CheckoutFact> billDiscountFacts(CartBilling billing) => [
  (
    label: '(%)Discount',
    value: '${formatAmount(billing.percentDiscountSpecial)}%',
  ),
  (label: 'Baht Disc.', value: formatAmount(billing.discountSpecial)),
  (
    label: 'Promotion',
    value: billing.promotionCode.isEmpty
        ? '—'
        : '${billing.promotionCode} | ${billing.promotionName}',
  ),
];

/// Legacy Checkout → More → Gift with Purchase: each offer, the ones this
/// bill already qualifies for ticked.
class GiftWithPurchaseList extends StatelessWidget {
  final List<GiftWithPurchase> gifts;

  const GiftWithPurchaseList({super.key, required this.gifts});

  @override
  Widget build(BuildContext context) {
    return TestId(
      CheckoutIds.gwpList,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final gift in gifts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    gift.canApply
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 17,
                    color: gift.canApply
                        ? AppColors.success
                        : AppColors.mutedText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      gift.text,
                      style: TextStyle(
                        fontSize: 13,
                        color: gift.canApply
                            ? AppColors.textPrimary
                            : AppColors.mutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

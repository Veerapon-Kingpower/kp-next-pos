import 'package:flutter/material.dart';

import '../../../../core/presentation/handheld/handheld.dart' show formatAmount;
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customer/presentation/customer_summary.dart';
import '../../domain/entities/cart.dart';
import '../sale_cart_view_model.dart';

/// One label / value row of the Checkout details.
typedef CheckoutFact = ({String label, String value});

String _or(String value) => value.trim().isEmpty ? '—' : value.trim();

/// Legacy Checkout → Customer (`CustomerProfilePage`) "PROFILE": who the
/// bill is for, the shopping card and order, registration and privilege.
List<CheckoutFact> checkoutCustomerFacts(SaleCartViewModel vm) {
  final person = vm.customer?.person;
  final privilege = vm.selectedPrivilege;
  return [
    if (person != null) ...[
      (label: 'Customer name', value: _or(person.englishName)),
      (label: 'Customer type', value: _or(person.customerTypeCode)),
      (label: 'Nationality', value: _or(person.nationality)),
    ],
    (label: 'Shopping card', value: _or(vm.shoppingCard)),
    (label: 'Order no', value: _or(vm.cart?.orderNo ?? '')),
    if (person != null)
      (
        label: 'Status',
        value: person.isActivate ? 'Registered' : 'Not registered',
      ),
    if (privilege != null)
      (
        label: 'Privilege',
        value: [
          privilege.name,
          if (privilege.typeCode.isNotEmpty || privilege.promoCode.isNotEmpty)
            '[${privilege.typeCode}]:${privilege.promoCode}',
        ].where((s) => s.isNotEmpty).join(' · '),
      ),
  ];
}

/// The profile's passport and flight (legacy "Flight : code, date time").
List<CheckoutFact> checkoutTripFacts(SaleCartViewModel vm, DateTime now) {
  final person = vm.customer?.person;
  if (person == null) return const [];
  final departs = departsIn(person, now);
  return [
    (label: 'Passport no.', value: _or(person.passportNo)),
    (
      label: 'Flight',
      value: _or(
        [
          person.flightCode,
          person.flightRouteDetail,
        ].where((s) => s.isNotEmpty).join(' · '),
      ),
    ),
    (
      label: 'Departs',
      value: _or(
        [
          flightWhen(person),
          if (departs != null) 'in $departs',
        ].where((s) => s.isNotEmpty).join(' · '),
      ),
    ),
    if (person.flightPickup.isNotEmpty)
      (label: 'Pickup', value: person.flightPickup),
  ];
}

/// The profile's "SALE" block: the cashier and the mPOS; on airport mPOS
/// also the order's DFA, promoter and date, as legacy shows there.
List<CheckoutFact> checkoutSaleFacts(
  SaleCartViewModel vm, {
  required bool isAirportMpos,
}) {
  final session = vm.session;
  final cart = vm.cart;
  return [
    (
      label: 'Sale',
      value: _or(
        [
          session?.userCode ?? '',
          session?.userName ?? '',
        ].where((s) => s.isNotEmpty).join(' · '),
      ),
    ),
    (label: 'mPOS no', value: _or(session?.machineNo ?? '')),
    if (isAirportMpos) ...[
      (label: 'DFA', value: _or(cart?.dfa ?? '')),
      (label: 'Promoter', value: _or(cart?.promoter ?? '')),
      (label: 'Order date', value: _or(cart?.createDate ?? '')),
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

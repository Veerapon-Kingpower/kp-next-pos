import 'package:flutter/material.dart';

/// Order types — as legacy's `CustomerPage.setDefaultShopping()` defines
/// them (`shoppingObj`: `orderType` code, `text`, `color`): `N` NORMAL,
/// `D` DELIVERY, `P` Pre-order; on airport mPOS only NORMAL and `D`
/// DEPOSIT. The handheld mockup themes the Sale header by them (screens 3,
/// 16, 17); header colors follow the mockup, the rest matches legacy.
/// Presentation-only: the cart has no order-type field yet, so the app
/// always runs [normal] — see `HandheldSaleView`.
enum SaleOrderType {
  normal(
    code: 'N',
    label: 'NORMAL',
    icon: Icons.shopping_bag_outlined,
    header: Color(0xFF654F1C),
    band: Color(0xFF4A3A14),
  ),
  delivery(
    code: 'D',
    label: 'DELIVERY',
    icon: Icons.local_shipping_outlined,
    header: Color(0xFF165FA9),
    band: Color(0xFF0F4C8A),
  ),
  preOrder(
    code: 'P',
    label: 'Pre-order',
    icon: Icons.event_available_outlined,
    header: Color(0xFFBF4D0D),
    band: Color(0xFF963A08),
  ),

  /// Airport mPOS only (legacy `isMPOSAirport` branch).
  deposit(
    code: 'D',
    label: 'DEPOSIT',
    icon: Icons.savings_outlined,
    header: Color(0xFF165FA9),
    band: Color(0xFF0F4C8A),
  );

  /// Legacy `orderType` code.
  final String code;

  /// Legacy `shoppingObj.text`, shown as-is.
  final String label;
  final IconData icon;

  /// Header background.
  final Color header;

  /// Darker totals band under the header.
  final Color band;

  const SaleOrderType({
    required this.code,
    required this.label,
    required this.icon,
    required this.header,
    required this.band,
  });

  /// The order types a station offers — legacy shows NORMAL / DEPOSIT on
  /// airport mPOS and NORMAL / DELIVERY / Pre-order elsewhere.
  static List<SaleOrderType> optionsFor({required bool isAirportMpos}) =>
      isAirportMpos
      ? const [normal, deposit]
      : const [normal, delivery, preOrder];
}

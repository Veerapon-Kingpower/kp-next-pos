import 'package:flutter/material.dart';

/// Order types the handheld mockup themes the Sale header by (screens 3,
/// 16, 17). Presentation-only: the cart has no order-type field yet, so the
/// app always runs [shopping] — see `HandheldSaleView`.
enum SaleOrderType {
  shopping(
    label: 'Normal',
    icon: Icons.shopping_bag_outlined,
    header: Color(0xFF654F1C),
    band: Color(0xFF4A3A14),
  ),
  delivery(
    label: 'Delivery',
    icon: Icons.local_shipping_outlined,
    header: Color(0xFF165FA9),
    band: Color(0xFF0F4C8A),
  ),
  preOrder(
    label: 'Pre-order',
    icon: Icons.event_available_outlined,
    header: Color(0xFFBF4D0D),
    band: Color(0xFF963A08),
  );

  final String label;
  final IconData icon;

  /// Header background.
  final Color header;

  /// Darker totals band under the header.
  final Color band;

  const SaleOrderType({
    required this.label,
    required this.icon,
    required this.header,
    required this.band,
  });
}

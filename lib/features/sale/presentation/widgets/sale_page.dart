import 'package:flutter/material.dart';

import '../desktop/desktop_sale_view.dart';
import '../sale_cart_view_model.dart';

/// Sale section body at desktop width (≥ 840 dp) — the POS Desktop mockup's
/// scan + lines table + bill summary (screens 3 / 4). Handheld widths use
/// `HandheldSaleView` instead (see `HomePage`).
class SalePage extends StatelessWidget {
  final SaleCartViewModel viewModel;
  final bool isAirportMpos;
  final VoidCallback? onExit;
  final VoidCallback? onFindCustomer;
  final Future<void> Function()? onSignOut;

  const SalePage({
    super.key,
    required this.viewModel,
    this.isAirportMpos = false,
    this.onExit,
    this.onFindCustomer,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) => DesktopSaleView(
    viewModel: viewModel,
    isAirportMpos: isAirportMpos,
    onExit: onExit,
    onFindCustomer: onFindCustomer,
    onSignOut: onSignOut,
  );
}

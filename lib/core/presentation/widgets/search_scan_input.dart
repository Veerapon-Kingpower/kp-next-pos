import 'package:flutter/material.dart';

import '../../theme/app_sizing.dart';

/// Search input with a scan affordance, shared by every workflow that looks
/// up a customer/article/document by barcode or manual entry (see
/// `inventory.md` — barcode scanning appears across home, customer, sale,
/// payment, voucher, and customer-form). [onScanPressed] triggers whatever
/// platform scan input is configured (camera, HW scanner focus, MRZ
/// reader) — this widget only owns the text field and the request to scan.
class SearchScanInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onScanPressed;
  final ValueChanged<String>? onSubmitted;

  const SearchScanInput({
    super.key,
    required this.controller,
    this.hintText = 'Search or scan',
    this.onScanPressed,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onScanPressed != null
            ? IconButton(
                icon: const Icon(
                  Icons.qr_code_scanner,
                  size: AppSizing.iconSize,
                ),
                tooltip: 'Scan',
                onPressed: onScanPressed,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizing.cornerRadiusMd),
        ),
      ),
    );
  }
}

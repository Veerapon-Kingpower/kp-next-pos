import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/test_id.dart';
import 'handheld_tokens.dart';

/// The handheld's always-in-reach scan / type field (mockup screens 2, 3,
/// 16, 17): a 62 dp gold-bordered box with a barcode glyph. Hardware
/// scanners on the Sunmi deliver scans as keyboard input followed by
/// Enter, so [onSubmitted] fires for both a trigger scan and a typed code.
class ScanField extends StatelessWidget {
  final String id;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;

  const ScanField({
    super.key,
    required this.id,
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      id,
      child: SizedBox(
        height: HandheldMetrics.scanFieldHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(HandheldMetrics.radius),
            border: Border.all(color: AppColors.goldMuted, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldMuted.withValues(alpha: 0.1),
                spreadRadius: 4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  size: 21,
                  color: AppColors.goldDark,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    enabled: enabled,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSubmitted,
                    style: HandheldText.body,
                    decoration: InputDecoration.collapsed(
                      hintText: hintText,
                      hintStyle: HandheldText.body.copyWith(
                        color: AppColors.hintText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/test_id.dart';
import 'handheld_tokens.dart';

/// The handheld's always-in-reach scan / type field (mockup screens 2, 3,
/// 16, 17). Hardware scanners on the Sunmi deliver scans as keyboard input
/// followed by Enter, so [onSubmitted] fires for both a trigger scan and a
/// typed code.
///
/// On light pages it is the 62 dp gold-bordered box (Home); with [onDark]
/// it is the 52 dp translucent box that sits inside a coloured header
/// (Sale).
class ScanField extends StatelessWidget {
  final String id;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final bool onDark;
  // When set, a trailing search button (with this id) submits the typed
  // text, for a code keyed in by hand rather than scanned.
  final String? searchButtonId;
  // When set, a ✕ (with this id) empties the field while it has text and
  // keeps focus there for the next scan.
  final String? clearButtonId;
  // Keep focus after Enter, so the next trigger scan lands here too (a
  // TextField otherwise drops focus on submit).
  final bool keepFocusOnSubmit;

  const ScanField({
    super.key,
    required this.id,
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.onDark = false,
    this.searchButtonId,
    this.clearButtonId,
    this.keepFocusOnSubmit = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? Colors.white : AppColors.textPrimary;
    final decoration = onDark
        ? BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          )
        : BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(HandheldMetrics.radius),
            border: Border.all(color: AppColors.goldMuted, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldMuted.withValues(alpha: 0.1),
                spreadRadius: 4,
              ),
            ],
          );

    return TestId(
      id,
      child: SizedBox(
        height: onDark
            ? HandheldMetrics.darkScanFieldHeight
            : HandheldMetrics.scanFieldHeight,
        child: DecoratedBox(
          decoration: decoration,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: onDark ? 14 : 16),
            child: Row(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: onDark ? 18 : 21,
                  color: onDark ? Colors.white : AppColors.goldDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: autofocus,
                    enabled: enabled,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSubmitted,
                    onEditingComplete: keepFocusOnSubmit ? () {} : null,
                    cursorColor: onDark ? Colors.white : null,
                    style: HandheldText.body.copyWith(color: foreground),
                    decoration: InputDecoration.collapsed(
                      hintText: hintText,
                      hintStyle: HandheldText.body.copyWith(
                        fontSize: onDark ? 14 : 14.5,
                        color: onDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.hintText,
                      ),
                    ),
                  ),
                ),
                if (clearButtonId != null)
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : TestId(
                            clearButtonId!,
                            child: IconButton(
                              tooltip: 'Clear',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.cancel, size: 18),
                              color: onDark
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : const Color(0xFF9AA2AE),
                              onPressed: enabled
                                  ? () {
                                      controller.clear();
                                      focusNode?.requestFocus();
                                    }
                                  : null,
                            ),
                          ),
                  ),
                if (searchButtonId != null)
                  TestId(
                    searchButtonId!,
                    child: IconButton(
                      tooltip: 'Search',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.search, color: foreground),
                      onPressed: enabled
                          ? () => onSubmitted(controller.text)
                          : null,
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

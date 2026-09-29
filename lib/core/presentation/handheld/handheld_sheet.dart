import 'package:flutter/material.dart';

import '../../theme/app_breakpoints.dart';
import '../../theme/app_colors.dart';
import '../widgets/test_id.dart';
import 'handheld_tokens.dart';

/// Opens a handheld sheet (Discount, Edit line, Signature, Menu, …).
///
/// Compact widths get the mockup's bottom sheet — white, 18 dp top radius,
/// drag handle. On medium and wider (tablet / iPad) a full-width bottom
/// sheet would stretch across the screen, so the same content opens as a
/// centred dialog capped at [HandheldMetrics.mediumSheetMaxWidth]
/// (handheld spec decision 5). [id] is applied to the sheet content.
Future<T?> showHandheldSheet<T>(
  BuildContext context, {
  required String id,
  required WidgetBuilder builder,
}) {
  if (AppBreakpoints.sizeClass(context) == AppSizeClass.compact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.ink.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(HandheldMetrics.sheetRadius),
        ),
      ),
      builder: (context) => TestId(
        id,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              12,
              18,
              18 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Flexible(child: builder(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.5),
    builder: (context) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HandheldMetrics.sheetRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: HandheldMetrics.mediumSheetMaxWidth,
        ),
        child: TestId(
          id,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: builder(context),
          ),
        ),
      ),
    ),
  );
}

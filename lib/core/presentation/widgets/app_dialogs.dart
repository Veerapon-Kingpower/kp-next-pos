import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'app_buttons.dart';

/// Shared confirmation dialog — used for destructive/irreversible actions
/// (cancel sale, void payment, delete item) so the confirm/cancel pattern
/// looks and behaves the same everywhere. Base design: both actions sit in
/// one row, evenly split via [Expanded] — [AlertDialog]'s default `actions`
/// layout (`OverflowBar`) gives each child its own intrinsic width first,
/// and [AppSecondaryButton]/[AppPrimaryButton]/[AppDestructiveButton] all
/// request infinite width (`Size.fromHeight`, for their normal full-width
/// form-button use), so two of them side by side never fit and
/// `OverflowBar` falls back to stacking them vertically. Wrapping both in a
/// single `Row` as the lone `actions` entry sidesteps that entirely: the
/// `Row` is what gets sized by `OverflowBar`, and `Expanded` gives each
/// button a bounded, equal share of it.
Future<bool> showAppConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppSecondaryButton(
                label: cancelLabel,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: destructive
                  ? AppDestructiveButton(
                      label: confirmLabel,
                      onPressed: () => Navigator.of(context).pop(true),
                    )
                  : AppPrimaryButton(
                      label: confirmLabel,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}

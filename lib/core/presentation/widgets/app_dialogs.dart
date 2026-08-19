import 'package:flutter/material.dart';

import 'app_buttons.dart';

/// Shared confirmation dialog — used for destructive/irreversible actions
/// (cancel sale, void payment, delete item) so the confirm/cancel pattern
/// looks and behaves the same everywhere.
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
        AppSecondaryButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        destructive
            ? AppDestructiveButton(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(true),
              )
            : AppPrimaryButton(
                label: confirmLabel,
                onPressed: () => Navigator.of(context).pop(true),
              ),
      ],
    ),
  );
  return result ?? false;
}

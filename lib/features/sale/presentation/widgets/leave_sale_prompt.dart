import 'package:flutter/material.dart';

import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_spacing.dart';
import '../sale_cart_view_model.dart';

enum _LeaveChoice { save, discard }

/// Ports legacy `sale.ts`'s `showBeforeLeave()` and what its buttons run.
/// With lines on the Buying list (not on airport mPOS) it asks "Do you want
/// to save order?": Yes saves then leaves, No reverses the reserved stock
/// then leaves. Otherwise "Do you want to go back?": OK leaves. Leaving
/// unlocks the shopping card ([SaleCartViewModel.releaseOrder]). If the
/// unlock can't reach the sale engine, legacy alerts and logs out; here the
/// cashier is asked first — Log out runs [onSignOut], Cancel stays on Sale
/// with the card still locked. Returns whether the Sale was left — false
/// on Cancel, a failed save or a failed unlock.
Future<bool> confirmLeaveSale(
  BuildContext context,
  SaleCartViewModel viewModel, {
  required bool isAirportMpos,
  required Future<void> Function() onSignOut,
}) async {
  // Nothing held: there is no order to save or unlock.
  if (viewModel.shoppingCard.isEmpty) return true;

  final askSave = viewModel.hasBuyingItems && !isAirportMpos;
  final choice = await showDialog<_LeaveChoice>(
    context: context,
    builder: (context) {
      Widget button(String id, String label, _LeaveChoice? value) => Expanded(
        child: TestId(
          id,
          child: value == null
              ? AppSecondaryButton(
                  label: label,
                  onPressed: () => Navigator.of(context).pop(),
                )
              : AppPrimaryButton(
                  label: label,
                  onPressed: () => Navigator.of(context).pop(value),
                ),
        ),
      );
      const gap = SizedBox(width: AppSpacing.sm);
      return TestId(
        SaleIds.leaveDialog,
        child: AlertDialog(
          title: const Text('Warning !'),
          content: Text(
            askSave ? 'Do you want to save order?' : 'Do you want to go back?',
          ),
          actions: [
            Row(
              children: askSave
                  ? [
                      button(SaleIds.leaveCancel, 'Cancel', null),
                      gap,
                      button(SaleIds.leaveNo, 'No', _LeaveChoice.discard),
                      gap,
                      button(SaleIds.leaveYes, 'Yes', _LeaveChoice.save),
                    ]
                  : [
                      button(SaleIds.leaveCancel, 'Cancel', null),
                      gap,
                      button(SaleIds.leaveOk, 'OK', _LeaveChoice.discard),
                    ],
            ),
          ],
        ),
      );
    },
  );
  if (choice == null) return false;

  String? stockError;
  if (askSave && choice == _LeaveChoice.save) {
    // A failed save stays on Sale with the server's message shown there.
    if (!await viewModel.saveOrder()) return false;
  } else if (askSave) {
    stockError = await viewModel.reverseVirtualStock();
  }
  if (!await viewModel.releaseOrder()) {
    if (context.mounted && await _askSignOutAfterUnlockFailed(context)) {
      await onSignOut();
    }
    return false;
  }

  if (stockError != null && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error !'),
        content: Text(stockError!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  return true;
}

// Legacy `onlyUnlockShoppingCard()`'s HTTP error: "Http Error / Something
// went wrong", OK → log out. Asked here, so Cancel keeps the cashier on
// Sale to try again.
Future<bool> _askSignOutAfterUnlockFailed(BuildContext context) async {
  final signOut = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => TestId(
      SaleIds.unlockFailedDialog,
      child: AlertDialog(
        title: const Text('Http Error'),
        content: const Text(
          'Something went wrong — the shopping card could not be unlocked. '
          'Log out now?',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TestId(
                  SaleIds.unlockFailedCancel,
                  child: AppSecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TestId(
                  SaleIds.unlockFailedLogout,
                  child: AppPrimaryButton(
                    label: 'Log out',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return signOut ?? false;
}

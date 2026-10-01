import 'package:flutter/material.dart';

import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_spacing.dart';
import '../sale_cart_view_model.dart';

/// Ports legacy `sale.ts`'s `goCheckout()`. Checks the user
/// ([SaleCartViewModel.checkoutGate]), asks "You have not selected a
/// privilege" for a member without one, then sends `UpdateOrderStatus` `e`
/// ([SaleCartViewModel.markCheckout]). True when Checkout should open.
/// With no signed-in user, or no network for the status call, legacy
/// alerts and signs out ([onSignOut]).
Future<bool> confirmGoCheckout(
  BuildContext context,
  SaleCartViewModel viewModel, {
  required Future<void> Function() onSignOut,
}) async {
  switch (await viewModel.checkoutGate()) {
    case CheckoutGate.noSession:
      if (context.mounted) {
        await _alert(context, 'Warning !', 'Something went wrong');
      }
      await onSignOut();
      return false;
    case CheckoutGate.noPermission:
      if (context.mounted) {
        await _alert(context, 'Oops !', "Sorry, you don't have permission.");
      }
      return false;
    case CheckoutGate.noPrivilege:
      if (!context.mounted || !await _askContinueWithoutPrivilege(context)) {
        return false;
      }
    case CheckoutGate.ready:
      break;
  }
  if (await viewModel.markCheckout()) return true;
  if (context.mounted) {
    await _alert(context, 'Oops !', 'Network not connection');
  }
  await onSignOut();
  return false;
}

Future<void> _alert(BuildContext context, String title, String message) =>
    showDialog<void>(
      context: context,
      builder: (context) => TestId(
        SaleIds.checkoutAlert,
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

Future<bool> _askContinueWithoutPrivilege(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => TestId(
      SaleIds.checkoutNoPrivilegeDialog,
      child: AlertDialog(
        title: const Text('You have not selected a privilege'),
        content: const Text('Do you want to continue?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: TestId(
                  SaleIds.checkoutNoPrivilegeCancel,
                  child: AppSecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TestId(
                  SaleIds.checkoutNoPrivilegeOk,
                  child: AppPrimaryButton(
                    label: 'OK',
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
  return ok ?? false;
}

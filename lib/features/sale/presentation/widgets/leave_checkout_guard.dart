import 'package:flutter/material.dart';

import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_spacing.dart';
import '../sale_cart_view_model.dart';

/// Legacy Checkout's `ionViewCanLeave()`: back (button, Esc or the system
/// back) asks "Do you want to go back?" first. OK runs
/// [SaleCartViewModel.leaveCheckout] (abort, status back to Sale) and
/// returns to Sale; its error is shown and Checkout stays.
class LeaveCheckoutGuard extends StatelessWidget {
  final SaleCartViewModel viewModel;
  final Widget child;

  const LeaveCheckoutGuard({
    super.key,
    required this.viewModel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || viewModel.isBusy) return;
        final navigator = Navigator.of(context);
        if (await confirmLeaveCheckout(context, viewModel)) navigator.pop();
      },
      child: child,
    );
  }
}

/// Asks, then leaves Checkout's order for Sale. True once it may pop.
Future<bool> confirmLeaveCheckout(
  BuildContext context,
  SaleCartViewModel viewModel,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => TestId(
      CheckoutIds.leaveDialog,
      child: AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Do you want to go back?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: TestId(
                  CheckoutIds.leaveCancel,
                  child: AppSecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TestId(
                  CheckoutIds.leaveOk,
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
  if (ok != true) return false;
  final error = await viewModel.leaveCheckout();
  if (error == null) return true;
  if (context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (context) => TestId(
        CheckoutIds.leaveError,
        child: AlertDialog(
          title: const Text('Error'),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
  return false;
}

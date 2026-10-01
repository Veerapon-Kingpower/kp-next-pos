import 'package:flutter/material.dart';

import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/finish_payment.dart';
import '../sale_cart_view_model.dart';
import 'order_signature.dart';

/// Legacy Checkout's Finish, in its order:
/// 1. `onFinishPayment()`: "Confirm Payment", then a required signature
///    ([confirmSignedBeforeFinish]). The delivery shipping-address step is
///    skipped — only NORMAL orders are sold here.
/// 2. `validateGWP()`: `GWP_authorize` asks Yes / No, `GWP` (or any other
///    message) blocks.
/// 3. `savePaymentV2()`: `FinishPaymentOrder` with the signatures. Done —
///    or `EARN_ERROR`, which legacy treats as done — it prints the invoice
///    and signs out ([onSignOut]). `SESSION_EXPIRE` and no network sign out
///    too; any other error stays to try again.
///
/// Not ported: printing the invoice (`PrintTaxInvoice`, no printer here
/// yet) and the airport RC request.
Future<void> completeSale(
  BuildContext context,
  SaleCartViewModel viewModel, {
  required Future<void> Function() onSignOut,
}) async {
  if (!await _confirm(
    context,
    title: 'Confirm Payment',
    message: 'Do you want to confirm payments',
    ok: 'Confirm',
    cancel: 'Cancel',
  )) {
    return;
  }
  if (!context.mounted ||
      !await confirmSignedBeforeFinish(context, viewModel)) {
    return;
  }

  final gwp = await viewModel.validateGwp();
  if (!context.mounted) return;
  if (gwp == null) {
    await _alert(context, 'Oops !', 'Network not connection');
    return;
  }
  if (!gwp.completed) {
    final authorize = gwp.message(FinishMessageCode.gwpAuthorize);
    if (authorize != null) {
      if (!await _confirm(
        context,
        title: authorize.type,
        message: authorize.desc,
        ok: 'Yes',
        cancel: 'No',
      )) {
        return;
      }
    } else {
      final block = gwp.message(FinishMessageCode.gwp);
      final other = gwp.messages.isEmpty ? null : gwp.messages.first;
      await _alert(
        context,
        block != null
            ? block.type
            : other == null
            ? 'Error !'
            : 'Error Code: ${other.code}',
        (block ?? other)?.desc ?? 'Could not validate the gift with purchase.',
      );
      return;
    }
  }
  if (!context.mounted) return;

  final done = await viewModel.finishPaymentOrder();
  if (!context.mounted) return;
  if (done == null) {
    await _alert(context, 'Error !', 'Network not connection');
    await onSignOut();
    return;
  }
  if (done.completed) {
    await _saved(context);
    await onSignOut();
    return;
  }
  final error = done.messages.isEmpty ? null : done.messages.first;
  await _alert(
    context,
    error == null ? 'Error !' : 'Error Code:  ${error.code}',
    error == null ? 'Network not connection' : error.desc,
  );
  if (!context.mounted) return;
  if (error?.code == FinishMessageCode.sessionExpire) {
    await onSignOut();
  } else if (error?.code == FinishMessageCode.earnError) {
    await _saved(context);
    await onSignOut();
  }
}

// Legacy "Save Complete — Wait for printing", then the invoice prints.
Future<void> _saved(BuildContext context) => _alert(
  context,
  'Save Complete',
  'The sale is complete. Printing the invoice is not available yet.',
  id: PaymentIds.finishSaved,
);

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String ok,
  required String cancel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => TestId(
      PaymentIds.finishConfirm,
      child: AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          Row(
            children: [
              Expanded(
                child: TestId(
                  PaymentIds.finishConfirmCancel,
                  child: AppSecondaryButton(
                    label: cancel,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TestId(
                  PaymentIds.finishConfirmOk,
                  child: AppPrimaryButton(
                    label: ok,
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
  return confirmed ?? false;
}

Future<void> _alert(
  BuildContext context,
  String title,
  String message, {
  String id = PaymentIds.finishAlert,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => TestId(
    id,
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

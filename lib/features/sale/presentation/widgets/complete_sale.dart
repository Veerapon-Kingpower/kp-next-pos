import 'package:flutter/material.dart';

import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/app_buttons.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/finish_payment.dart';
import '../../domain/entities/print_documents.dart';
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
///    ([_printInvoice]) and signs out ([onSignOut]). `SESSION_EXPIRE` and no
///    network sign out too; any other error stays to try again.
///
/// Not ported: the airport RC request.
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
    await _printInvoice(context, viewModel, onSignOut);
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
    await _printInvoice(context, viewModel, onSignOut);
  }
}

/// Legacy `onPrintInvice()`: `getInvoice()` under "Save Complete — Wait for
/// printing", then one dialog per page ("Printing original" "[1/2]") whose
/// OK prints it, then sign out. `SYNC_ERROR` offers RETRY; `TIMEOUT` and no
/// network sign out; any other error stays.
Future<void> _printInvoice(
  BuildContext context,
  SaleCartViewModel viewModel,
  Future<void> Function() onSignOut,
) async {
  while (true) {
    if (!context.mounted) return;
    final answer = await _whileLoading(
      context,
      'Save Complete\nWait for printing',
      viewModel.printInvoice(),
    );
    if (!context.mounted) return;
    if (answer == null) {
      await _alert(context, 'Error !', 'Network not connection');
      await onSignOut();
      return;
    }
    if (!answer.completed) {
      final error = answer.firstMessage;
      final code = error?.code ?? '';
      final desc = error?.desc ?? '';
      if (code == FinishMessageCode.syncError) {
        await _alert(context, code, desc, ok: 'RETRY');
        continue;
      }
      if (code == FinishMessageCode.timeout) {
        await _alert(context, code, desc);
        await onSignOut();
        return;
      }
      await _alert(context, 'Error ! $code', desc);
      return;
    }

    for (final job in printJobsFor(answer.documents)) {
      if (!context.mounted) return;
      await _alert(
        context,
        job.title,
        '[${job.index}/${job.count}]',
        id: PaymentIds.printPage,
        okId: PaymentIds.printPageOk,
      );
      try {
        if (job.isImage) {
          await viewModel.slipPrinter.printImageUrl(job.value);
        } else {
          await viewModel.slipPrinter.printText(job.value);
        }
      } on Exception catch (e) {
        if (!context.mounted) return;
        await _alert(
          context,
          'Printing failed',
          '$e',
          id: PaymentIds.printFailed,
        );
      }
    }
    await onSignOut();
    return;
  }
}

Future<T> _whileLoading<T>(
  BuildContext context,
  String message,
  Future<T> future,
) async {
  final navigator = Navigator.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => TestId(
      PaymentIds.printLoading,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
  try {
    return await future;
  } finally {
    navigator.pop();
  }
}

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
  String? okId,
  String ok = 'OK',
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (context) => TestId(
    id,
    child: AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        _maybeId(
          okId,
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ok),
          ),
        ),
      ],
    ),
  ),
);

Widget _maybeId(String? id, Widget child) =>
    id == null ? child : TestId(id, child: child);

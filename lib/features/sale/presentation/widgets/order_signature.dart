import 'package:flutter/material.dart';

import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../handheld/payment/signature_page.dart';
import '../sale_cart_view_model.dart';
import '../sale_currency.dart';

/// Legacy Checkout's `goSignaturePage()`: the signature comes after
/// payment. With anything left to pay it alerts "Please pay first.";
/// otherwise it opens the pad with the signatures taken before and keeps
/// what Save returns ([SaleCartViewModel.signature]). Cancel keeps the
/// earlier signature, as legacy does.
Future<void> captureOrderSignature(
  BuildContext context,
  SaleCartViewModel viewModel,
) async {
  if (viewModel.remainingToPay != 0) {
    await _alert(context, 'Error', 'Please pay first.');
    return;
  }
  final capture = await openSignaturePage(
    context,
    netPay: orderNetPay(viewModel.cart),
    initial: viewModel.signature,
  );
  if (capture == null) return;
  viewModel
    ..signature = capture
    ..update();
}

/// Legacy `onFinishPayment()`'s first check: an order that requires a
/// signature can't finish without one — "This shopping card is require
/// signature." True when it may go on.
Future<bool> confirmSignedBeforeFinish(
  BuildContext context,
  SaleCartViewModel viewModel,
) async {
  if (!viewModel.signatureMissing) return true;
  await _alert(context, 'Warning!', 'This shopping card is require signature.');
  return false;
}

Future<void> _alert(BuildContext context, String title, String message) =>
    showDialog<void>(
      context: context,
      builder: (context) => TestId(
        SignatureIds.alert,
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

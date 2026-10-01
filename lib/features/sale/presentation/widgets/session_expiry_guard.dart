import 'package:flutter/material.dart';

import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../sale_cart_view_model.dart';

/// Legacy Checkout's `SESSION_EXPIRE` handling: once any sale-engine call
/// reports the session gone ([SaleCartViewModel.sessionExpired]), it tells
/// the cashier and logs out ([onSignOut]) — the app then shows the login
/// page. Wraps a page that rebuilds on the view model's updates.
class SessionExpiryGuard extends StatefulWidget {
  final SaleCartViewModel viewModel;
  final Future<void> Function()? onSignOut;
  final Widget child;

  const SessionExpiryGuard({
    super.key,
    required this.viewModel,
    required this.onSignOut,
    required this.child,
  });

  @override
  State<SessionExpiryGuard> createState() => _SessionExpiryGuardState();
}

class _SessionExpiryGuardState extends State<SessionExpiryGuard> {
  Future<void> _signOut() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TestId(
        CheckoutIds.sessionExpiredDialog,
        child: AlertDialog(
          title: const Text('Session expired'),
          content: const Text('Your session has expired. Please log in again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    await widget.onSignOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    if (viewModel.sessionExpired && !viewModel.sessionExpiryHandled) {
      viewModel.sessionExpiryHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _signOut();
      });
    }
    return widget.child;
  }
}

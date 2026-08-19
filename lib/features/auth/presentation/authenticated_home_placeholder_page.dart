import 'package:flutter/material.dart';

import '../../../core/app/session_state.dart';
import '../../../core/presentation/widgets/app_buttons.dart';
import '../domain/usecases/logout_usecase.dart';

/// Route target for `/home` once authenticated. The real home/dashboard
/// workflow is out of scope for task 4.1 (auth/context/settings/logout) —
/// this exists so logout has somewhere to be exercised from until the
/// sale/customer workflows (task 4.x) land.
class AuthenticatedHomePlaceholderPage extends StatelessWidget {
  final SessionState sessionState;
  final LogoutUseCase logoutUseCase;

  const AuthenticatedHomePlaceholderPage({
    super.key,
    required this.sessionState,
    required this.logoutUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Home (placeholder — see task 4.x / 6.4)'),
            const SizedBox(height: 16),
            AppSecondaryButton(
              label: 'Log out',
              onPressed: () async {
                await logoutUseCase();
                sessionState.signedOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}

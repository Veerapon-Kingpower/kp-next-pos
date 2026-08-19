import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/app_buttons.dart';
import 'package:kp_pos/core/presentation/widgets/app_shell.dart';
import 'package:kp_pos/core/presentation/widgets/status_chip.dart';
import 'package:kp_pos/core/theme/app_theme.dart';
import 'package:kp_pos/core/theme/transaction_status.dart';

/// Golden (reference-image) tests for the shared component states built in
/// task 3.3, verifying the responsive Android/Windows layouts from task
/// 3.4. Baselines were generated in this environment with
/// `flutter test --update-goldens` and are only guaranteed to reproduce
/// byte-for-byte on a machine with matching font rendering/DPI — CI must
/// regenerate its own baselines rather than reuse these blindly.
void main() {
  Future<void> pumpSized(
    WidgetTester tester,
    Widget child,
    Size size, {
    bool wrapInScaffold = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final home = wrapInScaffold ? Scaffold(body: child) : child;
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: home));
  }

  testWidgets('AppShell — Android touch-first (narrow, bottom navigation)', (
    tester,
  ) async {
    await pumpSized(
      tester,
      const AppShell(
        title: 'Sale',
        body: Center(child: Text('cart contents')),
        destinations: [
          AppNavDestination(icon: Icons.point_of_sale, label: 'Sale'),
          AppNavDestination(icon: Icons.people, label: 'Customer'),
        ],
      ),
      const Size(400, 700),
      wrapInScaffold: false,
    );

    await expectLater(
      find.byType(AppShell),
      matchesGoldenFile('goldens/app_shell_narrow.png'),
    );
  });

  testWidgets(
    'AppShell — Windows keyboard/scanner-first (wide, navigation rail)',
    (tester) async {
      await pumpSized(
        tester,
        const AppShell(
          title: 'Sale',
          body: Center(child: Text('cart contents')),
          destinations: [
            AppNavDestination(icon: Icons.point_of_sale, label: 'Sale'),
            AppNavDestination(icon: Icons.people, label: 'Customer'),
          ],
        ),
        const Size(1024, 700),
        wrapInScaffold: false,
      );

      await expectLater(
        find.byType(AppShell),
        matchesGoldenFile('goldens/app_shell_wide.png'),
      );
    },
  );

  testWidgets('StatusChip — every transaction status state', (tester) async {
    await pumpSized(
      tester,
      Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TransactionStatus.values
              .map((s) => StatusChip(status: s))
              .toList(growable: false),
        ),
      ),
      const Size(500, 300),
    );

    await expectLater(
      find.byType(Wrap),
      matchesGoldenFile('goldens/status_chips_all_states.png'),
    );
  });

  testWidgets('AppPrimaryButton — enabled and disabled', (tester) async {
    await pumpSized(
      tester,
      const Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppPrimaryButton(label: 'Save', onPressed: null),
            SizedBox(height: 8),
            _EnabledPrimaryButton(),
          ],
        ),
      ),
      const Size(220, 120),
    );

    await expectLater(
      find.byType(Column),
      matchesGoldenFile('goldens/app_primary_button_states.png'),
    );
  });
}

class _EnabledPrimaryButton extends StatelessWidget {
  const _EnabledPrimaryButton();

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(label: 'Save', onPressed: () {});
  }
}

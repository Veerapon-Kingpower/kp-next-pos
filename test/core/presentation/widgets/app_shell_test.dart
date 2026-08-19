import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/app_shell.dart';

void main() {
  testWidgets(
    'renders the title, body, and navigation destinations, and reports selection',
    (tester) async {
      int? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            title: 'Sale',
            body: const Text('cart contents'),
            destinations: const [
              AppNavDestination(icon: Icons.point_of_sale, label: 'Sale'),
              AppNavDestination(icon: Icons.people, label: 'Customer'),
            ],
            onDestinationSelected: (index) => selected = index,
          ),
        ),
      );

      expect(find.text('Sale'), findsWidgets);
      expect(find.text('cart contents'), findsOneWidget);
      expect(find.text('Customer'), findsOneWidget);

      await tester.tap(find.text('Customer'));
      await tester.pump();

      expect(selected, 1);
    },
  );

  testWidgets('omits the navigation bar when no destinations are provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppShell(title: 'Detail', body: Text('content')),
      ),
    );

    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets(
    'uses a bottom NavigationBar below the wide breakpoint (Android touch-first)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(
            title: 'Sale',
            body: Text('cart contents'),
            destinations: [
              AppNavDestination(icon: Icons.point_of_sale, label: 'Sale'),
              AppNavDestination(icon: Icons.people, label: 'Customer'),
            ],
          ),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    },
  );

  testWidgets(
    'uses a persistent NavigationRail at/above the wide breakpoint (Windows keyboard/scanner-first)',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            title: 'Sale',
            body: const Text('cart contents'),
            destinations: const [
              AppNavDestination(icon: Icons.point_of_sale, label: 'Sale'),
              AppNavDestination(icon: Icons.people, label: 'Customer'),
            ],
            onDestinationSelected: (index) => selected = index,
          ),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.text('Customer'));
      await tester.pump();

      expect(selected, 1);
    },
  );
}

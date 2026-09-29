import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/desktop/desktop.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/core/theme/app_colors.dart';

import '../../../helpers/test_id_finders.dart';

void main() {
  group('DesktopShell', () {
    Future<List<String>> pumpShell(
      WidgetTester tester, {
      int selected = 0,
    }) async {
      final events = <String>[];
      setDeviceSize(tester, const Size(1440, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: DesktopShell(
            items: const [
              DesktopNavItem(
                id: NavIds.home,
                icon: Icons.home_outlined,
                label: 'Home',
              ),
              DesktopNavItem(
                id: NavIds.sale,
                icon: Icons.shopping_bag_outlined,
                label: 'Sale',
              ),
            ],
            selectedIndex: selected,
            onSelected: (i) => events.add('select $i'),
            footerItems: [
              DesktopNavItem(
                id: NavIds.signOut,
                icon: Icons.logout,
                label: 'Sign out',
                onTap: () => events.add('signOut'),
              ),
            ],
            title: 'Home',
            subtitle: 'Shift overview',
            contextItems: const [
              DesktopContextItem(label: 'Store', value: 'Downtown'),
              DesktopContextItem(label: 'Machine', value: 'RN-POS-0412'),
            ],
            user: const DesktopUser(
              name: 'Somchai R.',
              detail: 'Cashier · U001',
            ),
            body: const Text('body'),
          ),
        ),
      );
      return events;
    }

    testWidgets('ink rail, top bar context, user chip and body', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpShell(tester);

      expect(find.text('body'), findsOneWidget);
      expect(find.text('Shift overview'), findsOneWidget);
      expect(find.text('Store Downtown', findRichText: true), findsOneWidget);
      expect(
        find.text('Machine RN-POS-0412', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: byTestId(DesktopIds.userChip),
          matching: find.text('SR'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(byTestId(NavIds.home)),
        isSemantics(isSelected: true, isButton: true),
      );
      final rail = tester.widget<ColoredBox>(
        find
            .ancestor(
              of: byTestId(NavIds.home),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(rail.color, AppColors.ink);
      expect(
        tester.getSize(find.byType(DesktopRail)).width,
        DesktopMetrics.railWidth,
      );
      handle.dispose();
    });

    testWidgets('rail taps report the index; footer items run their action', (
      tester,
    ) async {
      final events = await pumpShell(tester);
      await tester.tap(byTestId(NavIds.sale));
      await tester.tap(byTestId(NavIds.signOut));
      expect(events, ['select 1', 'signOut']);
    });

    testWidgets('fits a 1024 dp iPad-portrait-Pro width without overflow', (
      tester,
    ) async {
      await pumpShell(tester);
      setDeviceSize(tester, const Size(1024, 1366));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('DesktopPanel / DesktopActionTile / buttons', () {
    testWidgets('panel title is a gold caps label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DesktopPanel(
              id: 'x.panel',
              title: 'Terminal identity',
              child: Text('content'),
            ),
          ),
        ),
      );
      expect(find.text('TERMINAL IDENTITY'), findsOneWidget);
      expect(byTestId('x.panel'), findsOneWidget);
    });

    testWidgets('action tile shows its hotkey and fires', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: DesktopActionTile(
                id: 'x.tile',
                icon: Icons.shopping_bag_outlined,
                title: 'Sale',
                subtitle: 'Walk-in, take or collect',
                hotkey: 'F2',
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      );
      expect(find.text('F2'), findsOneWidget);
      await tester.tap(byTestId('x.tile'));
      expect(taps, 1);
    });

    testWidgets('primary / secondary buttons, hotkey chip, disabled state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DesktopButton(
                  id: 'x.primary',
                  label: 'Sign in',
                  hotkey: 'ENTER',
                  onPressed: () => taps++,
                ),
                const DesktopButton(
                  id: 'x.secondary',
                  label: 'Reprint',
                  icon: Icons.print_outlined,
                  secondary: true,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('ENTER'), findsOneWidget);
      await tester.tap(byTestId('x.primary'));
      expect(taps, 1);
      expect(
        tester.getSemantics(byTestId('x.secondary')),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });
  });
}

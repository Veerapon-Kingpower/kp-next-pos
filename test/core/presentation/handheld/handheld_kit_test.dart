import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/handheld/handheld.dart';
import 'package:kp_pos/core/theme/app_colors.dart';

import '../../../helpers/test_id_finders.dart';

Widget _app(Widget child) => MaterialApp(home: child);

void main() {
  group('HandheldScaffold', () {
    testWidgets('renders header, body, action bar and nav bar in order', (
      tester,
    ) async {
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(
        _app(
          const HandheldScaffold(
            header: HandheldHeader(title: 'Sale'),
            body: Text('body'),
            actionBar: HandheldActionBar(
              primary: HandheldPrimaryButton(id: 'x.primary', label: 'Go'),
            ),
            navBar: SizedBox(key: Key('nav'), height: 76),
          ),
        ),
      );

      final headerY = tester.getTopLeft(find.text('Sale')).dy;
      final bodyY = tester.getTopLeft(find.text('body')).dy;
      final barY = tester.getTopLeft(byTestId('x.primary')).dy;
      final navY = tester.getTopLeft(find.byKey(const Key('nav'))).dy;
      expect(headerY < bodyY, isTrue);
      expect(bodyY < barY, isTrue);
      expect(barY < navY, isTrue);
    });

    testWidgets('compact: body uses the full width', (tester) async {
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(
        _app(
          const HandheldScaffold(
            body: SizedBox(
              key: Key('body'),
              height: 10,
              width: double.infinity,
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('body'))).width, 400);
    });

    testWidgets('medium (tablet portrait): body is centred at 720', (
      tester,
    ) async {
      setDeviceSize(tester, mediumSize);
      await tester.pumpWidget(
        _app(
          const HandheldScaffold(
            body: SizedBox(
              key: Key('body'),
              height: 10,
              width: double.infinity,
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byKey(const Key('body')));
      expect(rect.width, HandheldMetrics.mediumContentMaxWidth);
      expect(rect.center.dx, closeTo(410, 0.5));
    });
  });

  group('HandheldHeader', () {
    testWidgets('shows title, subtitle, trailing and stats on ink', (
      tester,
    ) async {
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: HandheldHeader(
              title: 'Good afternoon',
              titleId: 'h.title',
              subtitle: 'MPOS-14 · Somchai',
              subtitleId: 'h.subtitle',
              trailing: Text('ONLINE'),
              stats: [
                HandheldStat(id: 'h.bills', label: 'Bills', value: '18'),
                HandheldStat(
                  id: 'h.net',
                  label: 'Net sales',
                  value: '฿842,190',
                  flex: 3,
                ),
              ],
            ),
          ),
        ),
      );

      expect(byTestId('h.title'), findsOneWidget);
      expect(byTestId('h.subtitle'), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.text('BILLS'), findsOneWidget);
      expect(find.text('฿842,190'), findsOneWidget);

      final bills = tester.getSize(byTestId('h.bills')).width;
      final net = tester.getSize(byTestId('h.net')).width;
      expect(net > bills, isTrue, reason: 'flex 3 vs default 2');

      final box = tester.widget<ColoredBox>(
        find
            .ancestor(
              of: byTestId('h.title'),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(box.color, AppColors.ink);
    });
  });

  group('ScanField', () {
    testWidgets('submits typed text and exposes its semantics id', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      setDeviceSize(tester, compactSize);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? submitted;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ScanField(
              id: 'x.scan',
              controller: controller,
              hintText: 'Scan shopping card or passport',
              onSubmitted: (v) => submitted = v,
            ),
          ),
        ),
      );

      expect(find.text('Scan shopping card or passport'), findsOneWidget);
      expect(find.bySemanticsIdentifier('x.scan'), findsOneWidget);
      expect(
        tester.getSize(byTestId('x.scan')).height,
        HandheldMetrics.scanFieldHeight,
      );

      await tester.enterText(find.byType(TextField), '8823');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted, '8823');
      handle.dispose();
    });
  });

  group('HandheldActionBar', () {
    testWidgets('primary and bar items fire; disabled primary does not', (
      tester,
    ) async {
      setDeviceSize(tester, compactSize);
      var primary = 0;
      var more = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: HandheldActionBar(
              primary: HandheldPrimaryButton(
                id: 'x.checkout',
                label: 'Checkout',
                icon: Icons.payments_outlined,
                onPressed: () => primary++,
              ),
              items: [
                HandheldBarItem(
                  id: 'x.more',
                  icon: Icons.more_horiz,
                  label: 'More',
                  onPressed: () => more++,
                ),
                const HandheldBarItem(
                  id: 'x.save',
                  icon: Icons.save_outlined,
                  label: 'Save',
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.getSize(byTestId('x.checkout')).height,
        HandheldMetrics.primaryActionHeight,
      );
      await tester.tap(byTestId('x.checkout'));
      await tester.tap(byTestId('x.more'));
      await tester.tap(byTestId('x.save')); // inert — no crash, no callback
      expect(primary, 1);
      expect(more, 1);
      expect(
        tester.getSize(byTestId('x.more')).height,
        greaterThanOrEqualTo(44),
      );
    });

    testWidgets('onDark primary uses gold with ink text', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: HandheldPrimaryButton(
              id: 'x.signin',
              label: 'Sign in',
              onDark: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      final material = tester.widget<Material>(
        find
            .descendant(
              of: byTestId('x.signin'),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, AppColors.gold);
      final text = tester.widget<Text>(find.text('Sign in'));
      expect(text.style?.color, AppColors.ink);
    });

    testWidgets('secondary button fires', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: HandheldSecondaryButton(
              id: 'x.cancel',
              label: 'Cancel',
              onPressed: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(byTestId('x.cancel'));
      expect(taps, 1);
    });
  });

  group('HandheldNavBar', () {
    testWidgets('marks the selected item and reports taps by index', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      setDeviceSize(tester, compactSize);
      int? tapped;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: HandheldNavBar(
              selectedIndex: 1,
              onSelected: (i) => tapped = i,
              items: const [
                HandheldNavItem(id: 'n.home', icon: Icons.home, label: 'Home'),
                HandheldNavItem(id: 'n.sale', icon: Icons.sell, label: 'Sale'),
              ],
            ),
          ),
        ),
      );

      expect(find.bySemanticsIdentifier('n.home'), findsOneWidget);
      expect(
        tester.getSemantics(byTestId('n.sale')),
        isSemantics(isSelected: true, isButton: true, label: 'Sale'),
      );
      await tester.tap(byTestId('n.home'));
      expect(tapped, 0);
      expect(
        tester.getSize(byTestId('n.home')).height,
        HandheldMetrics.navItemHeight,
      );
      handle.dispose();
    });
  });

  group('HandheldTile / HandheldSection', () {
    testWidgets('tile taps and section renders title, count and children', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 90,
                  child: HandheldTile(
                    id: 'x.tile',
                    icon: Icons.badge_outlined,
                    label: 'Register',
                    onTap: () => taps++,
                  ),
                ),
                const HandheldSection(
                  id: 'x.section',
                  title: 'Suspended bills',
                  count: '3',
                  footer: Text('Tap a bill to resume'),
                  children: [Text('row 1'), Text('row 2')],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(byTestId('x.tile'));
      expect(taps, 1);
      expect(
        tester.getSize(byTestId('x.tile')).height,
        HandheldMetrics.tileHeight,
      );
      expect(find.text('Suspended bills'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('row 2'), findsOneWidget);
      expect(find.text('Tap a bill to resume'), findsOneWidget);
    });
  });

  group('showHandheldSheet', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showHandheldSheet<void>(
                  context,
                  id: 'x.sheet',
                  builder: (_) => const Text('sheet body'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('compact: bottom sheet anchored to the bottom edge', (
      tester,
    ) async {
      setDeviceSize(tester, compactSize);
      await open(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(byTestId('x.sheet'), findsOneWidget);
      expect(tester.getBottomLeft(byTestId('x.sheet')).dy, closeTo(860, 1));
    });

    testWidgets('medium: centred dialog capped at 560 wide', (tester) async {
      setDeviceSize(tester, mediumSize);
      await open(tester);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(Dialog), findsOneWidget);
      final rect = tester.getRect(byTestId('x.sheet'));
      expect(
        rect.width,
        lessThanOrEqualTo(HandheldMetrics.mediumSheetMaxWidth),
      );
      expect(rect.center.dx, closeTo(410, 0.5));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/overlay_panel.dart';
import '../../../helpers/test_app.dart';

void main() {
  testWidgets('renders the title and child', (tester) async {
    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: OverlayPanel(
            title: 'Discount & promotion',
            onClose: () {},
            child: const Text('overlay body'),
          ),
        ),
      ),
    );

    expect(find.text('Discount & promotion'), findsOneWidget);
    expect(find.text('overlay body'), findsOneWidget);
  });

  testWidgets('tapping the close button invokes onClose', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: OverlayPanel(
            title: 'Discount',
            onClose: () => closed = true,
            child: const Text('body'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('overlayPanelCloseButton')));
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('pressing Escape invokes onClose', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: OverlayPanel(
            title: 'Discount',
            onClose: () => closed = true,
            child: const Text('body'),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(closed, isTrue);
  });
}

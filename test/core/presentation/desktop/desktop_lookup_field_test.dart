import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/desktop/desktop.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';

import '../../../helpers/test_id_finders.dart';

class _Item {
  final String code;
  final String name;
  const _Item(this.code, this.name);
}

const _items = [
  _Item('TG916', 'Bangkok → Frankfurt'),
  _Item('TG920', 'Bangkok → London'),
  _Item('TG930', 'Bangkok → Zurich'),
];

const _fieldId = 'test.lookup';

void main() {
  late List<String> queries;
  late List<_Item> picked;

  Future<List<_Item>> search(String query) async {
    queries.add(query);
    final q = query.toLowerCase();
    return _items
        .where(
          (i) =>
              i.code.toLowerCase().contains(q) ||
              i.name.toLowerCase().contains(q),
        )
        .toList();
  }

  setUp(() {
    queries = [];
    picked = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    _Item? value,
    bool enabled = true,
    VoidCallback? onCleared,
    Future<List<_Item>> Function(String)? searchFn,
  }) async {
    setDeviceSize(tester, const Size(1280, 800));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: 420,
                  child: DesktopLookupField<_Item>(
                    id: _fieldId,
                    label: 'Flight code',
                    required: true,
                    value: value,
                    enabled: enabled,
                    disabledHint: 'Choose an agent first',
                    search: searchFn ?? search,
                    code: (i) => i.code,
                    name: (i) => i.name,
                    onSelected: picked.add,
                    onCleared: onCleared,
                  ),
                ),
                const SizedBox(width: 420, child: TextField(key: Key('next'))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Finder input() =>
      find.descendant(of: byTestId(_fieldId), matching: find.byType(TextField));

  Finder option(int i) => byTestId(DesktopLookupIds.option(_fieldId, i));

  Future<void> typeAndWait(WidgetTester tester, String text) async {
    await tester.tap(input());
    await tester.enterText(input(), text);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  testWidgets('label carries the required marker', (tester) async {
    await pump(tester);
    expect(find.text('FLIGHT CODE *'), findsOneWidget);
  });

  testWidgets('typing filters and pre-selects the first match', (tester) async {
    await pump(tester);
    await typeAndWait(tester, 'tg9');

    expect(queries, ['tg9']);
    expect(option(0), findsOneWidget);
    expect(option(2), findsOneWidget);
    expect(
      tester.getSemantics(option(0)),
      isSemantics(isSelected: true, isButton: true, hasTapAction: true),
    );
    expect(find.text('3 matches · Enter to pick'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(picked.single.code, 'TG916');
    expect(option(0), findsNothing);
  });

  testWidgets('arrow keys move the selection; Enter picks and advances focus', (
    tester,
  ) async {
    await pump(tester);
    await typeAndWait(tester, 'bangkok');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(picked.single.code, 'TG920');
    expect(tester.widget<TextField>(input()).controller!.text, 'TG920');
    final next = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('next')),
        matching: find.byType(EditableText),
      ),
    );
    expect(next.focusNode.hasFocus, isTrue);
  });

  testWidgets('Esc closes the list and restores the committed value', (
    tester,
  ) async {
    await pump(tester, value: _items[1]);
    expect(tester.widget<TextField>(input()).controller!.text, 'TG920');

    await typeAndWait(tester, 'zur');
    expect(option(0), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(option(0), findsNothing);
    expect(picked, isEmpty);
    expect(tester.widget<TextField>(input()).controller!.text, 'TG920');
  });

  testWidgets('an exact code typed in full commits without opening the list', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(input());
    await tester.enterText(input(), 'tg930');
    // Enter before the debounce fires.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(picked.single.code, 'TG930');
    expect(option(0), findsNothing);
    await tester.pump(const Duration(milliseconds: 400));
    expect(option(0), findsNothing);
  });

  testWidgets('tapping an option picks it', (tester) async {
    await pump(tester);
    await typeAndWait(tester, 'tg');
    await tester.tap(option(2));
    await tester.pump();
    expect(picked.single.code, 'TG930');
  });

  testWidgets('the magnifier opens the list without typing', (tester) async {
    await pump(tester);
    await tester.tap(byTestId(DesktopLookupIds.open(_fieldId)));
    await tester.pump();
    expect(queries, ['']);
    expect(option(0), findsOneWidget);
  });

  testWidgets('a failed search shows no matches instead of hanging', (
    tester,
  ) async {
    await pump(tester, searchFn: (_) async => throw Exception('offline'));
    await typeAndWait(tester, 'x');
    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('disabled shows its reason and cannot be edited', (tester) async {
    await pump(tester, enabled: false);
    expect(find.text('Choose an agent first'), findsOneWidget);
    expect(tester.widget<TextField>(input()).enabled, isFalse);
  });

  testWidgets('the clear button drops the value and closes the list', (
    tester,
  ) async {
    var cleared = 0;
    await pump(tester, value: _items[0], onCleared: () => cleared++);
    final clear = byTestId(FieldIds.clear(_fieldId));
    expect(clear, findsOneWidget);

    await typeAndWait(tester, 'tg9');
    expect(option(0), findsOneWidget);
    await tester.tap(clear);
    await tester.pump();

    expect(cleared, 1);
    expect(tester.widget<TextField>(input()).controller!.text, isEmpty);
    expect(option(0), findsNothing);
  });

  testWidgets('no clear button without onCleared', (tester) async {
    await pump(tester, value: _items[0]);
    expect(byTestId(FieldIds.clear(_fieldId)), findsNothing);
  });

  testWidgets('a new value from the parent replaces the text', (tester) async {
    await pump(tester, value: _items[0]);
    await pump(tester, value: _items[2]);
    expect(tester.widget<TextField>(input()).controller!.text, 'TG930');
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/autocomplete_field.dart';

void main() {
  Widget buildSubject({
    required Future<List<String>> Function(String query) search,
    required ValueChanged<String> onSelected,
    String? initialText,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AutocompleteField<String>(
          label: 'Nationality',
          hintText: 'Type to search',
          initialText: initialText,
          search: search,
          itemLabel: (item) => item,
          onSelected: onSelected,
        ),
      ),
    );
  }

  testWidgets('typing shows suggestions inline once the debounce elapses', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        search: (query) async => const ['Thailand', 'Taiwan'],
        onSelected: (_) {},
      ),
    );

    await tester.enterText(find.byType(TextField), 'th');
    // Before the debounce elapses, nothing has been searched yet.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Thailand'), findsNothing);

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();

    expect(find.text('Thailand'), findsOneWidget);
    expect(find.text('Taiwan'), findsOneWidget);
  });

  testWidgets('rapid typing only searches once, with the settled query', (
    tester,
  ) async {
    final queries = <String>[];
    await tester.pumpWidget(
      buildSubject(
        search: (query) async {
          queries.add(query);
          return const ['Thailand'];
        },
        onSelected: (_) {},
      ),
    );

    await tester.enterText(find.byType(TextField), 't');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'th');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'tha');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(queries, ['THA']); // typed text is upper-cased
  });

  testWidgets(
    'tapping a suggestion fills the field, calls onSelected, and clears the suggestions',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        buildSubject(
          search: (query) async => const ['Thailand'],
          onSelected: (value) => selected = value,
        ),
      );

      await tester.enterText(find.byType(TextField), 'tha');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.byType(ListTile), findsOneWidget);

      await tester.tap(find.text('Thailand'));
      await tester.pump();

      expect(selected, 'Thailand');
      expect(find.byType(ListTile), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Thailand',
      );
    },
  );

  testWidgets('an empty result list shows no suggestions box', (tester) async {
    await tester.pumpWidget(
      buildSubject(search: (query) async => const [], onSelected: (_) {}),
    );

    await tester.enterText(find.byType(TextField), 'zz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets(
    'shows a loading indicator while the search is in flight, then swaps to results',
    (tester) async {
      final completer = Completer<List<String>>();
      await tester.pumpWidget(
        buildSubject(search: (query) => completer.future, onSelected: (_) {}),
      );

      await tester.enterText(find.byType(TextField), 'th');
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);

      completer.complete(const ['Thailand']);
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Thailand'), findsOneWidget);
    },
  );

  testWidgets(
    'a search that fails after being in flight clears the loading state instead of leaving it stuck',
    (tester) async {
      final completer = Completer<List<String>>();
      await tester.pumpWidget(
        buildSubject(search: (query) => completer.future, onSelected: (_) {}),
      );

      await tester.enterText(find.byType(TextField), 'th');
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.completeError(Exception('network down'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ListTile), findsNothing);
    },
  );

  testWidgets('shows the initial text when provided', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        search: (query) async => const [],
        onSelected: (_) {},
        initialText: 'Thailand',
      ),
    );

    expect(find.text('Thailand'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/desktop_data_table.dart';

void main() {
  testWidgets('renders column headers and one row per data row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopDataTable(
            columns: const [
              DesktopDataColumn(label: 'Item'),
              DesktopDataColumn(label: 'Qty'),
            ],
            rows: [
              [const Text('Cola 500ml'), const Text('2')],
              [const Text('Water 1L'), const Text('1')],
            ],
          ),
        ),
      ),
    );

    expect(find.text('Item'), findsOneWidget);
    expect(find.text('Qty'), findsOneWidget);
    expect(find.text('Cola 500ml'), findsOneWidget);
    expect(find.text('Water 1L'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('shows the empty placeholder when there are no rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopDataTable(
            columns: const [DesktopDataColumn(label: 'Item')],
            rows: const [],
            emptyPlaceholder: const Text('No items yet'),
          ),
        ),
      ),
    );

    expect(find.text('No items yet'), findsOneWidget);
    expect(find.text('Item'), findsNothing);
  });

  testWidgets('keepHeaderWhenEmpty shows headers above the placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DesktopDataTable(
            columns: [DesktopDataColumn(label: 'Item')],
            rows: [],
            emptyPlaceholder: Text('No items yet'),
            keepHeaderWhenEmpty: true,
          ),
        ),
      ),
    );
    expect(find.text('Item'), findsOneWidget);
    expect(find.text('No items yet'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Item')).dy <
          tester.getTopLeft(find.text('No items yet')).dy,
      isTrue,
    );
  });
}

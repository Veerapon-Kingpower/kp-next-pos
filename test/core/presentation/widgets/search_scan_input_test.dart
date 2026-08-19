import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/search_scan_input.dart';

void main() {
  testWidgets(
    'shows the hint text and invokes onScanPressed when the scan icon is tapped',
    (tester) async {
      final controller = TextEditingController();
      var scanned = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchScanInput(
              controller: controller,
              hintText: 'Search or scan',
              onScanPressed: () => scanned = true,
            ),
          ),
        ),
      );

      expect(find.text('Search or scan'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.qr_code_scanner));
      await tester.pump();

      expect(scanned, isTrue);
    },
  );

  testWidgets('submitting text invokes onSubmitted with the entered value', (
    tester,
  ) async {
    final controller = TextEditingController();
    String? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScanInput(
            controller: controller,
            onSubmitted: (value) => submitted = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'ART001');
    await tester.testTextInput.receiveAction(TextInputAction.search);

    expect(submitted, 'ART001');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/app_buttons.dart';

void main() {
  testWidgets('AppPrimaryButton shows its label and invokes onPressed', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(
            label: 'Save',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('AppSecondaryButton shows its label and invokes onPressed', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSecondaryButton(
            label: 'Cancel',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('AppDestructiveButton shows its label and invokes onPressed', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDestructiveButton(
            label: 'Delete',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('a null onPressed disables the button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppPrimaryButton(label: 'Save', onPressed: null)),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}

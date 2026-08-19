import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/app_text_field.dart';

void main() {
  testWidgets('shows the label, error text, and reports changes', (
    tester,
  ) async {
    final controller = TextEditingController();
    String? changed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: 'Customer name',
            errorText: 'Required',
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );

    expect(find.text('Customer name'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'John');

    expect(changed, 'John');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/wizard_step_bar.dart';
import '../../../helpers/test_app.dart';

void main() {
  testWidgets('renders the title and the current/total step count', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: WizardStepBar(title: 'Checkout', currentStep: 2, totalSteps: 3),
        ),
      ),
    );

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Step 2 of 3'), findsOneWidget);
  });
}

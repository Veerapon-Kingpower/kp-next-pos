import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/loading_view.dart';
import '../../../helpers/test_app.dart';

void main() {
  testWidgets('shows a spinner, and the message when provided', (tester) async {
    await tester.pumpWidget(TestApp(home: LoadingView()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Text), findsNothing);

    await tester.pumpWidget(
      TestApp(home: LoadingView(message: 'Loading order...')),
    );
    expect(find.text('Loading order...'), findsOneWidget);
  });
}

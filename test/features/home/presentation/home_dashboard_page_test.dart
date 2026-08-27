import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/home/presentation/home_dashboard_page.dart';

void main() {
  testWidgets('renders a placeholder message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeDashboardPage()),
    );

    expect(find.textContaining('coming soon'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/status_chip.dart';
import 'package:kp_pos/core/theme/transaction_status.dart';

void main() {
  testWidgets('renders the label and icon for the given status', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusChip(status: TransactionStatus.approved)),
      ),
    );

    expect(find.text('Approved'), findsOneWidget);
    expect(find.byIcon(TransactionStatus.approved.style.icon), findsOneWidget);
  });
}

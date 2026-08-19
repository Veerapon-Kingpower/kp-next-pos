import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/theme/transaction_status.dart';

void main() {
  test(
    'every status has a non-empty label and an icon distinct from every other status',
    () {
      final seenIcons = <dynamic>{};

      for (final status in TransactionStatus.values) {
        final style = status.style;
        expect(style.label, isNotEmpty, reason: '$status has no label');
        expect(
          seenIcons.add(style.icon),
          isTrue,
          reason: '$status reuses an icon already used by another status',
        );
      }
    },
  );

  test('finalized and failed are visually distinct (not just by colour)', () {
    expect(
      TransactionStatus.finalized.style.icon,
      isNot(TransactionStatus.failed.style.icon),
    );
    expect(
      TransactionStatus.finalized.style.color,
      isNot(TransactionStatus.failed.style.color),
    );
  });
}

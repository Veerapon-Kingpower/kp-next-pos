import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/theme/app_breakpoints.dart';

void main() {
  group('AppBreakpoints.sizeClassForWidth', () {
    final cases = {
      360.0: AppSizeClass.compact, // small phone
      400.0: AppSizeClass.compact, // Sunmi V2 handheld
      599.9: AppSizeClass.compact,
      600.0: AppSizeClass.medium, // small Android tablet portrait
      744.0: AppSizeClass.medium, // iPad mini portrait
      820.0: AppSizeClass.medium, // iPad Air portrait
      834.0: AppSizeClass.medium, // iPad Pro 11 portrait
      839.9: AppSizeClass.medium,
      840.0: AppSizeClass.expanded,
      1024.0: AppSizeClass.expanded, // iPad Pro 12.9 portrait / iPad landscape
      1366.0: AppSizeClass.expanded, // iPad Pro 12.9 landscape
    };

    for (final entry in cases.entries) {
      test('${entry.key} dp -> ${entry.value.name}', () {
        expect(AppBreakpoints.sizeClassForWidth(entry.key), entry.value);
      });
    }
  });

  testWidgets('sizeClass reads the MediaQuery width', (tester) async {
    late AppSizeClass seen;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(820, 1180)),
        child: Builder(
          builder: (context) {
            seen = AppBreakpoints.sizeClass(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen, AppSizeClass.medium);
  });

  test('isWide stays consistent with the expanded size class', () {
    expect(AppBreakpoints.wide, AppBreakpoints.sizeClassExpandedMin);
  });
}

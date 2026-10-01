import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/hotkey_tile_grid.dart';
import '../../../helpers/test_app.dart';

void main() {
  testWidgets('renders a tile per entry and invokes its onTap when tapped', (
    tester,
  ) async {
    var saleTapped = false;
    var customerTapped = false;

    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: HotkeyTileGrid(
            tiles: [
              HotkeyTile(
                icon: Icons.point_of_sale,
                label: 'New sale',
                onTap: () => saleTapped = true,
              ),
              HotkeyTile(
                icon: Icons.person_add,
                label: 'Registration',
                onTap: () => customerTapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('New sale'), findsOneWidget);
    expect(find.text('Registration'), findsOneWidget);

    await tester.tap(find.byKey(const Key('hotkeyTile_New sale')));
    await tester.pump();

    expect(saleTapped, isTrue);
    expect(customerTapped, isFalse);
  });
}

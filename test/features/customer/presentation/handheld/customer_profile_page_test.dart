import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/customer/domain/entities/customer.dart';
import 'package:kp_pos/features/customer/domain/entities/privilege.dart';
import 'package:kp_pos/features/customer/presentation/handheld/customer_profile_page.dart';
import 'package:kp_pos/features/flight/domain/entities/flight.dart';

import '../../../../helpers/test_id_finders.dart';

const _gold = Privilege(
  name: 'Gold Member',
  discount: 10,
  typeCode: 'VIP',
  promoCode: 'PROMO123',
);
const _birthday = Privilege(name: 'Birthday voucher', discount: 0);

const sofia = Customer(
  action: 'found',
  isFound: true,
  person: CustomerPerson(
    englishName: 'Sofia Almeida',
    passportNo: 'CB912447',
    nationality: 'PRT',
    contacts: [],
    privileges: [_gold, _birthday],
    walletMembers: [
      {'balance': '4200'},
    ],
    shoppingCard: '8823-4419-0027',
    typeCardMember: 'Elite',
    isActivate: true,
    flightCode: 'TG916',
    flightDate: '2026-08-26',
    flightTime: '23:45',
    flightRouteDetail: 'BKK - FRA',
    flightPickup: 'Pickup D',
    customerTypeCode: 'TOURIST',
    customerTypeDetail: 'Tourist',
  ),
  tour: {},
  agentCode: 'AG1',
  subAgentCode: 'GD1',
  isMember: true,
);

const walkIn = Customer(
  action: 'found',
  isFound: true,
  person: CustomerPerson(
    englishName: 'John Smith',
    passportNo: '',
    nationality: '',
    contacts: [],
    privileges: [],
    walletMembers: [],
  ),
  tour: {},
  agentCode: '',
  isMember: false,
);

void main() {
  late List<Privilege?> attached;
  late int edits;
  late bool attachAllowed;

  setUp(() {
    attached = [];
    edits = 0;
    attachAllowed = true;
  });

  Future<void> open(
    WidgetTester tester, {
    Customer customer = sofia,
    Privilege? selected,
    Size size = compactSize,
  }) async {
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CustomerProfilePage(
                    customer: customer,
                    initialPrivilege: selected,
                    searchFlights: (_) async => const <Flight>[],
                    onAttach: (p) async {
                      attached.add(p);
                      return attachAllowed;
                    },
                    onEdit: () => edits++,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  testWidgets('header: initials, name, member badge, card and status', (
    tester,
  ) async {
    await open(tester);
    expect(byTestId(ProfileIds.page), findsOneWidget);
    expect(find.text('SA'), findsOneWidget);
    expect(textIn(tester, ProfileIds.name), 'Sofia Almeida');
    expect(textIn(tester, ProfileIds.badge), 'ELITE');
    expect(textIn(tester, ProfileIds.cardLine), '8823-4419-0027 · PRT');
    expect(textIn(tester, ProfileIds.status), 'Registered');
  });

  testWidgets('stats: e-Purse from the wallet, the rest unavailable', (
    tester,
  ) async {
    await open(tester);
    expect(textIn(tester, ProfileIds.ePurseStat), '฿4,200.00');
    expect(textIn(tester, ProfileIds.pointsStat), '—');
    expect(textIn(tester, ProfileIds.spendStat), '—');
    expect(textIn(tester, ProfileIds.visitsStat), '—');
  });

  testWidgets('flight card shows the linked flight', (tester) async {
    await open(tester);
    final card = byTestId(ProfileIds.flightCard);
    expect(
      find.descendant(of: card, matching: find.text('TG916 · BKK - FRA')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.textContaining('2026-08-26 23:45'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('privileges are single-select and carried into Attach', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    await tester.ensureVisible(byTestId(ProfileIds.privilege(0)));
    await tester.tap(byTestId(ProfileIds.privilege(0)));
    await tester.pump();
    expect(
      tester.getSemantics(byTestId(ProfileIds.privilege(0))),
      isSemantics(isSelected: true),
    );
    await tester.tap(byTestId(ProfileIds.privilege(1)));
    await tester.pump();
    expect(
      tester.getSemantics(byTestId(ProfileIds.privilege(0))),
      isSemantics(isSelected: false),
    );

    await tester.tap(byTestId(ProfileIds.attachButton));
    await tester.pumpAndSettle();
    expect(attached, [_birthday]);
    expect(byTestId(ProfileIds.page), findsNothing, reason: 'popped');
    handle.dispose();
  });

  testWidgets('tapping the selected privilege again clears it', (tester) async {
    await open(tester, selected: _gold);
    await tester.ensureVisible(byTestId(ProfileIds.privilege(0)));
    await tester.tap(byTestId(ProfileIds.privilege(0)));
    await tester.pump();
    await tester.tap(byTestId(ProfileIds.attachButton));
    await tester.pumpAndSettle();
    expect(attached, [null]);
  });

  testWidgets('a blocked attach keeps the profile open', (tester) async {
    attachAllowed = false;
    await open(tester);
    await tester.tap(byTestId(ProfileIds.attachButton));
    await tester.pumpAndSettle();
    expect(byTestId(ProfileIds.page), findsOneWidget);
  });

  testWidgets('Edit calls back', (tester) async {
    await open(tester);
    await tester.tap(byTestId(ProfileIds.editButton));
    expect(edits, 1);
  });

  testWidgets('Traveller details opens the passport & flight page', (
    tester,
  ) async {
    await open(tester);
    await tester.ensureVisible(byTestId(ProfileIds.travellerButton));
    await tester.tap(byTestId(ProfileIds.travellerButton));
    await tester.pumpAndSettle();
    expect(byTestId(TravellerIds.page), findsOneWidget);
  });

  testWidgets('a sparse walk-in profile degrades gracefully', (tester) async {
    await open(tester, customer: walkIn);
    expect(textIn(tester, ProfileIds.status), 'Not registered');
    expect(byTestId(ProfileIds.badge), findsNothing);
    expect(textIn(tester, ProfileIds.ePurseStat), '—');
    expect(
      find.descendant(
        of: byTestId(ProfileIds.flightCard),
        matching: find.text('No flight linked'),
      ),
      findsOneWidget,
    );
    expect(find.text('No privileges on this card.'), findsOneWidget);
  });

  testWidgets('recent purchases are marked unavailable', (tester) async {
    await open(tester);
    await tester.ensureVisible(byTestId(ProfileIds.recentPurchases));
    expect(
      find.descendant(
        of: byTestId(ProfileIds.recentPurchases),
        matching: find.textContaining('not available yet'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('iPad portrait renders without overflow', (tester) async {
    await open(tester, size: mediumSize);
    expect(tester.takeException(), isNull);
  });
}

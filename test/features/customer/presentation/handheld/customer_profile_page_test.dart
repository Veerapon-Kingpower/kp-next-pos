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
      {'Code': 'CARAT_WALLET', 'PaymentCode': 'CARAT', 'Balance': 1475.0},
      {'Code': 'CASH_WALLET', 'PaymentCode': 'CASHW', 'Balance': 4200.0},
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
  late List<Privilege?> picked;
  late int edits;
  late int sales;

  setUp(() {
    picked = [];
    edits = 0;
    sales = 0;
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
                    onPrivilegeChanged: picked.add,
                    onEdit: () => edits++,
                    onGoToSale: () => sales++,
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

  testWidgets('stats: Carat and e-Purse from their wallets only', (
    tester,
  ) async {
    await open(tester);
    expect(textIn(tester, ProfileIds.caratStat), '1,475.00');
    expect(textIn(tester, ProfileIds.ePurseStat), '฿4,200.00');
    expect(find.text('SPEND YTD'), findsNothing);
    expect(find.text('VISITS'), findsNothing);
    // Sofia's Carat wallet has nothing nearly expired.
    expect(byTestId(ProfileIds.caratExpiring), findsNothing);
  });

  testWidgets('Carat tile notes the amount nearly expiring', (tester) async {
    const expiring = Customer(
      action: 'found',
      isFound: true,
      person: CustomerPerson(
        englishName: 'KP DEV',
        passportNo: '1234567',
        nationality: 'USA',
        contacts: [],
        privileges: [],
        walletMembers: [
          {
            'Code': 'CARAT_WALLET',
            'PaymentCode': 'CARAT',
            'Balance': 1475.0,
            'NearlyExpiredAmount': 1475.0,
            'NearlyExpiredAt': '2029-12-31T16:59:59.999Z',
          },
        ],
      ),
      tour: {},
      agentCode: '',
      isMember: true,
    );
    await open(tester, customer: expiring);
    expect(
      textIn(tester, ProfileIds.caratExpiring),
      '1,475.00 expiring 31/12/2029',
    );
    // A small hint, well under the value.
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: byTestId(ProfileIds.caratExpiring),
              matching: find.byType(Text),
            ),
          )
          .style
          ?.fontSize,
      10,
    );
    // The expiring line doesn't make the Carat tile taller than e-Purse.
    double tileHeight(String id) => tester
        .getSize(
          find
              .ancestor(of: byTestId(id), matching: find.byType(Expanded))
              .first,
        )
        .height;
    expect(tileHeight(ProfileIds.caratStat), tileHeight(ProfileIds.ePurseStat));
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

  testWidgets('privileges are a radio list, "No privilege" by default, '
      'each pick reported', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    expect(
      tester.getSemantics(byTestId(ProfileIds.noPrivilege)),
      isSemantics(isSelected: true),
    );
    await tester.ensureVisible(byTestId(ProfileIds.privilege(0)));
    await tester.tap(byTestId(ProfileIds.privilege(0)));
    await tester.pump();
    expect(
      tester.getSemantics(byTestId(ProfileIds.privilege(0))),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(byTestId(ProfileIds.noPrivilege)),
      isSemantics(isSelected: false),
    );
    await tester.tap(byTestId(ProfileIds.privilege(1)));
    await tester.pump();
    expect(
      tester.getSemantics(byTestId(ProfileIds.privilege(0))),
      isSemantics(isSelected: false),
    );
    await tester.tap(byTestId(ProfileIds.noPrivilege));
    await tester.pump();

    expect(picked, [_gold, _birthday, null]);
    expect(find.text('[VIP]:PROMO123'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('no Attach to bill; Update customer is the main action', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Attach to bill'), findsNothing);
    expect(
      find.descendant(
        of: byTestId(ProfileIds.editButton),
        matching: find.text('Update customer'),
      ),
      findsOneWidget,
    );
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
    expect(textIn(tester, ProfileIds.caratStat), '—');
    expect(
      find.descendant(
        of: byTestId(ProfileIds.flightCard),
        matching: find.text('No flight linked'),
      ),
      findsOneWidget,
    );
    expect(find.text('None on this card'), findsOneWidget);
  });

  testWidgets('a registered customer gets Go to Sale, not recent purchases', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Recent purchases'), findsNothing);
    await tester.ensureVisible(byTestId(ProfileIds.goToSaleButton));
    await tester.tap(byTestId(ProfileIds.goToSaleButton));
    expect(sales, 1);
  });

  testWidgets('an unregistered customer has no Go to Sale', (tester) async {
    await open(tester, customer: walkIn);
    expect(byTestId(ProfileIds.goToSaleButton), findsNothing);
    expect(find.text('Recent purchases'), findsNothing);
  });

  testWidgets('iPad portrait renders without overflow', (tester) async {
    await open(tester, size: mediumSize);
    expect(tester.takeException(), isNull);
  });
}

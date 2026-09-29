import 'package:flutter/material.dart';

import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flight/domain/entities/flight.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/privilege.dart';
import 'traveller_details_page.dart';

/// Customer profile (mockup screen 8), opened from a Home lookup result.
///
/// Real: name, member badge, shopping card, nationality, registration
/// status, e-Purse (first wallet member's balance), linked flight,
/// privileges (single-select), customer type / agent / guide. Not available
/// from `GetCustomer` yet, so shown as "—" / a notice: points, spend YTD,
/// visits, recent purchases, delivery address.
///
/// [onAttach] runs the page owner's Go-to-Sale guards with the chosen
/// privilege and resolves true when the customer was attached — the page
/// then closes; false (blocked) keeps it open.
// TODO(pos-handheld): points / spend / visits / recent purchases once a
// member-profile API exists.
class CustomerProfilePage extends StatefulWidget {
  final Customer customer;
  final Privilege? initialPrivilege;
  final Future<List<Flight>> Function(String query) searchFlights;
  final Future<bool> Function(Privilege? privilege) onAttach;
  final VoidCallback onEdit;

  const CustomerProfilePage({
    super.key,
    required this.customer,
    required this.searchFlights,
    required this.onAttach,
    required this.onEdit,
    this.initialPrivilege,
  });

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  late Privilege? _privilege = widget.initialPrivilege;

  CustomerPerson get _person => widget.customer.person;

  String get _ePurse {
    for (final member in _person.walletMembers) {
      final balance = double.tryParse('${member['balance'] ?? ''}');
      if (balance != null) return formatBaht(balance);
    }
    return '—';
  }

  Future<void> _attach() async {
    final attached = await widget.onAttach(_privilege);
    if (attached && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final person = _person;
    final badge = person.typeCardMember.trim().toUpperCase();
    final cardLine = [
      person.shoppingCard,
      person.nationality,
    ].where((s) => s.isNotEmpty).join(' · ');

    return TestId(
      ProfileIds.page,
      child: HandheldScaffold(
        header: _ProfileHeader(
          name: person.englishName,
          badge: badge,
          cardLine: cardLine.isEmpty ? 'No shopping card' : cardLine,
          registered: person.isActivate,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(HandheldMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      id: ProfileIds.pointsStat,
                      label: 'Points',
                      value: '—',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(
                      id: ProfileIds.ePurseStat,
                      label: 'e-Purse',
                      value: _ePurse,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      id: ProfileIds.spendStat,
                      label: 'Spend YTD',
                      value: '—',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(
                      id: ProfileIds.visitsStat,
                      label: 'Visits',
                      value: '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FlightCard(
                person: person,
                onTraveller: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TravellerDetailsPage(
                      customer: widget.customer,
                      searchFlights: widget.searchFlights,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              HandheldSection(
                id: ProfileIds.privileges,
                title: 'Privileges',
                count: person.privileges.isEmpty
                    ? null
                    : '${person.privileges.length}',
                children: [
                  if (person.privileges.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No privileges on this card.',
                        style: HandheldText.bodySmall,
                      ),
                    ),
                  for (var i = 0; i < person.privileges.length; i++)
                    _PrivilegeTile(
                      id: ProfileIds.privilege(i),
                      privilege: person.privileges[i],
                      selected: identical(_privilege, person.privileges[i]),
                      onTap: () => setState(() {
                        _privilege = identical(_privilege, person.privileges[i])
                            ? null
                            : person.privileges[i];
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              HandheldSection(
                title: 'Details',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _Detail(
                          'Customer type',
                          person.customerTypeDetail.isEmpty
                              ? person.customerTypeCode
                              : '${person.customerTypeCode} · '
                                    '${person.customerTypeDetail}',
                        ),
                        _Detail('Agent', widget.customer.agentCode),
                        _Detail('Guide', widget.customer.subAgentCode),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const HandheldSection(
                id: ProfileIds.recentPurchases,
                title: 'Recent purchases',
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Purchase history is not available yet on this device.',
                      style: HandheldText.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actionBar: HandheldActionBar(
          primary: HandheldPrimaryButton(
            id: ProfileIds.attachButton,
            label: 'Attach to bill',
            icon: Icons.check,
            onPressed: _attach,
          ),
          secondary: HandheldSecondaryButton(
            id: ProfileIds.editButton,
            label: 'Edit',
            onPressed: widget.onEdit,
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String badge;
  final String cardLine;
  final bool registered;

  const _ProfileHeader({
    required this.name,
    required this.badge,
    required this.cardLine,
    required this.registered,
  });

  static String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ink,
      child: SafeArea(
        bottom: false,
        child: HandheldContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 20, 20),
            child: Row(
              children: [
                const BackButton(color: Colors.white),
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.goldMuted, AppColors.goldDark],
                    ),
                  ),
                  child: Text(
                    _initials(name),
                    style: HandheldText.title.copyWith(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: TestId(
                              ProfileIds.name,
                              child: Text(
                                name.isEmpty ? '—' : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: HandheldText.title.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          if (badge.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            TestId(
                              ProfileIds.badge,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      TestId(
                        ProfileIds.cardLine,
                        child: Text(
                          cardLine,
                          style: HandheldText.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      TestId(
                        ProfileIds.status,
                        child: Text(
                          registered ? 'Registered' : 'Not registered',
                          style: TextStyle(
                            fontSize: 11,
                            color: registered
                                ? AppColors.onlineOnInk
                                : AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String id;
  final String label;
  final String value;

  const _StatTile({required this.id, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(HandheldMetrics.radius),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: HandheldText.overline.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 6),
          TestId(
            id,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HandheldText.statValue.copyWith(fontSize: 21),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightCard extends StatelessWidget {
  final CustomerPerson person;
  final VoidCallback onTraveller;

  const _FlightCard({required this.person, required this.onTraveller});

  @override
  Widget build(BuildContext context) {
    final hasFlight = person.flightCode.isNotEmpty;
    final title = !hasFlight
        ? 'No flight linked'
        : person.flightRouteDetail.isEmpty
        ? person.flightCode
        : '${person.flightCode} · ${person.flightRouteDetail}';
    final when = [
      person.flightDate,
      person.flightTime,
    ].where((s) => s.isNotEmpty).join(' ');

    return TestId(
      ProfileIds.flightCard,
      child: HandheldSection(
        title: 'Flight',
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.flight_takeoff,
                  size: 18,
                  color: hasFlight
                      ? const Color(0xFF00AAB4)
                      : AppColors.hintText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasFlight &&
                          (when.isNotEmpty || person.flightPickup.isNotEmpty))
                        Text(
                          [
                            when,
                            person.flightPickup,
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: HandheldText.bodySmall.copyWith(
                            fontSize: 11.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TestId(
            ProfileIds.travellerButton,
            child: InkWell(
              onTap: onTraveller,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFEDEFF3))),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Traveller details',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.goldDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.goldDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivilegeTile extends StatelessWidget {
  final String id;
  final Privilege privilege;
  final bool selected;
  final VoidCallback onTap;

  const _PrivilegeTile({
    required this.id,
    required this.privilege,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final code = privilege.typeCode.isEmpty && privilege.promoCode.isEmpty
        ? ''
        : '[${privilege.typeCode}]:${privilege.promoCode}';
    return TestId(
      id,
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          onTap: onTap,
          child: Container(
            color: selected ? AppColors.cream : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: selected ? AppColors.goldDark : AppColors.hintText,
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.card_giftcard,
                  size: 16,
                  color: AppColors.goldDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        privilege.name.isEmpty ? 'Privilege' : privilege.name,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (code.isNotEmpty)
                        Text(
                          code,
                          style: HandheldText.bodySmall.copyWith(
                            fontSize: 11.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;

  const _Detail(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.mutedText,
              ),
            ),
          ),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

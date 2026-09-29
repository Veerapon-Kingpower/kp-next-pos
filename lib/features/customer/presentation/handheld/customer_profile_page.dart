import 'package:flutter/material.dart';

import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flight/domain/entities/flight.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/privilege.dart';
import '../widgets/privilege_radio_list.dart';
import '../widgets/registration_checks_list.dart';
import 'traveller_details_page.dart';

/// Customer profile (mockup screen 8), opened from a Home lookup result.
///
/// Real: name, member badge, shopping card, nationality, registration
/// status, Carat / e-Purse (the `CARAT` / `CASHW` wallet balances), linked
/// flight, privileges (radio list), customer type / agent / guide.
///
/// Every privilege pick is reported through [onPrivilegeChanged] straight
/// away (as on desktop); [onEdit] opens the Update customer form. Start
/// sale ([onGoToSale]) is enabled only for a registered (`isActivate`) card.
class CustomerProfilePage extends StatefulWidget {
  final Customer customer;
  final Privilege? initialPrivilege;
  final Future<List<Flight>> Function(String query) searchFlights;
  final ValueChanged<Privilege?> onPrivilegeChanged;
  final VoidCallback onEdit;
  final VoidCallback onGoToSale;

  const CustomerProfilePage({
    super.key,
    required this.customer,
    required this.searchFlights,
    required this.onPrivilegeChanged,
    required this.onEdit,
    required this.onGoToSale,
    this.initialPrivilege,
  });

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  late Privilege? _privilege = widget.initialPrivilege;

  CustomerPerson get _person => widget.customer.person;

  void _selectPrivilege(Privilege? privilege) {
    setState(() => _privilege = privilege);
    widget.onPrivilegeChanged(privilege);
  }

  @override
  Widget build(BuildContext context) {
    final person = _person;
    final badge = person.typeCardMember.trim().toUpperCase();
    final expiring = person.caratNearlyExpired;
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
              // Equal-height tiles even when only Carat has an expiring line.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _StatTile(
                        id: ProfileIds.caratStat,
                        label: 'Carat',
                        value: formatCarat(person.caratBalance),
                        note: expiring == null
                            ? null
                            : formatCaratExpiring(expiring.amount, expiring.at),
                        noteId: ProfileIds.caratExpiring,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        id: ProfileIds.ePurseStat,
                        label: 'e-Purse',
                        value: formatEPurse(person.ePurseBalance),
                      ),
                    ),
                  ],
                ),
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
              PrivilegeRadioList(
                privileges: person.privileges,
                selected: _privilege,
                onChanged: _selectPrivilege,
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
              HandheldSection(
                title: 'Registration checks',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RegistrationChecksList(person: person),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Start sale is always there but only a registered (`isActivate`)
        // card can press it; Update customer is how the rest register.
        actionBar: HandheldActionBar(
          primary: HandheldPrimaryButton(
            id: ProfileIds.goToSaleButton,
            label: 'Start sale',
            icon: Icons.shopping_bag_outlined,
            onPressed: person.isActivate ? widget.onGoToSale : null,
          ),
          secondary: HandheldSecondaryButton(
            id: ProfileIds.editButton,
            label: person.isActivate ? 'Update customer' : 'Register',
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
  // Small amber line under the value (Carat nearly expiring); none if null.
  final String? note;
  final String? noteId;

  const _StatTile({
    required this.id,
    required this.label,
    required this.value,
    this.note,
    this.noteId,
  });

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
          if (note != null) ...[
            const SizedBox(height: 4),
            TestId(
              noteId ?? '',
              child: Text(
                note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HandheldText.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
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

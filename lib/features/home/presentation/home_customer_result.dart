import 'package:flutter/material.dart';

import '../../../core/presentation/desktop/desktop.dart';
import '../../../core/presentation/handheld/money_format.dart';
import '../../../core/presentation/test_ids.dart';
import '../../../core/presentation/widgets/test_id.dart';
import '../../../core/theme/app_colors.dart';
import '../../customer/domain/entities/customer.dart';
import '../../customer/domain/entities/privilege.dart';
import '../../customer/presentation/customer_summary.dart';
import '../../customer/presentation/widgets/privilege_radio_list.dart';
import '../../customer/presentation/widgets/registration_checks_list.dart';

/// Desktop Home lookup result ("Find customer to start a sale"): a status
/// strip, the customer's identity and facts with the privilege radio list
/// on the left, registration checks and the next actions on the right.
///
/// Only data `Register/GetCustomer` returns is shown — facts without a
/// value (and the mockup's member ID, last purchase, join / expiry dates,
/// which have no API) are left out rather than faked. Points are the
/// Carat wallet; e-Purse is the cash wallet.
class HomeCustomerResult extends StatelessWidget {
  final Customer customer;
  final String query;
  final DateTime foundAt;
  final DateTime now;
  final Privilege? selectedPrivilege;
  final ValueChanged<Privilege?> onSelectPrivilege;
  final VoidCallback onStartSale;
  final VoidCallback onRegister;
  final VoidCallback onEnquiry;
  final VoidCallback onEditProfile;
  final VoidCallback onClear;

  const HomeCustomerResult({
    super.key,
    required this.customer,
    required this.query,
    required this.foundAt,
    required this.now,
    required this.selectedPrivilege,
    required this.onSelectPrivilege,
    required this.onStartSale,
    required this.onRegister,
    required this.onEnquiry,
    required this.onEditProfile,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final registered = customer.person.isActivate;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesktopMetrics.panelRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesktopMetrics.panelRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusStrip(
              registered: registered,
              foundBy: foundBy(customer, query),
              foundAt: foundAt,
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final side = constraints.maxWidth >= 1100 ? 320.0 : 280.0;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: _Identity(
                          customer: customer,
                          now: now,
                          selectedPrivilege: selectedPrivilege,
                          onSelectPrivilege: onSelectPrivilege,
                          onEditProfile: onEditProfile,
                        ),
                      ),
                    ),
                    Container(
                      width: side,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: AppColors.line)),
                      ),
                      child: _Actions(
                        person: customer.person,
                        onStartSale: onStartSale,
                        onRegister: onRegister,
                        onEnquiry: onEnquiry,
                        onClear: onClear,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final bool registered;
  final String foundBy;
  final DateTime foundAt;

  const _StatusStrip({
    required this.registered,
    required this.foundBy,
    required this.foundAt,
  });

  @override
  Widget build(BuildContext context) {
    final color = registered ? AppColors.success : AppColors.warning;
    final time =
        '${foundAt.hour.toString().padLeft(2, '0')}:'
        '${foundAt.minute.toString().padLeft(2, '0')}';
    return TestId(
      DesktopIds.homeStatus,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
        color: color.withValues(alpha: 0.1),
        child: Row(
          children: [
            Icon(
              registered ? Icons.check : Icons.error_outline,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 10),
            Text(
              registered ? 'Registered customer' : 'Not registered',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                registered
                    ? '· ready to start a sale'
                    : '· register before starting a sale',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ),
            if (foundBy.isNotEmpty)
              TestId(
                DesktopIds.homeFoundBy,
                child: Text(
                  'Found by $foundBy · $time',
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Avatar, name, tier badge and "gender · nationality · type · phone" with
/// Edit profile at the end of that header, the fact grid, then the
/// privilege radio list.
class _Identity extends StatelessWidget {
  final Customer customer;
  final DateTime now;
  final Privilege? selectedPrivilege;
  final ValueChanged<Privilege?> onSelectPrivilege;
  final VoidCallback onEditProfile;

  const _Identity({
    required this.customer,
    required this.now,
    required this.selectedPrivilege,
    required this.onSelectPrivilege,
    required this.onEditProfile,
  });

  static String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final last = parts.length > 1 ? parts.last[0] : '';
    return (parts.first[0] + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final person = customer.person;
    final badge = person.typeCardMember.trim().toUpperCase();
    final line = [
      genderLabel(person.gender),
      person.nationality,
      person.customerTypeCode,
      mobileNumber(person),
    ].where((s) => s.isNotEmpty).join(' · ');
    final flight = [
      person.flightCode,
      flightWhen(person),
    ].where((s) => s.isNotEmpty).join(' · ');
    final departs = departsIn(person, now);
    final expiring = person.caratNearlyExpired;

    final facts = <_Fact>[
      if (person.shoppingCard.isNotEmpty)
        _Fact('shoppingCard', 'Shopping card', person.shoppingCard),
      if (person.passportNo.isNotEmpty)
        _Fact('passport', 'Passport', person.passportNo, person.nationality),
      if (person.flightCode.isNotEmpty)
        _Fact(
          'flight',
          'Flight',
          flight,
          departs == null ? '' : 'Departs in $departs',
        ),
      if (person.caratBalance != null)
        _Fact(
          'carat',
          'Carat',
          formatCarat(person.caratBalance),
          expiring == null
              ? ''
              : formatCaratExpiring(expiring.amount, expiring.at),
        ),
      if (person.ePurseBalance != null)
        _Fact('ePurse', 'e-Purse', formatEPurse(person.ePurseBalance)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
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
                _initials(person.englishName),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: TestId(
                          DesktopIds.homeCustomerName,
                          child: Text(
                            person.englishName.isEmpty
                                ? '—'
                                : person.englishName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DesktopText.heroTitle,
                          ),
                        ),
                      ),
                      if (badge.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        TestId(
                          ProfileIds.badge,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldDark,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (line.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    TestId(
                      DesktopIds.homeCustomerLine,
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            TestId(
              DesktopIds.homeEditProfileButton,
              child: OutlinedButton.icon(
                onPressed: onEditProfile,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.goldDark,
                ),
                label: const Text('Edit profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  side: const BorderSide(color: Color(0xFFD8DDE5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        if (facts.isNotEmpty) ...[
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 20.0;
              final width = (constraints.maxWidth - gap * 2) / 3;
              return Wrap(
                spacing: gap,
                runSpacing: 12,
                children: [
                  for (final fact in facts)
                    SizedBox(
                      width: width,
                      child: _FactCell(fact: fact),
                    ),
                ],
              );
            },
          ),
        ],
        const SizedBox(height: 16),
        PrivilegeRadioList(
          privileges: person.privileges,
          selected: selectedPrivilege,
          onChanged: onSelectPrivilege,
        ),
      ],
    );
  }
}

class _Fact {
  final String key;
  final String label;
  final String value;
  final String sub;

  const _Fact(this.key, this.label, this.value, [this.sub = '']);
}

class _FactCell extends StatelessWidget {
  final _Fact fact;

  const _FactCell({required this.fact});

  @override
  Widget build(BuildContext context) {
    return TestId(
      DesktopIds.homeFact(fact.key),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fact.label.toUpperCase(), style: DesktopText.fieldLabel),
          const SizedBox(height: 6),
          Text(
            fact.value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (fact.sub.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              fact.sub,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Registration checks, then Start sale (enabled once registered) — plus
/// Register for an unregistered card — with Enquiry / Clear beneath.
class _Actions extends StatelessWidget {
  final CustomerPerson person;
  final VoidCallback onStartSale;
  final VoidCallback onRegister;
  final VoidCallback onEnquiry;
  final VoidCallback onClear;

  const _Actions({
    required this.person,
    required this.onStartSale,
    required this.onRegister,
    required this.onEnquiry,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('REGISTRATION CHECKS', style: DesktopText.fieldLabel),
        const SizedBox(height: 6),
        RegistrationChecksList(
          person: person,
          rowPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        const SizedBox(height: 16),
        // Always shown; only a registered (`isActivate`) card can start a
        // sale — the rest register first.
        DesktopButton(
          id: ProfileIds.goToSaleButton,
          label: 'Start sale',
          icon: Icons.shopping_bag_outlined,
          hotkey: 'F2',
          height: 58,
          onPressed: person.isActivate ? onStartSale : null,
        ),
        if (!person.isActivate) ...[
          const SizedBox(height: 10),
          DesktopButton(
            id: DesktopIds.homeRegisterButton,
            label: 'Register',
            icon: Icons.badge_outlined,
            hotkey: 'F3',
            secondary: true,
            onPressed: onRegister,
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SmallAction(
                id: DesktopIds.homeEnquiryButton,
                label: 'Enquiry',
                icon: Icons.search,
                hotkey: 'F4',
                onPressed: onEnquiry,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SmallAction(
                id: DesktopIds.homeClearButton,
                label: 'Clear',
                hotkey: 'ESC',
                onPressed: onClear,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact outlined action for the three-up row under Start sale — tighter
/// than [DesktopButton] so icon, label and hotkey fit a third of the
/// column; only the label gives way (ellipsis) when space runs out.
class _SmallAction extends StatelessWidget {
  final String id;
  final String label;
  final IconData? icon;
  final String? hotkey;
  final VoidCallback onPressed;

  const _SmallAction({
    required this.id,
    required this.label,
    required this.onPressed,
    this.icon,
    this.hotkey,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      id,
      child: Semantics(
        button: true,
        enabled: true,
        child: SizedBox(
          height: 44,
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
              side: const BorderSide(color: Color(0xFFD8DDE5)),
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(9),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                // Narrow columns (iPad landscape) drop the icon first.
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null && constraints.maxWidth >= 96) ...[
                        Icon(icon, size: 15, color: AppColors.goldDark),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (hotkey != null) ...[
                        const SizedBox(width: 5),
                        DesktopHotkeyChip(hotkey!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

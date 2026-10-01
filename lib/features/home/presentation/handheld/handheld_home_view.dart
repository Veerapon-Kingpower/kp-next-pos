import 'package:flutter/material.dart';

import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customer/domain/entities/customer.dart';

/// Header of the handheld Home screen (mockup screen 2): avatar initials,
/// time-of-day greeting, the module / branch / user line, the sale-mode
/// badge, and the two shift stats.
class HandheldHomeHeader extends StatelessWidget {
  final String userName;
  final String module;
  final String branch;

  /// `DeviceSettings.forceOfflineMode` — the configured sale mode, not live
  /// connectivity.
  // TODO(pos-handheld): switch to a real connectivity / RC-reachability
  // signal once one exists.
  final bool offlineMode;
  final DateTime now;

  const HandheldHomeHeader({
    super.key,
    required this.userName,
    required this.module,
    required this.branch,
    required this.offlineMode,
    required this.now,
  });

  static String greetingFor(DateTime time) {
    if (time.hour < 12) return 'Good morning';
    if (time.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  static String initialsOf(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return HandheldHeader(
      title: greetingFor(now),
      titleId: HomeIds.greeting,
      subtitle: '$module · Branch $branch · $userName',
      subtitleId: HomeIds.sessionLine,
      leading: _Avatar(initials: initialsOf(userName)),
      trailing: _SaleModeBadge(offline: offlineMode),
      // TODO(pos-handheld): shift bill count / net sales need a shift
      // summary API — shown as "—" rather than invented numbers.
      stats: const [
        HandheldStat(id: HomeIds.billsStat, label: 'Bills', value: '—'),
        HandheldStat(
          id: HomeIds.netSalesStat,
          label: 'Net sales',
          value: '—',
          flex: 3,
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;

  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
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
        initials,
        style: HandheldText.title.copyWith(fontSize: 16, color: Colors.white),
      ),
    );
  }
}

class _SaleModeBadge extends StatelessWidget {
  final bool offline;

  const _SaleModeBadge({required this.offline});

  @override
  Widget build(BuildContext context) {
    final color = offline ? AppColors.gold : AppColors.onlineOnInk;
    return TestId(
      HomeIds.onlineStatus,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: offline ? AppColors.gold : AppColors.online,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            offline ? 'OFFLINE' : 'ONLINE',
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

/// Body of the handheld Home screen (mockup screen 2): the scan field that
/// looks up a customer, the lookup result slot, the shortcut tiles and the
/// suspended-bills list.
class HandheldHomeView extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  /// Loading / error / empty / result-card state for the last lookup,
  /// built by the page that owns the search view-model.
  final Widget searchResults;
  final VoidCallback onRegister;
  final VoidCallback onSale;
  final VoidCallback onEnquiry;

  /// The scan field's focus — Search again (after a miss) returns to it.
  final FocusNode? searchFocus;

  const HandheldHomeView({
    super.key,
    required this.searchController,
    required this.onSearch,
    required this.searchResults,
    required this.onRegister,
    required this.onSale,
    required this.onEnquiry,
    this.searchFocus,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        HandheldMetrics.pagePadding,
        18,
        HandheldMetrics.pagePadding,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScanField(
            id: HomeIds.scanField,
            controller: searchController,
            focusNode: searchFocus,
            // Ready for a trigger scan as soon as Home opens, and after
            // each one.
            autofocus: true,
            keepFocusOnSubmit: true,
            clearButtonId: FieldIds.clear(HomeIds.scanField),
            hintText: 'Scan shopping card or passport',
            onSubmitted: onSearch,
          ),
          TestId(
            HomeIds.customerResult,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: searchResults,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: HandheldTile(
                  id: HomeIds.tileRegister,
                  icon: Icons.badge_outlined,
                  label: 'Register',
                  onTap: onRegister,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: HandheldTile(
                  id: HomeIds.tileSale,
                  icon: Icons.shopping_bag_outlined,
                  label: 'Sale',
                  onTap: onSale,
                ),
              ),
              const SizedBox(width: 9),
              // TODO(pos-handheld): Checkout lands in sub-phase H3 — inert
              // until the checkout screen exists.
              const Expanded(
                child: HandheldTile(
                  id: HomeIds.tileCheckout,
                  icon: Icons.payments_outlined,
                  label: 'Checkout',
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: HandheldTile(
                  id: HomeIds.tileEnquiry,
                  icon: Icons.search,
                  label: 'Enquiry',
                  onTap: onEnquiry,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // TODO(pos-handheld): list suspended bills once a suspend / resume
          // bill API exists; tapping a row resumes it on the Sale tab.
          const HandheldSection(
            id: HomeIds.suspendedBills,
            title: 'Suspended bills',
            footer: Text('Tap a bill to resume'),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  'Suspended bills are not available on this device yet.',
                  style: HandheldText.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One handheld Home lookup result (mockup screen 2 → 8): initials, name,
/// member badge, shopping card and registration status; tap opens the
/// customer profile.
class HandheldCustomerResultTile extends StatelessWidget {
  final String id;
  final Customer customer;
  final VoidCallback onTap;

  const HandheldCustomerResultTile({
    super.key,
    required this.id,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final person = customer.person;
    final badge = person.typeCardMember.trim().toUpperCase();
    final line = [
      person.shoppingCard,
      person.passportNo,
      person.nationality,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TestId(
        id,
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HandheldMetrics.radius),
            side: const BorderSide(color: AppColors.line),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(HandheldMetrics.radius),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _Avatar(
                    initials: HandheldHomeHeader.initialsOf(person.englishName),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                person.englishName.isEmpty
                                    ? '—'
                                    : person.englishName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (badge.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (line.isNotEmpty)
                          Text(
                            line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HandheldText.bodySmall.copyWith(
                              fontSize: 11.5,
                            ),
                          ),
                        Text(
                          person.isActivate ? 'Registered' : 'Not registered',
                          style: TextStyle(
                            fontSize: 11,
                            color: person.isActivate
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.mutedText),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

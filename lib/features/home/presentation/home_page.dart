import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/app/session_state.dart';
import '../../../core/presentation/widgets/app_buttons.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/app_dialogs.dart';
import '../../../core/presentation/widgets/app_shell.dart';
import '../../../core/presentation/widgets/empty_state_view.dart';
import '../../../core/presentation/widgets/loading_view.dart';
import '../../../core/presentation/widgets/retryable_error_view.dart';
import '../../../core/presentation/widgets/search_scan_input.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizing.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/domain/usecases/logout_usecase.dart';
import '../../customer/domain/entities/customer.dart';
import '../../customer/presentation/customer_registration_page.dart';
import '../../customer/presentation/customer_registration_view_model.dart';
import '../../sale/presentation/sale_cart_view_model.dart';
import '../../sale/presentation/widgets/sale_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../settings/presentation/settings_view_model.dart';
import 'home_view_model.dart';

/// The `Register/GetCustomer` search only accepts a single `shoppingCard`
/// identifier — a shopping card, passport, or ID card number are all
/// entered the same way, so the hint text lists them instead of offering
/// separate per-type selection controls (see [HomeViewModel]).
const _customerSearchHint =
    'Search by shopping card, passport, or ID card number';

/// App shell with the primary POS navigation — Customers (default-active on
/// landing here, including right after login), Sale, and Settings — per
/// design.md's nav scope. Customers/Sale swap in place via [IndexedStack]
/// so cart/search state survives switching tabs; Settings is a full page,
/// pushed rather than swapped in, matching how it's already reached from
/// Login. The header shows the signed-in user, module, and branch so the
/// cashier always has that context on screen.
class HomePage extends StatefulWidget {
  final HomeViewModel viewModel;
  final SessionState sessionState;
  final LogoutUseCase logoutUseCase;
  final SettingsViewModel Function() settingsViewModelFactory;
  final SaleCartViewModel Function() saleCartViewModelFactory;
  final CustomerRegistrationViewModel Function()
  customerRegistrationViewModelFactory;

  const HomePage({
    super.key,
    required this.viewModel,
    required this.sessionState,
    required this.logoutUseCase,
    required this.settingsViewModelFactory,
    required this.saleCartViewModelFactory,
    required this.customerRegistrationViewModelFactory,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _destinations = [
    AppNavDestination(icon: Icons.people, label: 'Customers'),
    AppNavDestination(icon: Icons.point_of_sale, label: 'Sale'),
    AppNavDestination(icon: Icons.settings, label: 'Settings'),
  ];

  final _customerSearchController = TextEditingController();
  // Customers is the landing tab — including immediately after login.
  int _tabIndex = 0;
  late final SaleCartViewModel _saleCartViewModel;

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
    _saleCartViewModel = widget.saleCartViewModelFactory();
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    super.dispose();
  }

  Future<void> _logOut() async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Log out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (!confirmed) return;

    await widget.logoutUseCase();
    widget.sessionState.signedOut();
  }

  void _searchCustomer() {
    widget.viewModel.searchCustomer(_customerSearchController.text);
  }

  void _openSettings() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          viewModel: widget.settingsViewModelFactory(),
          sessionState: widget.sessionState,
        ),
      ),
    );
  }

  void _openRegistration({Customer? existingCustomer}) {
    final session = widget.viewModel.session;
    if (session == null) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => CustomerRegistrationPage(
          viewModel: widget.customerRegistrationViewModelFactory(),
          userCode: session.userCode,
          isAirportMpos: widget.viewModel.settings.isAirportMpos,
          existingCustomer: existingCustomer,
        ),
      ),
    );
  }

  void _onDestinationSelected(int index) {
    if (index == 2) {
      _openSettings();
      return;
    }
    setState(() => _tabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeViewModel>(
      init: widget.viewModel,
      global: false,
      builder: (viewModel) => _buildContent(context, viewModel),
    );
  }

  Widget _buildContent(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const AppShell(title: 'Home', body: LoadingView());
    }

    return AppShell(
      title: _destinations[_tabIndex].label,
      destinations: _destinations,
      selectedIndex: _tabIndex,
      onDestinationSelected: _onDestinationSelected,
      actions: [
        _sessionInfo(viewModel),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
          onPressed: _logOut,
        ),
      ],
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _customerSearchSection(context, viewModel),
          SalePage(viewModel: _saleCartViewModel),
        ],
      ),
    );
  }

  /// Signed-in user, module, and branch — shown in the header so the
  /// cashier always has that context on screen, per the request to surface
  /// it on the navbar rather than a dashboard card.
  Widget _sessionInfo(HomeViewModel viewModel) {
    final session = viewModel.session;
    if (session == null) return const SizedBox.shrink();
    final settings = viewModel.settings;
    final module = settings.moduleKey.isEmpty ? '—' : settings.moduleKey;
    final branch = settings.branch.isEmpty ? '—' : settings.branch;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Center(
        child: Text(
          '${session.userName} · $module · $branch',
          style: const TextStyle(color: Colors.white, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _customerSearchSection(BuildContext context, HomeViewModel viewModel) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search customer', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SearchScanInput(
                            controller: _customerSearchController,
                            hintText: _customerSearchHint,
                            onSubmitted: (_) => _searchCustomer(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 120,
                          child: AppPrimaryButton(
                            label: 'Search',
                            onPressed: viewModel.isSearchingCustomer
                                ? null
                                : _searchCustomer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _customerSearchResults(context, viewModel),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Own card, physically separated from Search, so it can't be
              // mis-tapped for it — see the "own card below Search" mockup
              // decision.
              AppCard(
                child: Column(
                  children: [
                    Text(
                      "New customer not in the system?",
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: SizedBox(
                        width: 240,
                        child: AppPrimaryButton(
                          label: 'Register new customer',
                          onPressed: _openRegistration,
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
    );
  }

  Widget _customerSearchResults(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isSearchingCustomer) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: LoadingView(),
      );
    }
    if (viewModel.customerSearchError != null) {
      return RetryableErrorView(
        message: viewModel.customerSearchError!,
        onRetry: _searchCustomer,
      );
    }
    if (!viewModel.hasSearchedCustomer) {
      return const SizedBox.shrink();
    }
    if (viewModel.customerSearchResults.isEmpty) {
      return const EmptyStateView(
        message: 'No customer found.',
        icon: Icons.person_search_outlined,
      );
    }
    return Column(
      children: viewModel.customerSearchResults
          .map(
            (customer) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: _CustomerResultCard(
                customer: customer,
                isAirportMpos: viewModel.settings.isAirportMpos,
                onEdit: (c) => _openRegistration(existingCustomer: c),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

/// Search-result card, restyled to match legacy smart-pos's `CustomerPage`
/// header: the shopping card number, name, passport, nationality, customer
/// type, agent, guide, and register status are always visible (legacy shows
/// exactly one customer per screen, so its whole header is static); flight
/// info and the raw privilege/wallet/tour data stay behind a "Details"
/// toggle, since a search here can return several candidates. The edit icon
/// next to the register status ports legacy's `btn-edit-icon` — it opens
/// the same registration form used for new customers, prefilled from this
/// one (`onEdit`).
class _CustomerResultCard extends StatefulWidget {
  final Customer customer;
  final bool isAirportMpos;
  final ValueChanged<Customer> onEdit;

  const _CustomerResultCard({
    required this.customer,
    required this.isAirportMpos,
    required this.onEdit,
  });

  @override
  State<_CustomerResultCard> createState() => _CustomerResultCardState();
}

class _CustomerResultCardState extends State<_CustomerResultCard> {
  bool _expanded = false;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CustomerCardFace(customer: customer),
                Expanded(
                  child: _CustomerHeaderDetail(
                    customer: customer,
                    onEdit: widget.onEdit,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _toggleExpanded,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceAlt,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Details',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: AppSizing.iconSize,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            _CustomerExpandedDetails(
              customer: customer,
              isAirportMpos: widget.isAirportMpos,
            ),
        ],
      ),
    );
  }
}

/// Left-hand card face — mirrors legacy's gold-bordered member card visual
/// (`wrapper-card` in `customer.scss`): the member-card photo
/// (`Customer.pathURLMemberCard`, a real top-level API field) as the
/// background when present, with the type-code/member-tier badge overlaid
/// on it — same as legacy's `cardImg` + `.text-card-type`/
/// `.text-type-card-member` overlay. Falls back to the icon placeholder
/// when there's no photo, or if it fails to load.
class _CustomerCardFace extends StatelessWidget {
  final Customer customer;

  const _CustomerCardFace({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      decoration: const BoxDecoration(
        color: Color(0x14C5A059), // AppColors.goldAccent at low opacity
        border: Border(right: BorderSide(color: AppColors.goldAccent, width: 4)),
      ),
      child: customer.pathURLMemberCard.isEmpty
          ? _placeholder(context)
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  customer.pathURLMemberCard,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : _placeholder(context),
                  errorBuilder: (context, error, stackTrace) =>
                      _placeholder(context),
                ),
                if (_badgeText(customer.person).isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(color: Color(0x99000000)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxs,
                        ),
                        child: _badgeLabels(context, customer.person, onDark: true),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: AppSizing.iconSizeLarge,
            color: AppColors.goldDark,
          ),
          const SizedBox(height: AppSpacing.xxs),
          _badgeLabels(context, customer.person, onDark: false),
        ],
      ),
    );
  }

  String _badgeText(CustomerPerson person) =>
      person.custTypeCode + person.typeCardMember;

  Widget _badgeLabels(
    BuildContext context,
    CustomerPerson person, {
    required bool onDark,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (person.custTypeCode.isNotEmpty)
          Text(
            person.custTypeCode,
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(
              color: onDark ? Colors.white : null,
            ),
          ),
        if (person.typeCardMember.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.goldAccent,
              borderRadius: BorderRadius.circular(AppSizing.cornerRadiusSm),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                person.typeCardMember.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Always-visible header detail block — shopping card number, name, and the
/// label/value facts legacy shows in `CustomerPage`'s header (Passport,
/// Nationality, Customer Type, Agent, Guide, register status).
class _CustomerHeaderDetail extends StatelessWidget {
  final Customer customer;
  final ValueChanged<Customer> onEdit;

  const _CustomerHeaderDetail({required this.customer, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final person = customer.person;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  person.shoppingCard.isEmpty ? '—' : person.shoppingCard,
                  textAlign: TextAlign.right,
                  style: textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              const Icon(
                Icons.qr_code_2,
                size: AppSizing.iconSize,
                color: AppColors.goldAccent,
              ),
            ],
          ),
          const Divider(color: AppColors.goldAccent, thickness: 2, height: AppSpacing.md),
          Text(
            person.englishName.isEmpty ? 'Unnamed customer' : person.englishName,
            textAlign: TextAlign.right,
            style: textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          _FactRow(label: 'Passport', value: person.passportNo),
          _FactRow(label: 'Nationality', value: person.nationality),
          _FactRow(
            label: 'Customer Type',
            value: person.customerTypeCode,
            sub: person.customerTypeDetail,
          ),
          _FactRow(label: 'Agent', value: customer.agentCode),
          _FactRow(label: 'Guide', value: customer.subAgentCode),
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Icon(
                  person.isActivate ? Icons.check_circle : Icons.cancel,
                  size: AppSizing.iconSize,
                  color: person.isActivate
                      ? AppColors.success
                      : AppColors.danger,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    person.isActivate ? 'Registered' : 'Not Registered',
                    style: textTheme.labelLarge?.copyWith(
                      color: person.isActivate
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                ),
                // Mirrors legacy's `btn-edit-icon` — pushes the same form
                // used to register a new customer, prefilled for editing
                // (`customer.ts`'s `editInfo()` → `CustomerFormPage`).
                IconButton(
                  key: const Key('editCustomerButton'),
                  tooltip: 'Edit customer',
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: AppSizing.iconSize,
                  color: AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onEdit(customer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One label-left/value-right fact row, mirroring legacy's
/// `text-detail-left`/`text-detail-right` pairing. Renders nothing when
/// both [value] and [sub] are empty, so absent fields don't leave a blank
/// row.
class _FactRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _FactRow({required this.label, required this.value, this.sub = ''});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty && sub.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.isEmpty ? '—' : value,
                  textAlign: TextAlign.right,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    textAlign: TextAlign.right,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Content behind the "Details" toggle — the flight block (styled like
/// legacy's blue-accented flight card, or a compact "not available" bar
/// when there's no flight) plus the raw contact/privilege/wallet/tour JSON
/// the compact header doesn't show.
class _CustomerExpandedDetails extends StatelessWidget {
  final Customer customer;
  final bool isAirportMpos;

  const _CustomerExpandedDetails({
    required this.customer,
    required this.isAirportMpos,
  });

  @override
  Widget build(BuildContext context) {
    final person = customer.person;
    final extras = <Widget>[
      ..._mapListSection(context, 'Privileges', person.privileges),
      ..._mapListSection(context, 'Wallet', person.walletMembers),
      ..._mapSection(context, 'Tour', customer.tour),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          person.flightCode.isEmpty
              ? const _NoFlightBar()
              : _FlightCard(person: person, isAirportMpos: isAirportMpos),
          if (extras.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            ...extras,
          ],
        ],
      ),
    );
  }

  List<Widget> _mapListSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) return const [];
    final textTheme = Theme.of(context).textTheme;
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.labelLarge),
          for (final item in items) _KeyValueRows(data: item),
        ],
      ),
    ];
  }

  List<Widget> _mapSection(
    BuildContext context,
    String title,
    Map<String, dynamic> data,
  ) {
    if (data.isEmpty) return const [];
    final textTheme = Theme.of(context).textTheme;
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.labelLarge),
          _KeyValueRows(data: data),
        ],
      ),
    ];
  }
}

/// Flight block, styled like legacy's blue-accented flight card: an icon
/// column (flight code) beside date/time, route, and — off airport-mPOS
/// only, matching legacy's `*ngIf="!isMPOSAirport"` — a pickup (PU) row.
class _FlightCard extends StatelessWidget {
  final CustomerPerson person;
  final bool isAirportMpos;

  const _FlightCard({required this.person, required this.isAirportMpos});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          right: BorderSide(color: AppColors.info, width: 4),
        ),
        borderRadius: BorderRadius.circular(AppSizing.cornerRadiusSm),
        boxShadow: const [
          BoxShadow(color: Color(0x1F0A192F), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizing.cornerRadiusSm),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                color: AppColors.info,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flight, color: Colors.white, size: AppSizing.iconSize),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      person.flightCode,
                      style: textTheme.labelMedium?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            person.flightDate,
                            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            person.flightTime,
                            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      _FactRow(
                        label: 'Route',
                        value: person.flightRouteDetail,
                      ),
                      if (!isAirportMpos)
                        _FactRow(label: 'PU', value: person.flightPickup),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact "no flight" bar — legacy's collapsed `wrapper-no-flight` state.
class _NoFlightBar extends StatelessWidget {
  const _NoFlightBar();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          right: BorderSide(color: AppColors.info, width: 4),
        ),
        borderRadius: BorderRadius.circular(AppSizing.cornerRadiusSm),
        boxShadow: const [
          BoxShadow(color: Color(0x1F0A192F), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.flight_outlined,
            color: AppColors.info.withValues(alpha: 0.55),
            size: AppSizing.iconSize,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Flight: Not available',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRows extends StatelessWidget {
  final Map<String, dynamic> data;

  const _KeyValueRows({required this.data});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries
          .map(
            (entry) => Text(
              '${entry.key}: ${entry.value ?? '—'}',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

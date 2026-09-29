import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/app/session_state.dart';
import '../../../core/presentation/handheld/handheld.dart';
import '../../../core/presentation/test_ids.dart';
import '../../../core/presentation/widgets/test_id.dart';
import '../../../core/presentation/widgets/app_buttons.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/app_dialogs.dart';
import '../../../core/presentation/widgets/app_shell.dart';
import '../../../core/presentation/widgets/empty_state_view.dart';
import '../../../core/presentation/widgets/loading_view.dart';
import '../../../core/presentation/widgets/retryable_error_view.dart';
import '../../../core/presentation/widgets/search_scan_input.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizing.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/domain/usecases/logout_usecase.dart';
import '../../customer/domain/entities/customer.dart';
import '../../customer/domain/entities/privilege.dart';
import '../../customer/presentation/customer_registration_page.dart';
import '../../customer/presentation/customer_registration_view_model.dart';
import '../../customer/presentation/handheld/customer_profile_page.dart';
import '../../enquiry/presentation/enquiry_page.dart';
import '../../sale/presentation/handheld/handheld_sale_view.dart';
import '../../sale/presentation/sale_cart_view_model.dart';
import '../../sale/presentation/widgets/sale_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../settings/presentation/settings_view_model.dart';
import 'handheld/handheld_home_view.dart';
import 'home_dashboard_page.dart';
import 'home_view_model.dart';

/// The `Register/GetCustomer` search only accepts a single `shoppingCard`
/// identifier — a shopping card, passport, or ID card number are all
/// entered the same way, so the hint text lists them instead of offering
/// separate per-type selection controls (see [HomeViewModel]).
const _customerSearchHint =
    'Search by shopping card, passport, or ID card number';

/// The body sections `HomePage` can show, independent of which nav
/// destinations are visible at the current breakpoint (handheld shows
/// `home`/`sale`/`enquiry`, with customer lookup on Home's scan field;
/// desktop shows all four — see `_HomePageState`'s
/// `_handheldSections`/`_desktopSections`).
enum _HomeSection { home, customers, sale, enquiry }

enum _MenuChoice { settings, logout }

/// App shell with the primary POS navigation. Below
/// [AppBreakpoints.wide] it is the handheld layout
/// (docs/superpowers/specs/2026-09-29-pos-handheld-design.md): Home /
/// Sale / Enquiry / Menu bottom nav, landing on Home, where the scan field
/// looks up a customer; Menu opens a sheet with Settings and Log out. At
/// desktop width it is the 5-item rail. Sections swap in place via
/// [IndexedStack] so cart/search state survives switching tabs; Settings
/// is a full page, pushed rather than swapped in, matching how it's
/// already reached from Login.
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
  // Canonical order backing the body's IndexedStack — index into this list
  // (via `.values.indexOf`) must stay stable regardless of breakpoint, so
  // switching width mid-session doesn't recreate (and lose the state of)
  // any of these pages.
  // Handheld's 4-item nav (handheld spec decision 4). "Menu" is not a
  // section — it opens a sheet — so it sits past the end of
  // `_handheldSections`.
  static const _handheldNavItems = [
    HandheldNavItem(id: NavIds.home, icon: Icons.home_outlined, label: 'Home'),
    HandheldNavItem(
      id: NavIds.sale,
      icon: Icons.shopping_bag_outlined,
      label: 'Sale',
    ),
    HandheldNavItem(id: NavIds.enquiry, icon: Icons.search, label: 'Enquiry'),
    HandheldNavItem(id: NavIds.menu, icon: Icons.menu, label: 'Menu'),
  ];
  static const _handheldSections = [
    _HomeSection.home,
    _HomeSection.sale,
    _HomeSection.enquiry,
  ];

  // Desktop's 5-item nav from the POS Desktop mockup (see
  // docs/superpowers/specs/2026-08-27-pos-desktop-design.md, decision 2) —
  // "Customer" is the full customer search section, "Setup" pushes
  // Settings.
  static const _desktopDestinations = [
    AppNavDestination(icon: Icons.dashboard_outlined, label: 'Home'),
    AppNavDestination(icon: Icons.point_of_sale, label: 'Sale'),
    AppNavDestination(icon: Icons.receipt_long_outlined, label: 'Enquiry'),
    AppNavDestination(icon: Icons.people, label: 'Customer'),
    AppNavDestination(icon: Icons.settings, label: 'Setup'),
  ];
  static const _desktopSections = [
    _HomeSection.home,
    _HomeSection.sale,
    _HomeSection.enquiry,
    _HomeSection.customers,
  ];

  final _customerSearchController = TextEditingController();
  // Null until the first build, which picks each breakpoint's own default
  // landing section (Customers on mobile, Home on desktop) — see
  // `_buildContent`. Set explicitly after that by nav taps and `_goToSale`.
  _HomeSection? _section;
  late final SaleCartViewModel _saleCartViewModel;
  // The privilege picked from a result card's selectable privilege cards
  // (see `_selectPrivilege`) — independent of the (currently unreachable)
  // `_choosePrivilege` dialog below, which was the old "Go to Sale"-gated
  // way to pick one.
  Privilege? _selectedPrivilege;

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
    // A fresh search returns brand-new `Privilege` instances even for the
    // same customer, so a prior selection (matched by identity — see
    // `_selectPrivilege`) can never highlight correctly against them.
    // Clearing it here avoids stale/mismatched selection state.
    if (_selectedPrivilege != null) {
      setState(() => _selectedPrivilege = null);
      _saleCartViewModel.selectPrivilege(null);
    }
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

  void _onDestinationSelected(int index, List<_HomeSection> sections) {
    if (index >= sections.length) {
      _openSettings();
      return;
    }
    setState(() => _section = sections[index]);
  }

  // Ports the two cheap, data-only guards from `customer.ts`'s
  // `checkConditionToSalePage()` — same order, same "Oops !"/"Got it"
  // copy. The rest of that method (POS-authorization checks, shopping-card
  // locking, order-type resolution) needs infrastructure this app doesn't
  // have yet (no `AuthorizeCode` system, no shopping-card-aware
  // `SaleCartViewModel`), so this deliberately stops at switching to the
  // Sale tab rather than attempting to fabricate that machinery.
  //
  // When the customer has any privileges, legacy prompts the cashier to
  // pick one before proceeding (`presentPrivilegeSelection`) — ported here
  // as a blocking dialog: cancelling it keeps the cashier on Customers,
  // picking an option (including "No privilege") stores the choice on
  // [_saleCartViewModel] and then switches tabs.
  Future<void> _goToSale(Customer customer) async {
    final person = customer.person;
    if (person.fastRegister) {
      await _showSaleBlockedDialog('ShoppingCard is fast register');
      return;
    }
    if (!person.isActivate) {
      await _showSaleBlockedDialog('ShoppingCard is not register');
      return;
    }
    if (person.privileges.isEmpty) {
      _saleCartViewModel.selectPrivilege(null);
      setState(() => _section = _HomeSection.sale);
      return;
    }
    final selection = await _choosePrivilege(person.privileges);
    if (selection == null) return;
    _saleCartViewModel.selectPrivilege(selection.privilege);
    setState(() => _section = _HomeSection.sale);
  }

  /// Handheld customer profile (mockup screen 8), pushed over Home.
  void _openHandheldProfile(Customer customer, HomeViewModel viewModel) {
    final selected = _selectedPrivilege;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerProfilePage(
          customer: customer,
          initialPrivilege:
              selected != null &&
                  customer.person.privileges.any((p) => identical(p, selected))
              ? selected
              : null,
          searchFlights: widget
              .customerRegistrationViewModelFactory()
              .searchFlights,
          onAttach: (privilege) => _attachToBill(customer, privilege),
          onEdit: () => _openRegistration(existingCustomer: customer),
        ),
      ),
    );
  }

  /// Handheld "Attach to bill": the same data guards as [_goToSale], but
  /// the privilege was already picked on the profile page, so no picker
  /// dialog. Returns whether the customer was attached (the profile page
  /// closes on true).
  Future<bool> _attachToBill(Customer customer, Privilege? privilege) async {
    final person = customer.person;
    if (person.fastRegister) {
      await _showSaleBlockedDialog('ShoppingCard is fast register');
      return false;
    }
    if (!person.isActivate) {
      await _showSaleBlockedDialog('ShoppingCard is not register');
      return false;
    }
    setState(() {
      _selectedPrivilege = privilege;
      _section = _HomeSection.sale;
    });
    _saleCartViewModel.selectPrivilege(privilege);
    return true;
  }

  Future<_PrivilegeSelection?> _choosePrivilege(List<Privilege> privileges) {
    return showDialog<_PrivilegeSelection>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select privilege'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (var i = 0; i < privileges.length; i++)
                ListTile(
                  key: Key('privilegeOption_$i'),
                  leading: const Icon(
                    Icons.card_giftcard,
                    color: AppColors.goldAccent,
                  ),
                  title: _PrivilegeRow(privilege: privileges[i]),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_PrivilegeSelection(privileges[i])),
                ),
              ListTile(
                key: const Key('noPrivilegeOption'),
                leading: const Icon(
                  Icons.block,
                  color: AppColors.textSecondary,
                ),
                title: const Text('No privilege'),
                onTap: () =>
                    Navigator.of(context).pop(const _PrivilegeSelection(null)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Tapping the already-selected card again deselects it — the simplest
  // toggle affordance for a single-select list. Mirrors the choice through
  // to [_saleCartViewModel] so it's still reflected on the Sale page (see
  // `SalePage`'s `_SelectedPrivilegeRow`).
  void _selectPrivilege(Privilege? privilege) {
    setState(() {
      _selectedPrivilege = identical(_selectedPrivilege, privilege)
          ? null
          : privilege;
    });
    _saleCartViewModel.selectPrivilege(_selectedPrivilege);
  }

  Future<void> _showSaleBlockedDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oops !'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
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

    if (!AppBreakpoints.isWide(context)) {
      return _buildHandheld(context, viewModel);
    }

    const destinations = _desktopDestinations;
    const sections = _desktopSections;
    final section = (_section != null && sections.contains(_section))
        ? _section!
        : sections.first;
    final selectedIndex = sections.indexOf(section);

    return AppShell(
      title: destinations[selectedIndex].label,
      destinations: destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onDestinationSelected(index, sections),
      actions: [
        _sessionInfo(viewModel),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
          onPressed: _logOut,
        ),
      ],
      // IndexedStack only builds the sections valid for the current
      // breakpoint (via `sections`, not the full `_HomeSection.values`) —
      // otherwise a mobile-width IndexedStack would still build (just not
      // paint) the Home/Enquiry pages, and any widget test asserting they
      // aren't present on mobile would find them anyway, since IndexedStack
      // keeps every child mounted regardless of which index is showing.
      body: IndexedStack(
        index: selectedIndex,
        children: [for (final s in sections) _pageFor(s, context, viewModel)],
      ),
    );
  }

  /// Handheld layout (phones, Sunmi, tablets / iPads in portrait) — see
  /// the handheld spec. Same sections, same view-models as desktop; only
  /// the chrome and the Home body differ.
  Widget _buildHandheld(BuildContext context, HomeViewModel viewModel) {
    const sections = _handheldSections;
    final section = (_section != null && sections.contains(_section))
        ? _section!
        : sections.first;
    final selectedIndex = sections.indexOf(section);
    // The Sale screen brings its own order-type header and Checkout bar
    // and, as in the mockup, hides the bottom nav (its back button returns
    // Home).
    final isSale = section == _HomeSection.sale;

    return HandheldScaffold(
      header: isSale ? null : _handheldHeaderFor(section, viewModel),
      fullWidthBody: isSale,
      body: IndexedStack(
        index: selectedIndex,
        children: [
          for (final s in sections) _handheldPageFor(s, context, viewModel),
        ],
      ),
      navBar: isSale
          ? null
          : HandheldNavBar(
              items: _handheldNavItems,
              selectedIndex: selectedIndex,
              onSelected: (index) {
                if (index >= sections.length) {
                  _openHandheldMenu(viewModel);
                  return;
                }
                setState(() => _section = sections[index]);
              },
            ),
    );
  }

  void _showHandheldHome() => setState(() => _section = _HomeSection.home);

  Widget _handheldHeaderFor(_HomeSection section, HomeViewModel viewModel) {
    switch (section) {
      case _HomeSection.home:
        final settings = viewModel.settings;
        return HandheldHomeHeader(
          userName: viewModel.session?.userName ?? '',
          module: settings.moduleKey.isEmpty ? '—' : settings.moduleKey,
          branch: settings.branch.isEmpty ? '—' : settings.branch,
          offlineMode: settings.forceOfflineMode,
          now: DateTime.now(),
        );
      case _HomeSection.sale:
        // Not shown — the Sale screen renders its own header.
        return const HandheldHeader(title: 'Sale');
      case _HomeSection.enquiry:
        return const HandheldHeader(
          title: 'Enquiry',
          subtitle: 'Bills, claim checks, refunds',
        );
      case _HomeSection.customers:
        return const HandheldHeader(title: 'Customer');
    }
  }

  Widget _handheldPageFor(
    _HomeSection section,
    BuildContext context,
    HomeViewModel viewModel,
  ) {
    if (section == _HomeSection.sale) {
      return HandheldSaleView(
        viewModel: _saleCartViewModel,
        onExit: _showHandheldHome,
        // Customer lookup lives on Home's scan field.
        onCustomer: _showHandheldHome,
      );
    }
    if (section != _HomeSection.home) {
      return _pageFor(section, context, viewModel);
    }
    return HandheldHomeView(
      searchController: _customerSearchController,
      onSearch: (_) => _searchCustomer(),
      searchResults: _customerSearchResults(context, viewModel, compact: true),
      onRegister: () => _openRegistration(),
      onSale: () => setState(() => _section = _HomeSection.sale),
      onEnquiry: () => setState(() => _section = _HomeSection.enquiry),
    );
  }

  Future<void> _openHandheldMenu(HomeViewModel viewModel) async {
    final session = viewModel.session;
    final choice = await showHandheldSheet<_MenuChoice>(
      context,
      id: MenuIds.sheet,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Menu', style: HandheldText.sectionTitle),
          if (session != null) ...[
            const SizedBox(height: 4),
            Text(
              '${session.userName} · ${session.userCode}',
              style: HandheldText.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          _MenuRow(
            id: MenuIds.settings,
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Navigator.of(sheetContext).pop(_MenuChoice.settings),
          ),
          _MenuRow(
            id: MenuIds.logout,
            icon: Icons.logout,
            label: 'Log out',
            destructive: true,
            onTap: () => Navigator.of(sheetContext).pop(_MenuChoice.logout),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _MenuChoice.settings:
        _openSettings();
      case _MenuChoice.logout:
        await _logOut();
      case null:
        break;
    }
  }

  Widget _pageFor(
    _HomeSection section,
    BuildContext context,
    HomeViewModel viewModel,
  ) {
    switch (section) {
      case _HomeSection.home:
        return const HomeDashboardPage();
      case _HomeSection.customers:
        return _customerSearchSection(context, viewModel);
      case _HomeSection.sale:
        return SalePage(viewModel: _saleCartViewModel);
      case _HomeSection.enquiry:
        return const EnquiryPage();
    }
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
              // Hidden once a search actually returns a candidate — mirrors
              // legacy's own routing: a found shopping card goes to the
              // profile, a search that turns up nothing goes to
              // registration (`customer.ts`'s `isFound`-gated branch in
              // `ionViewWillEnter()`). Kept visible before any search and
              // after a no-results search, matching that same intent.
              if (viewModel.customerSearchResults.isEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                // Own card, physically separated from Search, so it can't
                // be mis-tapped for it — see the "own card below Search"
                // mockup decision.
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _customerSearchResults(
    BuildContext context,
    HomeViewModel viewModel, {
    bool compact = false,
  }) {
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
    if (compact) {
      // Handheld: a tile per match; the full profile opens on tap.
      final results = viewModel.customerSearchResults;
      return Column(
        children: [
          for (var i = 0; i < results.length; i++)
            HandheldCustomerResultTile(
              id: HomeIds.customerTile(i),
              customer: results[i],
              onTap: () => _openHandheldProfile(results[i], viewModel),
            ),
        ],
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
                onGoToSale: _goToSale,
                selectedPrivilege: _selectedPrivilege,
                onSelectPrivilege: _selectPrivilege,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

/// One tappable row of the handheld Menu sheet.
class _MenuRow extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _MenuRow({
    required this.id,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.textPrimary;
    return TestId(
      id,
      child: ListTile(
        minTileHeight: HandheldMetrics.primaryActionHeight,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: destructive ? color : AppColors.goldDark),
        title: Text(label, style: HandheldText.body.copyWith(color: color)),
        onTap: onTap,
      ),
    );
  }
}

/// Result of the "Select privilege" dialog — distinct from the dialog's
/// `showDialog` future resolving to `null` on cancel (back/outside tap),
/// since picking "No privilege" also carries a `null` [privilege].
class _PrivilegeSelection {
  final Privilege? privilege;

  const _PrivilegeSelection(this.privilege);
}

/// Search-result card, restyled to match legacy smart-pos's `CustomerPage`
/// header: the shopping card number, name, passport, nationality, customer
/// type, agent, guide, and register status are always visible (legacy shows
/// exactly one customer per screen, so its whole header is static); flight
/// info and the privilege/wallet/tour data sit directly below that header,
/// always visible too — there is no expand/collapse step. The edit icon
/// next to the register status ports legacy's `btn-edit-icon` — it opens
/// the same registration form used for new customers, prefilled from this
/// one (`onEdit`). The "Go to Sale" button ports the two data-only guards
/// from legacy's `checkConditionToSalePage()` before switching tabs — see
/// `_HomePageState._goToSale`'s doc comment for what's deliberately not
/// replicated.
class _CustomerResultCard extends StatelessWidget {
  final Customer customer;
  final bool isAirportMpos;
  final ValueChanged<Customer> onEdit;
  final Future<void> Function(Customer) onGoToSale;
  final Privilege? selectedPrivilege;
  final ValueChanged<Privilege?> onSelectPrivilege;

  const _CustomerResultCard({
    required this.customer,
    required this.isAirportMpos,
    required this.onEdit,
    required this.onGoToSale,
    required this.selectedPrivilege,
    required this.onSelectPrivilege,
  });

  @override
  Widget build(BuildContext context) {
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
                    onEdit: onEdit,
                    onGoToSale: onGoToSale,
                  ),
                ),
              ],
            ),
          ),
          _CustomerDetails(
            customer: customer,
            isAirportMpos: isAirportMpos,
            selectedPrivilege: selectedPrivilege,
            onSelectPrivilege: onSelectPrivilege,
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
      width: 72,
      decoration: const BoxDecoration(
        color: Color(0x14C5A059), // AppColors.goldAccent at low opacity
        border: Border(
          right: BorderSide(color: AppColors.goldAccent, width: 4),
        ),
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
                        child: _badgeLabels(
                          context,
                          customer.person,
                          onDark: true,
                        ),
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
  final Future<void> Function(Customer) onGoToSale;

  const _CustomerHeaderDetail({
    required this.customer,
    required this.onEdit,
    required this.onGoToSale,
  });

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
          const Divider(
            color: AppColors.goldAccent,
            thickness: 2,
            height: AppSpacing.md,
          ),
          Text(
            person.englishName.isEmpty
                ? 'Unnamed customer'
                : person.englishName,
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

/// Always-visible, directly below the header — the flight block (styled
/// like legacy's blue-accented flight card, or a compact "not available"
/// bar when there's no flight) plus privilege/wallet/tour. Previously sat
/// behind a "Details" tap-to-expand toggle; removed so flight info reads as
/// part of the customer's info rather than a separate step.
class _CustomerDetails extends StatelessWidget {
  final Customer customer;
  final bool isAirportMpos;
  final Privilege? selectedPrivilege;
  final ValueChanged<Privilege?> onSelectPrivilege;

  const _CustomerDetails({
    required this.customer,
    required this.isAirportMpos,
    required this.selectedPrivilege,
    required this.onSelectPrivilege,
  });

  @override
  Widget build(BuildContext context) {
    final person = customer.person;
    final extras = <Widget>[
      ..._privilegeSection(context, person.privileges),
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

  // Rendered as tappable cards, not read-only rows — the customer's
  // privileges (when any) are directly selectable from the search result
  // now, rather than read-only display text. Tapping a card selects it
  // (again to deselect); see `_HomePageState._selectPrivilege`.
  List<Widget> _privilegeSection(
    BuildContext context,
    List<Privilege> privileges,
  ) {
    if (privileges.isEmpty) return const [];
    final textTheme = Theme.of(context).textTheme;
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select privilege', style: textTheme.labelLarge),
          for (var i = 0; i < privileges.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: _SelectablePrivilegeCard(
                key: Key('privilegeCard_$i'),
                privilege: privileges[i],
                selected: identical(selectedPrivilege, privileges[i]),
                onTap: () => onSelectPrivilege(privileges[i]),
              ),
            ),
        ],
      ),
    ];
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
          BoxShadow(
            color: Color(0x1F0A192F),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
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
                    const Icon(
                      Icons.flight,
                      color: Colors.white,
                      size: AppSizing.iconSize,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      person.flightCode,
                      style: textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                      ),
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
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            person.flightTime,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      _FactRow(label: 'Route', value: person.flightRouteDetail),
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
          BoxShadow(
            color: Color(0x1F0A192F),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
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
          Expanded(
            child: Text(
              'Flight: Not available',
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One privilege — `Name` prominent (the label legacy's own privilege
/// *picker* shows, `presentPrivilegeSelection`'s action-sheet buttons),
/// `[TypeCode]:PromoCode` as secondary detail (the format legacy's
/// *settled-selection* display actually uses, `sale.html:138-141`). There's
/// no native "list every privilege" screen in legacy to mirror beyond
/// those two real display precedents — this combines both rather than
/// inventing a third format.
class _PrivilegeRow extends StatelessWidget {
  final Privilege privilege;

  const _PrivilegeRow({required this.privilege});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // `[TypeCode]:PromoCode` — legacy's actual persistent display of a
    // privilege (`sale.html:138-141`'s `*ngIf="isMember && selectPrivilege
    // != null"` row), not a generic dump. Legacy never displays
    // `PrivilegeModel.Discount` directly anywhere — the amount shown at
    // checkout is a computed order-level total (`TotalBillingAmount
    // .DiscountAmount`), not this field — so it's left off here too.
    final code = privilege.typeCode.isEmpty && privilege.promoCode.isEmpty
        ? ''
        : '[${privilege.typeCode}]:${privilege.promoCode}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.card_giftcard,
          size: AppSizing.iconSize,
          color: AppColors.goldAccent,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                privilege.name.isEmpty ? 'Privilege' : privilege.name,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (code.isNotEmpty)
                Text(
                  code,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One privilege rendered as a tappable, single-select card — the "card
/// privilege ให้เลือก" the customer's info now shows inline (previously,
/// picking a privilege only happened via the `_choosePrivilege` dialog
/// gated behind "Go to Sale", which is currently unreachable). Same
/// Name/`[TypeCode]:PromoCode` display as [_PrivilegeRow], plus a
/// selected/unselected visual state.
class _SelectablePrivilegeCard extends StatelessWidget {
  final Privilege privilege;
  final bool selected;
  final VoidCallback onTap;

  const _SelectablePrivilegeCard({
    super.key,
    required this.privilege,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final code = privilege.typeCode.isEmpty && privilege.promoCode.isEmpty
        ? ''
        : '[${privilege.typeCode}]:${privilege.promoCode}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizing.cornerRadiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0x1FC5A059) // AppColors.goldAccent at low opacity
              : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.goldAccent : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizing.cornerRadiusSm),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: AppSizing.iconSize,
              color: selected ? AppColors.goldAccent : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    privilege.name.isEmpty ? 'Privilege' : privilege.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (code.isNotEmpty)
                    Text(
                      code,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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

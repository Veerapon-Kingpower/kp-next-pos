import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/app/session_state.dart';
import '../../../core/presentation/desktop/desktop.dart';
import '../../../core/presentation/handheld/handheld.dart';
import '../../../core/presentation/test_ids.dart';
import '../../../core/presentation/widgets/test_id.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/app_dialogs.dart';
import '../../../core/presentation/widgets/app_shell.dart';
import '../../../core/presentation/widgets/empty_state_view.dart';
import '../../../core/presentation/widgets/loading_view.dart';
import '../../../core/presentation/widgets/retryable_error_view.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/domain/usecases/logout_usecase.dart';
import '../../customer/domain/entities/customer.dart';
import '../../customer/domain/entities/privilege.dart';
import '../../customer/presentation/customer_registration_page.dart';
import '../../customer/presentation/customer_registration_view_model.dart';
import '../../customer/presentation/handheld/customer_profile_page.dart';
import '../../customer/presentation/widgets/privilege_radio_list.dart';
import '../../enquiry/presentation/enquiry_page.dart';
import '../../enquiry/presentation/handheld_enquiry_view.dart';
import '../../sale/domain/entities/sale_order_context.dart';
import '../../sale/presentation/handheld/handheld_sale_view.dart';
import '../../sale/presentation/handheld/sale_order_type.dart';
import '../../sale/presentation/sale_cart_view_model.dart';
import '../../sale/presentation/widgets/leave_sale_prompt.dart';
import '../../sale/presentation/widgets/sale_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../settings/presentation/settings_view_model.dart';
import 'handheld/handheld_home_view.dart';
import 'home_customer_result.dart';
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
    DesktopNavItem(id: NavIds.home, icon: Icons.home_outlined, label: 'Home'),
    DesktopNavItem(
      id: NavIds.sale,
      icon: Icons.shopping_bag_outlined,
      label: 'Sale',
    ),
    DesktopNavItem(id: NavIds.enquiry, icon: Icons.search, label: 'Enquiry'),
    DesktopNavItem(
      id: NavIds.customer,
      icon: Icons.badge_outlined,
      label: 'Customer',
    ),
    DesktopNavItem(
      id: NavIds.setup,
      icon: Icons.settings_outlined,
      label: 'Setup',
    ),
  ];
  static const _desktopSections = [
    _HomeSection.home,
    _HomeSection.sale,
    _HomeSection.enquiry,
    _HomeSection.customers,
  ];

  final _customerSearchController = TextEditingController();
  final _dashboardScanController = TextEditingController();
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
  // Desktop Customer tab (S8): which search result the profile / form show,
  // and the embedded form's view model, recreated per shown customer (see
  // `_customerForm`).
  int _selectedResult = 0;
  // Desktop Home lookup ("Find customer to start a sale"): shown in place
  // of the dashboard while on, for the query typed there. The results are
  // the same `customerSearchResults` the Customer tab shows, so Edit
  // profile / Register just switch to that tab.
  bool _homeLookup = false;
  String _homeQuery = '';
  DateTime _homeFoundAt = DateTime.now();
  int _formGeneration = 0;
  String? _formKey;
  CustomerRegistrationViewModel? _formViewModel;

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
    _saleCartViewModel = widget.saleCartViewModelFactory();
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _dashboardScanController.dispose();
    super.dispose();
  }

  // Sign out without asking again — the cashier already chose Log out
  // (after a failed unlock). The card could not be unlocked, so no
  // release is attempted.
  Future<void> _signOutNow() async {
    await widget.logoutUseCase();
    widget.sessionState.signedOut();
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

    // Legacy `unlockShoppingCard()` before logging out; needs the session
    // key, so it runs first.
    await _saleCartViewModel.releaseOrder();
    await widget.logoutUseCase();
    widget.sessionState.signedOut();
  }

  Future<void> _searchCustomer() {
    // A fresh search returns brand-new `Privilege` instances even for the
    // same customer, so a prior selection (matched by identity — see
    // `_selectPrivilege`) can never highlight correctly against them.
    // Clearing it here avoids stale/mismatched selection state.
    if (_selectedPrivilege != null) {
      setState(() => _selectedPrivilege = null);
      _saleCartViewModel.selectPrivilege(null);
    }
    _selectedResult = 0;
    // A search from elsewhere replaces what the Home lookup was showing.
    _homeLookup = false;
    return widget.viewModel.searchCustomer(_customerSearchController.text);
  }

  // Desktop Home scan / Search: found (registered or not) → the result on
  // Home; not found → the Customer tab's register form.
  Future<void> _lookUpFromHome(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    _customerSearchController.text = query;
    final search = _searchCustomer();
    setState(() {
      _homeLookup = true;
      _homeQuery = query;
    });
    await search;
    if (!mounted || !_homeLookup) return;
    final viewModel = widget.viewModel;
    if (viewModel.customerSearchError == null &&
        _notFound(viewModel.customerSearchResults)) {
      // The Customer tab's form picks up an `isFound: false` record as its
      // prefilled "Register customer" (legacy passes `customer` along).
      _dashboardScanController.clear();
      setState(() {
        _homeLookup = false;
        _section = _HomeSection.customers;
      });
      return;
    }
    setState(() => _homeFoundAt = DateTime.now());
  }

  // `GetCustomer`'s "not found" is a record with `isFound: false`, not an
  // empty list — legacy `customer.ts` checks `Data[0]` and its `isFound`
  // and sends either case to CustomerFormPage (REGISTER) with that record.
  static bool _notFound(List<Customer> results) =>
      results.isEmpty || !results.first.isFound;

  // Clear (Esc): back to the dashboard with nothing looked up.
  void _clearHomeLookup() {
    _dashboardScanController.clear();
    _newCustomer();
    setState(() => _homeLookup = false);
  }

  // Handheld Home scan: one match opens its profile, none opens Register.
  Future<void> _lookUpOnHandheld() async {
    await _searchCustomer();
    if (!mounted) return;
    final viewModel = widget.viewModel;
    if (viewModel.customerSearchError != null) return;
    final results = viewModel.customerSearchResults;
    if (_notFound(results)) {
      _openRegistration(
        existingCustomer: results.isEmpty ? null : results.first,
      );
    } else if (results.length == 1) {
      _openHandheldProfile(results.first, viewModel);
    }
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

  Future<void> _openRegistration({Customer? existingCustomer}) async {
    final session = widget.viewModel.session;
    if (session == null) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final homeRoute = ModalRoute.of(context);
    final shoppingCard = await navigator.push<String>(
      MaterialPageRoute(
        builder: (_) => CustomerRegistrationPage(
          viewModel: widget.customerRegistrationViewModelFactory(),
          userCode: session.userCode,
          isAirportMpos: widget.viewModel.settings.isAirportMpos,
          existingCustomer: existingCustomer,
        ),
      ),
    );
    // Null = backed out without saving.
    if (shoppingCard == null || !mounted) return;
    // Saved: close anything still over Home (e.g. the handheld profile the
    // edit started from).
    if (homeRoute != null) navigator.popUntil((route) => route == homeRoute);
    _showSavedCustomerOnHome(shoppingCard);
  }

  // After a register / update: back to Home, looking up the saved card so
  // Home shows what the server now holds.
  void _showSavedCustomerOnHome(String shoppingCard) {
    setState(() => _section = _HomeSection.home);
    if (shoppingCard.isEmpty) {
      _clearHomeLookup();
      return;
    }
    if (AppBreakpoints.isWide(context)) {
      _lookUpFromHome(shoppingCard);
      return;
    }
    _customerSearchController.text = shoppingCard;
    _searchCustomer();
  }

  Future<void> _onDestinationSelected(
    int index,
    List<_HomeSection> sections,
  ) async {
    if (index >= sections.length) {
      _openSettings();
      return;
    }
    final target = sections[index];
    // Leaving Sale is leaving legacy's Sale page (`ionViewCanLeave`): the
    // leave prompt runs and the shopping card is unlocked before going
    // anywhere else; Cancel stays on Sale.
    if (_section == _HomeSection.sale &&
        target != _HomeSection.sale &&
        _saleCartViewModel.hasCustomer) {
      final left = await confirmLeaveSale(
        context,
        _saleCartViewModel,
        isAirportMpos: widget.viewModel.settings.isAirportMpos,
        onSignOut: _signOutNow,
      );
      if (!left || !mounted) return;
    }
    setState(() => _section = target);
  }

  // Ports the two cheap, data-only guards from `customer.ts`'s
  // `checkConditionToSalePage()` — same order, same "Oops !"/"Got it"
  // copy. The rest of that method (POS-authorization checks, order-type
  // resolution) needs infrastructure this app doesn't have yet (no
  // `AuthorizeCode` system). Entering Sale then opens and locks the card's
  // order, as legacy Sale's `getOrder()` does.
  //
  // Legacy prompts for a privilege here (`presentPrivilegeSelection`); the
  // profile's radio list already asks that up front ("No privilege" by
  // default), so its pick, [_selectedPrivilege], is carried over as-is.
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
    final selected = _selectedPrivilege;
    final privilege = person.privileges.any((p) => identical(p, selected))
        ? selected
        : null;
    _saleCartViewModel.selectPrivilege(privilege);
    setState(() => _section = _HomeSection.sale);
    // Legacy `goToSalePage()` params; tier and wallets only for a member.
    final isMember = person.memberId.isNotEmpty;
    await _saleCartViewModel.openOrder(
      SaleOrderContext(
        shoppingCard: person.shoppingCard,
        memberId: person.memberId,
        tier: isMember ? privilege?.raw : null,
        walletMembers: isMember ? person.walletMembers : const [],
        cardGroupCode: person.cardGroupCode,
        cardTypeCode: person.cardTypeCode,
      ),
    );
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
          onPrivilegeChanged: (privilege) {
            setState(() => _selectedPrivilege = privilege);
            _saleCartViewModel.selectPrivilege(privilege);
          },
          onEdit: () => _openRegistration(existingCustomer: customer),
          onGoToSale: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await _goToSale(customer);
          },
        ),
      ),
    );
  }

  // Radio-list pick (null = "No privilege"). Mirrors the choice through to
  // [_saleCartViewModel] so it's still reflected on the Sale page (see
  // `SalePage`'s `_SelectedPrivilegeRow`).
  void _selectPrivilege(Privilege? privilege) {
    setState(() => _selectedPrivilege = privilege);
    _saleCartViewModel.selectPrivilege(privilege);
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

    final session = viewModel.session;
    final settings = viewModel.settings;
    String orDash(String v) => v.isEmpty ? '—' : v;

    return DesktopShell(
      items: destinations,
      selectedIndex: selectedIndex,
      onSelected: (index) => _onDestinationSelected(index, sections),
      footerItems: [
        DesktopNavItem(
          id: NavIds.signOut,
          icon: Icons.logout,
          label: 'Sign out',
          onTap: _logOut,
        ),
      ],
      // The Sale screen names its order type, as in the mockup; the app
      // only runs NORMAL bills today (see SaleOrderType).
      title: section == _HomeSection.sale
          ? 'Sale · ${SaleOrderType.normal.label}'
          : destinations[selectedIndex].label,
      contextItems: [
        // The login's `MachineEnv.MachineNo` (legacy `home.html` shows
        // `userInfo.MachineEnv.MachineNo`), not the device-settings number.
        DesktopContextItem(
          label: 'Machine',
          value: orDash(session?.machineNo ?? ''),
        ),
        DesktopContextItem(label: 'Module', value: orDash(settings.moduleKey)),
        DesktopContextItem(label: 'Branch', value: orDash(settings.branch)),
      ],
      user: session == null
          ? null
          : DesktopUser(
              name: session.userName,
              detail: 'Cashier · ${session.userCode}',
            ),
      // IndexedStack only builds the sections valid for the current
      // breakpoint (via `sections`, not the full `_HomeSection.values`) —
      // otherwise the other layout's pages would be built (just not
      // painted) and tests asserting their absence would find them.
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
    // Enquiry also paints its own dark header (search + filters) but keeps
    // the bottom nav.
    final ownsHeader = isSale || section == _HomeSection.enquiry;

    return HandheldScaffold(
      header: ownsHeader ? null : _handheldHeaderFor(section, viewModel),
      fullWidthBody: ownsHeader,
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

  // Leaving the handheld Sale screen is leaving legacy's Sale page: the
  // leave prompt runs, then the held shopping card is unlocked.
  Future<void> _leaveHandheldSale() async {
    final left = await confirmLeaveSale(
      context,
      _saleCartViewModel,
      isAirportMpos: widget.viewModel.settings.isAirportMpos,
      onSignOut: _signOutNow,
    );
    if (left && mounted) _showHandheldHome();
  }

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
    if (section == _HomeSection.enquiry) {
      return const HandheldEnquiryView();
    }
    if (section == _HomeSection.sale) {
      return HandheldSaleView(
        viewModel: _saleCartViewModel,
        onExit: _leaveHandheldSale,
        // Customer lookup lives on Home's scan field.
        onCustomer: _leaveHandheldSale,
        isAirportMpos: viewModel.settings.isAirportMpos,
      );
    }
    if (section != _HomeSection.home) {
      return _pageFor(section, context, viewModel);
    }
    return HandheldHomeView(
      searchController: _customerSearchController,
      onSearch: (_) => _lookUpOnHandheld(),
      searchResults: _customerSearchResults(context, viewModel),
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
        return HomeDashboardPage(
          scanController: _dashboardScanController,
          // The Home scan is a customer lookup (shopping card / passport /
          // ID card number).
          onScan: _lookUpFromHome,
          onRegister: () => _openRegistration(),
          onEnquiry: () => setState(() => _section = _HomeSection.enquiry),
          lookup: _homeLookup ? _homeLookupFor(viewModel) : null,
        );
      case _HomeSection.customers:
        return _customerSearchSection(context, viewModel);
      case _HomeSection.sale:
        return SalePage(
          viewModel: _saleCartViewModel,
          isAirportMpos: viewModel.settings.isAirportMpos,
          onExit: () => setState(() => _section = _HomeSection.home),
          onFindCustomer: () => setState(() => _section = _HomeSection.home),
          onSignOut: _signOutNow,
        );
      case _HomeSection.enquiry:
        return const EnquiryPage();
    }
  }

  HomeLookup _homeLookupFor(HomeViewModel viewModel) {
    final results = viewModel.customerSearchResults;
    final index = _selectedResult < results.length ? _selectedResult : 0;
    final customer = results.isEmpty ? null : results[index];
    void editProfile() => setState(() => _section = _HomeSection.customers);

    final Widget body;
    if (viewModel.isSearchingCustomer) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingView(),
      );
    } else if (viewModel.customerSearchError != null) {
      body = RetryableErrorView(
        message: viewModel.customerSearchError!,
        onRetry: () => _lookUpFromHome(_homeQuery),
      );
    } else if (customer == null) {
      body = const SizedBox.shrink();
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (results.length > 1) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < results.length; i++)
                  TestId(
                    DesktopIds.homeResult(i),
                    child: ChoiceChip(
                      label: Text(
                        results[i].person.englishName.isNotEmpty
                            ? results[i].person.englishName
                            : results[i].person.shoppingCard,
                      ),
                      selected: i == index,
                      onSelected: (_) => _showResult(i),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          HomeCustomerResult(
            customer: customer,
            query: _homeQuery,
            foundAt: _homeFoundAt,
            now: DateTime.now(),
            selectedPrivilege: _selectedPrivilege,
            onSelectPrivilege: _selectPrivilege,
            onStartSale: () => _goToSale(customer),
            onRegister: editProfile,
            onEnquiry: () => setState(() => _section = _HomeSection.enquiry),
            onEditProfile: editProfile,
            onClear: _clearHomeLookup,
          ),
        ],
      );
    }

    final registered = customer?.person.isActivate ?? false;
    return HomeLookup(
      step: customer == null
          ? HomeLookupStep.search
          : registered
          ? HomeLookupStep.sale
          : HomeLookupStep.register,
      body: body,
      onClear: _clearHomeLookup,
      onStartSale: registered ? () => _goToSale(customer!) : null,
      onRegister: customer != null && !registered ? editProfile : null,
    );
  }

  /// Desktop Customer (POS Desktop mockup screen 8): one identifier
  /// resolves to one customer, so the form sits where a result list would
  /// be — the edit form on the left (a new-customer form until a search
  /// finds someone, mirroring legacy's found → profile / not found →
  /// register routing), the profile on the right.
  Widget _customerSearchSection(BuildContext context, HomeViewModel viewModel) {
    final results = viewModel.customerSearchResults;
    final index = _selectedResult < results.length ? _selectedResult : 0;
    final customer = results.isEmpty ? null : results[index];
    final profile = TestId(
      DesktopCustomerIds.profile,
      child: _customerProfile(viewModel, customer, index),
    );
    final form = _customerForm(viewModel, customer);

    return Padding(
      padding: const EdgeInsets.all(DesktopMetrics.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _customerSearchBar(viewModel),
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Too narrow for side-by-side (small landscape tablets):
                // profile above the form.
                if (constraints.maxWidth < 1000) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [profile, const SizedBox(height: 20), form],
                    ),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: SingleChildScrollView(child: form)),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: constraints.maxWidth >= 1300 ? 560 : 440,
                      child: SingleChildScrollView(child: profile),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerSearchBar(HomeViewModel viewModel) {
    return DesktopPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TestId(
                  DesktopCustomerIds.searchField,
                  child: TextField(
                    controller: _customerSearchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchCustomer(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: _customerSearchHint,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.goldDark,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(
                          color: AppColors.goldMuted,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IntrinsicWidth(
                child: DesktopButton(
                  id: DesktopCustomerIds.searchButton,
                  label: 'Search',
                  hotkey: 'ENTER',
                  height: 58,
                  onPressed: viewModel.isSearchingCustomer
                      ? null
                      : _searchCustomer,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 170,
                child: DesktopButton(
                  id: DesktopCustomerIds.newCustomerButton,
                  label: 'New customer',
                  icon: Icons.person_add_alt_1_outlined,
                  secondary: true,
                  height: 58,
                  onPressed: _newCustomer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // `Register/GetCustomer` takes the value as-is — no format
          // detection, so no "detected ID type" is claimed.
          const Text(
            'Scan or type a shopping card, passport no. or ID card number.',
            style: TextStyle(fontSize: 12.5, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  // A fresh embedded form (and view model) per shown customer — or per
  // "New customer" — so its fields always start from that customer.
  Widget _customerForm(HomeViewModel viewModel, Customer? customer) {
    final key = '${identityHashCode(customer)}#$_formGeneration';
    if (key != _formKey || _formViewModel == null) {
      _formKey = key;
      _formViewModel = widget.customerRegistrationViewModelFactory();
    }
    return CustomerRegistrationPage(
      key: ValueKey(key),
      embedded: true,
      viewModel: _formViewModel!,
      userCode: viewModel.session?.userCode ?? '',
      isAirportMpos: viewModel.settings.isAirportMpos,
      existingCustomer: customer,
      onSaved: _onCustomerSaved,
    );
  }

  // The embedded form saved: back to Home with the saved card looked up.
  void _onCustomerSaved(String shoppingCard) {
    setState(() => _formGeneration++);
    _showSavedCustomerOnHome(shoppingCard);
  }

  void _newCustomer() {
    _customerSearchController.clear();
    if (_selectedPrivilege != null) _saleCartViewModel.selectPrivilege(null);
    setState(() {
      _selectedPrivilege = null;
      _selectedResult = 0;
      _formGeneration++;
    });
    widget.viewModel.clearCustomerSearch();
  }

  void _showResult(int index) {
    if (_selectedPrivilege != null) _saleCartViewModel.selectPrivilege(null);
    setState(() {
      _selectedPrivilege = null;
      _selectedResult = index;
    });
  }

  Widget _customerProfile(
    HomeViewModel viewModel,
    Customer? customer,
    int index,
  ) {
    const muted = TextStyle(fontSize: 13.5, color: AppColors.mutedText);
    if (viewModel.isSearchingCustomer) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: LoadingView(),
      );
    }
    if (viewModel.customerSearchError != null) {
      return RetryableErrorView(
        message: viewModel.customerSearchError!,
        onRetry: _searchCustomer,
      );
    }
    if (customer == null) {
      return DesktopPanel(
        id: DesktopCustomerIds.profileEmpty,
        title: 'Profile',
        child: viewModel.hasSearchedCustomer
            ? const Column(
                children: [
                  EmptyStateView(
                    message: 'No customer found.',
                    icon: Icons.person_search_outlined,
                  ),
                  Text(
                    'Register them with the form.',
                    textAlign: TextAlign.center,
                    style: muted,
                  ),
                ],
              )
            : const Text(
                'Search a customer to see their profile here. To register '
                'a new one, fill in the form.',
                style: muted,
              ),
      );
    }

    final results = viewModel.customerSearchResults;
    final expiring = customer.person.caratNearlyExpired;
    Widget stat(String id, String label, String value, {String? note}) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: DesktopText.fieldLabel),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: TestId(
                    id,
                    child: Text(value, style: DesktopText.kpiValue),
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  TestId(
                    ProfileIds.caratExpiring,
                    child: Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (results.length > 1) ...[
          DesktopPanel(
            title: '${results.length} matches',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < results.length; i++)
                  TestId(
                    DesktopCustomerIds.result(i),
                    child: ChoiceChip(
                      label: Text(
                        results[i].person.englishName.isNotEmpty
                            ? results[i].person.englishName
                            : results[i].person.shoppingCard,
                      ),
                      selected: i == index,
                      onSelected: (_) => _showResult(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Equal-height tiles even when only Carat has an expiring line.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              stat(
                ProfileIds.caratStat,
                'Carat',
                formatCarat(customer.person.caratBalance),
                note: expiring == null
                    ? null
                    : formatCaratExpiring(expiring.amount, expiring.at),
              ),
              const SizedBox(width: 10),
              stat(
                ProfileIds.ePurseStat,
                'e-Purse',
                formatEPurse(customer.person.ePurseBalance),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _CustomerResultCard(
          customer: customer,
          selectedPrivilege: _selectedPrivilege,
          onSelectPrivilege: _selectPrivilege,
        ),
        // Always shown; only a registered (`isActivate`) card can press it.
        const SizedBox(height: 16),
        DesktopButton(
          id: ProfileIds.goToSaleButton,
          label: 'Start sale',
          icon: Icons.shopping_bag_outlined,
          height: 58,
          onPressed: customer.person.isActivate
              ? () => _goToSale(customer)
              : null,
        ),
      ],
    );
  }

  /// Handheld Home lookup results: a tile per match; the full profile
  /// opens on tap.
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

/// Search-result card: the privilege radio list. It is the desktop Customer
/// tab's profile body, beside the edit form, so the name, shopping card,
/// passport, nationality, customer type, agent/guide, flight and register
/// status are left to that form instead of being repeated here; the wallets
/// are the Carat / e-Purse tiles above the card. The member-card face is
/// left out for now.
class _CustomerResultCard extends StatelessWidget {
  final Customer customer;
  final Privilege? selectedPrivilege;
  final ValueChanged<Privilege?> onSelectPrivilege;

  const _CustomerResultCard({
    required this.customer,
    required this.selectedPrivilege,
    required this.onSelectPrivilege,
  });

  @override
  Widget build(BuildContext context) {
    // The same radio list as the handheld profile: "No privilege" (default)
    // plus each privilege; see `_HomePageState._selectPrivilege`.
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: PrivilegeRadioList(
        privileges: customer.person.privileges,
        selected: selectedPrivilege,
        onChanged: onSelectPrivilege,
      ),
    );
  }
}

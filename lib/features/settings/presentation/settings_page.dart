import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/app/router.dart';
import '../../../core/app/session_state.dart';
import '../../../core/config/device_settings.dart';
import '../../../core/presentation/desktop/desktop.dart';
import '../../../core/presentation/handheld/handheld.dart';
import '../../../core/presentation/test_ids.dart';
import '../../../core/presentation/widgets/app_shell.dart';
import '../../../core/presentation/widgets/loading_view.dart';
import '../../../core/presentation/widgets/retryable_error_view.dart';
import '../../../core/presentation/widgets/test_id.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'settings_view_model.dart';

/// First-time/ongoing device configuration — ports the legacy `SettingsPage`
/// (branch, module, endpoints, default page, sub-branch, pickup codes,
/// device UUID; see `inventory.md`). Device UUID binding via a platform
/// device-ID plugin (parity-checklist.md) is out of scope here — that's
/// hardware/platform work for task 7.x, so the UUID field stays a plain
/// editable/generatable string in the meantime.
class SettingsPage extends StatefulWidget {
  final SettingsViewModel viewModel;
  final SessionState? sessionState;

  const SettingsPage({super.key, required this.viewModel, this.sessionState});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late final _moduleKey = TextEditingController();
  late final _branch = TextEditingController();
  late final _subBranchCode = TextEditingController();
  late final _location = TextEditingController();
  late final _machine = TextEditingController();
  late final _company = TextEditingController();
  late final _serial = TextEditingController();
  late final _macAddress = TextEditingController();
  late final _ipAddress = TextEditingController();
  late final _printerName = TextEditingController();
  late final _edcPort = TextEditingController();
  late final _webServiceEndpoint = TextEditingController();
  late final _updateEndpoint = TextEditingController();
  late final _uuid = TextEditingController();
  late final _saleEngineEndpoint = TextEditingController();
  late final _flightApi = TextEditingController();
  late final _cashCardApi = TextEditingController();
  late final _webServiceEndpointFocus = FocusNode();
  bool _isAirportMpos = false;
  bool _forceOfflineMode = false;
  bool _showUuidQrCode = false;

  bool _initialized = false;
  String? _lastShownSubBranchError;
  bool _navigatedAfterSave = false;

  @override
  void initState() {
    super.initState();
    // Separate from the GetBuilder used for rendering in build(): this
    // fires exactly once per real update() call (GetxController genuinely
    // implements Listenable), which the one-shot guards below
    // (_initialized, _navigatedAfterSave, _lastShownSubBranchError) depend
    // on — GetBuilder's own builder callback re-runs on every ambient
    // rebuild, not just on update(), which would break that cardinality.
    widget.viewModel.addListener(_onSideEffect);
    widget.viewModel.load();
    _webServiceEndpointFocus.addListener(_onWebServiceEndpointFocusChange);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onSideEffect);
    _webServiceEndpointFocus.removeListener(_onWebServiceEndpointFocusChange);
    _webServiceEndpointFocus.dispose();
    for (final controller in [
      _moduleKey,
      _branch,
      _subBranchCode,
      _location,
      _machine,
      _company,
      _serial,
      _macAddress,
      _ipAddress,
      _printerName,
      _edcPort,
      _webServiceEndpoint,
      _updateEndpoint,
      _uuid,
      _saleEngineEndpoint,
      _flightApi,
      _cashCardApi,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Triggers on blur (focus loss by any means — tabbing away, tapping
  /// another field, or the keyboard's "Done" action's default unfocus) so
  /// the sub-branch dropdown refreshes without requiring the keyboard's
  /// "Done" action specifically.
  void _onWebServiceEndpointFocusChange() {
    if (!_webServiceEndpointFocus.hasFocus) {
      widget.viewModel.loadSubBranches(_webServiceEndpoint.text);
    }
  }

  void _onSideEffect() {
    if (!_initialized &&
        widget.viewModel.loadStatus == SettingsLoadStatus.ready) {
      // _applySettings mutates local widget state (_isAirportMpos) that
      // isn't part of the GetX-managed view model, so GetBuilder's own
      // update()-driven rebuild can't be relied on to pick it up — force
      // it explicitly rather than depending on GetX listener ordering.
      setState(() => _applySettings(widget.viewModel.settings));
      _initialized = true;
    }
    if (widget.viewModel.saveStatus == SettingsSaveStatus.success) {
      widget.sessionState?.deviceSetupCompleted();
      if (!_navigatedAfterSave) {
        _navigatedAfterSave = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // Opened as a modal from the Login page's settings icon (pushed
          // on top, so it can pop) vs. the app's own first-time-setup
          // route (nothing to pop back to) — navigate accordingly instead
          // of relying solely on the SessionState-driven router redirect,
          // which only fires as an indirect side effect and isn't visible
          // to a route pushed outside go_router's own navigation.
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else if (GoRouter.maybeOf(context) != null) {
            context.go(AppRoutes.login);
          }
        });
      }
    }
    final subBranchError = widget.viewModel.subBranchLoadError;
    if (subBranchError != null && subBranchError != _lastShownSubBranchError) {
      _lastShownSubBranchError = subBranchError;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Connection error'),
            content: Text(subBranchError),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  void _applySettings(DeviceSettings settings) {
    _moduleKey.text = settings.moduleKey;
    _branch.text = settings.branch;
    _subBranchCode.text = settings.subBranchCode;
    _location.text = settings.location;
    _machine.text = settings.machine == 0 ? '' : settings.machine.toString();
    _company.text = settings.company;
    _serial.text = settings.serial;
    _macAddress.text = settings.macAddress;
    _ipAddress.text = settings.ipAddress;
    _printerName.text = settings.printerName;
    _edcPort.text = settings.edcPort;
    _webServiceEndpoint.text = settings.webServiceEndpoint;
    _updateEndpoint.text = settings.updateEndpoint;
    _uuid.text = settings.uuid;
    _saleEngineEndpoint.text = settings.saleEngineEndpoint;
    _flightApi.text = settings.flightApi;
    _cashCardApi.text = settings.cashCardApi;
    _isAirportMpos = settings.isAirportMpos;
    _forceOfflineMode = settings.forceOfflineMode;
  }

  void _generateUuid() {
    final random = Random.secure();
    String hex(int bytes) => List.generate(
      bytes,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    setState(() {
      _uuid.text = '${hex(4)}-${hex(2)}-${hex(2)}-${hex(2)}-${hex(6)}';
      _showUuidQrCode = true;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Member API, member profile, Print Hub endpoint, pickup code, and
    // default page are no longer edited on this form — preserve whatever
    // was already persisted for them instead of clobbering with an empty
    // value.
    final current = widget.viewModel.settings;
    final updated = DeviceSettings(
      moduleKey: _moduleKey.text,
      branch: _branch.text,
      subBranchCode: _subBranchCode.text,
      location: _location.text,
      machine: int.tryParse(_machine.text) ?? 0,
      company: _company.text,
      serial: _serial.text,
      macAddress: _macAddress.text,
      ipAddress: _ipAddress.text,
      printerName: _printerName.text,
      edcPort: _edcPort.text,
      webServiceEndpoint: _webServiceEndpoint.text,
      updateEndpoint: _updateEndpoint.text,
      uuid: _uuid.text,
      saleEngineEndpoint: _saleEngineEndpoint.text,
      defaultPage: current.defaultPage,
      flightApi: _flightApi.text,
      memberProfile: current.memberProfile,
      memberApi: current.memberApi,
      cashCardApi: _cashCardApi.text,
      printHubEndpoint: current.printHubEndpoint,
      pickupCode: current.pickupCode,
      isAirportMpos: _isAirportMpos,
      forceOfflineMode: _forceOfflineMode,
    );
    await widget.viewModel.save(updated);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsViewModel>(
      init: widget.viewModel,
      global: false,
      builder: (viewModel) => _buildContent(context, viewModel),
    );
  }

  Widget _buildContent(BuildContext context, SettingsViewModel viewModel) {
    if (viewModel.loadStatus == SettingsLoadStatus.loading) {
      return const AppShell(
        title: 'Device settings',
        body: LoadingView(message: 'Loading device settings...'),
      );
    }
    if (viewModel.loadStatus == SettingsLoadStatus.failure) {
      return AppShell(
        title: 'Device settings',
        body: RetryableErrorView(
          message: viewModel.errorMessage ?? 'Could not load settings.',
          onRetry: viewModel.load,
        ),
      );
    }

    final isSaving = viewModel.saveStatus == SettingsSaveStatus.saving;

    if (!AppBreakpoints.isWide(context)) {
      return _buildHandheld(context, viewModel, isSaving);
    }

    return _buildDesktop(context, viewModel, isSaving);
  }

  /// Desktop layout (POS Desktop mockup screen 11): Terminal identity +
  /// Peripherals, Service endpoints and Device panels side by side, with
  /// Save / Cancel in the top bar. Same fields, validation and save as the
  /// handheld layout; short fields pair up two to a row.
  ///
  /// Like handheld, the mockup's supervisor lock is not applied (this page
  /// is also first-run setup and card verification has no API), and live
  /// peripheral / endpoint health is omitted until there is a source.
  // TODO(pos-desktop): SupervisorLockGate once supervisor-card verification
  // exists; live peripheral health (openspec 7.6) and endpoint reachability.
  Widget _buildDesktop(
    BuildContext context,
    SettingsViewModel viewModel,
    bool isSaving,
  ) {
    final canPop = Navigator.of(context).canPop();
    final module = _moduleKey.text.isEmpty ? '—' : _moduleKey.text;

    final terminal = DesktopPanel(
      id: DesktopIds.settingsTerminalPanel,
      title: 'Terminal identity',
      child: _fields([
        _pair(_moduleField(), _branchField()),
        _subBranchField(),
        _airportSwitch(),
        _saleMode(),
      ]),
    );

    final peripherals = DesktopPanel(
      id: DesktopIds.settingsPeripheralsPanel,
      title: 'Peripherals',
      child: _fields([
        _pair(_printerField(), _edcField()),
        _note(
          'Live device status (ready / paired / offline) is not available '
          'yet.',
        ),
      ]),
    );

    final endpoints = DesktopPanel(
      id: DesktopIds.settingsEndpointsPanel,
      title: 'Service endpoints',
      child: _fields(_endpointFields()),
    );

    final device = DesktopPanel(
      id: DesktopIds.settingsDevicePanel,
      title: 'Device',
      child: _fields([
        _uuidRow(),
        ?_uuidQrCode(context),
        _pair(_machineField(), _locationField()),
        _pair(_companyField(), _serialField()),
        _pair(_macField(), _ipField()),
      ]),
    );

    return DesktopPageFrame(
      title: 'Device settings',
      subtitle: 'Smart POS · cashier station · $module',
      actions: [
        if (canPop)
          DesktopButton(
            id: SettingsIds.cancelButton,
            label: 'Cancel',
            secondary: true,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        DesktopButton(
          id: SettingsIds.saveButton,
          label: isSaving ? 'Saving...' : 'Save',
          icon: Icons.check,
          onPressed: isSaving ? null : _save,
        ),
      ],
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesktopMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (viewModel.saveStatus == SettingsSaveStatus.failure) ...[
                _saveError(viewModel),
                const SizedBox(height: AppSpacing.md),
              ],
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = SizedBox(width: 20, height: 20);
                  if (constraints.maxWidth >= 1500) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(children: [terminal, gap, peripherals]),
                        ),
                        gap,
                        Expanded(child: endpoints),
                        gap,
                        Expanded(child: device),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(children: [terminal, gap, peripherals]),
                      ),
                      gap,
                      Expanded(
                        child: Column(children: [endpoints, gap, device]),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handheld layout (mockup screen 11): dark header, the same fields
  /// grouped into Terminal / Sale mode / Endpoints / Device sections, and
  /// a fixed Save / Cancel bar.
  ///
  /// The mockup's read-only-until-supervisor-scan mode is deliberately not
  /// applied: this page is also first-run device setup (before any sign-in),
  /// and supervisor-card verification has no API yet, so gating edits would
  /// lock setup out entirely.
  // TODO(pos-handheld): add the SupervisorLockGate read-only mode once
  // supervisor-card verification exists, exempting first-run setup.
  // Endpoint health ("5 of 5 up") and paired-device status are omitted
  // until there is a real health check / device API to back them.
  Widget _buildHandheld(
    BuildContext context,
    SettingsViewModel viewModel,
    bool isSaving,
  ) {
    final canPop = Navigator.of(context).canPop();
    final module = _moduleKey.text.isEmpty ? '—' : _moduleKey.text;

    Widget section(String id, String title, List<Widget> children) =>
        HandheldSection(
          id: id,
          title: title,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _fields(children),
            ),
          ],
        );

    return HandheldScaffold(
      header: HandheldHeader(
        title: 'Device settings',
        subtitle: 'Smart POS Mobile · $module',
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HandheldMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              section(SettingsIds.terminalSection, 'Terminal', [
                _moduleField(),
                _branchField(),
                _subBranchField(),
                _airportSwitch(),
              ]),
              const SizedBox(height: AppSpacing.md),
              section(SettingsIds.saleModeSection, 'Sale mode', [
                _saleMode(label: false),
              ]),
              const SizedBox(height: AppSpacing.md),
              section(
                SettingsIds.endpointsSection,
                'Endpoints',
                _endpointFields(),
              ),
              const SizedBox(height: AppSpacing.md),
              section(SettingsIds.deviceSection, 'Device', [
                _machineField(),
                _locationField(),
                _companyField(),
                _serialField(),
                _macField(),
                _ipField(),
                _printerField(),
                _edcField(),
                _uuidRow(),
                ?_uuidQrCode(context),
              ]),
              if (viewModel.saveStatus == SettingsSaveStatus.failure) ...[
                const SizedBox(height: AppSpacing.md),
                _saveError(viewModel),
              ],
            ],
          ),
        ),
      ),
      actionBar: HandheldActionBar(
        primary: HandheldPrimaryButton(
          id: SettingsIds.saveButton,
          label: isSaving ? 'Saving...' : 'Save',
          icon: Icons.check,
          onPressed: isSaving ? null : _save,
        ),
        secondary: canPop
            ? HandheldSecondaryButton(
                id: SettingsIds.cancelButton,
                label: 'Cancel',
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
    );
  }

  // ── Form building blocks, shared by both layouts ──────────────────────

  Widget _fields(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 14),
        children[i],
      ],
    ],
  );

  /// Two short fields side by side (desktop panels only — on a phone the
  /// labels would wrap and the boxes stop lining up).
  Widget _pair(Widget a, Widget b) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: a),
      const SizedBox(width: 12),
      Expanded(child: b),
    ],
  );

  Widget _note(String text) => Text(
    text,
    style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText),
  );

  Widget _saveError(SettingsViewModel viewModel) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.danger.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            viewModel.errorMessage ?? 'Could not save.',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    ),
  );

  Widget _branchField() => _SettingsInput(
    id: SettingsIds.branchField,
    label: 'Branch number',
    controller: _branch,
    required: true,
  );

  Widget _printerField() => _SettingsInput(
    id: SettingsIds.printerField,
    label: 'Printer name',
    controller: _printerName,
  );

  Widget _edcField() => _SettingsInput(
    id: SettingsIds.edcPortField,
    label: 'EDC port',
    controller: _edcPort,
  );

  Widget _machineField() => _SettingsInput(
    id: SettingsIds.machineField,
    label: 'Machine number',
    controller: _machine,
    keyboardType: TextInputType.number,
  );

  Widget _locationField() => _SettingsInput(
    id: SettingsIds.locationField,
    label: 'Location',
    controller: _location,
  );

  Widget _companyField() => _SettingsInput(
    id: SettingsIds.companyField,
    label: 'Company',
    controller: _company,
  );

  Widget _serialField() => _SettingsInput(
    id: SettingsIds.serialField,
    label: 'Serial',
    controller: _serial,
  );

  Widget _macField() => _SettingsInput(
    id: SettingsIds.macAddressField,
    label: 'MAC address',
    controller: _macAddress,
  );

  Widget _ipField() => _SettingsInput(
    id: SettingsIds.ipAddressField,
    label: 'IP address',
    controller: _ipAddress,
  );

  List<Widget> _endpointFields() => [
    _SettingsInput(
      id: SettingsIds.saleEngineField,
      label: 'Sale Engine endpoint',
      controller: _saleEngineEndpoint,
      required: true,
      hint: 'https://',
      keyboardType: TextInputType.url,
    ),
    _SettingsInput(
      id: SettingsIds.registerField,
      label: 'Register endpoint',
      controller: _webServiceEndpoint,
      focusNode: _webServiceEndpointFocus,
      required: true,
      hint: 'https://',
      keyboardType: TextInputType.url,
    ),
    _SettingsInput(
      id: SettingsIds.flightApiField,
      label: 'Flight API endpoint',
      controller: _flightApi,
      required: true,
      hint: 'https://',
      keyboardType: TextInputType.url,
    ),
    _SettingsInput(
      id: SettingsIds.cashCardApiField,
      label: 'Cash Card API endpoint',
      controller: _cashCardApi,
      hint: 'https://',
      keyboardType: TextInputType.url,
    ),
    _SettingsInput(
      id: SettingsIds.updateEndpointField,
      label: 'App update endpoint',
      controller: _updateEndpoint,
      hint: 'https://',
      keyboardType: TextInputType.url,
    ),
  ];

  Widget _airportSwitch() {
    return TestId(
      SettingsIds.airportMposSwitch,
      child: Material(
        color: _isAirportMpos ? AppColors.cream : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: BorderSide(
            color: _isAirportMpos ? AppColors.goldMuted : _fieldBorder,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => setState(() => _isAirportMpos = !_isAirportMpos),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            child: Row(
              children: [
                Icon(
                  Icons.flight_takeoff,
                  size: 18,
                  color: _isAirportMpos
                      ? AppColors.goldDark
                      : AppColors.mutedText,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Airport MPOS device',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: _isAirportMpos,
                  activeTrackColor: AppColors.goldDark,
                  onChanged: (value) => setState(() => _isAirportMpos = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _saleMode({bool label = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label) ...[
          const _FieldLabel('Sale mode'),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Expanded(
              child: _SaleModeOption(
                id: SettingsIds.sellOnline,
                icon: Icons.wifi,
                label: 'Sell online',
                selected: !_forceOfflineMode,
                onTap: () => setState(() => _forceOfflineMode = false),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _SaleModeOption(
                id: SettingsIds.sellOffline,
                icon: Icons.cloud_off_outlined,
                label: 'Sell offline',
                selected: _forceOfflineMode,
                onTap: () => setState(() => _forceOfflineMode = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _note(
          _forceOfflineMode
              ? 'Selling offline: prices from the local cache and no server '
                    'lookups. Switch back once the network or backend is '
                    'restored.'
              : 'Selling online: articles and prices come from the sale '
                    'engine.',
        ),
      ],
    );
  }

  Widget _uuidRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _SettingsInput(
            id: SettingsIds.uuidField,
            label: 'Device UUID',
            controller: _uuid,
          ),
        ),
        const SizedBox(width: 8),
        TestId(
          SettingsIds.generateUuidButton,
          child: SizedBox(
            height: _SettingsInput.height,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldDark,
                side: const BorderSide(color: AppColors.goldMuted),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              icon: const Icon(Icons.autorenew, size: 16),
              label: const Text('Generate'),
              onPressed: _generateUuid,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _uuidQrCode(BuildContext context) {
    if (!_showUuidQrCode || _uuid.text.isEmpty) return null;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _fieldBorder),
        ),
        child: Column(
          children: [
            QrImageView(
              data: _uuid.text,
              size: 160,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(_uuid.text, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  static const _moduleCodes = ['PosKpi', 'MposKpi', 'PosAir', 'MposAir'];

  Widget _moduleField() {
    final currentCode = _moduleKey.text;
    final hasMatch = _moduleCodes.contains(currentCode);
    return _SettingsDropdown(
      id: SettingsIds.moduleField,
      label: 'Module',
      value: hasMatch ? currentCode : null,
      items: {for (final code in _moduleCodes) code: code},
      onChanged: (value) => setState(() => _moduleKey.text = value ?? ''),
    );
  }

  Widget _subBranchField() {
    final subBranches = widget.viewModel.subBranches;
    if (subBranches.isEmpty) {
      return _SettingsInput(
        id: SettingsIds.subBranchField,
        label: 'Sub-branch code',
        controller: _subBranchCode,
      );
    }
    final currentCode = _subBranchCode.text;
    final hasMatch = subBranches.any((s) => s.subbranchCode == currentCode);
    return _SettingsDropdown(
      id: SettingsIds.subBranchField,
      label: 'Sub-branch',
      value: hasMatch ? currentCode : null,
      items: {
        for (final s in subBranches)
          s.subbranchCode: '${s.subbranchCode} — ${s.subbranchName}',
      },
      onChanged: (value) => setState(() => _subBranchCode.text = value ?? ''),
    );
  }
}

const _fieldBorder = Color(0xFFD8DDE5);

/// The page's field label: small, muted, uppercase-tracked (the POS kit's
/// field label), with a gold `*` on required fields.
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text.toUpperCase(),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.goldDark),
            ),
        ],
      ),
      semanticsLabel: text,
      style: DesktopText.fieldLabel,
    );
  }
}

/// One outlined, white box for every input on the page: gold when focused,
/// red with the message below when invalid.
InputDecoration _inputDecoration({String? hint, double vertical = 14}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.hintText, fontSize: 14),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: vertical),
    border: border(_fieldBorder),
    enabledBorder: border(_fieldBorder),
    focusedBorder: border(AppColors.goldDark, 1.5),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.5),
  );
}

class _SettingsInput extends StatelessWidget {
  /// The box's height, which the UUID Generate button matches.
  static const height = 48.0;

  final String id;
  final String label;
  final TextEditingController controller;
  final bool required;
  final String? hint;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;

  const _SettingsInput({
    required this.id,
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.focusNode,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FieldLabel(label, required: required),
        const SizedBox(height: 6),
        TestId(
          id,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14.5),
            decoration: _inputDecoration(hint: hint),
            validator: required
                ? (value) =>
                      (value == null || value.isEmpty) ? 'Required' : null
                : null,
          ),
        ),
      ],
    );
  }
}

class _SettingsDropdown extends StatelessWidget {
  final String id;
  final String label;
  final String? value;

  /// Value → shown text, in order.
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  const _SettingsDropdown({
    required this.id,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        TestId(
          id,
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            icon: const Icon(Icons.expand_more, color: AppColors.mutedText),
            borderRadius: BorderRadius.circular(9),
            style: const TextStyle(fontSize: 14.5, color: AppColors.ink),
            // The menu button sits 2 dp taller than text; this lines the boxes up.
            decoration: _inputDecoration(hint: 'Select', vertical: 13),
            items: [
              for (final entry in items.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// One of the two Sell online / Sell offline choices in the handheld
/// Sale mode section.
class _SaleModeOption extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SaleModeOption({
    required this.id,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.goldDark : AppColors.mutedText;
    return TestId(
      id,
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected ? AppColors.cream : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
            side: BorderSide(
              color: selected ? AppColors.goldMuted : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
            child: SizedBox(
              height: HandheldMetrics.primaryActionHeight - 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

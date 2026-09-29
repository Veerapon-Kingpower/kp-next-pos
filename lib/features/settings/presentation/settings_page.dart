import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/app/router.dart';
import '../../../core/app/session_state.dart';
import '../../../core/config/device_settings.dart';
import '../../../core/presentation/handheld/handheld.dart';
import '../../../core/presentation/test_ids.dart';
import '../../../core/presentation/widgets/app_buttons.dart';
import '../../../core/presentation/widgets/app_shell.dart';
import '../../../core/presentation/widgets/app_text_field.dart';
import '../../../core/presentation/widgets/loading_view.dart';
import '../../../core/presentation/widgets/retryable_error_view.dart';
import '../../../core/presentation/widgets/test_id.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizing.dart';
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

  String? _required(String? value) {
    return (value == null || value.isEmpty) ? 'Required' : null;
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

    return AppShell(
      title: 'Device settings',
      body: Form(
        key: _formKey,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Connectivity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        AppSizing.cornerRadiusMd,
                      ),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: SwitchListTile(
                      value: _forceOfflineMode,
                      onChanged: (value) =>
                          setState(() => _forceOfflineMode = value),
                      title: const Text('Offline mode'),
                      subtitle: const Text(
                        'Turn on when the network or backend is known to '
                        'be down. Skips server lookups and uses cached '
                        'article data directly. Turn off once connectivity '
                        'is restored.',
                      ),
                      secondary: Icon(
                        _forceOfflineMode
                            ? Icons.cloud_off
                            : Icons.cloud_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Service endpoints',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _validatedField(_saleEngineEndpoint, 'Sale Engine endpoint'),
                  const SizedBox(height: AppSpacing.sm),
                  _validatedField(
                    _webServiceEndpoint,
                    'Register endpoint',
                    focusNode: _webServiceEndpointFocus,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _validatedField(_flightApi, 'Flight API endpoint'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _cashCardApi,
                    label: 'Cash Card API endpoint',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _updateEndpoint,
                    label: 'App update endpoint',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Branch & module',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _validatedField(_branch, 'Branch number'),
                  const SizedBox(height: AppSpacing.sm),
                  _moduleField(),
                  const SizedBox(height: AppSpacing.sm),
                  _subBranchField(),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Airport MPOS device'),
                    value: _isAirportMpos,
                    onChanged: (value) =>
                        setState(() => _isAirportMpos = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(
                    'Device identity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(controller: _location, label: 'Location'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _machine,
                    label: 'Machine number',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(controller: _company, label: 'Company'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(controller: _serial, label: 'Serial'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(controller: _macAddress, label: 'MAC address'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(controller: _ipAddress, label: 'IP address'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(controller: _printerName, label: 'Printer name'),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(controller: _edcPort, label: 'EDC port'),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _uuid,
                          label: 'Device UUID',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 120,
                        child: AppSecondaryButton(
                          label: 'Generate',
                          onPressed: _generateUuid,
                        ),
                      ),
                    ],
                  ),
                  if (_showUuidQrCode && _uuid.text.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Column(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppSizing.cornerRadiusLg,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: QrImageView(
                                data: _uuid.text,
                                size: 160,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _uuid.text,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  if (viewModel.saveStatus == SettingsSaveStatus.failure)
                    RetryableErrorView(
                      message: viewModel.errorMessage ?? 'Could not save.',
                      onRetry: _save,
                    )
                  else
                    AppPrimaryButton(
                      label: isSaving ? 'Saving...' : 'Save',
                      onPressed: isSaving ? null : _save,
                    ),
                ],
              ),
            ),
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

    Widget fields(List<Widget> children) => Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            children[i],
          ],
        ],
      ),
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
              HandheldSection(
                id: SettingsIds.terminalSection,
                title: 'Terminal',
                children: [
                  fields([
                    _moduleField(),
                    _validatedField(_branch, 'Branch number'),
                    _subBranchField(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Airport MPOS device'),
                      value: _isAirportMpos,
                      onChanged: (value) =>
                          setState(() => _isAirportMpos = value),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              HandheldSection(
                id: SettingsIds.saleModeSection,
                title: 'Sale mode',
                children: [
                  fields([
                    Row(
                      children: [
                        Expanded(
                          child: _SaleModeOption(
                            id: SettingsIds.sellOnline,
                            icon: Icons.wifi,
                            label: 'Sell online',
                            selected: !_forceOfflineMode,
                            onTap: () =>
                                setState(() => _forceOfflineMode = false),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _SaleModeOption(
                            id: SettingsIds.sellOffline,
                            icon: Icons.cloud_off_outlined,
                            label: 'Sell offline',
                            selected: _forceOfflineMode,
                            onTap: () =>
                                setState(() => _forceOfflineMode = true),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _forceOfflineMode
                          ? 'Selling offline: prices from the local cache '
                                'and no server lookups. Switch back once the '
                                'network or backend is restored.'
                          : 'Selling online: articles and prices come from '
                                'the sale engine.',
                      style: HandheldText.bodySmall,
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              HandheldSection(
                id: SettingsIds.endpointsSection,
                title: 'Endpoints',
                children: [
                  fields([
                    _validatedField(
                      _saleEngineEndpoint,
                      'Sale Engine endpoint',
                    ),
                    _validatedField(
                      _webServiceEndpoint,
                      'Register endpoint',
                      focusNode: _webServiceEndpointFocus,
                    ),
                    _validatedField(_flightApi, 'Flight API endpoint'),
                    AppTextField(
                      controller: _cashCardApi,
                      label: 'Cash Card API endpoint',
                    ),
                    AppTextField(
                      controller: _updateEndpoint,
                      label: 'App update endpoint',
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              HandheldSection(
                id: SettingsIds.deviceSection,
                title: 'Device',
                children: [
                  fields([
                    AppTextField(controller: _location, label: 'Location'),
                    AppTextField(
                      controller: _machine,
                      label: 'Machine number',
                      keyboardType: TextInputType.number,
                    ),
                    AppTextField(controller: _company, label: 'Company'),
                    AppTextField(controller: _serial, label: 'Serial'),
                    AppTextField(controller: _macAddress, label: 'MAC address'),
                    AppTextField(controller: _ipAddress, label: 'IP address'),
                    AppTextField(
                      controller: _printerName,
                      label: 'Printer name',
                    ),
                    AppTextField(controller: _edcPort, label: 'EDC port'),
                    _uuidRow(),
                    ?_uuidQrCode(context),
                  ]),
                ],
              ),
              if (viewModel.saveStatus == SettingsSaveStatus.failure) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  viewModel.errorMessage ?? 'Could not save.',
                  style: const TextStyle(color: AppColors.danger),
                ),
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

  Widget _uuidRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(controller: _uuid, label: 'Device UUID'),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 120,
          child: AppSecondaryButton(
            label: 'Generate',
            onPressed: _generateUuid,
          ),
        ),
      ],
    );
  }

  Widget? _uuidQrCode(BuildContext context) {
    if (!_showUuidQrCode || _uuid.text.isEmpty) return null;
    return Center(
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
    );
  }

  Widget _validatedField(
    TextEditingController controller,
    String label, {
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: _required,
    );
  }

  static const _moduleCodes = ['PosKpi', 'MposKpi', 'PosAir', 'MposAir'];

  Widget _moduleField() {
    final currentCode = _moduleKey.text;
    final hasMatch = _moduleCodes.contains(currentCode);
    return DropdownButtonFormField<String>(
      initialValue: hasMatch ? currentCode : null,
      decoration: const InputDecoration(
        labelText: 'Module',
        border: OutlineInputBorder(),
      ),
      items: _moduleCodes
          .map((code) => DropdownMenuItem(value: code, child: Text(code)))
          .toList(growable: false),
      onChanged: (value) => setState(() => _moduleKey.text = value ?? ''),
    );
  }

  Widget _subBranchField() {
    final subBranches = widget.viewModel.subBranches;
    if (subBranches.isEmpty) {
      return AppTextField(controller: _subBranchCode, label: 'Sub-branch code');
    }
    final currentCode = _subBranchCode.text;
    final hasMatch = subBranches.any((s) => s.subbranchCode == currentCode);
    return DropdownButtonFormField<String>(
      initialValue: hasMatch ? currentCode : null,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Sub-branch',
        border: OutlineInputBorder(),
      ),
      items: subBranches
          .map(
            (s) => DropdownMenuItem(
              value: s.subbranchCode,
              child: Text(
                '${s.subbranchCode} — ${s.subbranchName}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: (value) => setState(() => _subBranchCode.text = value ?? ''),
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

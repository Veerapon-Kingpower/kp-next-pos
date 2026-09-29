import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/app/session_state.dart';
import '../../../core/config/device_settings.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../settings/presentation/settings_page.dart';
import '../../settings/presentation/settings_view_model.dart';
import 'desktop/desktop_login_view.dart';
import 'handheld/handheld_login_form.dart';
import 'login_view_model.dart';

/// King Power brand photo used as the Login background. A shared top-level
/// [AssetImage] (rather than a fresh one per build) so `KpPosApp` can
/// [precacheImage] it once at app start — see that file's doc comment for
/// why: without precaching, revisiting Login after logout has shown
/// corrupted diagonal-streak rendering on Windows desktop, which precaching
/// avoids by never letting the decoded image drop out of cache between
/// LoginPage mounts.
const loginBackgroundAsset = AssetImage(
  'assets/images/Login-sales_Branding_FINAL.jpg',
);

class LoginPage extends StatefulWidget {
  final LoginViewModel viewModel;
  final SessionState sessionState;
  final SettingsViewModel Function() settingsViewModelFactory;

  const LoginPage({
    super.key,
    required this.viewModel,
    required this.sessionState,
    required this.settingsViewModelFactory,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  // Local read for the desktop identity panel — null until it resolves.
  DeviceSettings? _deviceSettings;

  @override
  void initState() {
    super.initState();
    // Separate from the GetBuilder used for rendering below: this fires
    // exactly once per real update() call (GetxController genuinely
    // implements Listenable), which is required here since signedIn() has a
    // side effect (it flips SessionState, which go_router's
    // refreshListenable reacts to) that must not re-fire on every ambient
    // rebuild the way GetBuilder's own builder callback would.
    widget.viewModel.addListener(_onSideEffect);
    widget.sessionState.readDeviceSettings().then((settings) {
      if (mounted) setState(() => _deviceSettings = settings);
    });
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onSideEffect);
    _userCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSideEffect() {
    if (widget.viewModel.status == LoginStatus.success &&
        widget.viewModel.session != null) {
      widget.sessionState.signedIn(widget.viewModel.session!.sessionKey);
    }
  }

  Future<void> _submit() {
    FocusScope.of(context).unfocus();
    return widget.viewModel.submit(
      userCode: _userCodeController.text,
      userPassword: _passwordController.text,
    );
  }

  // Pushed on the root Navigator, outside go_router — the router's redirect
  // guard forces any go_router location back to /login while unauthenticated
  // (see router.dart), so device settings must stay reachable pre-login via
  // an independent Navigator stack instead of a GoRoute.
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

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginViewModel>(
      init: widget.viewModel,
      global: false,
      builder: (viewModel) => _buildContent(context, viewModel),
    );
  }

  Widget _buildContent(BuildContext context, LoginViewModel viewModel) {
    final isSubmitting = viewModel.status == LoginStatus.submitting;

    final errorMessage = viewModel.status == LoginStatus.failure
        ? viewModel.errorMessage ?? 'Sign-in failed.'
        : null;

    if (AppBreakpoints.isWide(context)) {
      // POS Desktop mockup screen 1 — see
      // docs/superpowers/specs/2026-08-27-pos-desktop-design.md.
      return DesktopLoginView(
        userCodeController: _userCodeController,
        passwordController: _passwordController,
        isSubmitting: isSubmitting,
        errorMessage: errorMessage,
        deviceSettings: _deviceSettings,
        now: DateTime.now(),
        onSubmit: _submit,
        onOpenSettings: _openSettings,
      );
    }

    // Handheld layout (phones, Sunmi, tablets / iPads in portrait) — see
    // docs/superpowers/specs/2026-09-29-pos-handheld-design.md, screen 1.
    return HandheldLoginForm(
      userCodeController: _userCodeController,
      passwordController: _passwordController,
      isSubmitting: isSubmitting,
      errorMessage: errorMessage,
      onSubmit: _submit,
      onOpenSettings: _openSettings,
    );
  }
}

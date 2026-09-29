import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/app/session_state.dart';
import '../../../core/presentation/widgets/app_buttons.dart';
import '../../../core/presentation/widgets/app_text_field.dart';
import '../../../core/presentation/widgets/retryable_error_view.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizing.dart';
import '../../../core/theme/app_spacing.dart';
import '../../settings/presentation/settings_page.dart';
import '../../settings/presentation/settings_view_model.dart';
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

    // Handheld layout (phones, Sunmi, tablets / iPads in portrait) — see
    // docs/superpowers/specs/2026-09-29-pos-handheld-design.md, screen 1.
    if (!AppBreakpoints.isWide(context)) {
      return HandheldLoginForm(
        userCodeController: _userCodeController,
        passwordController: _passwordController,
        isSubmitting: isSubmitting,
        errorMessage: viewModel.status == LoginStatus.failure
            ? viewModel.errorMessage ?? 'Sign-in failed.'
            : null,
        onSubmit: _submit,
        onOpenSettings: _openSettings,
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // King Power brand photography, filling the whole screen with no
          // cropping and no letterboxing (may stretch slightly to fit).
          Image(image: loginBackgroundAsset, fit: BoxFit.fill),
          // Scrim so the form card stays readable against busy areas of the
          // photo regardless of screen size.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black38],
                stops: [0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'Device settings',
                onPressed: _openSettings,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Card(
                    color: AppColors.surface,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizing.cornerRadiusLg,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            controller: _userCodeController,
                            label: 'User code',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: true,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (viewModel.status == LoginStatus.failure)
                            RetryableErrorView(
                              message:
                                  viewModel.errorMessage ?? 'Sign-in failed.',
                              onRetry: _submit,
                            )
                          else
                            AppPrimaryButton(
                              label: isSubmitting ? 'Signing in...' : 'Sign in',
                              onPressed: isSubmitting ? null : _submit,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

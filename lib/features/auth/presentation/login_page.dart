import 'package:flutter/material.dart';

import '../../../core/app/session_state.dart';
import '../../../core/presentation/widgets/app_buttons.dart';
import '../../../core/presentation/widgets/app_text_field.dart';
import '../../../core/presentation/widgets/retryable_error_view.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizing.dart';
import '../../../core/theme/app_spacing.dart';
import 'login_view_model.dart';

class LoginPage extends StatefulWidget {
  final LoginViewModel viewModel;
  final SessionState sessionState;

  const LoginPage({
    super.key,
    required this.viewModel,
    required this.sessionState,
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
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _userCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (widget.viewModel.status == LoginStatus.success &&
        widget.viewModel.session != null) {
      widget.sessionState.signedIn(widget.viewModel.session!.sessionKey);
    }
    setState(() {});
  }

  Future<void> _submit() {
    return widget.viewModel.submit(
      userCode: _userCodeController.text,
      userPassword: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = widget.viewModel.status == LoginStatus.submitting;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // King Power brand photography, filling the whole screen with no
          // cropping and no letterboxing (may stretch slightly to fit).
          Image.asset(
            'assets/images/Login-sales_Branding_FINAL.jpg',
            fit: BoxFit.fill,
          ),
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
                          if (widget.viewModel.status == LoginStatus.failure)
                            RetryableErrorView(
                              message:
                                  widget.viewModel.errorMessage ??
                                  'Sign-in failed.',
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

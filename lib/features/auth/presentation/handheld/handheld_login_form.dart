import 'package:flutter/material.dart';

import '../../../../core/presentation/form_inputs.dart';
import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';

/// Handheld sign-in (mockup screen 1): dark `ink` page, username /
/// password on dark fields, gold Sign in, and a QR-code
/// login alternative. Wired to the existing user-code + password flow; the
/// owning page holds the controllers and the view-model.
class HandheldLoginForm extends StatefulWidget {
  final TextEditingController userCodeController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final String? errorMessage;

  /// Shown under the form; nothing is shown while it's null.
  final String? appVersion;
  final VoidCallback onSubmit;
  final VoidCallback onOpenSettings;

  const HandheldLoginForm({
    super.key,
    required this.userCodeController,
    required this.passwordController,
    required this.isSubmitting,
    required this.errorMessage,
    this.appVersion,
    required this.onSubmit,
    required this.onOpenSettings,
  });

  @override
  State<HandheldLoginForm> createState() => _HandheldLoginFormState();
}

class _HandheldLoginFormState extends State<HandheldLoginForm> {
  static const _formMaxWidth = 440.0;

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _formMaxWidth),
                  child: _form(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: TestId(
                LoginIds.settingsButton,
                child: IconButton(
                  icon: const Icon(Icons.settings),
                  color: Colors.white.withValues(alpha: 0.7),
                  tooltip: 'Device settings',
                  onPressed: widget.onOpenSettings,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    final dividerColor = Colors.white.withValues(alpha: 0.14);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SMART POS MOBILE',
          textAlign: TextAlign.center,
          style: HandheldText.overline.copyWith(
            color: AppColors.gold,
            fontSize: 10.5,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Welcome back',
          textAlign: TextAlign.center,
          style: HandheldText.displayTitle.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 34),
        _DarkField(
          id: LoginIds.userCodeField,
          label: 'Username',
          icon: Icons.person_outline,
          controller: widget.userCodeController,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 18),
        _DarkField(
          id: LoginIds.passwordField,
          label: 'Password',
          icon: Icons.lock_outline,
          controller: widget.passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => widget.onSubmit(),
          suffix: TestId(
            LoginIds.passwordVisibility,
            child: TextButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              style: TextButton.styleFrom(foregroundColor: AppColors.gold),
              child: Text(_obscurePassword ? 'Show' : 'Hide'),
            ),
          ),
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 14),
          TestId(
            LoginIds.errorMessage,
            child: Semantics(
              liveRegion: true,
              child: Text(
                widget.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFFFF9C9C)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        HandheldPrimaryButton(
          id: LoginIds.signInButton,
          label: widget.isSubmitting ? 'Signing in...' : 'Sign in',
          onDark: true,
          onPressed: widget.isSubmitting ? null : widget.onSubmit,
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(child: Divider(color: dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'OR',
                style: HandheldText.overline.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            Expanded(child: Divider(color: dividerColor)),
          ],
        ),
        const SizedBox(height: 22),
        // TODO(pos-handheld): staff QR / staff-card login needs an auth API
        // variant — shown but inert until then (handheld spec decision 3).
        TestId(
          LoginIds.qrLoginButton,
          child: Semantics(
            button: true,
            enabled: false,
            child: SizedBox(
              height: HandheldMetrics.primaryActionHeight,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.qr_code_2, size: 18),
                label: const Text('Login with QR code'),
                style: OutlinedButton.styleFrom(
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      HandheldMetrics.radiusSm,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.appVersion != null) ...[
          const SizedBox(height: 28),
          TestId(
            LoginIds.appVersion,
            child: Text(
              'Version ${widget.appVersion}',
              textAlign: TextAlign.center,
              style: HandheldText.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Caps label over a 56 dp field on the dark sign-in page; gold border when
/// focused.
class _DarkField extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const _DarkField({
    required this.id,
    required this.label,
    required this.icon,
    required this.controller,
    required this.textInputAction,
    this.obscureText = false,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
      borderSide: BorderSide(color: color, width: width),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: HandheldText.overline.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 9),
        TestId(
          id,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            inputFormatters: FormInputs.noThai,
            cursorColor: AppColors.gold,
            style: HandheldText.title.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              contentPadding: const EdgeInsets.symmetric(vertical: 17),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              suffixIcon: suffix,
              enabledBorder: border(Colors.white.withValues(alpha: 0.18), 1),
              focusedBorder: border(AppColors.gold, 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/config/device_settings.dart';
import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../handheld/handheld_login_form.dart' show kingPowerMobileLogo;
import '../login_page.dart' show loginBackgroundAsset;

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Desktop sign-in (POS Desktop mockup screen 1): terminal identity on the
/// brand photo, the sign-in form on white.
///
/// Wired to the existing user-code + password flow. The identity panel
/// reads local device settings (store, machine, sale mode) and today's
/// date; live RC / bridge status has no source yet so it isn't shown.
/// QR sign-in, staff-card sign-in and "Remember username" are inert
/// (desktop spec decision 3 — PIN / terminal binding out of scope).
// TODO(pos-desktop): QR + staff-card sign-in, remember-username
// persistence, live RC / app / bridge status.
class DesktopLoginView extends StatefulWidget {
  final TextEditingController userCodeController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final String? errorMessage;
  final DeviceSettings? deviceSettings;
  final DateTime now;
  final VoidCallback onSubmit;
  final VoidCallback onOpenSettings;

  const DesktopLoginView({
    super.key,
    required this.userCodeController,
    required this.passwordController,
    required this.isSubmitting,
    required this.errorMessage,
    required this.deviceSettings,
    required this.now,
    required this.onSubmit,
    required this.onOpenSettings,
  });

  @override
  State<DesktopLoginView> createState() => _DesktopLoginViewState();
}

class _DesktopLoginViewState extends State<DesktopLoginView> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 53,
            child: _IdentityPanel(
              settings: widget.deviceSettings,
              now: widget.now,
            ),
          ),
          Expanded(
            flex: 47,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _form(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Sign in',
          style: TextStyle(
            fontFamily: 'KingPowerHeadline',
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your username and password.',
          style: TextStyle(fontSize: 15, color: AppColors.mutedText),
        ),
        const SizedBox(height: 32),
        const Text('USERNAME', style: DesktopText.fieldLabel),
        const SizedBox(height: 8),
        _Field(
          id: LoginIds.userCodeField,
          controller: widget.userCodeController,
          icon: Icons.person_outline,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        const Text('PASSWORD', style: DesktopText.fieldLabel),
        const SizedBox(height: 8),
        _Field(
          id: LoginIds.passwordField,
          controller: widget.passwordController,
          icon: Icons.lock_outline,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => widget.onSubmit(),
          suffix: TestId(
            LoginIds.passwordVisibility,
            child: TextButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              child: Text(_obscure ? 'Show' : 'Hide'),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TestId(
          DesktopIds.loginRememberUser,
          child: const CheckboxListTile(
            value: false,
            onChanged: null,
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'Remember username on this terminal',
              style: TextStyle(fontSize: 13.5),
            ),
          ),
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 8),
          TestId(
            LoginIds.errorMessage,
            child: Semantics(
              liveRegion: true,
              child: Text(
                widget.errorMessage!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        DesktopButton(
          id: LoginIds.signInButton,
          label: widget.isSubmitting ? 'Signing in...' : 'Sign in',
          hotkey: 'ENTER',
          height: DesktopMetrics.largeButtonHeight,
          onPressed: widget.isSubmitting ? null : widget.onSubmit,
        ),
        const SizedBox(height: 26),
        const Row(
          children: [
            Expanded(child: Divider(color: AppColors.line)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('or', style: TextStyle(color: AppColors.mutedText)),
            ),
            Expanded(child: Divider(color: AppColors.line)),
          ],
        ),
        const SizedBox(height: 22),
        TestId(
          LoginIds.qrLoginButton,
          child: Semantics(
            button: true,
            enabled: false,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFCFD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_2, size: 56, color: AppColors.hintText),
                  SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Login with QR code',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Signing in with the KP Staff app is not available '
                          'yet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: DesktopButton(
                id: DesktopIds.loginIdCardButton,
                label: 'Staff card',
                icon: Icons.badge_outlined,
                secondary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DesktopButton(
                id: LoginIds.settingsButton,
                label: 'Device settings',
                icon: Icons.settings_outlined,
                secondary: true,
                onPressed: widget.onOpenSettings,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  final DeviceSettings? settings;
  final DateTime now;

  const _IdentityPanel({required this.settings, required this.now});

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final station = s == null || s.location.isEmpty
        ? 'King Power POS'
        : s.location;
    final machine = s == null || s.machine == 0 ? '—' : '${s.machine}';
    final branch = s == null || s.branch.isEmpty ? '—' : s.branch;
    final saleMode = s == null
        ? '—'
        : s.forceOfflineMode
        ? 'Sell offline'
        : 'Sell online';
    final date = '${now.day} ${_months[now.month - 1]} ${now.year}';

    return TestId(
      DesktopIds.loginIdentityPanel,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Image(image: loginBackgroundAsset, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xF0191712),
                  Color(0x94191712),
                  Color(0x57191712),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: const Image(image: kingPowerMobileLogo, height: 52),
                ),
                const Spacer(),
                const Text(
                  'SMART POS · CASHIER STATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  station,
                  style: const TextStyle(
                    fontFamily: 'KingPowerHeadline',
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 40,
                  runSpacing: 16,
                  children: [
                    _Fact(label: 'Machine', value: machine),
                    _Fact(label: 'Branch', value: branch),
                    _Fact(label: 'Business date', value: date),
                    _Fact(label: 'Sale mode', value: saleMode),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String id;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const _Field({
    required this.id,
    required this.controller,
    required this.icon,
    required this.textInputAction,
    this.obscureText = false,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
    return TestId(
      id,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.goldDark),
          suffixIcon: suffix,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 22),
          enabledBorder: border(const Color(0xFFD8DDE5), 1),
          focusedBorder: border(AppColors.goldMuted, 2),
        ),
      ),
    );
  }
}

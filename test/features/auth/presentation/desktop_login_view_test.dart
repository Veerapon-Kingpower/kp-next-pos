import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/auth/presentation/desktop/desktop_login_view.dart';

import '../../../helpers/test_id_finders.dart';

void main() {
  late TextEditingController user;
  late TextEditingController password;
  late List<String> events;

  setUp(() {
    user = TextEditingController();
    password = TextEditingController();
    events = [];
  });
  tearDown(() {
    user.dispose();
    password.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    DeviceSettings? settings = const DeviceSettings(
      location: 'Downtown Rangnam',
      machine: 412,
      branch: '03',
      moduleKey: 'PosKpi',
    ),
    String? error,
    bool submitting = false,
    Size size = const Size(1440, 900),
  }) async {
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        home: DesktopLoginView(
          userCodeController: user,
          passwordController: password,
          isSubmitting: submitting,
          errorMessage: error,
          deviceSettings: settings,
          now: DateTime(2026, 8, 26, 14, 26),
          onSubmit: () => events.add('submit'),
          onOpenSettings: () => events.add('settings'),
        ),
      ),
    );
  }

  testWidgets('identity panel shows station, machine and business date', (
    tester,
  ) async {
    await pump(tester);
    final panel = byTestId(DesktopIds.loginIdentityPanel);
    expect(
      find.descendant(of: panel, matching: find.text('Downtown Rangnam')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: panel, matching: find.text('412')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: panel, matching: find.text('26 Aug 2026')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: panel, matching: find.text('Sell online')),
      findsOneWidget,
    );
  });

  testWidgets('identity panel falls back to — before settings load', (
    tester,
  ) async {
    await pump(tester, settings: null);
    final panel = byTestId(DesktopIds.loginIdentityPanel);
    expect(
      find.descendant(of: panel, matching: find.text('King Power POS')),
      findsOneWidget,
    );
    expect(find.descendant(of: panel, matching: find.text('—')), findsWidgets);
  });

  testWidgets('Sign in and Enter on the password submit', (tester) async {
    await pump(tester);
    await tester.tap(byTestId(LoginIds.signInButton));
    await tester.enterText(
      find.descendant(
        of: byTestId(LoginIds.passwordField),
        matching: find.byType(TextField),
      ),
      'pw',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(events, ['submit', 'submit']);
  });

  testWidgets('Show toggles the password; error is announced', (tester) async {
    await pump(tester, error: 'Invalid username or password.');
    EditableText field() => tester.widget<EditableText>(
      find.descendant(
        of: byTestId(LoginIds.passwordField),
        matching: find.byType(EditableText),
      ),
    );
    expect(field().obscureText, isTrue);
    await tester.tap(byTestId(LoginIds.passwordVisibility));
    await tester.pump();
    expect(field().obscureText, isFalse);
    expect(
      find.descendant(
        of: byTestId(LoginIds.errorMessage),
        matching: find.text('Invalid username or password.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('QR, ID card and remember-username are inert; settings works', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    for (final id in [
      LoginIds.qrLoginButton,
      DesktopIds.loginIdCardButton,
      DesktopIds.loginRememberUser,
    ]) {
      expect(
        tester.getSemantics(byTestId(id)),
        isSemantics(hasEnabledState: true, isEnabled: false),
        reason: id,
      );
    }
    await tester.tap(byTestId(LoginIds.settingsButton));
    expect(events, ['settings']);
    handle.dispose();
  });

  testWidgets('submitting disables Sign in', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, submitting: true);
    expect(find.text('Signing in...'), findsOneWidget);
    expect(
      tester.getSemantics(byTestId(LoginIds.signInButton)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  for (final size in [const Size(1024, 768), const Size(1920, 1080)]) {
    testWidgets('no overflow at ${size.width.toInt()} dp', (tester) async {
      await pump(tester, size: size);
      expect(tester.takeException(), isNull);
    });
  }
}

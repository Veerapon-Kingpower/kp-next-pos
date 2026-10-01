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
    String? appVersion = '1.0.0 (1)',
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
          appVersion: appVersion,
          onSubmit: () => events.add('submit'),
          onOpenSettings: () => events.add('settings'),
        ),
      ),
    );
  }

  testWidgets('identity panel shows the station and app version only', (
    tester,
  ) async {
    await pump(tester);
    final panel = byTestId(DesktopIds.loginIdentityPanel);
    expect(
      find.descendant(of: panel, matching: find.text('Downtown Rangnam')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: byTestId(LoginIds.appVersion),
        matching: find.text('Version 1.0.0 (1)'),
      ),
      findsOneWidget,
    );
    // The Machine / Branch / Business date / Sale mode row is gone.
    for (final label in ['MACHINE', 'BRANCH', 'BUSINESS DATE', 'SALE MODE']) {
      expect(find.text(label), findsNothing, reason: label);
    }
    // Nor is the gold King Power Mobile logo.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName.contains('kingpower_mobile_logo'),
      ),
      findsNothing,
    );
  });

  testWidgets('before settings / version load: default station, no version', (
    tester,
  ) async {
    await pump(tester, settings: null, appVersion: null);
    final panel = byTestId(DesktopIds.loginIdentityPanel);
    expect(
      find.descendant(of: panel, matching: find.text('King Power POS')),
      findsOneWidget,
    );
    expect(byTestId(LoginIds.appVersion), findsNothing);
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

  testWidgets('QR is inert, settings works; no Staff card or '
      'remember-username', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(byTestId(LoginIds.qrLoginButton)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    expect(find.text('Staff card'), findsNothing);
    expect(find.text('Remember username on this terminal'), findsNothing);
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

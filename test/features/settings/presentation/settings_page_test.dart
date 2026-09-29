import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/app/session_state.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/core/startup/startup_validator.dart';
import 'package:kp_pos/features/settings/domain/entities/sub_branch.dart';
import 'package:kp_pos/features/settings/domain/usecases/list_sub_branches_usecase.dart';
import 'package:kp_pos/features/settings/domain/usecases/load_device_settings_usecase.dart';
import 'package:kp_pos/features/settings/domain/usecases/save_device_settings_usecase.dart';
import 'package:kp_pos/features/settings/presentation/settings_page.dart';
import 'package:kp_pos/features/settings/presentation/settings_view_model.dart';

import '../../../core/storage/fakes.dart';
import '../../../helpers/test_id_finders.dart';
import '../fake_settings_repository.dart';

void main() {
  // This form is long enough that the default 800x600 test surface leaves
  // the Save button below the fold — `ensureVisible` alone doesn't reliably
  // scroll it into a hit-testable position, so grow the surface instead.
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(800, 3200);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  });

  SettingsViewModel buildViewModel(FakeSettingsRepository repo) {
    return SettingsViewModel(
      loadDeviceSettings: LoadDeviceSettingsUseCase(repo),
      saveDeviceSettings: SaveDeviceSettingsUseCase(repo),
      listSubBranches: ListSubBranchesUseCase(repo),
    );
  }

  Future<void> enterByLabel(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    final finder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    expect(finder, findsOneWidget, reason: 'Field "$label" not found');
    await tester.enterText(finder, value);
  }

  testWidgets(
    'tapping Save with required fields filled persists settings and completes device setup',
    (tester) async {
      final repo = FakeSettingsRepository();
      final viewModel = buildViewModel(repo);
      final sessionState = SessionState(
        startupValidator: StartupValidator(
          deviceSettingsStorage: FakeDeviceSettingsStorage(),
          sessionStorage: FakeSessionStorage(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(viewModel: viewModel, sessionState: sessionState),
        ),
      );
      await tester.pumpAndSettle();

      await enterByLabel(tester, 'Branch number', '03');
      await enterByLabel(tester, 'Sale Engine endpoint', 'https://sale-engine');
      await enterByLabel(tester, 'Register endpoint', 'https://register');
      await enterByLabel(tester, 'Flight API endpoint', 'https://flight');

      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.settings.branch, '03');
      expect(repo.settings.saleEngineEndpoint, 'https://sale-engine');
      expect(repo.settings.webServiceEndpoint, 'https://register');
      expect(repo.settings.flightApi, 'https://flight');
      expect(viewModel.saveStatus, SettingsSaveStatus.success);
      expect(sessionState.status, StartupStatus.needsLogin);
    },
  );

  testWidgets('toggling Offline mode and saving persists forceOfflineMode', (
    tester,
  ) async {
    final repo = FakeSettingsRepository();
    final viewModel = buildViewModel(repo);
    final sessionState = SessionState(
      startupValidator: StartupValidator(
        deviceSettingsStorage: FakeDeviceSettingsStorage(),
        sessionStorage: FakeSessionStorage(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(viewModel: viewModel, sessionState: sessionState),
      ),
    );
    await tester.pumpAndSettle();

    await enterByLabel(tester, 'Branch number', '03');
    await enterByLabel(tester, 'Sale Engine endpoint', 'https://sale-engine');
    await enterByLabel(tester, 'Register endpoint', 'https://register');
    await enterByLabel(tester, 'Flight API endpoint', 'https://flight');

    expect(repo.settings.forceOfflineMode, isFalse);
    await tester.tap(byTestId(SettingsIds.sellOffline));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.settings.forceOfflineMode, isTrue);
  });

  testWidgets(
    'tapping Save with a required field empty does not save and stays on the page',
    (tester) async {
      final repo = FakeSettingsRepository();
      final viewModel = buildViewModel(repo);
      final sessionState = SessionState(
        startupValidator: StartupValidator(
          deviceSettingsStorage: FakeDeviceSettingsStorage(),
          sessionStorage: FakeSessionStorage(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(viewModel: viewModel, sessionState: sessionState),
        ),
      );
      await tester.pumpAndSettle();

      // Leave the required "Branch number" field empty.
      await enterByLabel(tester, 'Sale Engine endpoint', 'https://sale-engine');
      await enterByLabel(tester, 'Register endpoint', 'https://register');
      await enterByLabel(tester, 'Flight API endpoint', 'https://flight');

      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
      expect(repo.settings.isComplete, isFalse);
      expect(sessionState.status, isNot(StartupStatus.needsLogin));
    },
  );

  testWidgets(
    'entering the Register endpoint loads sub-branches and turns the field into a dropdown',
    (tester) async {
      final repo = FakeSettingsRepository(
        subBranches: const [
          SubBranch(
            subbranchCode: 'CPX-DT',
            subbranchName: 'Rangnam Complex Downtown',
            branchNo: '03',
            configSC: '',
            cutOffTime: '',
          ),
        ],
      );
      final viewModel = buildViewModel(repo);
      final sessionState = SessionState(
        startupValidator: StartupValidator(
          deviceSettingsStorage: FakeDeviceSettingsStorage(),
          sessionStorage: FakeSessionStorage(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(viewModel: viewModel, sessionState: sessionState),
        ),
      );
      await tester.pumpAndSettle();

      // No Register endpoint entered yet — sub-branch is still free text.
      expect(find.text('Sub-branch code'), findsOneWidget);
      expect(find.text('Sub-branch'), findsNothing);

      await enterByLabel(tester, 'Register endpoint', 'https://register');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Sub-branch code'), findsNothing);
      expect(find.text('Sub-branch'), findsOneWidget);
      expect(viewModel.subBranches.single.subbranchCode, 'CPX-DT');
      expect(
        viewModel.subBranches.single.subbranchName,
        'Rangnam Complex Downtown',
      );

      // The page also has a Module dropdown, so scope to the one labelled
      // "Sub-branch" specifically.
      final subBranchDropdown = find.ancestor(
        of: find.text('Sub-branch'),
        matching: find.byType(DropdownButtonFormField<String>),
      );
      expect(subBranchDropdown, findsOneWidget);

      // Selecting the option in the (now open) dropdown menu updates the
      // controller backing the saved DeviceSettings.subBranchCode.
      await tester.tap(subBranchDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('CPX-DT — Rangnam Complex Downtown').last);
      await tester.pumpAndSettle();

      expect(find.text('CPX-DT — Rangnam Complex Downtown'), findsOneWidget);
    },
  );

  testWidgets(
    'a sub-branch load failure shows an alert with the server message',
    (tester) async {
      final repo = FakeSettingsRepository(
        subBranchesError: const ApiException(
          messageDesc: 'No network connection.',
        ),
      );
      final viewModel = buildViewModel(repo);
      final sessionState = SessionState(
        startupValidator: StartupValidator(
          deviceSettingsStorage: FakeDeviceSettingsStorage(),
          sessionStorage: FakeSessionStorage(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(viewModel: viewModel, sessionState: sessionState),
        ),
      );
      await tester.pumpAndSettle();

      await enterByLabel(tester, 'Register endpoint', 'https://register');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('No network connection.'), findsOneWidget);

      // Dismissing the popup returns to the form, which stays usable as
      // free text rather than blocking on the failed lookup.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Sub-branch code'), findsOneWidget);
    },
  );

  testWidgets(
    'losing focus on the Register endpoint field (without pressing Done) '
    'still loads sub-branches',
    (tester) async {
      final repo = FakeSettingsRepository(
        subBranches: const [
          SubBranch(
            subbranchCode: 'CPX-DT',
            subbranchName: 'Rangnam Complex Downtown',
            branchNo: '03',
            configSC: '',
            cutOffTime: '',
          ),
        ],
      );
      final viewModel = buildViewModel(repo);
      final sessionState = SessionState(
        startupValidator: StartupValidator(
          deviceSettingsStorage: FakeDeviceSettingsStorage(),
          sessionStorage: FakeSessionStorage(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(viewModel: viewModel, sessionState: sessionState),
        ),
      );
      await tester.pumpAndSettle();

      await enterByLabel(tester, 'Register endpoint', 'https://register');
      expect(viewModel.subBranches, isEmpty);

      // Tap straight into another field instead of pressing the keyboard's
      // "Done" action — focus moves away without an editing-complete event.
      final flightApiField = find.byWidgetPredicate(
        (w) =>
            w is TextField && w.decoration?.labelText == 'Flight API endpoint',
      );
      await tester.tap(flightApiField);
      await tester.pumpAndSettle();

      expect(viewModel.subBranches.single.subbranchCode, 'CPX-DT');
      expect(find.text('Sub-branch'), findsOneWidget);
    },
  );

  testWidgets('a save failure shows a retryable error', (tester) async {
    final repo = FakeSettingsRepository();
    final viewModel = SettingsViewModel(
      loadDeviceSettings: LoadDeviceSettingsUseCase(repo),
      saveDeviceSettings: _FailingSaveDeviceSettingsUseCase(),
      listSubBranches: ListSubBranchesUseCase(repo),
    );
    final sessionState = SessionState(
      startupValidator: StartupValidator(
        deviceSettingsStorage: FakeDeviceSettingsStorage(),
        sessionStorage: FakeSessionStorage(),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(viewModel: viewModel, sessionState: sessionState),
      ),
    );
    await tester.pumpAndSettle();

    await enterByLabel(tester, 'Branch number', '03');
    await enterByLabel(tester, 'Sale Engine endpoint', 'https://sale-engine');
    await enterByLabel(tester, 'Register endpoint', 'https://register');
    await enterByLabel(tester, 'Flight API endpoint', 'https://flight');

    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Could not save device settings.'), findsOneWidget);
    expect(sessionState.status, isNot(StartupStatus.needsLogin));
  });

  group('desktop settings (desktop width)', () {
    const configured = DeviceSettings(
      moduleKey: 'PosKpi',
      branch: '03',
      location: 'Downtown Rangnam',
      printerName: 'Star TSP143',
      edcPort: 'COM3',
      saleEngineEndpoint: 'https://sale-engine',
      webServiceEndpoint: 'https://register',
      flightApi: 'https://flight',
    );

    Future<FakeSettingsRepository> pumpDesktop(
      WidgetTester tester, {
      Size size = const Size(1440, 1400),
      bool pushed = false,
    }) async {
      setDeviceSize(tester, size);
      final repo = FakeSettingsRepository(settings: configured);
      final page = SettingsPage(viewModel: buildViewModel(repo));
      if (pushed) {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => page)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
      } else {
        await tester.pumpWidget(MaterialApp(home: page));
      }
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('four panels side by side with automation ids', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDesktop(tester);
      expect(find.text('Device settings'), findsOneWidget);
      for (final id in [
        DesktopIds.settingsTerminalPanel,
        DesktopIds.settingsPeripheralsPanel,
        DesktopIds.settingsEndpointsPanel,
        DesktopIds.settingsDevicePanel,
        SettingsIds.sellOnline,
        SettingsIds.sellOffline,
        SettingsIds.saveButton,
      ]) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
      }
      final terminal = tester.getRect(
        byTestId(DesktopIds.settingsTerminalPanel),
      );
      final endpoints = tester.getRect(
        byTestId(DesktopIds.settingsEndpointsPanel),
      );
      expect(endpoints.left, greaterThan(terminal.right), reason: 'columns');
      expect(
        find.descendant(
          of: byTestId(DesktopIds.settingsPeripheralsPanel),
          matching: find.textContaining('not available yet'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('Sell offline + Save in the top bar persists', (tester) async {
      final repo = await pumpDesktop(tester);
      await tester.tap(byTestId(SettingsIds.sellOffline));
      await tester.pumpAndSettle();
      await tester.tap(byTestId(SettingsIds.saveButton));
      await tester.pumpAndSettle();
      expect(repo.settings.forceOfflineMode, isTrue);
      expect(repo.settings.printerName, 'Star TSP143');
    });

    testWidgets('edits in any panel are saved', (tester) async {
      final repo = await pumpDesktop(tester);
      await enterByLabel(tester, 'EDC port', 'COM7');
      await enterByLabel(tester, 'Location', 'Airport Pickup D');
      await tester.tap(byTestId(SettingsIds.saveButton));
      await tester.pumpAndSettle();
      expect(repo.settings.edcPort, 'COM7');
      expect(repo.settings.location, 'Airport Pickup D');
    });

    testWidgets('a required field left empty blocks Save', (tester) async {
      final repo = await pumpDesktop(tester);
      await enterByLabel(tester, 'Branch number', '');
      await tester.tap(byTestId(SettingsIds.saveButton));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);
      expect(repo.settings.branch, '03');
    });

    testWidgets('Cancel is offered when pushed and pops', (tester) async {
      await pumpDesktop(tester, pushed: true);
      await tester.tap(byTestId(SettingsIds.cancelButton));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('no overflow at 1024 dp (iPad landscape)', (tester) async {
      await pumpDesktop(tester, size: const Size(1024, 1400));
      expect(tester.takeException(), isNull);
    });
  });

  group('handheld settings (below desktop width)', () {
    const configured = DeviceSettings(
      moduleKey: 'MposKpi',
      branch: '03',
      saleEngineEndpoint: 'https://sale-engine',
      webServiceEndpoint: 'https://register',
      flightApi: 'https://flight',
    );

    Future<FakeSettingsRepository> pumpSettings(
      WidgetTester tester, {
      Size size = compactSize,
      DeviceSettings settings = configured,
      bool pushed = false,
    }) async {
      setDeviceSize(tester, size);
      final repo = FakeSettingsRepository(settings: settings);
      final page = SettingsPage(viewModel: buildViewModel(repo));
      if (pushed) {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => page)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
      } else {
        await tester.pumpWidget(MaterialApp(home: page));
      }
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('dark header, grouped sections and automation ids', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSettings(tester);

      expect(find.text('Device settings'), findsOneWidget);
      expect(find.text('Smart POS Mobile · MposKpi'), findsOneWidget);
      for (final id in [
        SettingsIds.terminalSection,
        SettingsIds.saleModeSection,
        SettingsIds.sellOnline,
        SettingsIds.sellOffline,
        SettingsIds.saveButton,
      ]) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
      }
      // Lower sections exist but may be scrolled off — check the tree.
      expect(byTestId(SettingsIds.endpointsSection), findsOneWidget);
      expect(byTestId(SettingsIds.deviceSection), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Save sits in the fixed bottom bar, reachable without scroll', (
      tester,
    ) async {
      final repo = await pumpSettings(tester);
      final save = tester.getRect(byTestId(SettingsIds.saveButton));
      expect(save.bottom, lessThanOrEqualTo(compactSize.height));
      expect(save.top, greaterThan(compactSize.height - 120));

      await tester.tap(byTestId(SettingsIds.saveButton));
      await tester.pumpAndSettle();
      expect(repo.settings.moduleKey, 'MposKpi');
    });

    testWidgets('Sell online / Sell offline is a single-choice toggle', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final repo = await pumpSettings(tester);

      expect(
        tester.getSemantics(byTestId(SettingsIds.sellOnline)),
        isSemantics(isSelected: true),
      );
      await tester.tap(byTestId(SettingsIds.sellOffline));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(byTestId(SettingsIds.sellOffline)),
        isSemantics(isSelected: true),
      );
      expect(
        find.textContaining('prices from the local cache'),
        findsOneWidget,
      );

      await tester.tap(byTestId(SettingsIds.saveButton));
      await tester.pumpAndSettle();
      expect(repo.settings.forceOfflineMode, isTrue);
      handle.dispose();
    });

    testWidgets('Cancel is offered when pushed, and pops without saving', (
      tester,
    ) async {
      final repo = await pumpSettings(tester, pushed: true);
      await tester.tap(find.text('Sell offline'));
      await tester.pumpAndSettle();
      await tester.tap(byTestId(SettingsIds.cancelButton));
      await tester.pumpAndSettle();

      expect(find.text('open'), findsOneWidget);
      expect(repo.settings.forceOfflineMode, isFalse);
    });

    testWidgets('first-run setup (not pushed) has no Cancel', (tester) async {
      await pumpSettings(tester);
      expect(byTestId(SettingsIds.cancelButton), findsNothing);
    });

    testWidgets('iPad portrait: sections centred at the medium width', (
      tester,
    ) async {
      await pumpSettings(tester, size: mediumSize);
      final rect = tester.getRect(byTestId(SettingsIds.terminalSection));
      expect(rect.width, lessThanOrEqualTo(720));
      expect(rect.center.dx, closeTo(410, 0.5));
    });
  });
}

class _FailingSaveDeviceSettingsUseCase implements SaveDeviceSettingsUseCase {
  @override
  Future<void> call(DeviceSettings settings) async {
    throw Exception('network down');
  }
}

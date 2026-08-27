# POS Desktop Phase 1: Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the shared infrastructure the rest of the POS Desktop mockup depends on: five new reusable widgets, a desktop text-theme pairing, and a breakpoint-aware navigation model on the Home page with stub Home/Enquiry landing screens — with zero visual change to the existing mobile layout.

**Architecture:** Purely additive. No new state-management approach, no new routing system. Five new stateless widgets live under `lib/core/presentation/widgets/`, each with a narrow, generic API and its own widget test. `AppTypography` gains a second `TextTheme` factory alongside the existing one. `HomePage` replaces its single hardcoded 3-destination list and `int` tab index with a breakpoint-aware destination/section model built on a new `_HomeSection` enum, so mobile (`AppBreakpoints.isWide == false`) renders exactly as it does today and desktop-width renders the mockup's 5-item nav (Home/Sale/Enquiry/Customer/Setup) with two new stub pages.

**Tech Stack:** Flutter/Dart, `flutter_test`, existing `AppColors`/`AppSpacing`/`AppSizing`/`AppBreakpoints` tokens, GetX (`GetBuilder`) already used by `HomePage` — unchanged by this plan.

**Spec:** `docs/superpowers/specs/2026-08-27-pos-desktop-design.md`

## Global Constraints

- Breakpoint threshold is `AppBreakpoints.wide` (840.0) — reuse it, never a new magic number.
- No visual or behavioral change to the existing mobile (`isWide == false`) layout — every change here is additive.
- Any backend-touching action with no existing use case gets a `// TODO(pos-desktop): <what's missing>` comment plus a disabled/inert affordance — never a silent fake success. (Applies to future phases; Phase 1 has no such actions.)
- The Enquiry module is presentation-only this phase — no domain/data layer scaffolding.
- New widgets use the existing design tokens (`AppColors`, `AppSpacing`, `AppSizing`) — no new hardcoded colors/sizes.
- Interactive elements get a `Key(...)` for testability, matching existing widgets (e.g. `AppCard`, `_CustomerHeaderDetail`'s `editCustomerButton`).
- `flutter analyze` must report no issues and `flutter test` must pass after every task.

---

### Task 1: `AppTypography.desktopTextTheme`

**Files:**
- Modify: `lib/core/theme/app_typography.dart`
- Test: `test/core/theme/app_typography_test.dart` (new file)

**Interfaces:**
- Produces: `AppTypography.desktopTextTheme(Color color) → TextTheme`, mirroring the existing `textTheme(Color color)` structure but pairing `'KingPowerHeadline'` (display/headline/title styles) with `'KingPowerText'` (body/label styles) — the "KP Head"/"KP Text" split from the POS Desktop mockup's CSS. `displayLarge` uses `FontWeight.w700`, not the existing `textTheme`'s `w900`, because the mockup's `@font-face` block only declares Bold(700)/Medium(500)/Regular(400) weights for `KP Head`.

- [ ] **Step 1: Write the failing test**

Create `test/core/theme/app_typography_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/theme/app_typography.dart';

void main() {
  group('desktopTextTheme', () {
    test('pairs KingPowerHeadline for headline styles', () {
      final theme = AppTypography.desktopTextTheme(Colors.black);

      expect(theme.displayLarge?.fontFamily, 'KingPowerHeadline');
      expect(theme.headlineLarge?.fontFamily, 'KingPowerHeadline');
      expect(theme.headlineMedium?.fontFamily, 'KingPowerHeadline');
      expect(theme.titleLarge?.fontFamily, 'KingPowerHeadline');
      expect(theme.titleMedium?.fontFamily, 'KingPowerHeadline');
    });

    test('pairs KingPowerText for body/label styles', () {
      final theme = AppTypography.desktopTextTheme(Colors.black);

      expect(theme.bodyLarge?.fontFamily, 'KingPowerText');
      expect(theme.bodyMedium?.fontFamily, 'KingPowerText');
      expect(theme.bodySmall?.fontFamily, 'KingPowerText');
      expect(theme.labelLarge?.fontFamily, 'KingPowerText');
      expect(theme.labelMedium?.fontFamily, 'KingPowerText');
    });

    test('applies the given color to every style except bodySmall', () {
      final theme = AppTypography.desktopTextTheme(Colors.red);

      expect(theme.displayLarge?.color, Colors.red);
      expect(theme.bodyLarge?.color, Colors.red);
      // bodySmall always uses AppColors.textSecondary, matching textTheme()'s
      // existing behavior — not the passed-in color.
      expect(theme.bodySmall?.color, isNot(Colors.red));
    });

    test('does not change the existing single-family textTheme', () {
      final theme = AppTypography.textTheme(Colors.black);

      expect(theme.displayLarge?.fontFamily, 'KingPowerHeadline');
      expect(theme.bodyLarge?.fontFamily, 'KingPowerHeadline');
      expect(theme.displayLarge?.fontWeight, FontWeight.w900);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/theme/app_typography_test.dart`
Expected: FAIL — `desktopTextTheme` isn't defined on `AppTypography`.

- [ ] **Step 3: Write the implementation**

In `lib/core/theme/app_typography.dart`, add alongside the existing `_fontFamily` constant and `textTheme` method (do not modify `textTheme` itself):

```dart
  // The mockup's two-family pairing ("KP Head"/"KP Text" in its CSS) —
  // opt-in for desktop-width widgets via [desktopTextTheme] below. Mobile
  // keeps using [textTheme]'s single `_fontFamily` unchanged.
  static const _headFamily = 'KingPowerHeadline';
  static const _textFamily = 'KingPowerText';

  /// Desktop-width variant pairing `KingPowerHeadline` (display/headline/
  /// title) with `KingPowerText` (body/label), matching the POS Desktop
  /// mockup's "KP Head"/"KP Text" split (see
  /// docs/superpowers/specs/2026-08-27-pos-desktop-design.md). `KingPowerText`
  /// is not yet bundled as a Flutter-compatible asset — see that spec's Open
  /// Items — so until it's added, text using this theme falls back to the
  /// platform default font rather than erroring.
  static TextTheme desktopTextTheme(Color color) => TextTheme(
    displayLarge: TextStyle(
      fontFamily: _headFamily,
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    headlineLarge: TextStyle(
      fontFamily: _headFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    headlineMedium: TextStyle(
      fontFamily: _headFamily,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    titleLarge: TextStyle(
      fontFamily: _headFamily,
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: color,
    ),
    titleMedium: TextStyle(
      fontFamily: _headFamily,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: color,
    ),
    bodyLarge: TextStyle(
      fontFamily: _textFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    bodyMedium: TextStyle(
      fontFamily: _textFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    labelLarge: TextStyle(
      fontFamily: _textFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    labelMedium: TextStyle(
      fontFamily: _textFamily,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    bodySmall: TextStyle(
      fontFamily: _textFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
  );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/theme/app_typography_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_typography.dart test/core/theme/app_typography_test.dart
git commit -m "feat: add desktop text theme pairing KP Head/KP Text families"
```

---

### Task 2: `DesktopDataTable`

**Files:**
- Create: `lib/core/presentation/widgets/desktop_data_table.dart`
- Test: `test/core/presentation/widgets/desktop_data_table_test.dart`

**Interfaces:**
- Produces: `DesktopDataColumn({required String label, TextAlign align = TextAlign.left})`; `DesktopDataTable({required List<DesktopDataColumn> columns, required List<List<Widget>> rows, Widget? emptyPlaceholder})`. Each entry in `rows` must have exactly one `Widget` per column (asserted in debug mode).

- [ ] **Step 1: Write the failing test**

Create `test/core/presentation/widgets/desktop_data_table_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/desktop_data_table.dart';

void main() {
  testWidgets('renders column headers and one row per data row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopDataTable(
            columns: const [
              DesktopDataColumn(label: 'Item'),
              DesktopDataColumn(label: 'Qty'),
            ],
            rows: [
              [const Text('Cola 500ml'), const Text('2')],
              [const Text('Water 1L'), const Text('1')],
            ],
          ),
        ),
      ),
    );

    expect(find.text('Item'), findsOneWidget);
    expect(find.text('Qty'), findsOneWidget);
    expect(find.text('Cola 500ml'), findsOneWidget);
    expect(find.text('Water 1L'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('shows the empty placeholder when there are no rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopDataTable(
            columns: const [DesktopDataColumn(label: 'Item')],
            rows: const [],
            emptyPlaceholder: const Text('No items yet'),
          ),
        ),
      ),
    );

    expect(find.text('No items yet'), findsOneWidget);
    expect(find.text('Item'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/presentation/widgets/desktop_data_table_test.dart`
Expected: FAIL — file `desktop_data_table.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/core/presentation/widgets/desktop_data_table.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// One column heading for [DesktopDataTable].
class DesktopDataColumn {
  final String label;
  final TextAlign align;

  const DesktopDataColumn({required this.label, this.align = TextAlign.left});
}

/// Dense, header-plus-rows table used by the POS Desktop mockup's Sale,
/// Basket, and Enquiry screens — replacing the five-stacked-lines-per-item
/// mobile layout with one table row per item now that desktop width has
/// room for it (see docs/superpowers/specs/2026-08-27-pos-desktop-design.md).
/// Deliberately generic: callers supply pre-built cell widgets rather than
/// this table owning any row-formatting logic.
class DesktopDataTable extends StatelessWidget {
  final List<DesktopDataColumn> columns;
  final List<List<Widget>> rows;
  final Widget? emptyPlaceholder;

  const DesktopDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    assert(
      rows.every((row) => row.length == columns.length),
      'Each row must have exactly one cell per column',
    );

    if (rows.isEmpty && emptyPlaceholder != null) {
      return emptyPlaceholder!;
    }

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TableRow(
          columns.map(
            (c) => Text(
              c.label,
              textAlign: c.align,
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        for (var i = 0; i < rows.length; i++) ...[
          _TableRow(rows[i]),
          if (i != rows.length - 1)
            const Divider(height: 1, color: AppColors.divider),
        ],
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  final Iterable<Widget> cells;

  const _TableRow(this.cells);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          for (final cell in cells) Expanded(child: cell),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/presentation/widgets/desktop_data_table_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/presentation/widgets/desktop_data_table.dart test/core/presentation/widgets/desktop_data_table_test.dart
git commit -m "feat: add DesktopDataTable shared widget"
```

---

### Task 3: `OverlayPanel`

**Files:**
- Create: `lib/core/presentation/widgets/overlay_panel.dart`
- Test: `test/core/presentation/widgets/overlay_panel_test.dart`

**Interfaces:**
- Produces: `OverlayPanel({required String title, required Widget child, required VoidCallback onClose, double? width})`. Renders a header (title + a `Key('overlayPanelCloseButton')` close icon) above `child`; pressing the physical Escape key or tapping the close button both invoke `onClose`.

- [ ] **Step 1: Write the failing test**

Create `test/core/presentation/widgets/overlay_panel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/overlay_panel.dart';

void main() {
  testWidgets('renders the title and child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverlayPanel(
            title: 'Discount & promotion',
            onClose: () {},
            child: const Text('overlay body'),
          ),
        ),
      ),
    );

    expect(find.text('Discount & promotion'), findsOneWidget);
    expect(find.text('overlay body'), findsOneWidget);
  });

  testWidgets('tapping the close button invokes onClose', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverlayPanel(
            title: 'Discount',
            onClose: () => closed = true,
            child: const Text('body'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('overlayPanelCloseButton')));
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('pressing Escape invokes onClose', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverlayPanel(
            title: 'Discount',
            onClose: () => closed = true,
            child: const Text('body'),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(closed, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/presentation/widgets/overlay_panel_test.dart`
Expected: FAIL — file `overlay_panel.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/core/presentation/widgets/overlay_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizing.dart';
import '../../theme/app_spacing.dart';

/// Shared chrome for the mockup's overlay/side-panel screens (Discount &
/// promotion, Flight & passport capture, the flight date/time picker,
/// Lookups) — a title bar with a close action, plus "Esc to cancel/return"
/// (see docs/superpowers/specs/2026-08-27-pos-desktop-design.md). Callers
/// place this inside their own `showDialog`/overlay call; it owns only the
/// header chrome and the Escape-key binding, not the surrounding dialog
/// route.
class OverlayPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onClose;
  final double? width;

  const OverlayPanel({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
      child: Focus(
        autofocus: true,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.cornerRadiusMd),
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title, style: textTheme.titleMedium),
                      ),
                      IconButton(
                        key: const Key('overlayPanelCloseButton'),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/presentation/widgets/overlay_panel_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/presentation/widgets/overlay_panel.dart test/core/presentation/widgets/overlay_panel_test.dart
git commit -m "feat: add OverlayPanel shared widget"
```

---

### Task 4: `WizardStepBar`

**Files:**
- Create: `lib/core/presentation/widgets/wizard_step_bar.dart`
- Test: `test/core/presentation/widgets/wizard_step_bar_test.dart`

**Interfaces:**
- Produces: `WizardStepBar({required String title, required int currentStep, required int totalSteps})` — a 1-based step indicator ("Step X of Y") next to a title.

- [ ] **Step 1: Write the failing test**

Create `test/core/presentation/widgets/wizard_step_bar_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/wizard_step_bar.dart';

void main() {
  testWidgets('renders the title and the current/total step count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WizardStepBar(
            title: 'Checkout',
            currentStep: 2,
            totalSteps: 3,
          ),
        ),
      ),
    );

    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Step 2 of 3'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/presentation/widgets/wizard_step_bar_test.dart`
Expected: FAIL — file `wizard_step_bar.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/core/presentation/widgets/wizard_step_bar.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Step indicator for the mockup's Checkout/Payment wizard screens
/// ("Step 2 of 3", "Step 3 of 3") — see
/// docs/superpowers/specs/2026-08-27-pos-desktop-design.md.
class WizardStepBar extends StatelessWidget {
  final String title;
  final int currentStep;
  final int totalSteps;

  const WizardStepBar({
    super.key,
    required this.title,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: textTheme.titleMedium),
        Text(
          'Step $currentStep of $totalSteps',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/presentation/widgets/wizard_step_bar_test.dart`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add lib/core/presentation/widgets/wizard_step_bar.dart test/core/presentation/widgets/wizard_step_bar_test.dart
git commit -m "feat: add WizardStepBar shared widget"
```

---

### Task 5: `HotkeyTileGrid`

**Files:**
- Create: `lib/core/presentation/widgets/hotkey_tile_grid.dart`
- Test: `test/core/presentation/widgets/hotkey_tile_grid_test.dart`

**Interfaces:**
- Produces: `HotkeyTile({required IconData icon, required String label, required VoidCallback onTap})` and `HotkeyTileGrid({required List<HotkeyTile> tiles})`. Each tile is tappable and keyed `Key('hotkeyTile_<label>')`.

- [ ] **Step 1: Write the failing test**

Create `test/core/presentation/widgets/hotkey_tile_grid_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/hotkey_tile_grid.dart';

void main() {
  testWidgets('renders a tile per entry and invokes its onTap when tapped', (
    tester,
  ) async {
    var saleTapped = false;
    var customerTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HotkeyTileGrid(
            tiles: [
              HotkeyTile(
                icon: Icons.point_of_sale,
                label: 'New sale',
                onTap: () => saleTapped = true,
              ),
              HotkeyTile(
                icon: Icons.person_add,
                label: 'Registration',
                onTap: () => customerTapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('New sale'), findsOneWidget);
    expect(find.text('Registration'), findsOneWidget);

    await tester.tap(find.byKey(const Key('hotkeyTile_New sale')));
    await tester.pump();

    expect(saleTapped, isTrue);
    expect(customerTapped, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/presentation/widgets/hotkey_tile_grid_test.dart`
Expected: FAIL — file `hotkey_tile_grid.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/core/presentation/widgets/hotkey_tile_grid.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizing.dart';
import '../../theme/app_spacing.dart';

/// One tappable tile in a [HotkeyTileGrid].
class HotkeyTile {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const HotkeyTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Grid of icon+label shortcut tiles for the Home dashboard mockup screen
/// (New sale / Registration / Add / Pickup, etc. — see
/// docs/superpowers/specs/2026-08-27-pos-desktop-design.md).
class HotkeyTileGrid extends StatelessWidget {
  final List<HotkeyTile> tiles;

  const HotkeyTileGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      children: [for (final tile in tiles) _HotkeyTileButton(tile: tile)],
    );
  }
}

class _HotkeyTileButton extends StatelessWidget {
  final HotkeyTile tile;

  const _HotkeyTileButton({required this.tile});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('hotkeyTile_${tile.label}'),
      onTap: tile.onTap,
      borderRadius: BorderRadius.circular(AppSizing.cornerRadiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppSizing.cornerRadiusMd),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tile.icon,
              size: AppSizing.iconSizeLarge,
              color: AppColors.goldAccent,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(tile.label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/presentation/widgets/hotkey_tile_grid_test.dart`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add lib/core/presentation/widgets/hotkey_tile_grid.dart test/core/presentation/widgets/hotkey_tile_grid_test.dart
git commit -m "feat: add HotkeyTileGrid shared widget"
```

---

### Task 6: `SupervisorLockGate`

**Files:**
- Create: `lib/core/presentation/widgets/supervisor_lock_gate.dart`
- Test: `test/core/presentation/widgets/supervisor_lock_gate_test.dart`

**Interfaces:**
- Produces: `SupervisorLockGate({required bool locked, required VoidCallback onUnlock, required Widget child})`. When `locked` is `true`, shows a lock message and a `Key('supervisorUnlockButton')` button instead of `child`; when `false`, shows `child` directly.

- [ ] **Step 1: Write the failing test**

Create `test/core/presentation/widgets/supervisor_lock_gate_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/supervisor_lock_gate.dart';

void main() {
  testWidgets('shows the lock message and hides child when locked', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SupervisorLockGate(
            locked: true,
            onUnlock: () {},
            child: const Text('terminal settings form'),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('supervisorUnlockButton')), findsOneWidget);
    expect(find.text('terminal settings form'), findsNothing);
  });

  testWidgets('shows child directly when unlocked', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SupervisorLockGate(
            locked: false,
            onUnlock: () {},
            child: const Text('terminal settings form'),
          ),
        ),
      ),
    );

    expect(find.text('terminal settings form'), findsOneWidget);
    expect(find.byKey(const Key('supervisorUnlockButton')), findsNothing);
  });

  testWidgets('tapping Unlock invokes onUnlock', (tester) async {
    var unlocked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SupervisorLockGate(
            locked: true,
            onUnlock: () => unlocked = true,
            child: const Text('form'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('supervisorUnlockButton')));
    await tester.pump();

    expect(unlocked, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/presentation/widgets/supervisor_lock_gate_test.dart`
Expected: FAIL — file `supervisor_lock_gate.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/core/presentation/widgets/supervisor_lock_gate.dart`:

```dart
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizing.dart';
import '../../theme/app_spacing.dart';

/// Gates `child` behind a "supervisor card required" placeholder — the
/// mockup's Settings screen locks terminal setup fields until authorised
/// (see docs/superpowers/specs/2026-08-27-pos-desktop-design.md, decision
/// 4). `onUnlock` is a stub for now: there's no supervisor-card
/// verification backend yet, so callers should show their own
/// `// TODO(pos-desktop): verify supervisor card` at the call site rather
/// than this widget inventing a fake check.
class SupervisorLockGate extends StatelessWidget {
  final bool locked;
  final VoidCallback onUnlock;
  final Widget child;

  const SupervisorLockGate({
    super.key,
    required this.locked,
    required this.onUnlock,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;

    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: AppSizing.iconSizeLarge,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Locked — supervisor card required',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              key: const Key('supervisorUnlockButton'),
              onPressed: onUnlock,
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/presentation/widgets/supervisor_lock_gate_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/presentation/widgets/supervisor_lock_gate.dart test/core/presentation/widgets/supervisor_lock_gate_test.dart
git commit -m "feat: add SupervisorLockGate shared widget"
```

---

### Task 7: `HomeDashboardPage` stub

**Files:**
- Create: `lib/features/home/presentation/home_dashboard_page.dart`
- Test: `test/features/home/presentation/home_dashboard_page_test.dart`

**Interfaces:**
- Produces: `HomeDashboardPage` (a `StatelessWidget`, no constructor parameters). Placeholder for screen 2 of the mockup ("Home — shift, scan-to-start, hotkeys") — full content is a later phase.

- [ ] **Step 1: Write the failing test**

Create `test/features/home/presentation/home_dashboard_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/home/presentation/home_dashboard_page.dart';

void main() {
  testWidgets('renders a placeholder message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeDashboardPage()),
    );

    expect(find.textContaining('coming soon'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/home/presentation/home_dashboard_page_test.dart`
Expected: FAIL — file `home_dashboard_page.dart` doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/features/home/presentation/home_dashboard_page.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Desktop-only landing screen — screen 2 of the POS Desktop mockup ("Home —
/// shift, scan-to-start, hotkeys"). Placeholder for Phase 1: shift figures,
/// scan-to-start, and hotkey tiles land in a later phase (see
/// docs/superpowers/specs/2026-08-27-pos-desktop-design.md). Only reachable
/// at desktop width — see `HomePage`'s breakpoint-aware navigation.
class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text('Home dashboard — coming soon'),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/home/presentation/home_dashboard_page_test.dart`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/presentation/home_dashboard_page.dart test/features/home/presentation/home_dashboard_page_test.dart
git commit -m "feat: add HomeDashboardPage stub for desktop landing"
```

---

### Task 8: `EnquiryPage` stub

**Files:**
- Create: `lib/features/enquiry/presentation/enquiry_page.dart`
- Test: `test/features/enquiry/presentation/enquiry_page_test.dart`

**Interfaces:**
- Produces: `EnquiryPage` (a `StatelessWidget`, no constructor parameters). Placeholder for screen 10 of the mockup ("Enquiry — transaction search"); presentation-only per the spec's decision 4/global constraints — no domain or data layer for this feature yet.

- [ ] **Step 1: Write the failing test**

Create `test/features/enquiry/presentation/enquiry_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/enquiry/presentation/enquiry_page.dart';

void main() {
  testWidgets('renders a placeholder message', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EnquiryPage()));

    expect(find.textContaining('coming soon'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/enquiry/presentation/enquiry_page_test.dart`
Expected: FAIL — the `enquiry` feature directory/file doesn't exist.

- [ ] **Step 3: Write the implementation**

Create `lib/features/enquiry/presentation/enquiry_page.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Transaction search — screen 10 of the POS Desktop mockup. Placeholder
/// for Phase 1: presentation-only per
/// docs/superpowers/specs/2026-08-27-pos-desktop-design.md's decision 4 —
/// the real search UI, local state, and (eventually) a backend usecase land
/// in a later phase once scoped. Only reachable at desktop width — see
/// `HomePage`'s breakpoint-aware navigation.
class EnquiryPage extends StatelessWidget {
  const EnquiryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text('Enquiry — coming soon'),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/enquiry/presentation/enquiry_page_test.dart`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add lib/features/enquiry/presentation/enquiry_page.dart test/features/enquiry/presentation/enquiry_page_test.dart
git commit -m "feat: add EnquiryPage stub for the new Enquiry feature"
```

---

### Task 9: Breakpoint-aware navigation on `HomePage`

**Files:**
- Modify: `lib/features/home/presentation/home_page.dart`
- Test: `test/features/home/presentation/home_page_test.dart`

**Interfaces:**
- Consumes: `HomeDashboardPage` (Task 7), `EnquiryPage` (Task 8), `AppBreakpoints.isWide(BuildContext) → bool` (existing), `SaleCartViewModel.selectPrivilege(Privilege?)` (existing, unchanged).
- Produces: a private `_HomeSection` enum (`home`, `customers`, `sale`, `enquiry`) replacing `_tabIndex`'s `int`. Mobile (`isWide == false`) shows exactly today's 3 destinations (Customers/Sale/Settings) landing on Customers; desktop (`isWide == true`) shows 5 (Home/Sale/Enquiry/Customer/Setup) landing on Home. Behavior and labels for existing mobile screens are unchanged — this task only adds the desktop branch and swaps the underlying index type.

This task modifies existing code rather than adding new files, so the steps below are structured as a sequence of test-then-implementation edits against the current file rather than one file created from scratch.

- [ ] **Step 1: Write the failing tests for desktop navigation**

Add to `test/features/home/presentation/home_page_test.dart` (append inside `void main() { ... }`, after the existing tests — keep all existing tests as-is):

```dart
  testWidgets(
    'at desktop width, shows Home/Sale/Enquiry/Customer/Setup and lands on Home',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();

      expect(find.text('Home dashboard — coming soon'), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Sale'), findsWidgets);
      expect(find.text('Enquiry'), findsWidgets);
      expect(find.text('Customer'), findsWidgets);
      expect(find.text('Setup'), findsWidgets);
      // Mobile-only labels must not appear.
      expect(find.text('Customers'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    },
  );

  testWidgets(
    'at desktop width, tapping Enquiry shows the Enquiry placeholder',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enquiry').last);
      await tester.pumpAndSettle();

      expect(find.text('Enquiry — coming soon'), findsOneWidget);
    },
  );

  testWidgets(
    'at desktop width, tapping Customer shows customer search',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Customer').last);
      await tester.pumpAndSettle();

      expect(find.text('Search customer'), findsOneWidget);
    },
  );

  testWidgets(
    'at desktop width, tapping Setup pushes the settings page',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Setup').last);
      await tester.pumpAndSettle();

      expect(find.text('Device settings'), findsOneWidget);
    },
  );

  testWidgets(
    'below desktop width, still shows the original Customers/Sale/Settings nav landing on Customers',
    (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();

      expect(find.text('Search customer'), findsOneWidget);
      expect(find.text('Home dashboard — coming soon'), findsNothing);
      expect(find.text('Enquiry'), findsNothing);
    },
  );
```

- [ ] **Step 2: Run tests to verify the new ones fail**

Run: `flutter test test/features/home/presentation/home_page_test.dart`
Expected: the 5 new tests FAIL (no "Home"/"Enquiry"/"Customer"/"Setup" destinations exist yet); all pre-existing tests in this file still PASS.

- [ ] **Step 3: Add the imports and replace the destination/tab-index model**

In `lib/features/home/presentation/home_page.dart`, add two imports alongside the existing ones:

```dart
import '../../../core/theme/app_breakpoints.dart';
```

and, near the other feature imports:

```dart
import '../../enquiry/presentation/enquiry_page.dart';
import 'home_dashboard_page.dart';
```

Replace this block:

```dart
class _HomePageState extends State<HomePage> {
  static const _destinations = [
    AppNavDestination(icon: Icons.people, label: 'Customers'),
    AppNavDestination(icon: Icons.point_of_sale, label: 'Sale'),
    AppNavDestination(icon: Icons.settings, label: 'Settings'),
  ];

  final _customerSearchController = TextEditingController();
  // Customers is the landing tab — including immediately after login.
  int _tabIndex = 0;
  late final SaleCartViewModel _saleCartViewModel;
```

with:

```dart
class _HomePageState extends State<HomePage> {
  // Canonical order backing the body's IndexedStack — index into this list
  // (via `.values.indexOf`) must stay stable regardless of breakpoint, so
  // switching width mid-session doesn't recreate (and lose the state of)
  // any of these pages.
  static const _mobileDestinations = [
    AppNavDestination(icon: Icons.people, label: 'Customers'),
    AppNavDestination(icon: Icons.point_of_sale, label: 'Sale'),
    AppNavDestination(icon: Icons.settings, label: 'Settings'),
  ];
  static const _mobileSections = [_HomeSection.customers, _HomeSection.sale];

  // Desktop's 5-item nav from the POS Desktop mockup (see
  // docs/superpowers/specs/2026-08-27-pos-desktop-design.md, decision 2) —
  // "Customer"/"Setup" reuse the same underlying screens as mobile's
  // "Customers"/"Settings"; "Home" and "Enquiry" are new.
  static const _desktopDestinations = [
    AppNavDestination(icon: Icons.dashboard_outlined, label: 'Home'),
    AppNavDestination(icon: Icons.point_of_sale, label: 'Sale'),
    AppNavDestination(icon: Icons.receipt_long_outlined, label: 'Enquiry'),
    AppNavDestination(icon: Icons.people, label: 'Customer'),
    AppNavDestination(icon: Icons.settings, label: 'Setup'),
  ];
  static const _desktopSections = [
    _HomeSection.home,
    _HomeSection.sale,
    _HomeSection.enquiry,
    _HomeSection.customers,
  ];

  final _customerSearchController = TextEditingController();
  // Null until the first build, which picks each breakpoint's own default
  // landing section (Customers on mobile, Home on desktop) — see
  // `_buildContent`. Set explicitly after that by nav taps and `_goToSale`.
  _HomeSection? _section;
  late final SaleCartViewModel _saleCartViewModel;
```

- [ ] **Step 4: Add the `_HomeSection` enum**

Add this near the top of the file, above the `HomePage` class declaration (after the `_customerSearchHint` constant):

```dart
/// The body sections `HomePage` can show, independent of which nav
/// destinations are visible at the current breakpoint (mobile shows only
/// `customers`/`sale`; desktop shows all four — see `_HomePageState`'s
/// `_mobileSections`/`_desktopSections`).
enum _HomeSection { home, customers, sale, enquiry }
```

- [ ] **Step 5: Replace `_onDestinationSelected` and the two `_tabIndex = 1` assignments in `_goToSale`**

Replace:

```dart
  void _onDestinationSelected(int index) {
    if (index == 2) {
      _openSettings();
      return;
    }
    setState(() => _tabIndex = index);
  }
```

with:

```dart
  void _onDestinationSelected(int index, List<_HomeSection> sections) {
    if (index >= sections.length) {
      _openSettings();
      return;
    }
    setState(() => _section = sections[index]);
  }
```

Replace both occurrences of:

```dart
      setState(() => _tabIndex = 1);
```

(one inside the `if (person.privileges.isEmpty)` branch, one at the end of `_goToSale`) with:

```dart
      setState(() => _section = _HomeSection.sale);
```

- [ ] **Step 6: Rewrite `_buildContent`**

Replace:

```dart
  Widget _buildContent(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const AppShell(title: 'Home', body: LoadingView());
    }

    return AppShell(
      title: _destinations[_tabIndex].label,
      destinations: _destinations,
      selectedIndex: _tabIndex,
      onDestinationSelected: _onDestinationSelected,
      actions: [
        _sessionInfo(viewModel),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
          onPressed: _logOut,
        ),
      ],
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _customerSearchSection(context, viewModel),
          SalePage(viewModel: _saleCartViewModel),
        ],
      ),
    );
  }
```

with:

```dart
  Widget _buildContent(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const AppShell(title: 'Home', body: LoadingView());
    }

    final isWide = AppBreakpoints.isWide(context);
    final destinations = isWide ? _desktopDestinations : _mobileDestinations;
    final sections = isWide ? _desktopSections : _mobileSections;
    final section = (_section != null && sections.contains(_section))
        ? _section!
        : sections.first;
    final selectedIndex = sections.indexOf(section);

    return AppShell(
      title: destinations[selectedIndex].label,
      destinations: destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) =>
          _onDestinationSelected(index, sections),
      actions: [
        _sessionInfo(viewModel),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
          onPressed: _logOut,
        ),
      ],
      // IndexedStack only builds the sections valid for the current
      // breakpoint (via `sections`, not the full `_HomeSection.values`) —
      // otherwise a mobile-width IndexedStack would still build (just not
      // paint) the Home/Enquiry pages, and any widget test asserting they
      // aren't present on mobile would find them anyway, since IndexedStack
      // keeps every child mounted regardless of which index is showing.
      body: IndexedStack(
        index: selectedIndex,
        children: [
          for (final s in sections) _pageFor(s, context, viewModel),
        ],
      ),
    );
  }

  Widget _pageFor(
    _HomeSection section,
    BuildContext context,
    HomeViewModel viewModel,
  ) {
    switch (section) {
      case _HomeSection.home:
        return const HomeDashboardPage();
      case _HomeSection.customers:
        return _customerSearchSection(context, viewModel);
      case _HomeSection.sale:
        return SalePage(viewModel: _saleCartViewModel);
      case _HomeSection.enquiry:
        return const EnquiryPage();
    }
  }
```

- [ ] **Step 7: Run the full test file to verify everything passes**

Run: `flutter test test/features/home/presentation/home_page_test.dart`
Expected: PASS — all pre-existing tests plus the 5 new ones from Step 1.

- [ ] **Step 8: Run `flutter analyze` and the full test suite**

Run: `flutter analyze`
Expected: No issues found.

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 9: Commit**

```bash
git add lib/features/home/presentation/home_page.dart test/features/home/presentation/home_page_test.dart
git commit -m "feat: add breakpoint-aware Home/Sale/Enquiry/Customer/Setup navigation"
```

---

## Self-Review Notes

- **Spec coverage:** every Phase 1 item from the design spec's decisions 1–2 and the "New shared primitives" section has a task (typography pairing: Task 1; data table, overlay shell, step bar, hotkey grid, supervisor gate: Tasks 2–6; breakpoint-aware nav + stub Home/Enquiry: Tasks 7–9). Screens 2–13's real content, the font-sourcing open item, and screen 14 are explicitly out of scope for this plan (tracked in the spec's Open Items) — later phases.
- **Placeholder scan:** no "TBD"/"add error handling"/deferred-detail steps; every step has literal code. `SupervisorLockGate`'s `onUnlock` is a caller-supplied callback, not a stubbed-out method — Task 6 documents in its doc comment that call sites (a later phase) own the `// TODO(pos-desktop)` for the actual verification, since there's no call site yet in this plan to attach one to.
- **Type consistency:** `_HomeSection` (Task 9) matches its four values everywhere it's referenced; `HomeDashboardPage`/`EnquiryPage` (Tasks 7–8) are parameterless `StatelessWidget`s used identically in Task 9's `IndexedStack`. `DesktopDataColumn`/`DesktopDataTable`, `HotkeyTile`/`HotkeyTileGrid` constructor shapes in Task 2/5 match their tests exactly.

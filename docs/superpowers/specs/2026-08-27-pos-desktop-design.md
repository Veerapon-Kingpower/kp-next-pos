# POS Desktop design — implementation design

**Branch:** `feature/pos-desktop-design`
**Source:** Claude Design project "King Power POS UI mockups" (`f4bf75c0-b94d-459f-b93e-36e18865d1fb`), file `POS Desktop.dc.html`, fetched via the `claude_design` MCP (`DesignSync` tool).
**Reference copy:** `docs/design/pos-desktop/reference/POS_Desktop.dc.html` (screens 1–13 complete; screen 14 truncated — see Open Items). Font files under `docs/design/pos-desktop/reference/fonts/*.woff2`.

## Background

The mockup specifies 14 screens for a desktop-oriented POS UI, targeting the same counter-station use case the existing Flutter app (`kp-next-pos`) already serves on mobile/tablet. The app already has one responsive shell (`AppShell`, bottom `NavigationBar` below `AppBreakpoints.wide`, `NavigationRail` at/above it) driven by the same view-models regardless of width. This design extends that pattern rather than building a parallel desktop app.

**Known limitation:** `DesignSync.get_file` caps individual file reads at 256 KiB. `POS Desktop.dc.html` exceeds that; the fetched copy is `truncated: true`, cut off mid-attribute inside screen 14 ("Edit line — Order item" overlay, its "Flags" panel). Screens 1–13 are each confirmed complete (all `id="s1"`..`id="s14"` anchors fall before the truncation point, and s1–s13's content precedes s14 entirely). Screen 14 and anything that might follow it (additional screens, or the `<script data-dc-script>` interaction block) are unknown. Per user decision, this pass implements screens 1–13; screen 14 is an explicit follow-up once the rest of the source file is available (re-fetch after the design project is split into smaller per-screen files, or the remainder is pasted in directly).

## Decisions

1. **Extend existing screens in place.** Same routes, same `GetxController`s (`HomeViewModel`, `SaleCartViewModel`, `CustomerRegistrationViewModel`, `SettingsViewModel`, `LoginViewModel`), same domain/data layers. Each affected screen grows a wide-layout branch (gated on `AppBreakpoints.isWide`) that renders the mockup's structure, instead of the mobile layout simply stretched wider. No parallel "desktop" app, no new state-management approach.

2. **Desktop gets its own nav model.** `AppShell`'s destination list becomes breakpoint-aware:
   - Mobile (unchanged): 3 destinations — Customers, Sale, Settings — landing on Customers.
   - Desktop (new): 5 destinations — Home, Sale, Enquiry, Customer, Setup — landing on a new Home dashboard.

   "Customer" and "Setup" at desktop width map to the same underlying screens as mobile's "Customers" and "Settings"; "Home" and "Enquiry" are new.

3. **Login is a restyle only.** Screen 1 shows PIN entry + terminal binding, but today's `LoginUseCase` is username/password with no terminal-binding concept. This pass builds the desktop-width layout from the mockup and wires it to the *existing* username/password flow. PIN entry and real terminal binding are out of scope — a separately-scoped change once that backend/logic exists.

4. **New-behavior screens: layout and local state now, backend wiring later.** Checkout, Payment, Discount & promotion, Enquiry, Flight & passport capture (MRZ), and Settings' supervisor-lock all introduce interactions with no backend counterpart in the app yet. For all of these:
   - Build the full visual layout from the mockup.
   - Implement all local/client-side UI state: tab switching, step position, form fields, item/row selection, split-tender running totals computed client-side from entered amounts, etc.
   - Any action that would need a real backend call that doesn't exist as a use case (submit payment, run a transaction search, verify a supervisor card, enforce a live max-discount ceiling from the server) is stubbed: a clearly marked `// TODO(pos-desktop): <what's missing>` comment plus a disabled or visibly inert affordance. Never a silent fake success.

5. **Existing-behavior screens wire to real view-models.** Sale/Basket (`SaleCartViewModel`), Customer lookup/edit/register (existing search + `CustomerRegistrationViewModel`), Settings' non-supervisor parts (`SettingsViewModel`), the flight date/time picker (existing `getDatesForFlight`), and the Lookups shell (existing nationality/agent/guide/flight searches) all use real data end to end — only their *layout* is new.

## Screen → feature mapping

| # | Screen | Feature / file | Status |
|---|--------|----------------|--------|
| 1 | Sign in — PIN + terminal binding | `auth/presentation/login_page.dart` | Restyle only (decision 3) |
| 2 | Home — shift, scan-to-start, hotkeys | New: `home/presentation/` desktop landing widget | New screen; scan-to-start reuses `SaleCartViewModel.scan()`; shift/hotkey data is layout-only |
| 3 | Sale — scan & item list (Buying tab) | `sale/presentation/widgets/sale_page.dart` | Wide-layout table view of the real cart |
| 4 | Basket — committed lines & cancellations | `sale` feature, second tab | Check whether `Cart`/`CartItem` model a "cancelled but visible" state; add if not (small domain addition) |
| 5 | Checkout — final review before tender | New, `sale` feature | Decision 4 |
| 6 | Payment — split tender in progress | New, `sale` feature | Decision 4 |
| 7 | Discount & promotion overlay | New, `sale` feature | Decision 4 |
| 8 | Customer — lookup, edit & register | `customer/presentation/` | Wide layout: edit form left, profile right; real view-models |
| 9 | Flight & passport capture | New overlay, `customer` feature | Flight pick real; MRZ stubbed (already tracked in project memory as deferred) |
| 10 | Enquiry — transaction search | New feature module: `enquiry/` | Decision 4 — genuinely new, no backend usecase exists. Presentation-layer only for this pass (view model holding local UI state, no domain/data scaffolding) — add the full clean-architecture layers once a real search API exists, rather than scaffolding usecases/repositories with nothing to call yet |
| 11 | Settings — terminal setup | `settings/presentation/settings_page.dart` | Wide layout; supervisor-lock gate is decision 4, rest is real |
| 12 | Flight date & time picker overlay | Extends `customer_registration_page.dart`'s `_pickFlightDate` | Real data (`getDatesForFlight`), new overlay chrome |
| 13 | Lookups — shared searchable-field shell | New shared widget (extends/replaces `AutocompleteField` for wide layout) | Real data across nationality/agent/guide/flight/customer-type lookups |
| 14 | Edit line — Order item overlay | — | **Deferred** — see Background |

## New shared primitives (`core/presentation/widgets/`)

- **Dense data table** — Sale/Basket item lists, Enquiry results.
- **Step/wizard bar** — Checkout ("Step 2 of 3"), Payment ("Step 3 of 3").
- **Overlay/side-panel shell** with an "Esc to cancel/return" affordance — Discount, Flight & passport capture, the flight date/time picker, Lookups.
- **Supervisor-lock gate** — Settings now, reusable later.
- **Hotkey tile grid** — Home.

## Assets and fonts

Images (`alipay.png`, `logo.png`, `pay-cash.png`, `pay-cup-card.png`, `pay-master-card.png`, `pay-visa.png`, `wechat.png`) were fetched via `DesignSync` during design (all complete, not truncated) but not yet copied into the repo — re-fetch them from the same design project at implementation time (cheap: each is under 20 KB) and add under `assets/imgs/` with a `pubspec.yaml` entry.

**Font gotcha:** the mockup's CSS pairs two families — `KP Head` (`KingPowerHeadline`, weights 400/500/700) and `KP Text` (`KingPowerText`, weights 300/400/700). The app already bundles `KingPowerHeadline` as `.ttf` (`assets/fonts/king_power_headline/`, used today as the *sole* family for the entire `AppTypography` scale) — reuse that directly for `KP Head`. `KingPowerText` is not currently bundled, and the only copies fetched from the design project are `.woff2`, which **Flutter's font asset loader does not accept** (only `.ttf`/`.otf`). The `pubspec.yaml` has a standing comment noting a `KingPowerText2` asset exists in the legacy `smart-pos-mobile` source repo but was excluded as unused — check there first for real `.ttf`/`.otf` files before resorting to a `.woff2`→`.ttf` conversion. This is an implementation-plan task, not a blocking decision.

`AppTypography` will need a second family parameter (or a `KP Text`-specific style set) rather than its current single hardcoded `_fontFamily`, to let desktop-width widgets opt into the headline/body pairing the mockup uses while mobile keeps today's single-family scale (no visual change to existing mobile screens).

## Testing

Same TDD workflow as the rest of the app. Each screen's wide-layout branch gets widget test coverage exercising it at a wide window size (the existing `home_page_test.dart` pattern of pumping a wide `physicalSize` applies directly). New shared widgets (data table, wizard bar, overlay shell, supervisor-lock gate, hotkey grid) get their own focused widget tests independent of any one screen.

## Open items (not blocking this spec)

1. **Screen 14 (Edit line — Order item overlay)** — deferred pending the full, untruncated source file.
2. **`KingPowerText` font sourcing** — locate/convert to `.ttf`/`.otf` before screens that use body-text styling can match the mockup exactly.
3. **Basket's "cancelled but visible" line state** — confirm during implementation whether `Cart`/`CartItem` need a small domain addition, or whether existing fields already cover it.
4. Genuinely new capabilities intentionally stubbed per decision 4 (checkout submission, split-tender payment submission, live discount-ceiling enforcement, transaction search, MRZ capture, supervisor-card verification) remain unimplemented beyond their UI — each is a candidate for its own future architectural pass once the corresponding backend capability exists.

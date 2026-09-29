# POS Handheld design — implementation design

**Branch:** `feature/pos-desktop-design`
**Source:** Claude Design artifact `https://claude.ai/artifact/GMZC7RTrWhvgW5RPKJcrYE`
("King Power · Smart POS · Sunmi handheld — The same fifteen flows, one thumb").
**Reference copy:** `docs/design/pos-handheld/reference/POS_Handheld.dc.html` (bundled page)
and `docs/design/pos-handheld/reference/screens/mNN.html` (one unpacked file per screen,
icons rewritten as `[ICON m-<name> <style>]` — read these, not the bundle).
**Sibling spec:** `2026-08-27-pos-desktop-design.md` (desktop, ≥ 840 dp).

## Background

The handheld mockup is a portrait re-cut (400×860, Sunmi V2) of the same POS flows the
desktop mockup covers: one number that matters per screen, a persistent bottom action
bar with 44 px+ targets, and the scan field always in reach of the hardware trigger.
It has 20 screens. The app today renders an older, generic Material layout below
`AppBreakpoints.wide` (3-tab Customers / Sale / Settings). This design **replaces**
that layout.

## Decisions

1. **Replace the compact layout.** Below `AppBreakpoints.wide` the app renders the
   handheld design. The current compact UI is retired; its view-models, use cases and
   dialogs are reused. This **amends desktop Phase 2 rule #1** ("mobile renders
   byte-for-byte unchanged") — it now reads "below 840 dp renders the handheld layout
   from this spec".
2. **Same routes, same controllers.** `LoginViewModel`, `HomeViewModel`,
   `SaleCartViewModel`, `CustomerRegistrationViewModel`, `SettingsViewModel`. No parallel
   app, no new state-management approach (mirrors desktop decision 1).
3. **All 20 screens now, UI-first.** Every screen gets its full layout and local UI
   state. Any action needing a backend call with no existing use case gets a
   `// TODO(pos-handheld): <what's missing>` comment plus a disabled / visibly inert
   affordance. Never a fake success path (mirrors desktop decision 4). Numbers the app
   cannot know yet (shift bills, net sales, suspended bills, points, e-Purse) render as
   `—` or an empty state, never mock values.
4. **Handheld nav model.** 4 bottom destinations — **Home / Sale / Enquiry / Menu**.
   Home is the landing tab. Customer lookup moves onto Home's scan field (the design's
   "Scan shopping card or passport"); the result opens the customer profile (screen 8).
   Menu opens a bottom sheet (Settings, Log out, device info) rather than a tab body.
5. **Tablet / iPad support** — three width classes, all width-based (no platform checks):

   | Class | Width | Devices | Layout |
   |-------|-------|---------|--------|
   | compact | < 600 | phones, Sunmi V2 | handheld, as drawn |
   | medium | 600 – 839 | iPad mini/Air/Pro 11 portrait, Android tablets portrait | handheld, widened |
   | expanded | ≥ 840 | iPad landscape, iPad Pro 12.9 portrait, Windows | desktop spec |

   *Medium* rules: page body centred with `maxWidth` 720; tile grids and key-value
   blocks go 2-up where the compact layout stacks; bottom sheets render as centred
   dialogs (`maxWidth` 560); the bottom action bar spans the full width. A new
   `AppBreakpoints.medium = 600.0` + `AppBreakpoints.sizeClass(context)` carry this.
   *Expanded* on touch devices: the desktop layout must keep ≥ 44 dp touch targets
   (added as a cross-cutting rule for desktop Phase 2).
6. **Test IDs are mandatory.** Every new or changed interactive element, and every
   element an automation script needs to read (totals, status text), is wrapped in the
   shared `TestId` widget (`lib/core/presentation/widgets/test_id.dart`), which applies
   both a `ValueKey<String>(id)` for widget tests and `Semantics(identifier: id)` for
   device automation (Flutter maps it to Android `resource-id` and iOS
   `accessibilityIdentifier`, so Appium / Maestro can target it).
   ID format: `<screen>.<element>` in lowerCamel, e.g. `home.scanField`,
   `nav.sale`, `sale.checkoutButton`, `payment.tender.card`. IDs are listed in
   `lib/core/presentation/test_ids.dart` as constants — tests and widgets both use the
   constants, never string literals. Existing keys (`editCustomerButton`,
   `privilegeCard_$i`, …) stay unchanged.
7. **Tests per UI change.** Every widget added or changed ships with a widget test
   written first (TDD) that (a) pumps it at compact 400×860, and at medium 820×1180
   where the medium rules change the layout, (b) finds elements via `TestId`
   constants, (c) asserts the semantics identifier is present
   (`find.bySemanticsIdentifier`). Pure logic (formatters, size-class resolution)
   gets unit tests. `flutter analyze` clean + `flutter test` green after every task.

## Visual tokens (additions to `AppColors`)

The handheld design uses a warm near-black chrome instead of the current navy.
New tokens (existing ones unchanged; the desktop layout keeps navy):

| Token | Value | Use |
|-------|-------|-----|
| `ink` | `#191712` | handheld header / sign-in background |
| `gold` | `#C8A04B` | primary action fill, focus border on dark |
| `goldMuted` | `#9F8957` | focused scan-field border, avatar gradient start |
| `goldDark` (exists) | `#654F1C` | icons on light, gold text on cream |
| `cream` | `#FBF8F1` | selected nav item, hint strips |
| `canvas` | `#F4F6F9` (= `surfaceAlt`) | page background |
| `line` | `#E4E8EE` | card borders |
| `mutedText` | `#6B7480` | secondary text |
| `hintText` | `#9AA2AE` | placeholder, inactive nav |
| `online` | `#1DB87A` / `#5BD9A4` | online dot / text on dark |

Gold `#C8A04B` carries dark text (`ink`), never white — add a WCAG check to
`app_colors_test.dart` like the existing gold pairing. Typography uses the existing
`KingPowerHeadline` family; `KingPowerText` is still unbundled (desktop open item) and
falls back the same way.

## Handheld kit (`lib/core/presentation/handheld/`)

| Widget | Purpose | Screens |
|--------|---------|---------|
| `HandheldScaffold` | canvas bg, optional dark header, body, optional action bar; applies medium-width rules | all |
| `HandheldHeader` | dark `ink` block: title, subtitle, trailing slot, optional stat row | 2–12, 14–20 |
| `HandheldStat` | label (caps, 9.5 px) + big tabular number | 2, 3, 5, 6, 8 |
| `ScanField` | 62 dp gold-bordered scan/type field wired to a controller + `onSubmitted` | 2, 3, 16, 17 |
| `HandheldActionBar` | persistent bottom bar: 1 primary (gold, 56 dp) + up to 3 secondary | 3–9, 12–20 |
| `HandheldNavBar` | 4-item bottom nav with cream selected pill | Home/Sale/Enquiry |
| `HandheldTile` | 84 dp icon + label shortcut tile | 2 |
| `HandheldSection` | white card with title/count header and dividers | 2, 4, 5, 8, 10, 11, 19 |
| `HandheldSheet` | `showHandheldSheet()` — bottom sheet (compact) / dialog (medium) | 7, 13, 14, 15, 20, Menu |
| `SegmentedTabs` | Buying/Basket, Percent/Amount/Promo, method pickers | 3, 4, 6, 7 |
| `StatusPill` | APPROVED / PENDING / COMPLETE / REFUNDED … using `transaction_status.dart` colours | 6, 10, 19 |

## Screen → feature mapping

| # | Screen | Where | Data |
|---|--------|-------|------|
| 1 | Sign in | `auth/presentation/login_page.dart` compact branch | real (user code + password); "Login with QR code" and staff-card scan inert |
| 2 | Home | `home/presentation/handheld/handheld_home_page.dart` | scan → real customer search; tiles navigate; bills/net sales/suspended bills `—` / empty |
| 3 | Sale · Buying | `sale/presentation/handheld/` | real cart (scan, qty, remove); discount/fulfilment/serial chips inert |
| 4 | Basket | `sale/presentation/handheld/` | real lines grouped as "Take now" until fulfilment exists; cancel/un-cancel inert |
| 5 | Checkout | `sale/presentation/handheld/checkout_page.dart` | totals from real cart; customer from session selection; rate/VAT/subsidy `—` |
| 6 | Payment · split tender | `sale/presentation/handheld/payment_page.dart` | client-side tender entry + running remaining; Charge inert |
| 7 | Discount sheet | sheet | local state (percent/amount/promo, presets, net preview); Apply inert |
| 8 | Customer profile | `customer/presentation/handheld/` | real `Customer` + privileges; points/e-Purse/spend/visits `—`; Attach to bill = existing "Go to Sale" guards |
| 9 | Flight & passport | `customer/presentation/handheld/` | flight list inert until a flight-by-date API; MRZ inert (deferred per memory) |
| 10 | Enquiry | `enquiry/presentation/` compact branch | filters + search local; results empty state; Reprint/Refund inert |
| 11 | Settings | `settings/presentation/settings_page.dart` compact branch | real `SettingsViewModel`; supervisor Edit via `SupervisorLockGate` (inert verify) |
| 12 | Register customer | `customer/presentation/customer_registration_page.dart` compact branch | real `CustomerRegistrationViewModel`; scan passport inert |
| 13 | Flight date picker | sheet from 12 | real `getDatesForFlight` |
| 14 | Edit line | sheet from 3 | qty real; serial/freeze/lock/pickup/CITES/VAS inert |
| 15 | Signature | page from 5 | local capture (`CustomPainter`), Save inert |
| 16 | Sale · normal | variant of 3 | header variant only (flight + Take/Collect counts `—`) |
| 17 | Sale · pre-order | variant of 3 | header variant + pickup banner; order type selection inert |
| 18 | Wallet · B scan C | page from 6 | UI states local; charge/poll inert |
| 19 | Wallet · query | page from 6 | ledger + query result layout; query inert |
| 20 | Wallet · void | sheet from 19 | reason + manager approval via `SupervisorLockGate`; Void inert |

## Sub-phases

Each gets its own task-by-task TDD plan at execution time
(`docs/superpowers/plans/2026-09-29-pos-handheld-hN-*.md`).

- **H1 — foundation + quick wins:** size classes, `TestId` + `test_ids.dart`, colour
  tokens, handheld kit, `HandheldNavBar` in `HomePage` compact branch, screens 1, 2, 11.
- **H2 — sale spine:** 3, 16, 17, 4, 14, 7.
- **H3 — checkout & payment:** 5, 6, 18, 19, 20, 15.
- **H4 — customer & lookups:** 8, 12, 13, 9, 10.

## Open items

- `KingPowerText` font asset (shared with desktop).
- Backend for: shift stats, suspended bills, enquiry search, discount ceilings,
  fulfilment/claim checks, payment/EDC/wallet (2C2P), signature upload, MRZ.
- Staff-card / QR login needs an auth API variant.

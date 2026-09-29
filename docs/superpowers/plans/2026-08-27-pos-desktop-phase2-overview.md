# POS Desktop Phase 2: Screens — overview plan

> **For agentic workers:** this is the **structure** plan for Phase 2. It fixes
> the sub-phase split, sequencing, cross-cutting rules, and per-screen scope.
> Each sub-phase (2a–2d) gets its own task-by-task TDD plan file written
> **at execution time** (same granularity as
> `2026-08-27-pos-desktop-phase1-foundation.md`), not up front — the Group B
> screens need design calls that are better made against the code as it stands
> when that sub-phase starts. REQUIRED SUB-SKILL when executing a sub-phase:
> `superpowers:subagent-driven-development` or `superpowers:executing-plans`.

**Goal:** Build the 13 desktop-width screens from the POS Desktop mockup
(screens 1–13; screen 14 deferred) on top of the Phase 1 foundation, with zero
visual or behavioural change to the existing mobile layout.

**Spec:** `docs/superpowers/specs/2026-08-27-pos-desktop-design.md`
**Phase 1 plan (done):** `docs/superpowers/plans/2026-08-27-pos-desktop-phase1-foundation.md`
**Mockup reference:** `docs/design/pos-desktop/reference/POS_Desktop.dc.html` (screens 1–13 complete)

---

## Phase 1 recap — what Phase 2 builds on

Foundation shipped and available now:

| Primitive | File | Used by (Phase 2) |
|-----------|------|-------------------|
| `DesktopDataTable` | `lib/core/presentation/widgets/desktop_data_table.dart` | S3, S4, S5, S10 |
| `OverlayPanel` (Esc-to-cancel shell) | `lib/core/presentation/widgets/overlay_panel.dart` | S7, S9, S12, S13 |
| `WizardStepBar` | `lib/core/presentation/widgets/wizard_step_bar.dart` | S5, S6 |
| `HotkeyTileGrid` | `lib/core/presentation/widgets/hotkey_tile_grid.dart` | S2 |
| `SupervisorLockGate` | `lib/core/presentation/widgets/supervisor_lock_gate.dart` | S11 (S7 above-ceiling reuse) |
| `AppTypography.desktopTextTheme` | `lib/core/theme/app_typography.dart` | all wide-layout widgets |
| Breakpoint-aware nav + `HomeDashboardPage` / `EnquiryPage` stubs | `lib/features/home/presentation/home_page.dart` | S2, S10 fill the stubs |

`HomePage` already renders the desktop 5-item nav (Home/Sale/Enquiry/Customer/Setup)
via `IndexedStack` over `_HomeSection`; S2 and S10 fill in `HomeDashboardPage` and
`EnquiryPage`; S3/S8/S11 add a wide branch to `SalePage` / customer / settings.

---

## Cross-cutting rules (apply to every sub-phase)

1. **Breakpoint gate** — every new wide layout is gated on `AppBreakpoints.isWide(context)`
   (threshold `AppBreakpoints.wide == 840.0`). Below it, the handheld layout from
   `docs/superpowers/specs/2026-09-29-pos-handheld-design.md` renders (amended
   2026-09-29 — the old compact UI is being replaced). No new magic numbers.
   Desktop layouts also run on iPad landscape, so keep touch targets ≥ 44 dp.
8. **Test IDs** — every new interactive / automation-readable element is wrapped in
   `TestId` with a constant from `lib/core/presentation/test_ids.dart` (handheld spec
   decision 6), and has a widget test asserting it.
2. **Same routes, same controllers** — `LoginViewModel`, `HomeViewModel`,
   `SaleCartViewModel`, `CustomerRegistrationViewModel`, `SettingsViewModel`. No new
   state-management approach, no parallel desktop app (spec decision 1).
3. **No silent fakes** — any action needing a backend call with no existing use case
   gets a `// TODO(pos-desktop): <what's missing>` comment **plus** a disabled or
   visibly inert affordance. Never a fake success path (spec decision 4).
4. **Tokens only** — `AppColors` / `AppSpacing` / `AppSizing` / `AppBreakpoints`.
   New wide widgets opt into `desktopTextTheme`; mobile keeps the single-family scale.
5. **Keys for testability** — interactive elements get a `Key(...)`, matching
   `AppCard` / `editCustomerButton` precedent.
6. **TDD** — failing widget test first, at a wide `physicalSize` (the
   `home_page_test.dart` pattern). `flutter analyze` clean + `flutter test` green
   after every task.
7. **Desktop keyboard model** — the mockup labels hotkeys (F2/F9/Enter/Esc) on
   nearly every screen. Wire real `Shortcuts`/`Actions` for the ones whose target
   action already exists (scan focus, search submit, Esc-closes-overlay); label but
   leave inert (rule 3) the ones whose action is stubbed.

---

## Data-reality map — READ THIS before scoping any sale screen

The spec's decision 5 ("existing-behaviour screens wire to real view-models")
**overstates** what the sale domain currently provides. Ground truth:

| Concept the mockup shows | Exists today? | Where it belongs |
|--------------------------|---------------|------------------|
| scan-to-add, qty change, remove line | ✅ `SaleCartViewModel` | — |
| `Cart` = `guid`, `isCheckOut`, `items` | ✅ | — |
| `CartItem` = `row`, `articleCode`, `articleName`, `quantity`, `unitPrice`, `lineTotal` | ✅ **but field mapping is MOCK / unconfirmed** (`cart_item.dart` doc comment) | correct at UAT |
| per-line **discount** (`−780.00`, `5%`, `max disc 10%`) | ❌ | openspec task 4.4 / 5.2 |
| per-line **fulfilment** (Collect / Take) | ❌ | openspec task 6.1 |
| line **locked / frozen** state (tobacco) | ❌ | openspec task 5.2 |
| **cancelled-but-visible** line (S4 Basket) | ❌ | spec open item #3 — small domain add |
| bill **totals** (Total, line discounts, Grand, Cash-D subsidy, VAT, Net pay) | ❌ | openspec task 4.4 |
| **currency selection** + FX rate + change calc | ❌ | openspec task 4.4 |
| **payment / tender** (any) | ❌ | openspec task 5.1 |
| **checkout** state machine | ❌ | openspec task 5.4 |
| **signature** capture | ❌ | openspec task 5.3 |
| **transaction search** (S10 Enquiry) | ❌ | openspec task 6.3 |
| **supervisor-card verify** (S7 above-ceiling, S11 Edit) | ❌ | — |
| **MRZ** passport read (S9) | ❌ | openspec task 7.9 (deferred) |

**Consequence:** S3–S7 and S10 are mostly **Group B** (layout + local/client state,
backend stubbed), not Group A. Each of those screens introduces a
**presentation-only view model** holding local UI state and, where the mockup needs
numbers, **client-side arithmetic over entered values** (split-tender running total,
percent discount preview, change due) — never a server call. When openspec 4.4 / 5.x
later land the real domain, these screens swap their stub source for the real one
without a layout rewrite.

> This is also where Track A (openspec `migrate-smart-pos-to-flutter`) and Track B
> (this design work) **collide**. Phase 2 delivers the *desktop layout* for
> workflows that openspec 4.4 / 5.1–5.4 / 6.1 / 6.3 will later fill with real
> domain/data. Keep the presentation-only view models small and clearly marked so
> that later merge is mechanical, not a rewrite.

---

## Sub-phase split & sequencing

```
2a  quick wins (independent)        S1 · S2 · S10 · S11
2b  sale spine                      S3 ──▶ S4 (+domain add) ──▶ S7
2c  checkout flow                   S5 ──▶ S6 (+payment icon assets)
2d  customer & lookups              S13 ──▶ S12 ──▶ S8 ──▶ S9

dependency edges:
  S13 Lookups shell ─┬─▶ S8, S9
  S12 Flight picker ─┘   (S12 also used by S8's form)
  S3 Sale table ────┬─▶ S4, S7, S5
  S5 Checkout ──────────▶ S6
```

Recommended order: **2a → 2b → 2c → 2d**. 2a de-risks the foundation against real
screens and closes the two stubs. 2d can run in parallel with 2b/2c if a second
worker is available (no shared files: sale feature vs customer feature).

---

## Sub-phase 2a — quick wins

### S1 — Sign in (restyle only)

- **Scope:** wide-width branch of `login_page.dart` matching mockup screen 1
  (terminal-identity panel: station, machine, business date, RC/app/bridge status
  chips; username + password; "Remember username on this terminal"; QR sign-in
  block). Wire to the **existing** username/password flow + existing QR import.
- **Out of scope (rule 3, spec decision 3):** PIN entry, real terminal binding,
  "5 failed attempts locks terminal", live RC/bridge status. Render the identity
  panel from `SettingsViewModel` device settings where available; static/`—` otherwise.
- **Tasks:** (1) wide two-column `LoginPage` layout behind `isWide`; (2) terminal
  identity panel widget fed by device settings; (3) status-chip row (`status_chip.dart`)
  — values static-labelled, `// TODO(pos-desktop): live RC/app/bridge status`;
  (4) "Remember username" persisted via existing settings persistence; (5) widget
  tests at wide size — layout present, submit calls existing `login()`, mobile
  unchanged.

### S2 — Home dashboard (fill `HomeDashboardPage` stub)

- **Scope:** replace the "coming soon" placeholder with mockup screen 2 —
  greeting + shift line; the three KPI tiles (Bills / Net sales / Avg bill);
  "Start a sale" scan input; `HotkeyTileGrid` (New sale F2 / Registration F3 /
  Enquiry F4 / Suspended bills); suspended-bills list; today's-promotions list.
- **Real:** the scan input calls `SaleCartViewModel.scan()` then switches
  `_HomeSection.sale` (reuse `HomePage._goToSale`-style tab switch); hotkey tiles
  route to existing sections (Sale / Registration page / Enquiry section).
- **Stub (rule 3):** shift figures, float counted, KPI numbers, suspended-bills
  entries, promotions — all layout-only from a small `HomeDashboardViewModel`
  holding placeholder data; `// TODO(pos-desktop): shift + suspended-bill + KPI API`.
- **Tasks:** (1) `HomeDashboardViewModel` (presentation-only, placeholder data);
  (2) header/greeting + shift line; (3) KPI tile row; (4) scan-to-start wired to
  cart + section switch; (5) hotkey grid wired to real routes; (6) suspended-bills
  + promotions lists (inert); (7) widget tests — scan starts a sale, tiles route,
  desktop-only (absent on mobile).

### S11 — Settings (wide branch of `settings_page.dart`)

- **Scope:** mockup screen 11 — two-column terminal-identity / endpoints layout,
  wrapped in `SupervisorLockGate`: read-only until "Authorise edit" passes the gate.
  Sections: Terminal identity (module type locked, branch/sub-branch, sale mode
  online/offline), Peripherals list (printer / EDC / card reader status), Setup-by-QR.
- **Real:** everything `SettingsViewModel` already exposes (branch, sub-branch,
  module, sale mode, device settings) — read + write once the gate is open.
- **Stub:** supervisor-card verification inside `SupervisorLockGate` (already a
  Phase 1 stub affordance); live peripheral status (`READY`/`PAIRED`/`idle`) —
  static-labelled, `// TODO(pos-desktop): live peripheral health` (openspec 7.6).
- **Tasks:** (1) wide two-column layout behind `isWide`; (2) `SupervisorLockGate`
  wrapping the editable region; (3) terminal-identity fields bound to
  `SettingsViewModel`; (4) sale-mode online/offline control bound to VM;
  (5) peripherals list (inert status); (6) widget tests — gate blocks edit until
  authorised, fields persist, mobile settings unchanged.

### S10 — Enquiry (fill `EnquiryPage` stub)

- **Scope:** mockup screen 10 — replace the stub with a `DesktopDataTable` of
  transactions (Shopping card / Time / Customer / Lines / Net paid / Status),
  a filter row (shopping card, date range, status), Reprint / Refund / Open-bill
  actions, and a right-hand detail panel for the selected bill (order type,
  totals, discount, payment tenders, claim-check info).
- **Presentation-only (spec decision 4, mapping row):** no domain/data layer this
  pass — an `EnquiryViewModel` holding local UI state and a **static placeholder
  result set**; Search, Reprint, Refund, Open-bill all inert with
  `// TODO(pos-desktop): transaction search API` → openspec task 6.3. Add the full
  clean-architecture layers only once a real search API exists.
- **Tasks:** (1) `EnquiryViewModel` (filters + selection + placeholder rows);
  (2) filter row; (3) `DesktopDataTable` of results with ↑↓ + Enter-to-open;
  (4) selected-bill detail panel; (5) action row (inert); (6) widget tests —
  filter narrows the placeholder set, row selection drives the detail panel,
  desktop-only.

**2a plan file:** `2026-08-27-pos-desktop-phase2a-quick-wins.md`

---

## Sub-phase 2b — sale spine

### S3 — Sale, Buying tab (wide branch of `SalePage`)

- **Scope:** mockup screen 3 — `DesktopDataTable` with columns
  `# · Item · Qty · Unit price · Discount · Net (THB) · Fulfilment`, a permanent
  right-hand bill summary panel, sale context header (order type, customer,
  FX rate, cashier), scan/lookup row with `Lookup F9` / `Qty × F7` affordances,
  Buying/Basket tab switch.
- **Real:** the item rows, qty, unit price, line total, scan-to-add, qty change,
  remove — all from `SaleCartViewModel` / `Cart` / `CartItem` as they exist.
- **Stub (per data-reality map):** Discount column (show `—`), Fulfilment column
  (show `—`), locked/frozen badges, and the entire right-hand **bill summary**
  (Total / line discounts / Grand / Cash-D / VAT / Net pay). Drive the summary
  from a `SaleBillViewModel` (presentation-only) that sums `lineTotal` client-side
  for a provisional subtotal and shows `—` for every figure that needs the real
  totals API; `// TODO(pos-desktop): bill totals` → openspec task 4.4.
- **Tasks:** (1) `SaleBillViewModel` (client-side subtotal, stubbed figures);
  (2) wide `SalePage` branch: table + summary + header behind `isWide`;
  (3) `DesktopDataTable` config for cart rows incl. select-all / consolidate
  affordances (inert where no backend); (4) scan/lookup row with F9/F7 shortcuts
  (F9 lookup inert-stub, F7 qty-multiplier reuses existing `qty*barcode` parse);
  (5) Buying/Basket `TabBar` — Basket tab renders S4; (6) widget tests — real cart
  rows render, subtotal reflects lineTotals, stubbed figures show `—`, mobile
  `SalePage` unchanged.

### S4 — Basket tab (+ domain addition)

- **Domain add (spec open item #3):** first confirm whether `Cart` / `CartItem`
  can already model a **cancelled-but-visible** line. They cannot (no status
  field). Add a minimal `CartItem.status` (`active` / `cancelled`) or a
  `cancelledAt` / `cancelReason` pair — smallest change that lets a cancelled line
  stay in `items`, render struck-through, be excluded from totals, and be
  un-cancelled. Update `cart_item_model.dart` mapping + its doc caveat. Domain +
  model unit tests first.
- **Scope:** same `DesktopDataTable`, Basket tab — committed lines grouped by
  fulfilment, cancelled lines visible + reversible ("Un-cancel"), Print basket /
  Group-by-fulfilment / Cancel line / Edit discount / Claim check actions.
- **Stub:** cancel/un-cancel mutate **local** view-model state only
  (`// TODO(pos-desktop): commit line cancellation to order API`); claim-check,
  print basket, group-by-fulfilment inert; Edit discount opens S7.
- **Tasks:** (1) `CartItem` status domain add + model + tests; (2) Basket tab
  wide layout with grouped rows; (3) local cancel / un-cancel; (4) basket summary
  (lines / cancelled / per-fulfilment counts) client-side; (5) action row (mostly
  inert); (6) widget tests — cancelled line visible + excluded from count,
  un-cancel restores.

### S7 — Discount & promotion overlay

- **Scope:** `OverlayPanel` over the sale (never a route) — mockup screen 7:
  Percent / Amount / New-price tabs, promotion-code field, quick-set chips
  (3/5/7/10/15/20%), a **live line preview** (unit price, qty, discount amount,
  new line net) and a bill-net-pay delta, available-promotions list.
- **Real / client-side:** all discount arithmetic (percent ↔ amount ↔ new-price,
  line net, bill delta) computed client-side from the entered value and the line's
  `unitPrice` / `quantity`.
- **Stub (rule 3):** the **max-discount ceiling** ("max 10% for this article") —
  no per-article ceiling field exists; hard-code a stub ceiling per line or read
  a placeholder, and gate "above ceiling" behind `SupervisorLockGate`
  (`// TODO(pos-desktop): per-article max-discount ceiling` → openspec 5.2);
  tobacco "discount locked" — inert, no override; applying the discount writes to
  the **local** `CartItem` (needs the discount field from S4's domain work or a
  parallel local `lineDiscount` map on the bill VM), `// TODO(pos-desktop):
  persist line discount to order API`.
- **Tasks:** (1) discount-math domain helper (pure, fully unit-tested: percent/
  amount/new-price conversions, ceiling check); (2) `OverlayPanel` content — tabs,
  code field, quick-set chips; (3) live line-preview + bill-delta bound to the
  helper; (4) above-ceiling → `SupervisorLockGate` (stub verify); (5)
  available-promotions list (inert / eligibility labelled); (6) apply writes local
  line discount; (7) widget tests — math correct, ceiling blocks, locked line has
  no editable control.

**2b plan file:** `2026-08-27-pos-desktop-phase2b-sale-spine.md`

---

## Sub-phase 2c — checkout flow

### S5 — Checkout (`WizardStepBar` "Step 2 of 3")

- **Scope:** mockup screen 5, new in the `sale` feature, reached from S3's
  "Take payment". One-page review: customer block, flight & passport block,
  compact line table (`DesktopDataTable`, read-only), a blocking-flags panel
  ("All blocking flags cleared" / list of unmet flags), amount-due breakdown
  (Total / line discounts / Grand / Cash-D subsidy / VAT included / Net pay +
  USD approximation + fixed FX rate), customer-signature row, "Take payment"
  (→ S6) / Suspend bill / Print quote.
- **Stub:** the flags engine (serial captured, CITES, shipping address confirmed) —
  a `CheckoutViewModel` (presentation-only) holding a list of flag results, all
  defaulted to "cleared" with `// TODO(pos-desktop): real blocking-flags check`;
  totals reuse S3's stubbed `SaleBillViewModel`; signature row shows "captured on
  pad · tap to view" but capture itself is inert (openspec 5.3); Suspend / Print
  quote inert.
- **Tasks:** (1) `CheckoutViewModel` (flags list, all-clear default, entry from
  cart); (2) `WizardStepBar` + Esc-to-return-to-sale; (3) customer + flight/passport
  summary blocks (real customer data if a customer is attached, else walk-in);
  (4) read-only line table; (5) blocking-flags panel; (6) amount-due breakdown from
  bill VM; (7) signature row (inert) + Take payment → S6; (8) widget tests — flags
  panel reflects VM, Take payment routes, Esc returns.

### S6 — Payment (`WizardStepBar` "Step 3 of 3")

- **Assets first:** re-fetch payment icons from the design project (`alipay.png`,
  `logo.png`, `pay-cash.png`, `pay-cup-card.png`, `pay-master-card.png`,
  `pay-visa.png`, `wechat.png`), add under `assets/imgs/` (**new dir**) + `pubspec.yaml`.
- **Scope:** mockup screen 6 — method tiles (Credit card F1 / Cash F2 / UnionPay F3
  / Wallet QR F4 / Cash card F5 / e-Purse F6 / Voucher F7 / More F8); a selected
  method's detail panel (Cash shown: currency selector THB/USD/EUR/CNY/JPY with
  rates, amount-tendered field, quick chips, numeric keypad, "Applied to bill",
  "Change due", Add-cash-tender / Open-drawer); a **running tender ledger** (entries
  with status APPROVED / PENDING); a persistent Net pay / Tendered / Remaining
  block; "Complete sale" enabled only when Remaining reaches ฿0.00.
- **Real / client-side:** the entire split-tender arithmetic — per-tender applied
  amount (capped at remaining), change due, running remaining, multi-currency
  conversion using the entered rate table. All in a `PaymentViewModel`
  (presentation-only).
- **Stub (rule 3):** every actual payment authorisation — adding a tender appends
  a ledger entry with a fake `PENDING`/manual status but performs **no** EDC / 2C2P
  / wallet call (`// TODO(pos-desktop): tender authorisation` → openspec 5.1 / 7.4);
  Open drawer, Void tender, Payment history inert; "Complete sale" enables on
  Remaining == 0 but its handler is `// TODO(pos-desktop): finalize transaction`
  (openspec 5.4) + disabled/inert.
- **Tasks:** (1) `PaymentViewModel` (tender list, currency table, remaining/change
  math — heavily unit-tested); (2) method-tile grid + F-key shortcuts;
  (3) selected-method detail panel (Cash path fully, others labelled);
  (4) numeric keypad widget + quick chips; (5) tender ledger list; (6) persistent
  totals block; (7) Complete-sale enable-gate (inert handler); (8) widget tests —
  remaining decrements, change computed, over-tender capped, Complete disabled
  until zero.

**2c plan file:** `2026-08-27-pos-desktop-phase2c-checkout-flow.md`

---

## Sub-phase 2d — customer & lookups

### S13 — Lookups shell (do first — S8/S9/S12 depend on it)

- **Scope:** one shared widget covering the five customer-form searchable fields
  (Flight code / Nationality / Customer type / Agent code / Sub agent code).
  Extends or replaces `autocomplete_field.dart` for wide layout: magnifier or
  type-to-open (never a route), filter-every-keystroke on code **or** name,
  first-match pre-selected, ↑↓ move, Enter picks + advances focus, Esc closes
  unchanged, exact full code commits without opening the list. Sub-agent disabled
  until an agent is chosen; changing agent clears sub-agent.
- **Real:** all five datasets already have use cases — nationality
  (`ListNationalitiesUseCase`), agent/guide (`ListAgents` / `ListGuides`), flight
  (`GetFlightByCodeUseCase`), customer type (config). Wire each.
- **Tasks:** (1) `DesktopLookupField<T>` widget (keyboard model, filter, commit
  rules) with its own widget tests independent of any screen; (2) adapters for the
  five datasets; (3) agent → sub-agent dependency wiring; (4) drop-in replacement
  in `customer_registration_page.dart`'s wide branch (mobile keeps
  `AutocompleteField`); (5) widget tests per dataset + keyboard-nav tests.

### S12 — Flight date & time picker overlay

- **Scope:** `OverlayPanel` over the customer form — mockup screen 12: month
  calendar (past dates disabled, must be today-or-later), a departure-time list
  sourced from the flight schedule (not a free clock), selected-datetime readout,
  Confirm (Enter) / Cancel.
- **Real:** `getDatesForFlight` / `GetDateByFlightUseCase` **already exists and is
  wired** into `CustomerRegistrationViewModel` (`customer_registration_page.dart`
  `_pickFlightDate` @ line 341). This task is **overlay chrome only** over that
  existing data — replace the current picker UI with the mockup's calendar +
  time-list.
- **Tasks:** (1) `OverlayPanel`-based calendar + time-list widget fed by the
  resolved `List<Flight>` dates; (2) past-date disabling; (3) time list from the
  flight schedule entries; (4) swap into `_pickFlightDate` for the wide branch;
  (5) widget tests — past dates disabled, time from schedule, Confirm returns
  the datetime, mobile picker unchanged.

### S8 — Customer (wide branch of the customer feature)

- **Scope:** mockup screen 8 — edit form on the **left**, resolved-customer
  profile on the **right** (one identifier → one customer, so the form sits where
  a result list would be). Detected-ID-type chip; "Attach to bill"; profile card
  with points / e-Purse / spend YTD / visits / privileges-available-now;
  international-flight-required field markers; "Non-international flight (clears
  flight fields)" toggle; Update / Undo.
- **Real:** existing customer search + `CustomerRegistrationViewModel` for the
  form; the `_CustomerResultCard` content from `home_page.dart` is the basis for
  the right-hand profile. Uses S13 lookups + S12 picker.
- **Stub:** "Attach to bill" — needs a bill/order context the app doesn't hold yet
  (`// TODO(pos-desktop): attach customer to active order` → openspec 4.3/4.4);
  points / spend YTD / visits if not on the customer entity — show `—`.
- **Tasks:** (1) wide two-column `CustomerRegistrationPage` (or a new desktop
  wrapper) behind `isWide`; (2) left = existing form using S13 fields + S12 picker;
  (3) right = profile card (reuse `_CustomerResultCard` internals — consider
  extracting them to `customer/presentation/widgets/`); (4) detected-ID-type chip
  from the existing format detection; (5) non-international toggle clears flight
  fields; (6) Attach-to-bill inert; (7) widget tests — form + profile side by side,
  real search populates both, mobile registration unchanged.

### S9 — Flight & passport capture overlay

- **Scope:** `OverlayPanel` — mockup screen 9: passport MRZ read on the left
  (surname / given names / passport no. / nationality / DOB / expiry), boarding-pass
  scan, departure-flight list on the right (filter by no./destination/time, Today/
  Tomorrow/Europe/After-20:00 quick filters, per-flight status ON TIME/+25 MIN),
  collection-point block, "Save traveller details" (Enter) / Cancel.
- **Real:** the flight list — reuse S13's flight dataset / `GetFlightByCodeUseCase`;
  saving writes the picked flight to `CustomerRegistrationViewModel` (same path the
  form's optional Flight field already uses).
- **Stub (openspec 7.9, already deferred):** MRZ camera read — the left panel
  renders the parsed-fields layout but capture is inert; "Enter manually" is the
  working path; `// TODO(pos-desktop): camera MRZ scan`. Boarding-pass barcode
  scan inert. Allowance checks (liquor/tobacco vs nationality/destination) —
  labelled, not enforced.
- **Tasks:** (1) `OverlayPanel` two-pane layout; (2) MRZ-fields display + manual
  entry (capture inert); (3) departure-flight list + quick filters using flight
  dataset; (4) collection-point block (from settings / flight); (5) save → VM;
  (6) widget tests — flight filter works, manual entry + save writes VM, MRZ
  capture affordance is inert.

**2d plan file:** `2026-08-27-pos-desktop-phase2d-customer-lookups.md`

---

## Blockers & open items

| # | Item | Blocks | Action |
|---|------|--------|--------|
| 1 | `KingPowerText` — only `.woff2` available, Flutter needs `.ttf`/`.otf` | visual polish on every screen (not a hard block — `desktopTextTheme` falls back) | check `smart-pos-mobile` legacy repo for `KingPowerText2` `.ttf`/`.otf` before any `.woff2`→`.ttf` conversion (spec open item #2) |
| 2 | payment method icons not in repo; `assets/imgs/` does not exist | S6 | re-fetch from design project at start of 2c (each < 20 KB) + `pubspec.yaml` entry |
| 3 | `Cart` / `CartItem` have no line status | S4 | minimal domain add at start of 2b/S4 (spec open item #3) |
| 4 | no line-discount / fulfilment / totals / tender / checkout domain | S3–S7, S10 | **not a blocker** — Phase 2 ships layout + presentation-only VMs + client-side math per the data-reality map; openspec 4.4 / 5.x / 6.1 / 6.3 fill the real domain later |
| 5 | screen 14 (Edit line overlay) source truncated at 256 KiB | S14 only | deferred — re-fetch after the design project is split into per-screen files |
| 6 | supervisor-card verification has no backend | S7 above-ceiling, S11 Edit | `SupervisorLockGate` stub affordance (Phase 1) — keep inert |

## Testing

Per cross-cutting rule 6: failing widget test first, wide `physicalSize`, one
focused test file per screen's wide branch + independent test files for new shared
widgets (`DesktopLookupField`, numeric keypad). Pure helpers (discount math,
split-tender math, change calc) get exhaustive unit tests **before** any UI.
`flutter analyze` clean + `flutter test` green after every task. Golden tests for
the shared-component states follow the Phase 1 pattern.

## Reconciliation with Track A (openspec)

When openspec `migrate-smart-pos-to-flutter` tasks 4.4 / 5.1–5.4 / 6.1 / 6.3 are
implemented, revisit each Phase 2 presentation-only view model
(`SaleBillViewModel`, `CheckoutViewModel`, `PaymentViewModel`,
`HomeDashboardViewModel`, the Enquiry VM) and replace its stub source with the real
domain use case. The layouts do not change; only the data source behind them does.

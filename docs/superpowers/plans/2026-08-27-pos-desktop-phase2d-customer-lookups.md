# POS Desktop Phase 2d: Customer & lookups — task plan

> Written at execution time (2026-09-29) against the code after 2c, per the
> Phase 2 overview. REQUIRED SUB-SKILL: `superpowers:executing-plans`.

**Screens:** S13 Lookups · S12 Flight date & time · S8 Customer · S9 Flight & passport.
**Overview:** `2026-08-27-pos-desktop-phase2-overview.md` (sub-phase 2d).
**Mockups:** `docs/design/pos-desktop/reference/screens/s08.html`, `s09.html`, `s12.html`, `s13.html`.

## Ground truth found before planning

- The desktop branch of `CustomerRegistrationPage` is still the pre-desktop
  Material form (`AutocompleteField`, `showDatePicker`). Handheld has its own
  branch; both share one `State` (controllers, validation, submit).
- The desktop Customer tab (`home_page.dart` `_customerSearchSection`) is the
  old AppCard search + `_CustomerResultCard` (legacy-parity content, ~20 tests).
  Its "Go to Sale" is unreachable — desktop has no way to attach a customer.
- There is **no ID-format detection**: `Register/GetCustomer` takes a single
  `shoppingCard` value. The mockup's "Detected Member ID" chip has no source.
- Customer type: the repository documents `typeSearch: "customertype"` on
  `SaleEngine/GetListAgent` (legacy `CustomertypePickerPage`), but no use case
  calls it; the form's Customer type is free text.
- Guides (`typeSearch: "guide"`) take no agent parameter.
- No departures feed, gate / delay status, region, MRZ, boarding-pass reader,
  DOB / expiry field on the register API.

## Tasks

1. **`DesktopLookupField<T>`** (`lib/core/presentation/desktop/`) — S13 shell:
   label (+ required marker), magnifier opens, typing opens (debounced
   remote search), first match pre-selected, ↑↓ move, Enter picks and moves
   focus on, Esc closes and restores the committed value, an exact full code
   typed + Enter commits without the list, disabled state with a reason
   footer. Own widget tests.
2. **Customer-type dataset** — `ListCustomerTypesUseCase`
   (`typeSearch: "customertype"`), `CustomerRegistrationViewModel.searchCustomerTypes`,
   DI. Unit test.
3. **S12 `showDesktopFlightDatePicker`** — dialog: month calendar (days before
   the first candidate and non-operating days disabled), selected-datetime
   readout, departure time from the schedule candidate for the picked day
   (not a free clock), Confirm (Enter) / Cancel (Esc). Widget tests.
4. **Desktop registration form** — rewrite `_buildDesktop`: mockup two-column
   field grid using S13 lookups (Flight code / Nationality / Customer type /
   Agent code / Sub agent code) and S12; required markers for the
   international-flight fields; "Non-international flight" toggle
   (= Allow take-away) clears the flight fields; sub agent disabled until an
   agent is chosen, changing agent clears it; Undo restores the loaded
   customer; `embedded` mode (no page chrome, `onSaved` instead of pop) for
   S8; pushed use gets `DesktopPageFrame`. Existing shared-logic tests move to
   the handheld size (the handheld branch keeps `AutocompleteField`); new
   desktop tests.
5. **S9 `showDesktopTravellerOverlay`** — two panes: passport (MRZ / boarding
   pass inert, manual passport no. / English name / nationality), departure
   flight search with Today / Tomorrow / After 20:00 client filters, collection
   point from the picked flight; Save (Enter) returns the details to the form,
   which applies them through the same path as its own fields.
6. **S8 Customer tab** — search bar (+ New customer, inert Register member),
   form on the left (new or loaded customer; save re-runs the search), profile
   on the right: stats (e-Purse real; points / spend / visits "—"), the existing
   `_CustomerResultCard`, Attach to bill (real guards + picked privilege →
   Sale), recent purchases "not available". Update `home_page_test`.
7. Overview status + deviations, commit.

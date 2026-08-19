# Android/Windows Parity Checklist

Derived from the 43 active workflows and their hardware dependencies documented in `inventory.md` (task 1.1).
This defines what "parity" means per workflow and peripheral for release readiness (task 9.2 regression,
task 8.5 UAT); it does not define vendor-specific Windows test procedures — that is task 1.3, currently
blocked on vendor/procurement information (see `tasks.md`).

A workflow is "parity-complete" only when every applicable row below passes on **both** platforms it applies
to. Windows-only hardware rows (EDC, Windows signature pad, magnetic/smart-card reader) obviously have no
Android equivalent and are checked on Windows alone; Android-only rows (Bluetooth/Woosim or Sunmi printing,
camera/HW barcode scan, RCAgent AOT) are checked on Android alone. Shared workflow logic (cart math,
promotion rules, checkout state transitions) must produce identical results on both platforms.

## General criteria (every active workflow)

- [ ] Functional outcome matches the legacy Android app for the same input (manual side-by-side comparison against `smart-pos-mobile`, or documented intentional deviation).
- [ ] Shared King Power visual system applied (tokens/components from design.md, not ad hoc styling).
- [ ] Payment/device/validation/error states are distinguishable without relying on colour alone.
- [ ] Responsive layout is correct for the platform: Android touch-first compact layout; Windows keyboard/scanner-friendly density with navigation rail and multi-column working areas.
- [ ] Required permissions/hardware readiness are checked before the workflow is entered, with a recoverable error state if unavailable, blocking only the dependent operation (not the whole app).
- [ ] Automated test coverage exists per the test pyramid in design.md (unit for logic, contract for API mapping, widget/golden for UI, integration for the end-to-end path).

## 1. Authentication, settings, session

| Workflow (source page) | Android-specific check | Windows-specific check |
|---|---|---|
| Login (`LoginPage`) | Barcode/MRZ passport scan via camera or HW scanner works | Keyboard-driven login; scanner-friendly input if a HW barcode scanner is attached |
| Settings (`SettingsPage`) | Device UUID binding via Android device ID plugin | Device UUID binding via Windows machine identifier equivalent |
| App menu (`AppMenuPage`) | Touch-first hamburger/side menu | Persistent navigation rail per design.md |
| No-internet fallback (`NoInternetPage`) | Network-loss detection triggers fallback screen | Same, using Windows network-status API |

## 2. Sale, customer, cart

| Workflow (source page) | Android-specific check | Windows-specific check |
|---|---|---|
| Home / MRZ scan (`HomePage`) | Passport/boarding-pass MRZ scan via camera | Scanner-friendly MRZ input (attached HW scanner), no camera dependency assumed |
| Customer search/detail (`CustomerPage`) | Barcode/loyalty-card scan via camera or HW scanner | Barcode input via attached HW scanner or manual entry |
| Customer registration (`CustomerFormPage`) | MRZ scan for new-customer passport capture | Scanner-friendly MRZ input |
| Sale/cart (`SalePage`) | Article barcode scan via camera or HW scanner | Article barcode scan via attached HW scanner or manual entry |
| Edit sale / discount / cashback / special discount / currency / nationality / customer-type/agent/guide pickers | Cart math and rule outcomes match legacy for identical input | Same outcome verified on Windows with keyboard input |

## 3. Checkout, payment, signature, receipt

| Workflow (source page) | Android-specific check | Windows-specific check |
|---|---|---|
| Checkout hub (`CheckoutPage`) | Receipt prints via Bluetooth/Woosim or Sunmi built-in printer per device config | Receipt prints via Epson thermal printer over USB/Serial/COM |
| Checkout hub — AOT | RCAgent AOT e-tax receipt submission succeeds or fails gracefully per store policy (pending task 1.3-adjacent AOT decision) | N/A — AOT integration is Android-only per current findings; confirm no Windows equivalent is required |
| Payment method / payment (`PaymentMethodPage`, `PaymentPage`) | Wallet barcode scan via camera or HW scanner; network payment gateway (2C2P/Alipay/WeChat) reachable | EDC terminal integration over Serial/COM: approve/decline/cancel/timeout all produce the correct unresolved-vs-finalized state (task 1.3 vendor-dependent) |
| Signature (`SignaturePadPage`) | Touchscreen canvas capture | Windows signature-pad device capture (task 1.3 vendor-dependent) — until then, confirm whether Windows also needs a touchscreen/mouse fallback |
| Cash card (`CashCardPage`) | — | Magnetic-card or smart-card reader read matches manual QR-code entry result (task 1.3 vendor-dependent) |
| Payment form / EDC bank list (`PaymentFormPage`) | N/A — Android has no local EDC integration in the legacy app | Bank list + EDC approve/decline/cancel/timeout/transaction-reference handling (task 1.3 vendor-dependent) |
| e-Purse, 2C2P, voucher, payment history, claim check, enquiry-detail refund | Bluetooth/Woosim or Sunmi printer where receipt/claim-check output is required | Epson printer where receipt/claim-check output is required |

## 4. Pickup, flight, registration, enquiry, other operational workflows

| Workflow (source page) | Android-specific check | Windows-specific check |
|---|---|---|
| Pickup (`PickupPage`), picking list, claim check | Print Hub network print path works identically (no local Bluetooth dependency observed in source) | Same — Print Hub is network-based, not platform-hardware-dependent |
| Flight lookup (`FlightPage`) | — | — (no hardware dependency either platform) |
| Registration, shipping address, promoter/DFA and other pickers | — | — (no hardware dependency either platform) |
| Enquiry / enquiry detail / member info / article info | Bluetooth/Woosim or Sunmi printer for reprint actions where applicable | Epson printer for reprint actions where applicable |

## 5. Excluded from parity scope

Per `inventory.md` §4, these legacy page **classes** are dead/orphaned (zero real inbound navigation found
anywhere) and are explicitly **excluded** — no parity check applies: `AboutPage`, `ContactPage`, `TabsPage`,
`PromotionPage`, `InformationPage`, `RegistrationPage`, `ShoppingPage`, `ScanCustomerPage`, `PrinterPage`,
`SettingByQrPage`. `MemberProvider`'s two dead endpoints are likewise excluded — the Member workflow's real
functionality is `SaleEngine.GetCaratInformation`, covered under customer/checkout parity above, not as its
own row.

**Resolved:** `tasks.md` tasks 6.2, 6.3, and 6.4 originally referenced `RegistrationPage`, `ScanCustomerPage`,
`SettingByQrPage`, `InformationPage`, `AboutPage`, and `TabsPage` — all confirmed dead code per this
inventory. Those tasks have been corrected to drop the dead page classes (new-customer registration is still
covered, via `CustomerFormPage` under task 4.3).

## Open dependency

Windows hardware rows above marked "(task 1.3 vendor-dependent)" cannot be checked off until task 1.3 is
unblocked with real vendor models/SDKs/Serial-COM parameters. This checklist can still be used to scope and
sequence work; it should be revisited once 1.3 completes to confirm no rows are missing vendor-specific detail.

## Context

See `proposal.md` for motivation. The source application is Ionic 3/Cordova and combines UI, API calls, storage, and device calls in large pages and providers. The new repository is intentionally empty of application code. The replacement must preserve active operational behaviour while supporting Android and Windows from one Flutter codebase.

## Goals / Non-Goals

**Goals:**

- Establish a feature-first Clean Architecture that isolates business rules, transport, and platform peripherals.
- Reach Android/Windows feature parity for every active migrated workflow.
- Treat hardware state and payment outcomes as explicit, recoverable workflow states.
- Provide a test strategy that verifies business flows without physical devices and defines UAT for real devices.

**Non-Goals:**

- Copy Ionic/Cordova source, legacy build tooling, or unused assets into Flutter.
- Change existing backend business contracts as part of the client migration.
- Claim support for an unverified vendor protocol or hardware model.

## Decisions

### Feature-first Clean Architecture

The application will organize each feature as `presentation`, `domain`, and `data`; shared concerns live under `core`, and device implementations live under `platform`.

```text
lib/
  core/                 config, network, errors, shared UI
  features/
    checkout/
      presentation/     views and state
      domain/           entities, use cases, repository contracts
      data/             API/local implementations and DTOs
    sales/ customers/ promotions/ pickup/ ...
  platform/
    hardware/           common contracts and Android/Windows adapters
```

This prevents platform and API details from entering business rules. A page or state controller invokes a use case; the use case depends on a domain contract; only data and platform implementations know HTTP, Bluetooth, USB, or Serial/COM details. A flat layer-by-application structure was rejected because it would reintroduce the cross-feature coupling present in the source project.

### King Power visual system

The presentation layer will use a central token-based theme rather than per-screen styling. It preserves approved King Power assets and the legacy gold family (including the existing `#9F8957` primary) while using restrained gold accents on neutral surfaces, high-contrast operational text, clear success/warning/error states, and the available King Power typefaces where licensing permits. The visual direction references King Power Online's service-led navigation, membership prominence, and premium retail hierarchy; it does not copy its consumer-commerce layouts into the POS.

Shared components will cover app shell, navigation rail or bottom navigation, page headers, search and scan input, cards, data rows, forms, primary/secondary/destructive actions, status chips, confirmation dialogs, empty/loading/error states, and checkout summary. Android uses touch-first compact layouts; Windows uses keyboard/scan-friendly density, a persistent navigation rail, multi-column working areas, and large touch targets for counter hardware. Colour alone will never communicate a payment or device outcome.

Defining tokens and shared components once prevents visual drift across migrated modules. Translating the Ionic SCSS screen by screen was rejected because it preserves outdated density and spreads brand decisions across the app.

### Hardware ports with platform adapters

The domain exposes hardware contracts for printing, payment, signature capture, magnetic-card reading, and smart-card reading. Android and Windows supply adapter implementations selected at runtime by platform and device configuration. Windows native interop is permitted behind these adapters for USB/Serial/COM; Android Bluetooth/Woosim is likewise isolated. Android printing has two adapters behind the same printer contract — Bluetooth/Woosim and the Sunmi built-in printer SDK — selected by device configuration, matching the source application's dual printer paths.

This approach permits deterministic adapter fakes in automated tests. Direct platform calls from checkout were rejected because they make payment integrity and cross-platform testing unreliable.

### RCAgent AOT e-tax receipt agent as a platform port

The source application integrates a King Power native plugin (`RCAgentPlugin`) at login and checkout to submit e-tax receipts to the Airport of Thailand (AOT) agent, independent of printing or payment. This has no HTTP backend of its own. The Flutter app exposes it as its own platform port (login/status-check, submit-receipt, confirm-receipt, logout operations) with an Android adapter and a fake for tests, following the same pattern as the printer and payment ports.

This keeps AOT submission testable and swappable like the other device integrations, and avoids scattering plugin calls through login/checkout use cases. Treating it as an unstructured side effect inside checkout was rejected because it would hide a required business integration from the domain layer and from tests.

### Explicit checkout state machine

Checkout will model payment and finalization states explicitly: draft, validating, awaiting-device, approved, declined, cancelled, unresolved, finalizing, finalized, and failed. A sale cannot move to finalized from unresolved or failed payment states.

This protects against duplicate or lost transactions when an EDC disconnects after a customer interaction. Treating a timeout as a normal decline was rejected because it cannot establish whether a charge occurred.

### Workflow-led migration inventory

Migration begins with a source inventory that maps each active route to its UI, models, providers, API calls, assets, permissions, and device dependency. The inventory is the allow-list for migration and is reviewed before implementation of each feature.

```text
Inventory → foundation → vertical slices → parity review → device UAT
```

Vertical slices start with login/settings, sale/customer/cart, checkout/payment/signature/receipt, then remaining operational modules. The release is complete only after every active module has passed its Android and Windows parity checklist.

### Test pyramid and hardware simulation

Business rules and use cases are unit-tested; repository/API serialization is tested with contract fixtures; widgets are tested for key user states; end-to-end flows run on Android and Windows. Hardware adapters are tested with fakes covering success, denial, disconnect, cancellation, timeout, and retry. Physical-device UAT validates the actual vendor protocols and drivers.

## Risks / Trade-offs

- [Vendor SDK/protocols for EDC and readers are unavailable or vary by model] → Obtain model-specific integration material and run a hardware spike before implementing each Windows adapter.
- [RCAgent AOT plugin or protocol documentation is unavailable, or the integration is no longer required at all stores] → Confirm current business requirement and obtain the plugin's integration material before implementing the Android adapter; treat it as excludable per store/device configuration if confirmed optional.
- [Legacy API contracts differ by environment or are undocumented] → Capture request/response fixtures from approved environments and add contract tests before migrating dependent flows.
- [Feature parity expands delivery time] → Track parity per workflow and platform; do not release a feature as complete until both checklists pass.
- [Payment timeout can result in an unknown charge state] → Mark it unresolved, block finalization, preserve the transaction, and require terminal verification.
- [Large legacy screens hide unrelated workflows] → Split them into use cases and vertical slices based on the source inventory rather than translating page structure.

## Migration Plan

1. Create the source inventory and mark active files, assets, APIs, and devices.
2. Bootstrap Flutter Android/Windows targets, environments, navigation, persistence, error handling, and test harnesses.
3. Implement the visual tokens, shared components, and Android/Windows responsive shell before migrating feature pages.
4. Implement common hardware contracts and fake adapters; validate Android Woosim and the first Windows USB/Serial/COM adapter with real hardware.
5. Migrate vertical slices in workflow order, adding unit, contract, widget, visual-regression, and integration tests before parity review.
6. Run full Android/Windows regression and physical-device UAT; compare outcomes against the legacy application.
7. Roll out by store/device cohort. Retain the legacy application until each cohort has a tested rollback path and transaction reconciliation is accepted.

## Test Strategy

| Level | Scope | Required evidence |
| --- | --- | --- |
| Unit | entities, use cases, discount/promotion rules, checkout state transitions | automated Dart tests |
| Data/contract | API mapping, auth, error mapping, configuration | fixture-backed tests for each service |
| Widget | forms, validation, loading/error/retry, navigation | Flutter widget tests |
| Visual regression | shared components, light/dark contrast, Android and Windows breakpoints | reviewed golden tests |
| Integration | login → sale → checkout → payment → signature → receipt | Android and Windows automated runs with fakes |
| Hardware | printer, EDC, signature, magnetic-card, smart-card adapters | fake success/failure/timeout tests plus device UAT record |
| UAT | full store workflow and actual devices | signed Android and Windows parity checklist |

## Open Questions

- Which specific models, SDKs, and Serial/COM parameters apply to the Windows EDC, signature pad, magnetic-card reader, and smart-card reader?
- Are current legacy API request/response contracts the approved integration baseline for the Flutter release, or is a newer backend API required?
- Is the RCAgent AOT e-tax receipt integration still a required business capability for the Flutter release, and is it required at every store/device or only specific ones (e.g. airport locations)?
- Is Sunmi built-in printer support still required, or has the store fleet standardized on Bluetooth/Woosim printers only?

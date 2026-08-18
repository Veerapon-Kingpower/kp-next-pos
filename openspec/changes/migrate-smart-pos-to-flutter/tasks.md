## 1. Discovery and migration inventory

- [ ] 1.1 Create an active-workflow inventory that maps every legacy route to its referenced page, models, providers, APIs, assets, permissions, and hardware dependency.
- [ ] 1.2 Record the approved Flutter API environment matrix and capture request/response fixtures for Sale Engine, Register, Flight, Print Hub, Member, and Cash Card services.
- [ ] 1.3 Obtain and document Windows vendor models, SDKs, drivers, Serial/COM parameters, and test procedures for EDC, signature pad, magnetic-card reader, and smart-card reader.
- [ ] 1.4 Define Android and Windows parity checklists for each active workflow and connected peripheral.

## 2. Flutter foundation

- [ ] 2.1 Create the Flutter project with Android and Windows targets, development/UAT/production configuration, linting, formatting, and test commands.
- [ ] 2.2 Establish the feature-first Clean Architecture directory structure with core configuration, network, error, logging, and dependency-injection boundaries.
- [ ] 2.3 Implement environment configuration, secure session persistence, device settings persistence, and startup validation with unit tests.
- [ ] 2.4 Implement application shell, routing, authentication guard, retryable error presentation, and offline/device-unavailable states with widget tests.

## 3. King Power visual system

- [ ] 3.1 Package approved King Power fonts and active image assets selected by the migration inventory.
- [ ] 3.2 Define accessible colour, typography, spacing, elevation, sizing, and transaction-status tokens based on the approved King Power visual direction.
- [ ] 3.3 Build shared app shell, navigation, header, search/scan input, buttons, cards, forms, dialogs, status chips, and loading/empty/error components.
- [ ] 3.4 Implement responsive Android touch-first and Windows keyboard/scanner-first layouts with golden tests for the shared component states.

## 4. Core sale and customer workflows

- [ ] 4.1 Implement authentication, store/user context, settings access, and logout using the approved service contracts.
- [ ] 4.2 Implement product/article lookup, barcode scan input, serial/record validation, and cart state with domain and widget tests.
- [ ] 4.3 Implement customer search, selection, creation, profile, nationality, contact, shipping-address, agent, and guide workflows with API contract tests.
- [ ] 4.4 Implement sale creation, edit-sale, shopping cart, totals, currency selection, and change calculation with unit and integration tests.

## 5. Checkout and payment workflows

- [ ] 5.1 Implement payment-method selection, payment history, cash/card/e-purse flows, and bank selection using explicit checkout states.
- [ ] 5.2 Implement promotion, discount, cashback, special-discount, voucher, and payment-form rules with domain tests for success and rejection paths.
- [ ] 5.3 Implement signature capture, validation, storage, and required-signature checkout handling with widget and integration tests.
- [ ] 5.4 Implement checkout finalization, transaction reference handling, receipt initiation, cancellation, retry, and unresolved-payment recovery with integration tests.

## 6. Remaining operational workflows

- [ ] 6.1 Implement pickup, picking-list creation, pickup print, claim check, and amount-remaining workflows with contract tests.
- [ ] 6.2 Implement flight, registration, customer scanning, and setting-by-QR workflows with Android/Windows parity tests.
- [ ] 6.3 Implement enquiry, enquiry detail, member information, article information, information, and about workflows using active source inventory requirements.
- [ ] 6.4 Implement app menu, tabs, workflow navigation, no-internet recovery, and modal/picker patterns using shared visual components.

## 7. Hardware integration

- [ ] 7.1 Define printer, payment terminal, signature, magnetic-card, and smart-card domain contracts plus fake adapters for automated tests.
- [ ] 7.2 Implement Android Bluetooth discovery, pairing, connection health, and Woosim receipt printing with adapter tests.
- [ ] 7.3 Implement Windows USB/Serial/COM discovery, configuration, connection health, and Epson thermal receipt printing with adapter tests.
- [ ] 7.4 Implement the approved Windows Serial/COM EDC protocol including approve, decline, cancel, timeout, transaction reference, and unresolved-result handling.
- [ ] 7.5 Implement Windows signature, magnetic-card, and smart-card adapters from the approved vendor SDKs and validate each device using its test procedure.
- [ ] 7.6 Add hardware diagnostics screens and ensure dependent workflows block only the unavailable device operation.

## 8. Automated verification

- [ ] 8.1 Add unit tests for all use cases, discount/promotion calculations, checkout transitions, and recoverable error behaviour.
- [ ] 8.2 Add fixture-backed API contract tests for every migrated service operation and mapped error response.
- [ ] 8.3 Add widget and golden tests for shared components, forms, payment/device states, and responsive Android/Windows layouts.
- [ ] 8.4 Add Android and Windows integration tests for login, sale, checkout, payment, signature, and receipt flows using fake hardware adapters.
- [ ] 8.5 Execute physical-device UAT for Woosim, Epson, EDC, signature pad, magnetic-card reader, and smart-card reader; record platform parity results.

## 9. Release readiness

- [ ] 9.1 Run migration inventory reconciliation to verify every active legacy module, asset, API, and hardware dependency has a mapped Flutter outcome or documented exclusion.
- [ ] 9.2 Run full Android and Windows regression suites, accessibility review, and offline/error-recovery checks.
- [ ] 9.3 Produce signed Android and Windows builds, deployment configuration, rollback instructions, and transaction-reconciliation runbook for UAT rollout.

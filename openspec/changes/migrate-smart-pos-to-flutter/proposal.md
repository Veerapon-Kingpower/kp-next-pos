## Why

The current POS is an end-of-life Ionic 3/Cordova Android application with platform-specific integrations and tightly coupled feature code. A Flutter replacement is needed to preserve the active POS workflows while introducing an equally capable Windows application and a maintainable architecture for future device and API changes.

## What Changes

- Create a new Flutter POS foundation that targets Android and Windows with feature parity for all active source modules.
- Reimplement active sales, customer, checkout, payment, promotion, voucher, pickup, flight, registration, enquiry, and settings workflows from the Ionic application; unused source files and assets are excluded.
- Adopt feature-first Clean Architecture with presentation, domain, and data layers, shared core services, environment-based configuration, and secure local storage.
- Introduce a modern King Power-aligned visual system that preserves approved brand assets while defining accessible colour, typography, spacing, responsive Android/Windows layouts, and explicit transaction states.
- Add platform hardware adapters: Android Bluetooth/Woosim and Sunmi built-in receipt printing, Windows USB/Serial/COM support for Epson printing, EDC payment, signature pads, magnetic-card readers, and smart-card readers, and the RCAgent AOT (Airport of Thailand) e-tax receipt agent integration used at login and checkout.
- Establish automated test coverage and device UAT criteria for business flows and both platform implementations.

## Capabilities

### New Capabilities

- `flutter-pos-foundation`: Bootstraps the cross-platform Flutter application, configuration, authentication/session handling, navigation, local persistence, and common error behaviour.
- `pos-sales-workflows`: Delivers the active POS operational workflows, including sales, customer, checkout, payment, signature, receipt, promotion, voucher, pickup, flight, registration, enquiry, and settings.
- `cross-platform-hardware`: Provides a platform-independent hardware contract and Android/Windows implementations for required POS devices, including Windows Serial/COM EDC payment.

### Modified Capabilities

- None.

## Impact

- Affected systems: new `kp-pos` Flutter project, the existing `smart-pos-mobile` application used as behavioural reference, and its Sale Engine, Register, Flight, Print Hub, Member, and Cash Card integrations, plus two device-native integrations with no HTTP backend: the Sunmi built-in printer SDK and the RCAgent AOT e-tax receipt agent plugin.
- New dependencies: Flutter/Dart packages, Windows platform-channel or FFI support for hardware, Android Bluetooth/Woosim integration, API client and secure storage packages, and test tooling.
- Operational dependency: verified vendor protocols or SDKs and physical devices are required for Windows EDC, reader, signature-pad, and printer UAT.

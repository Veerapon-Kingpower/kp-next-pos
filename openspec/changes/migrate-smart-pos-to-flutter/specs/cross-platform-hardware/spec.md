## Purpose

Enable the required POS peripherals through a consistent application workflow
while using the appropriate Android and Windows transport for each device.

## ADDED Requirements

### Requirement: Hardware readiness and diagnostics
The system SHALL allow an authorized user to configure, test, and view the readiness of each required peripheral before using a dependent POS workflow.

#### Scenario: Device is unavailable
- **WHEN** a required peripheral is disconnected or cannot be opened
- **THEN** the system identifies the device and connection issue and prevents only the dependent operation

### Requirement: Platform-specific device connectivity
The system SHALL support Android printing via Bluetooth Woosim or Sunmi built-in printers, selected by device configuration, and Windows USB or Serial/COM connectivity for supported POS devices, including Epson thermal printing, EDC payment, signature pad, magnetic-card reader, and smart-card reader.

#### Scenario: Platform printer prints a receipt
- **WHEN** a receipt is requested with a configured and ready printer
- **THEN** the system sends the receipt to the platform-appropriate printer connection and reports the result

### Requirement: AOT e-tax receipt agent integration
The system SHALL integrate with the configured RCAgent AOT (Airport of Thailand) e-tax receipt agent on Android devices where it is enabled, submitting receipt data at login and checkout finalization, and SHALL surface agent unavailability through the hardware readiness state rather than failing silently.

#### Scenario: AOT agent is unavailable during checkout
- **WHEN** the AOT e-tax receipt agent is enabled for the device but unreachable during checkout
- **THEN** the system reports the integration failure through the hardware readiness state and follows the store's configured policy for blocking or allowing checkout completion

### Requirement: Windows EDC payment safety
The system SHALL communicate with a configured Windows Serial/COM EDC terminal, wait for a definitive approved, declined, cancelled, or timeout result, and SHALL return a transaction reference when supplied by the terminal.

#### Scenario: EDC times out
- **WHEN** an EDC terminal does not return a definitive result before its configured timeout
- **THEN** the system marks the payment as unresolved, does not finalize the sale, and instructs the user to verify the terminal before retrying

## Purpose

Preserve the active operational POS workflows from the existing application in
a testable Flutter experience for store users on both supported platforms.

## ADDED Requirements

### Requirement: Active workflow migration
The system SHALL provide all active legacy workflows: authentication, sale, customer, cart, checkout, payment, signature, receipt, promotion, voucher, pickup, flight, registration, enquiry, and settings. Workflows and assets not referenced by an active flow SHALL be excluded from the migration.

#### Scenario: User completes an active operational workflow
- **WHEN** a user starts an active workflow from the POS navigation
- **THEN** the system completes the workflow using the compatible service contract and shows its resulting state

### Requirement: Modern operational visual consistency
The system SHALL present active workflows through a shared King Power-aligned visual system with accessible text contrast, consistent typography, spacing, actions, transaction states, and responsive layouts for Android and Windows. Payment, device, validation, and error states SHALL include text or icon treatment in addition to colour.

#### Scenario: Checkout state is displayed
- **WHEN** checkout presents a payment, device, validation, or error state
- **THEN** the state is identifiable without relying on colour alone and uses the shared visual components

#### Scenario: Workflow is displayed on Windows
- **WHEN** an active workflow is opened in the Windows application
- **THEN** it uses the shared visual system with a keyboard and scanner-friendly responsive layout

### Requirement: Checkout completion integrity
The system SHALL finalize a sale only after required payment, signature, and validation steps report success, and SHALL retain an unfinalized transaction when any required step fails or is cancelled.

#### Scenario: Required payment does not complete
- **WHEN** a required payment is cancelled, times out, or fails
- **THEN** the system does not finalize the sale and returns the user to a recoverable checkout state

### Requirement: Receipt and transaction evidence
The system SHALL make the finalized transaction reference and required receipt output available after a successful checkout.

#### Scenario: Checkout is finalized
- **WHEN** all required checkout steps complete successfully
- **THEN** the system records the transaction result and initiates the configured receipt workflow

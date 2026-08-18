## Purpose

Provide the cross-platform application foundation required for a secure,
configurable, and behaviourally consistent Flutter POS on Android and Windows.

## ADDED Requirements

### Requirement: Android and Windows application parity
The system SHALL make every active POS capability available on both Android and Windows. A platform limitation SHALL be reported as an actionable device or configuration error and SHALL NOT silently remove the workflow.

#### Scenario: Active feature is opened on either platform
- **WHEN** an authenticated user selects an active POS feature on Android or Windows
- **THEN** the system presents the same business workflow and outcome for that feature

### Requirement: Managed configuration and session
The system SHALL obtain service endpoints from an environment-specific configuration and SHALL persist session and device settings without embedding credentials or environment URLs in application source code.

#### Scenario: Endpoint configuration is unavailable
- **WHEN** a required service endpoint has not been configured
- **THEN** the system prevents the dependent operation and identifies the setting that must be completed

### Requirement: Consistent recoverable errors
The system SHALL display recoverable network, authorization, and device failures with a user-visible action to retry, reconfigure, or cancel without losing a completed sale state.

#### Scenario: Network request fails during a non-final operation
- **WHEN** a service request fails before a sale is finalized
- **THEN** the system keeps the existing transaction data and offers retry or cancellation

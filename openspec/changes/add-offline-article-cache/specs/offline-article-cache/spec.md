## Purpose

Lets the Sale workflow's article/barcode lookup keep returning last-known results when the backend is unreachable, so a cashier can continue scanning and pricing already-seen items through a network or server outage instead of hitting a hard failure on every scan.

## ADDED Requirements

### Requirement: Article lookup falls back to a local cache when the network is unreachable
The system SHALL attempt an article/barcode lookup over the network first. WHEN the network request fails for a connectivity or timeout reason (not a legitimate "article not found" business response), the system SHALL fall back to a local, on-device cache of previously looked-up articles keyed by barcode, and return the cached article if one is present for that barcode.

#### Scenario: Network lookup succeeds
- **WHEN** a cashier scans a barcode and the backend is reachable
- **THEN** the system returns the network result and does not use the local cache to answer the lookup

#### Scenario: Network is unreachable and the article was looked up before
- **WHEN** a cashier scans a barcode while the network is unreachable, and that barcode was successfully looked up over the network at some earlier point this device has been used
- **THEN** the system returns the previously cached article instead of failing the lookup

#### Scenario: Network is unreachable and the article has never been looked up on this device
- **WHEN** a cashier scans a barcode while the network is unreachable, and no cached article exists for that barcode
- **THEN** the system reports the lookup as failed, the same as it does today when a network error occurs with no cache available

### Requirement: Successful network lookups keep the local cache current
The system SHALL update the local cache with the article data returned by every successful network lookup, so the cache reflects the most recently confirmed price and description for that barcode.

#### Scenario: A previously cached article is looked up again while online
- **WHEN** a cashier scans a barcode that already has a cached entry, and the network lookup for it succeeds
- **THEN** the system replaces the cached entry with the newly returned data

### Requirement: A cache-served result is identifiable as possibly outdated
The system SHALL make it possible to tell, from a lookup result, whether it was served from the local cache rather than confirmed against the network just now, so the cashier is not misled into treating a possibly stale price as current.

#### Scenario: A cashier scans an item while offline
- **WHEN** an article lookup is served from the local cache because the network is unreachable
- **THEN** the result is presented with an indication that it may be outdated, rather than presented identically to a fresh network result

### Requirement: Staff can manually force offline mode when an outage is already known
The system SHALL provide a device setting that, when enabled, makes article lookup skip the network attempt entirely and read directly from the local cache, for use when staff already know the network or backend is down and do not want to wait out a connection attempt on every scan. The system SHALL NOT attempt a network request for article lookup while this setting is enabled.

#### Scenario: Offline mode is enabled and the article is cached
- **WHEN** a cashier scans a barcode while the device's offline-mode setting is enabled, and that barcode has a cached entry
- **THEN** the system returns the cached article without attempting a network request

#### Scenario: Offline mode is enabled and the article is not cached
- **WHEN** a cashier scans a barcode while the device's offline-mode setting is enabled, and no cached entry exists for that barcode
- **THEN** the system reports the lookup as failed without attempting a network request

#### Scenario: Offline mode is disabled
- **WHEN** the device's offline-mode setting is disabled (the default)
- **THEN** article lookup behaves as described in the requirements above — network first, cache fallback only on a connectivity/timeout failure

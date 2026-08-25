## Context

See `proposal.md` for motivation. This is the first of several planned sub-projects toward letting a cashier keep operating through a backend outage; the others (offline cart, offline cash checkout, and — separately and later — offline card/QR payment, which is blocked on Windows EDC vendor selection, the same blocker as `migrate-smart-pos-to-flutter`'s task 1.3) are deliberately not designed here. `migrate-smart-pos-to-flutter` already delivered article lookup as a live, network-only call (`SaleRepositoryImpl.lookupArticleByBarcode`, calling `SaleRemoteDataSource.getMasterByBarcode` for `SaleEngine/GetMasterByBarcodeDLL`) and established this project's feature-first Clean Architecture (`presentation`/`domain`/`data` per feature) and its `ApiClient`-style abstraction-with-a-fake testing pattern; this change follows both.

## Goals / Non-Goals

**Goals:**

- Article/barcode lookups keep working, from previously-seen data, when the network is unreachable.
- The cache never becomes a competing source of truth: the network is authoritative whenever reachable, and the cache is only ever written from a successful network response.
- A cache-served result is distinguishable from a fresh one so the UI can flag it as possibly outdated.

**Non-Goals:**

- Any offline write path (cart mutation, checkout, payment) — this is read-only caching of one existing lookup.
- Any staleness expiry that blocks a cache hit. Stale-but-present beats a hard failure, per the business goal of "keep selling."
- Solving the Sale Engine's session-based write model. Nothing here touches `AddItemToOrder`/`ActionItemToOrder`/checkout.

## Decisions

### Realm as the local store, isolated behind an interface

`ArticleLocalDataSource` is defined as an abstract interface in `lib/features/sale/data/local/`, with a Realm-backed implementation. `SaleRepositoryImpl` depends only on the interface. This mirrors `ApiClient`'s existing role in this codebase (an abstraction real code and fakes both implement) so most tests exercise the fallback logic in `SaleRepositoryImpl` against a fake, and only a small, focused set of tests exercise the real Realm schema (using Realm's in-memory realm feature, which needs no device/file setup).

Realm was chosen over `sqflite`/`drift` because the user specified it, and because it is confirmed to support this project's two build targets (Windows desktop and Android — see proposal.md's Impact section) with no cross-platform gap. Its schema (typed Realm objects with a primary key) is a reasonable, low-ceremony fit for a single cached-record type; a relational schema/migration tool would be more machinery than this one-table cache needs. Realm's own cloud sync feature (Atlas Device Sync, deprecated by MongoDB in Sept 2024) is not used and is irrelevant to this design — this is a purely local, offline-first read cache against this app's own backend, not a synced Realm.

### Cache key is the barcode, not the article code

`GetMasterByBarcodeDLL` is looked up by the scanned barcode, and that is what a cashier has in hand when they need a cache hit — not the backend's internal article code, which the cashier never sees before a lookup succeeds at least once. The Realm schema's primary key is therefore `barcode`.

### Fallback triggers only on network-level failure, never on a business "not found"

`SaleRemoteDataSource.getMasterByBarcode` already distinguishes a network/timeout failure (`NetworkFailure`/`TimeoutFailure`, mapped via `mapExceptionToFailure` in `lib/core/network/api_client.dart`) from a legitimate "article not found" response from a reachable server (an `ApiException` from `ReturnObject.unwrap()` when `isCompleted` is false). Only the former falls back to the cache; the latter must keep failing exactly as it does today; a real, reachable server saying "no such article" is not a connectivity problem and the cache must not paper over it.

### Manual override: a Settings switch to force offline mode

Automatic fallback only engages once a network call actually fails, which means every lookup during a known outage still pays for a full connection attempt/timeout before falling back. Staff who already know the network or backend is down don't need that per-scan cost. `DeviceSettings.forceOfflineMode` (persisted the same way as `isAirportMpos`) lets them turn it off directly: `SaleRepositoryImpl.lookupArticleByBarcode` checks it first and, when set, reads the cache and returns — or fails — without ever calling `SaleRemoteDataSource`. It is a switch on *whether the network is tried*, not a second data source; it doesn't change what's cached or how caching works otherwise, so it composes with everything above rather than replacing any of it. Off is the default, matching every other device setting in this app.

### Staleness is surfaced, not enforced

No TTL blocks a cache read. `CachedArticle.cachedAt` is carried through to the caller (the domain `Article` result gains a way to know whether — and if so, since when — it came from cache) so the presentation layer can show something like "Price may be outdated — cached [date]" per proposal.md, rather than silently presenting a possibly-stale price as current. This is a deliberate business trade-off already confirmed with the user: keeping the sale moving matters more here than guaranteeing price accuracy while offline.

## Risks / Trade-offs

- [A cashier scans an item during an outage that has never been looked up on this device] → The lookup still fails, identically to today's network-error behavior; there is no way around this without a pre-seeded full catalog, which is out of scope here. Acceptable for a first step; worth reassessing once real outage patterns are observed.
- [Realm requires CMake 3.21+ for the Windows desktop build, not yet explicitly confirmed on build machines beyond Visual Studio 2022 being installed] → Verify as an early task before other implementation work depends on it; if unmet, this blocks the whole change until resolved.
- [Cached prices go stale and a cashier sells at a wrong price during an outage] → Mitigated by the visible "may be outdated" indicator (a UI/process control, not a technical one) rather than a technical staleness cutoff, per the confirmed goal of not blocking sales.

## Open Questions

- None. The two questions that would have belonged here — offline payment method coverage and how a synced sale later reconciles to a real tax invoice — were resolved with the user as scope decisions (deferred to a future sub-project, not unknowns within this one) and are recorded as non-goals above and in `proposal.md`, not as open questions here.

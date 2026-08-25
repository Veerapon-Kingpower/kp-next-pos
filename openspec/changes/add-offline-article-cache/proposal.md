## Why

Store connectivity to the Sale Engine backend is not guaranteed, and the business need is for the cashier to keep operating through an outage rather than stall at the register. The first, safest step toward that is read access: a cashier who has already scanned an article this shift should still see its price and description if the network drops mid-shift, instead of a hard failure on every subsequent scan of that item. This change delivers that narrow slice — a local cache for article/barcode lookups — as the foundation the later offline-cart and offline-checkout work (explicitly out of scope here) will build on.

## What Changes

- Add a local, on-device cache (via the `realm` package) for article/barcode lookup results (`SaleEngine/GetMasterByBarcodeDLL`), keyed by the scanned barcode.
- `SaleRepositoryImpl.lookupArticleByBarcode` tries the network first, as it does today; on a network-level failure (not a legitimate "not found" business response) it falls back to the local cache. A successful network lookup updates the cache.
- Surface a "may be outdated" indicator when a lookup result is served from cache rather than the network, so the cashier can make an informed call rather than trust a stale price silently.
- No change to `SaleRepository`'s public interface, to the checkout state machine, or to any payment/checkout behavior.

## Capabilities

### New Capabilities

- `offline-article-cache`: Provides a local, read-through cache for article/barcode lookups so the Sale workflow's scan-to-price step can degrade gracefully (serve last-known data, clearly marked as possibly stale) when the backend is unreachable, instead of failing outright.

### Modified Capabilities

- None. This does not change `pos-sales-workflows`' existing requirements — article lookup itself already exists as part of that capability's `sale` feature; this change only adds a fallback data path underneath it, not new externally-observable checkout/sale behavior beyond the cache-staleness indicator described above.

## Impact

- Affected code: `lib/features/sale/data/repositories/sale_repository_impl.dart` (adds the fallback branch), new files under `lib/features/sale/data/local/` (Realm schema + local data source), `pubspec.yaml` (new `realm` dependency).
- New dependency: `realm` (Dart/Flutter package) — confirmed to support this project's two targets, Windows desktop and Android; requires CMake 3.21+ for the Windows desktop build, which needs to be confirmed on build machines (not yet explicitly verified beyond Visual Studio 2022 being installed).
- Out of scope, explicitly: offline cart mutation, offline checkout/payment of any kind (including cash), offline card/QR payment (blocked on Windows EDC vendor selection — same blocker as the `migrate-smart-pos-to-flutter` change's task 1.3), and any change to the existing checkout state machine or its "Checkout completion integrity" requirement. These are later, separate sub-projects in the broader offline-sales roadmap and are not designed or implemented here.

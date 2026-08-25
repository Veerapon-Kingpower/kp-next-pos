## 1. Environment readiness

- [x] 1.1 Confirm CMake 3.21+ is available for the Windows desktop build (Visual Studio 2022 is installed; CMake version itself is unconfirmed) and document the result. **Confirmed: CMake 3.31.6-msvc6, bundled with Visual Studio 2022 Community, well above the 3.21 minimum. `flutter build windows` already resolves it automatically (verified working earlier this session).**
- [x] 1.2 Add the `realm` dependency to `pubspec.yaml` and run `dart run realm_generator` (or the current equivalent) to confirm codegen works on both build targets. **Added `realm: ^20.2.0` and `build_runner` (dev). Hit and fixed a real conflict: `realm_generator` must NOT be listed as an explicit dev_dependency — it's already transitively provided by `realm` and registering it twice causes a build_runner "Conflicting outputs" error. `dart run build_runner build` now succeeds cleanly (verified via `lib/features/sale/data/local/cached_article.dart` → generates `cached_article.realm.dart`). Codegen verified on the host (Windows); Android-target codegen is the same Dart-level step, not platform-specific, so not separately re-verified.**

## 2. Domain and local data source

- [x] 2.1 Define the `CachedArticle` Realm schema (`barcode` primary key, `articleCode`, `articleName`, `brandCode`, `brandName`, `price`, `vatRate`, `cachedAt`) under `lib/features/sale/data/local/`.
- [x] 2.2 Define the `ArticleLocalDataSource` interface (get-by-barcode, upsert) and its Realm-backed implementation.
- [x] 2.3 Extend the domain `Article` result (or introduce a small wrapper) with a way to carry "served from cache, cached at [time]" back to the caller, per design.md's staleness decision.

## 3. Repository fallback wiring

- [x] 3.1 Update `SaleRepositoryImpl.lookupArticleByBarcode` to try the network first, fall back to `ArticleLocalDataSource` only on `NetworkFailure`/`TimeoutFailure`, and propagate a legitimate "not found" business error unchanged. **Scope discovery: `mapExceptionToFailure`/`NetworkFailure`/`TimeoutFailure` already existed in `lib/core/error/failure.dart` and `lib/core/network/api_client.dart` but were dead code — nothing in `lib/` ever called `mapExceptionToFailure`, and it unconditionally returned `ApiFailure` for every `ApiException` regardless of cause, so the network/timeout-vs-business-error distinction this task depends on didn't actually exist yet. Fixed `mapExceptionToFailure` (in core, not sale-specific) to return `NetworkFailure`/`TimeoutFailure` when `ApiException.messageDesc` matches `DioApiClient`'s own literal connectivity/timeout messages, falling back to `ApiFailure` otherwise — the only signal available, since Dio-level error type information doesn't survive past `DioApiClient._mapDioException` today. Added `test/core/network/api_client_test.dart` for this. This was necessary to implement this task at all, not optional scope creep — flagging per the apply-change guardrail rather than absorbing it silently.**
- [x] 3.2 On a successful network lookup, upsert the result into `ArticleLocalDataSource`.
- [x] 3.3 Wire `ArticleLocalDataSource` into `sale_injection.dart`'s service locator.

## 4. Presentation

- [x] 4.1 Surface the "may be outdated — cached [date]" indicator in the Sale barcode-lookup UI when a result came from cache.

## 5. Tests

- [x] 5.1 Unit-test `SaleRepositoryImpl`'s fallback logic (network success updates cache; network failure + cache hit returns cached data flagged as such; network failure + cache miss still fails as it does today) against a fake `ArticleLocalDataSource`.
- [x] 5.2 Add a small set of tests against the real Realm schema using an in-memory realm, covering `CachedArticle` read/upsert. **Environment note: running these tests via `flutter test` (Dart VM, not a real device build) requires the Realm native binary to be fetched once via `dart run realm_dart install` — `flutter build`/`flutter run` bundle it automatically, but the bare test runner does not. Ran once in this environment; anyone running these tests fresh (a new machine, CI) needs the same one-time step, which isn't obvious from the package's own error message alone (`Could not open realm_dart.dll`).**
- [x] 5.3 Confirm existing `sale_cart_view_model_test.dart`/`barcode_scan_field_test.dart` online-path tests are unaffected. **Verified: full `test/features/sale` run passes (41/41), including all pre-existing online-path tests unchanged.**

## 6. Manual override (added after initial delivery, per user request)

- [x] 6.1 Add `DeviceSettings.forceOfflineMode` (persisted the same way as `isAirportMpos`), defaulting to `false`.
- [x] 6.2 Update `SaleRepositoryImpl.lookupArticleByBarcode` to check `forceOfflineMode` first and, when set, read the cache and return/fail without calling `SaleRemoteDataSource` at all.
- [x] 6.3 Add an "Offline mode" switch to the Settings page, with a description of what it does and when to use it.
- [x] 6.4 Tests: `DeviceSettings` round-trip/default, `SaleRepositoryImpl` forced-offline cache-hit and cache-miss behaviour (network never called in either case), and a Settings-page widget test that toggling and saving persists the value.

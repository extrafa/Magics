# StoreKit error handling — plan

Task spec: see conversation (2026-08-24). Bug: StoreManager swallows all
StoreKit errors (empty `catch {}` in purchase/restore/loadProducts), paywall
CTA gives zero feedback on failure, `.pending`, or offline product load.

## Chunk 1 — StoreManager: state + real error handling

File: `MagicTricks/Sources/Services/Store/StoreManager.swift`

- Add `enum PurchasePhase: Equatable { case idle, purchasing, restoring }`
  and `@Published private(set) var phase: PurchasePhase = .idle`.
- Add `@Published var alertMessage: String?` — single channel for all
  user-facing text (purchase failure, pending explanation, restore failure,
  restore-with-nothing-to-restore).
- Add `@Published private(set) var productsLoadError: String?`.
- Rewrite `purchase()`:
  - guard products non-empty else set `alertMessage` (safety net) and return.
  - set `phase = .purchasing`, always reset to `.idle` on exit (defer).
  - `.success` → `refreshAccess()`.
  - `.userCancelled` → no-op (expected, not an error).
  - `.pending` → `alertMessage` = pending explanation string.
  - `catch` → `alertMessage` = friendly text (use `error.localizedDescription`
    where StoreKitError provides one, else generic fallback).
- Rewrite `restore()`:
  - `phase = .restoring` around the call, reset in defer.
  - success but `hasProAccess` still false after `refreshAccess()` →
    `alertMessage` = "no purchases found" string.
  - `catch` → `alertMessage` = friendly error text.
- Rewrite `loadProducts()` (called from `start()`):
  - success → `productsLoadError = nil`.
  - `catch` → `productsLoadError` = friendly text.
- Add `func retryLoadProducts() async { await loadProducts() }` (or make
  `loadProducts()` internal so the view can call it directly — decide during
  implementation, keep it minimal).

No UI changes in this chunk — StoreManager only.

## Chunk 2 — Localization strings

File: `MagicTricks/Sources/Resources/Localizable.xcstrings`

Add keys under `onboarding.paywall.*` (reuse `common.ok` for the alert
button, it already exists):
- `onboarding.paywall.error.purchaseFailed`
- `onboarding.paywall.error.restoreFailed`
- `onboarding.paywall.error.pending` (Ask to Buy explanation)
- `onboarding.paywall.error.noPurchasesFound`
- `onboarding.paywall.error.productsLoadFailed`
- `onboarding.paywall.retry`

## Chunk 3 — OBPaywallScreen wiring

File: `MagicTricks/Sources/Modules/Onboarding/View/OBPaywallScreen.swift`

- CTA (`bottomBlock`): disabled + spinner while `store.phase == .purchasing`;
  disabled while products still loading and no `productsLoadError`.
- When `store.productsLoadError != nil`: replace/augment the CTA area with
  the error text + a "Retry" button that calls `store.retryLoadProducts()`.
- Restore link: disabled + spinner while `store.phase == .restoring`.
- Add `.alert(...)` bound to `store.alertMessage` (non-nil → presented),
  single `common.ok` button that clears it — same pattern as
  `ExitHintView.swift`.
- Verify `.onChange(of: store.hasProAccess)` auto-dismiss still fires on the
  success path.

## Out of scope
- Other StoreManager consumers (SettingsScreen, CollectionView,
  GeoMentalismCitiesView) only read `hasProAccess`/`isProOverride`, they
  don't call `purchase()`/`restore()` — untouched.
- No changes to `StoreService.swift` — its contract (`StorePurchaseResult`,
  throwing methods) already gives StoreManager everything it needs.

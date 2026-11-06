# StoreManager: dev-флаги через PreferenceStoring, первые тесты

## Проблема

`isProOverride`/`isWatermarkHidden` читаются и пишутся прямо в
`UserDefaults.standard` внутри `StoreManager`, хотя `StoreServicing` уже
инжектится и `PreferenceStoring` (тот же seam, что использует
`AppPreferences`) уже есть в проекте. Тест, создавший `StoreManager` и
выставивший `isProOverride`, пишет в реальные дефолты хоста — утечка
pro-доступа между тестами и в само приложение на симуляторе, плюс гонка
из-за `parallelizable = "YES"` в схеме.

## Чанки

1. `StoreManager.swift`: добавить `defaults: PreferenceStoring = UserDefaults.standard`
   в `init`, убрать все прямые обращения к `UserDefaults.standard` (5 мест),
   `sandboxGatedFlag` становится статическим методом с параметром `defaults:`.
2. Новый `StoreManagerTests.swift` с фейковыми `StoreServicing` и
   `PreferenceStoring` (in-memory):
   - `restore()` с entitlement productID из списка → `hasProAccess == true`
   - `restore()` с чужим productID → `hasProAccess == false`
   - `purchase()` при `.userCancelled` не даёт доступ
   - `restore()` вызывает `service.sync()` ровно один раз
   - `hasProAccess == _hasStoreAccess || isProOverride` — dev-override
     не потерялся при рефакторинге, и пишется через `defaults`, а не
     в реальный `UserDefaults.standard`
3. Сборка + прогон новых тестов + полного набора.

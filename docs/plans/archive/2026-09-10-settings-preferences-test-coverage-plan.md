# Покрыть hapticIntensity/isExitHintEnabled и вернуть AppPreferencesTests

## Проблема

- `SettingsStoreTests` покрывает 4 свойства из 6 — мимо прошли `hapticIntensity`
  и `isExitHintEnabled`.
- Дефолт интенсивности продублирован в трёх местах: `Default.hapticIntensity`
  (`.heavy`), магическая `2.0` в `AppPreferences.resetHapticSettings()`, и
  хардкод `.heavy` в `SettingsStore.resetHapticSettings()`. Смена дефолта на
  `.medium` рассинхронит UI и вибрацию, ни один тест не упадёт.
- `AppPreferencesTests.swift` отсутствует (была среди битых ссылок). Не
  покрыты ветки «значения в сторе нет → Default» и клампинг диапазонов.

## Чанки

1. Убрать дубли дефолта интенсивности: добавить `HapticIntensity.storageValue: Double`
   (+ `init(storageValue:)`), использовать в сеттере/геттере `AppPreferences.hapticIntensity`,
   в `resetHapticSettings()` заменить `2.0` на `Default.hapticIntensity.storageValue`,
   в `SettingsStore.resetHapticSettings()` заменить `.heavy` на
   `AppPreferences.Default.hapticIntensity`.
2. `SettingsStoreTests`: добавить `hapticIntensity` и `isExitHintEnabled` в
   `test_init`, `test_assigningValues`, `test_resetMethods` (последний —
   сверка с `AppPreferences.Default.*`, ловит рассинхрон дефолтов).
3. Новый `AppPreferencesTests.swift` с `MockPreferenceStore`: пустой стор →
   каждое свойство отдаёт свой `Default` (`hapticSpeedMultiplier` 1.5,
   `usesStandardMagicGallerySet` true, `hapticIntensity` .heavy,
   `screenDownHoldDuration` 0.30, `isExitHintEnabled` true,
   `magicGalleryGestureMode` .tap); клампинг: запись 5.0 → 2.5, 0.0 → 1.0
   для скорости, 5.0 → 1.5 / 0.0 → 0.10 для hold-duration; round-trip
   `hapticIntensity = .medium` → читается `.medium`.
4. Сборка + прогон новых и всех тестов.

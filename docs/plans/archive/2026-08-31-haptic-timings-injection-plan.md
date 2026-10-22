# Тайминговая математика прибита к AppPreferences.shared — план

Task spec: найдено ревью uamoder. `HapticPreferences` (enum со static-свойствами)
и `TimeControlHapticPattern` читают `AppPreferences.shared` напрямую, без единой
точки внедрения. `HapticEnginePlaying`/`HapticScheduling` уже дают подменить
движок и планировщик в тестах, но саму ТАЙМИНГОВУЮ МАТЕМАТИКУ подменить нельзя —
поэтому баг «`digitGap` не реагирует на скорость» (уже чинили в отдельном PR)
физически было негде поймать тестом.

## Разбор по файлам — что от чего зависит сейчас

Прочитал весь модуль `Shared/Haptics` + `AppPreferences.swift`. Реально
зависят от `AppPreferences.shared` (варьируются в рантайме):
`speedMultiplier`, `isGroupByThreeEnabled`, `intensity`, и всё, что из
`speedMultiplier` считается (`pulseGap`, `digitGap`, `shortDuration`,
`longDuration`, `groupedPulseGap`, `groupedRemainderPulseGap`, `groupedGroupGap`,
`groupedDigitGap`).

НЕ зависят от преференсов, хоть и лежат в `HapticPreferences`/
`TimeControlHapticPattern` — чистые константы: `sectionGap`, `completionPadding`,
`groupedChunkSize`. Их трогать не нужно, ссылка на них через
`HapticPreferences.xxx` не создаёт проблемы, но раз всё остальное переезжает —
удобнее унести и их прямыми ссылками на `HapticTiming.xxx`, чтобы
`HapticPreferences` не оставался наполовину живым.

## Архитектурное решение

Ревью предлагает `struct HapticTimings` с `init(preferences: HapticPreferenceManaging)`.
Беру это, но с двумя уточнениями сверх дословного примера:

1. **`TimeControlHapticPattern` удаляю целиком.** После переезда его
   свойств в `HapticTimings` он стал бы точной копией той же тонкой
   обёртки над `HapticPreferences`, которую и чиним — оставлять его
   значит оставить второй параллельный путь к тем же данным.

2. **`HapticScheduler` не меняет форму протокола.** У него 3 внутренних
   чтения `HapticPreferences` (`completionPadding` — на самом деле чистая
   константа, `intensity.impactIntensity` дважды). Вместо того чтобы
   добавлять параметр `timings:` в методы `HapticScheduling` (сломает
   `MockHapticScheduler` в существующих тестах без всякой пользы —
   тесты этот путь не проверяют), даю `HapticScheduler` свой
   `preferences: HapticPreferenceManaging` в `init` (дефолт `.shared`,
   как у `enginePlayer`/`scheduler` в `HapticManager` уже сегодня) и
   строю `HapticTimings` внутри, где нужно. Протокол не трогается,
   мок не трогается.

3. **`TimeHapticPatternBuilder` остаётся статическим, но берёт
   `timings:` параметром**, а не становится инстансом. Ревью его и
   называет «билдер» — билдеру идёт готовая структура на вход, это
   и есть чистая, легко тестируемая функция без скрытого состояния.

## Чанк 1 — AppPreferences.swift

`HapticPreferenceManaging` получает `var hapticIntensity: HapticIntensity { get set }` —
единственное свойство, которое реально читают тайминги, но протокол
его пока не объявлял.

## Чанк 2 — HapticModels.swift

- Новый `struct HapticTimings`: `pulseGap`, `digitGap`, `shortDuration`,
  `longDuration`, `groupedPulseGap`, `groupedRemainderPulseGap`,
  `groupedGroupGap`, `groupedDigitGap`, `intensity`, `isGroupByThreeEnabled` —
  все как `let`, посчитаны в `init(preferences: HapticPreferenceManaging)`.
  Плюс `zeroDuration` (алиас `longDuration`, для читаемости на месте
  использования) и `func digitDuration(_ digit: Int) -> TimeInterval`
  (переезжает из `TimeControlHapticPattern` как есть).
- Из `HapticPreferences` убираю всё, что переехало в `HapticTimings`
  (`speedMultiplier`, `isGroupByThreeEnabled`, `intensity`, `pulseGap`,
  `digitGap`, `shortDuration`, `longDuration`, `groupedPulseGap`,
  `groupedRemainderPulseGap`, `groupedGroupGap`, `groupTiming`,
  `groupedDigitGap`, `scaled`, `scaledWithFloor`). Остаются только чистые
  константы (`speedKey`, `groupByThreeKey`, `defaultSpeedMultiplier`,
  `defaultGroupByThree`, `groupedChunkSize`, `speedRange`) и `reset()`.
- `TimeControlHapticPattern` удаляется целиком.

## Чанк 3 — HapticScheduler.swift

- `private let preferences: HapticPreferenceManaging`, `init(preferences: HapticPreferenceManaging = AppPreferences.shared)`.
- `HapticPreferences.completionPadding` → `HapticTiming.completionPadding`
  (чистая константа, инъекция не нужна).
- `HapticPreferences.intensity.impactIntensity` (2 места) → `preferences.hapticIntensity.impactIntensity`.
- `scheduleTimeDigit` строит `HapticTimings(preferences: preferences)` и
  передаёт в `TimeHapticPatternBuilder.fallbackDigitImpactTimes`/`.nextDigitStartTime`.

## Чанк 4 — TimeHapticPatternBuilder.swift

Все функции (`timeValueEvents`, `fallbackDigitImpactTimes`, `nextDigitStartTime`,
приватный `appendDigitEvents`) получают параметр `timings: HapticTimings`
вместо чтения `TimeControlHapticPattern`/`HapticPreferences` изнутри.

## Чанк 5 — HapticManager.swift, +CountSignal.swift, +TimeControl.swift

- `HapticManager`: `let preferences: HapticPreferenceManaging`, добавляется
  в `init` (дефолт `.shared`), пробрасывается в дефолтную сборку
  `HapticScheduler(preferences: preferences)`. `playCount`/`playTimeValue`
  строят `let timings = HapticTimings(preferences: preferences)` один раз
  и передают дальше; переключение по группировке идёт через `timings.isGroupByThreeEnabled`.
- `+CountSignal.swift`, `+TimeControl.swift`: `playCountSignal`,
  `playGroupedCountSignal`, `playZeroBuzz`, `playGroupedTimeValue`,
  `playClassicTimeValue`, `playTimeValueWithCoreHaptics`, `playTimeValueFallback` —
  у всех добавляется параметр `timings: HapticTimings`, все обращения к
  `HapticPreferences.xxx`/`TimeControlHapticPattern.xxx` заменяются на `timings.xxx`.

## Чанк 6 — тест, доказывающий смысл всей затеи

Новый `HapticTimingsTests.swift`: фейковый `HapticPreferenceManaging` с
управляемым `hapticSpeedMultiplier`, тест «`HapticTimings(speed: 2.5).digitGap`
меньше `HapticTimings(speed: 1.0).digitGap`» — ровно тот тест, который ревью
называет физически невозможным сегодня. `MagicTricksTests` по-прежнему не
собирается целиком (старая, не связанная проблема) — логику проверю отдельным
скриптом на реальном коде, как и `CalculatorPredictionEngineTests` в своё время.

## Out of scope

- `HapticPreferences.groupedChunkSize`/`sectionGap`/`completionPadding` как
  константы — остаются, просто без обёртки (прямые ссылки на `HapticTiming`/
  `HapticPreferences.groupedChunkSize`).
- Починка `MagicTricksTests` (5 отсутствующих файлов) — отдельная старая проблема.

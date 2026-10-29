# mediumImpactGenerator / heavyImpactGenerator fix — plan (финальная версия)

Task spec: см. переписку в чате (2026-08-24). Bug: `mediumImpactGenerator` и
`heavyImpactGenerator` в `HapticManager.swift` возвращают идентичный код —
`UIImpactFeedbackGenerator(style: HapticPreferences.intensity.feedbackStyle)` —
разные имена, одно и то же значение, плюс computed property пересоздаёт объект
на каждое обращение, из-за чего `prepare()` в `HapticScheduler` греет объект,
который тут же выбрасывается.

Прошли через две промежуточные версии плана (форма-по-фиче + множитель силы;
потом один генератор на dot-стиле с кэшем-инвалидацией) — обе отброшены в
переписке как избыточно сложные. Финальное решение проще обеих:

**Один генератор, создаётся один раз навсегда (`let`, без пересоздания
вообще).** Настройка Settings (light/medium/heavy) выражается не стилем
(`.light`/`.medium`/`.heavy` — это как раз то, что пришлось бы кэшировать,
потому что `style` вшивается в объект при создании и не может поменяться),
а **числом** через `impactOccurred(intensity: CGFloat)` — параметр, который
передаётся при каждом вызове отдельно, а не хранится в объекте. Читаем
актуальное значение настройки прямо в момент каждого тактильного сигнала —
живое обновление получается бесплатно, без кэша и без инвалидации.

Шкала: light = 1/3, medium = 2/3, heavy = 1.0 (heavy=1.0 совпадает с
задокументированным поведением обычного `impactOccurred()` без параметра).

## Чанк 1 — HapticModels.swift

Добавить `HapticIntensity.impactIntensity: CGFloat`:
- `.light` → `1.0 / 3.0`
- `.medium` → `2.0 / 3.0`
- `.heavy` → `1.0`

(`feedbackStyle` в этом плане больше не используется этой задачей — оставляем
как есть, не трогаем, чтобы не расширять чанк, пока не потребуется явно.)

## Чанк 2 — HapticManager.swift

Заменить `mediumImpactGenerator`/`heavyImpactGenerator` (computed, пересоздают
объект) на одно свойство:
```swift
let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
```
Обновить `playColorCode`, `playTrainingDigit` (обе ветки), `playDigitSignal` —
использовать `impactGenerator` вместо `mediumImpactGenerator`/`heavyImpactGenerator`.

## Чанк 3 — HapticManager+TimeControl.swift

Обновить 5 мест использования `heavyImpactGenerator` → `impactGenerator`.

## Чанк 4 — HapticScheduler.swift

`scheduleImpact(using:after:intensity:)` и `scheduleImpactSequence(...)`
применяют `HapticPreferences.intensity.impactIntensity` как значение intensity,
когда явный override не передан (существующий необязательный параметр
`intensity: CGFloat?` в `scheduleImpact` остаётся приоритетным, если задан —
например, кейс `digit == 0` в `scheduleTimeDigit`, явно передающий `1.0`).
Сигнатуры функций и протокол `HapticScheduling` не меняются.

## Out of scope
- Числа шкалы (1/3, 2/3, 1.0) и базовый стиль (`.heavy`) — отправная точка,
  подлежат ручной подстройке по ощущениям после тестирования на устройстве.

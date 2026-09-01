# Отказ от оценки нигде не фиксируется — план

Task spec: ревью uamoder. `AppPreferences.shared.hasRespondedToRating = true`
ставится только в `handleLike()` и `handleWriteToUs()`. `handleDislike()`
просто переключает фазу на «disliked», `handleMaybeLater()` зовёт `dismiss()`,
свайп вниз не проходит ни через один из handler'ов. `AppFlowCoordinator.recordTrickClose()`
проверяет только `hasRespondedToRating` и при показе шторки обнуляет
`trickLaunchCount`, так что любой, кто не лайкнул и не написал нам, получает
ту же шторку каждые три закрытия трюка бесконечно.

Решение по итогам обсуждения:
- дизлайк/«maybe later»/свайп — не навсегда, а снюз на время (`ratingSnoozedUntil`);
- лайк и «написать нам» — навсегда (`hasRespondedToRating`, как сейчас);
- `handleLike`/`handleDislike`/`handleWriteToUs` и работа с `AppPreferences.shared`
  переезжают из `RateAppSheet` в отдельный `RateAppViewModel` с тестами.

## Чанк 1 — AppPreferences.swift

Новый протокол:
```swift
protocol RateAppPreferenceManaging {
    var hasRespondedToRating: Bool { get set }
    var ratingSnoozedUntil: Date? { get set }
}
```
`AppPreferences` конформит к нему (добавить в список протоколов структуры).
Новый ключ `Key.ratingSnoozedUntil`, свойство поверх `store.object(forKey:)`/
`store.set(_:forKey:)` (`PreferenceStoring` уже умеет `Any?`, доп. метод не нужен).

## Чанк 2 — AppFlowCoordinator.swift

`recordTrickClose()` добавляет вторую проверку рядом с `hasRespondedToRating`:
```swift
guard !preferences.hasRespondedToRating else { return }
if let until = preferences.ratingSnoozedUntil, until > Date() { return }
```
Счётчик `trickLaunchCount` и порог `ratingTriggerCount` не меняются — это
независимый газ, снюз просто не даёт шторке появиться раньше срока даже если
счётчик уже набрался.

## Чанк 3 — RateAppViewModel.swift (новый файл)

`@MainActor final class RateAppViewModel: ObservableObject`:
- `@Published private(set) var phase: Phase = .question` (`Phase` — enum
  `question`/`disliked`, переезжает из `RateAppSheet`);
- `init(preferences: RateAppPreferenceManaging = AppPreferences.shared)`;
- `func like()` — `preferences.hasRespondedToRating = true` (запрос ревью
  через `SKStoreReviewController` остаётся во View — это UIKit-сайд-эффект,
  не бизнес-логика);
- `func dislike()` — `phase = .disliked`, ничего в `AppPreferences` не пишет
  (снюз ставится централизованно в `markDismissed()`, см. ниже — так дизлайк
  с последующим свайпом без «maybe later» тоже засчитывается);
- `func writeToUs() -> URL?` — переносит текущую сборку `mailto:`-ссылки
  (адрес, subject, percent-encoding) из `handleWriteToUs`, плюс
  `preferences.hasRespondedToRating = true`;
- `func markDismissed()` — `preferences.ratingSnoozedUntil = Date().addingTimeInterval(Self.snoozeDuration)`,
  вызывается из `.onDisappear` шторки независимо от того, как она закрылась
  (лайк/дизлайк/write to us/maybe later/свайп) — единая точка, которая
  гарантированно останавливает цикл. Даже если `hasRespondedToRating` уже
  `true`, лишняя запись снюза безвредна: `recordTrickClose()` сначала
  проверяет постоянный флаг.
- `private static let snoozeDuration: TimeInterval = 14 * 24 * 60 * 60` (2 недели).

## Чанк 4 — RateAppSheet.swift

- `@StateObject private var viewModel = RateAppViewModel()` вместо
  `@State private var phase`.
- `switch phase` → `switch viewModel.phase`, `.animation(..., value: phase)` →
  `value: viewModel.phase`.
- `handleLike()`: `viewModel.like()`, дальше как сейчас (`dismiss()` + таск с
  `SKStoreReviewController`).
- `handleDislike()`: `withAnimation { viewModel.dislike() }`.
- `handleWriteToUs()`: `if let url = viewModel.writeToUs() { UIApplication.shared.open(url) }; dismiss()`.
- `handleMaybeLater()`: без изменений, просто `dismiss()`.
- Добавить `.onDisappear { viewModel.markDismissed() }` на корневой `VStack`.

## Чанк 5 — RateAppViewModelTests.swift (новый файл)

Мок `RateAppPreferenceManaging` (аналогично `MockHapticPreferences` в
`HapticTimingsTests.swift`). Тесты:
- `like()` ставит `hasRespondedToRating = true`;
- `dislike()` переключает `phase` на `.disliked` и НЕ трогает `hasRespondedToRating`/`ratingSnoozedUntil`;
- `writeToUs()` ставит `hasRespondedToRating = true` и возвращает `mailto:`-URL
  с адресом поддержки и закодированным subject;
- `markDismissed()` ставит `ratingSnoozedUntil` в будущее (проверка `> Date()`).

Регистрация нового test-файла и `RateAppViewModel.swift` в `project.pbxproj` —
обычная ручная 4-точечная процедура, как для `HapticTimingsTests.swift` в PR #32.

## Чанк 6 — сборка + живая проверка

`xcodebuild` + в симуляторе: дизлайкнуть → «Maybe later» → закрыть ещё три
трюка → убедиться, что шторка НЕ появляется снова (раньше появлялась).

# SettingsStore: убрать дублирующий источник правды

## Проверка находки (напоминание)

Ранее уже проверил: конкретный пример ревью (`SettingsScreen.swift:74`,
`hasRespondedToRating`/`trickLaunchCount`) бил мимо цели — эти свойства
`SettingsStore` вообще не зеркалит. Но сама архитектурная претензия верна:
6 свойств (`hapticSpeedMultiplier`, `isHapticGroupByThreeEnabled`,
`hapticIntensity`, `isSecretGestureEnabled`, `screenDownHoldDuration`,
`isExitHintEnabled`) продублированы как `@Published` + `didSet` в
`SettingsStore`, при этом реальное хранилище — `AppPreferences`
(UserDefaults). Живого бага сейчас нет (грепом подтвердил — никто не пишет
в эти ключи мимо `SettingsStore`), но это неявный риск и лишнее ручное
сопровождение списка в трёх местах (`@Published`, `didSet`, `init`, плюс
ручной повтор в `resetHapticSettings`/`resetMotionSettings`).

## Подход

Не переделываю `AppPreferences` в `ObservableObject`/класс — это разошлось
бы по ~10 файлам, где сейчас используется DI через протоколы
(`HapticPreferenceManaging`, `MotionPreferenceManaging` и т.д.) и моки в
тестах. Вместо этого убираю дублирующее *хранение* внутри `SettingsStore`:
все 6 свойств становятся вычисляемыми (`get`/`set`), которые напрямую
читают/пишут в `preferences`, без собственной копии значения. `SettingsStore`
превращается в тонкий прокси-адаптер для SwiftUI-биндингов, `AppPreferences`
остаётся единственным источником правды.

```swift
var hapticSpeedMultiplier: Double {
    get { preferences.hapticSpeedMultiplier }
    set {
        objectWillChange.send()
        preferences.hapticSpeedMultiplier = newValue
    }
}
```

`objectWillChange.send()` в сеттере — вручную, раз `@Published` больше нет.
`$settings.hapticSpeedMultiplier` (используется в `HapticSignalSettingsSection`,
`MotionSettingsSection`, `SettingsScreen`) продолжит работать: `Binding` через
`$`-проекцию на `ObservedObject`/`EnvironmentObject` строится по
key path'у на любое settable-свойство класса, не обязательно `@Published`.

`resetHapticSettings()`/`resetMotionSettings()` упрощаются — не нужно
руками переприсваивать 3 свойства после сброса, значения и так тут же
станут актуальными (они больше нигде не кэшируются):

```swift
func resetHapticSettings() {
    objectWillChange.send()
    preferences.resetHapticSettings()
}
```

`init` тоже упрощается — не нужно копировать 6 значений при старте, просто
сохраняем `preferences`.

Проверил все SwiftUI-места, где используются эти свойства
(`HapticSignalSettingsSection`, `MotionSettingsSection`, `SettingsScreen`,
`HapticSettingsScreen`, `MotionSettingsScreen`) — везде либо чтение, либо
`$settings.x`-биндинг, ничего не ломается по сигнатурам.
`SettingsStoreTests.swift` тестирует поведение (что читается/пишется через
`preferences`), а не реализацию — должны пройти без изменений.

## Чанк

Один чанк, один файл — `SettingsStore.swift`. Достаточно компактно, чтобы
не дробить дальше.

После правки — сборка, полный прогон тестов, и ручная проверка на
симуляторе: Settings → Vibrations → покрутить slider/toggle/intensity,
Reset — убедиться что UI обновляется как раньше.

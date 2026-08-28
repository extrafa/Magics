# Pro Access Override переживает переход TestFlight → App Store — план

Task spec: найдено ревью uamoder. `StoreManager.isProOverride` (`StoreManager.swift:34`)
хранится в `UserDefaults` под ключом `dev.proOverride` и участвует в `hasProAccess`
безусловно — независимо от того, sandbox сборка или релизная. UI-переключатель
скрыт в релизе (`SettingsScreen.showsTestFlightSection`, гейт по `#if DEBUG` /
`sandboxReceipt`), но сам флаг это не останавливает.

Сценарий: тестировщик включает тумблер в TestFlight, ставит поверх релиз из
App Store (контейнер и `UserDefaults` сохраняются) — `dev.proOverride` остаётся
`true`, `hasProAccess` его продолжает учитывать, тумблер выключить негде.

Ревью предлагает два варианта фикса — гейтить ЧТЕНИЕ оверрайда или сбрасывать
ключ при старте. Беру второй: он чинит данные в источнике, а не только точку
чтения. Если гейтить только чтение, `UserDefaults` продолжит хранить `true`
бессрочно — при любом будущем сценарии, где сборка снова становится sandbox
на том же устройстве (переустановка debug-сборки поверх старого контейнера),
старый флаг молча оживёт. Сброс в момент, когда сборка перестаёт быть sandbox,
устраняет проблему целиком, а не только её текущее проявление.

Проверка "sandbox или debug" уже есть в `SettingsScreen.showsTestFlightSection` —
дублировать `#if DEBUG` / `sandboxReceipt` во втором файле нельзя, разъедутся
рано или поздно. Выношу в общее место.

## Чанк 1 — AppBuildEnvironment.swift (новый файл)

`MagicTricks/Sources/Application/AppBuildEnvironment.swift` — та же папка, что
`AppConfig.swift`. Один статический флаг:

```swift
enum AppBuildEnvironment {
    static var isSandboxOrDebug: Bool {
        #if DEBUG
        true
        #else
        Bundle.main.appStoreReceiptURL?.path.contains("sandboxReceipt") ?? false
        #endif
    }
}
```

## Чанк 2 — StoreManager.swift

В `init`, сразу после чтения `isProOverride` из `UserDefaults`: если сборка не
sandbox/debug — сбросить в `false`. `didSet` уже пишет значение обратно в
`UserDefaults`, так что сброс сразу же самоисправляет и хранимое значение,
не только то, что в памяти. Момент выбран не случайно: это происходит до
того, как `StoreManager` попадёт в чьи-либо руки (SwiftUI-подписчики,
`hasProAccess`), так что устаревшее `true` никогда не видно снаружи, даже на
мгновение.

## Чанк 3 — SettingsScreen.swift

`showsTestFlightSection` переиспользует `AppBuildEnvironment.isSandboxOrDebug`
вместо собственной копии проверки.

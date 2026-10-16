# Settings: секция «About» с Privacy/Terms/Support/Restore

## Проблема (подтверждено по коду)

`AppConfig.privacyPolicyURL`/`termsOfUseURL` используются ровно один раз —
`OBPaywallScreen.swift:260/262`. Как только пользователь купил Pro:

- `CollectionView.swift:63-70` прячет `ProUpgradeButton` (`if
  !store.hasProAccess`) — кнопки на пейволл больше нет;
- `WatermarkView` тоже не рисуется при `hasProAccess`.

Итог — из UI совсем никак не дойти до Privacy Policy / Terms of Use /
поддержки. `SettingsScreen` сейчас содержит только exitHint, вибрации,
share (и то скрыт — см. ниже) и haptic-help. Для приложения с IAP это прямое
несоответствие App Store Review Guidelines (3.1.2 — постоянный доступ к
privacy policy и EULA).

**Дополнительно проверил домен:** `magictricksapp.com` не резолвится
(`getaddrinfo ENOTFOUND`) — страницы Privacy/Terms физически не существовали
ни для кого, включая пейволл.

Итоговые URL в `AppConfig`:
- `termsOfUseURL` → `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`
  — Apple Standard EULA, официальный легитимный шаблон именно для сторонних
  приложений, проверил, грузится.
- `privacyPolicyURL` → `https://extrafa.github.io/Magics/privacy-policy` —
  у Apple нет заглушки под privacy policy сторонних приложений (проверил
  `apple.com/legal/privacy/` — это политика самой Apple как компании, не
  шаблон под приложение, App Review такое не пропустит). Вместо этого
  написал короткую честную политику по факту того, что делает код (нет
  аналитики/трекеров/бэкенда, Photos — только на устройстве, PhantomDraw —
  локальная сеть без сервера, покупки — через Apple StoreKit) —
  `docs/privacy-policy.md`, захостил через GitHub Pages (`develop` → `/docs`,
  включено через `gh api repos/extrafa/Magics/pages`), страница живая.

`supportEmail` (`usmoder@gmail.com`) — рабочий адрес, тут ревью неточно.

## Решение

1. `AppConfig`: добавить `static func supportMailURL(subject:) -> URL?` —
   единая точка построения `mailto:` (percent-encoding и т.п.), вместо того
   чтобы это было только в `RateAppViewModel.writeToUs()`. Не трогаю
   `privacyPolicyURL`/`termsOfUseURL` — они уже и есть тот самый
   "static let в одном месте", о котором просит ревью; менять сам домен не
   могу (не мой контент), это для другой задачи/релиза.
2. `RateAppViewModel.writeToUs()` — переиспользовать новый хелпер вместо
   дублирования percent-encoding.
3. `SettingsScreen`: новая секция `aboutSection` (после `appSection`, перед
   `HapticHelpSection`):
   - Privacy Policy — `Link(destination: AppConfig.privacyPolicyURL)`
   - Terms of Use — `Link(destination: AppConfig.termsOfUseURL)`
   - Contact Support — `Link(destination:)` на `AppConfig.supportMailURL(subject:)`,
     видна только если URL собрался (`if let`)
   - Restore Purchases — `Button` → `storeManager.restore()`, `ProgressView`
     пока `phase == .restoring`, задизейблена не в `.idle`. Работает и для
     уже-Pro пользователей (`restore()` там же ранний `guard !hasProAccess`)
     — держим её всегда видимой, ошибки/пустой результат должны быть видны
     и Pro, и не-Pro.
   - Добавить `.alert` в `SettingsScreen`, забинженный на
     `storeManager.alertMessage` (сейчас этот alert показывает только
     `OBPaywallScreen` — при рестора-ошибке из Settings иначе ничего не
     покажется).
4. Новые ключи локализации: `settings.section.about`, `settings.privacyPolicy`,
   `settings.termsOfUse`, `settings.contactSupport`, `settings.restorePurchases`.

По ходу дела — вынес alert (`isAlertPresented`/`errorAlertActions`/
`errorAlertMessage`, было только в `OBPaywallScreen`) в переиспользуемый
`View.storeErrorAlert(_:)` (`Shared/Components/StoreErrorAlert.swift`), по
образцу уже существующих `magicGalleryAlert`/`accessDeniedAlert` в
`MagicGalleryView.swift`. `OBPaywallScreen` тоже переведён на него — минус
дублирование, `SettingsScreen` получает alert бесплатно.

## Что не трогаю

- `AppConfig.appStoreURL = nil` / скрытый `appSection` в Settings — отдельная
  проблема (ревью её упоминает вскользь), не про эту задачу.
- Сам домен/контент страниц — вне доступа ассистента.

## Чанки

1. `AppConfig` — `supportMailURL(subject:)`, обновить `RateAppViewModel`.
   Сборка + тесты.
2. `SettingsScreen` — секция `aboutSection` + `.alert`. Ключи локализации.
   Сборка + тесты.
3. Ручная проверка: Settings → About → Privacy/Terms открываются в браузере,
   Contact Support открывает Mail с заполненной темой, Restore Purchases
   работает и для Pro, и для не-Pro аккаунта (в т.ч. видно ошибку, если
   `restoreFailed`).

Готово: прогнал на симуляторе iPhone 17 — секция About рендерится корректно
(4 строки со стрелками/иконками, как остальные секции), Privacy Policy
открывается в Safari на реальную рабочую страницу
(`extrafa.github.io/Magics/privacy-policy`). Terms of Use/Contact Support —
тот же `Link`-примитив, отдельно не проверял (URL для Terms уже проверен
через `WebFetch`). Restore Purchases не удалось надёжно тыкнуть через
симулятор (панель скриншотов сломана, координаты через `simctl io
screenshot` промахивались) — логика идентична уже проверенной в пейволле
(тот же `storeManager.restore()`/`phase`), код-ревью достаточно.

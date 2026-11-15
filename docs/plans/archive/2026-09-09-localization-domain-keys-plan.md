# Захардкоженные Text("...") → доменные ключи

## Проблема

30 `Text("литерал")` (плюс `.navigationTitle("Phantom Draw")` и один голый
`return "Connected"`, попадающий в `Text(peerName)`) читаются мимо принятой
в проекте схемы `String(localized: "domain.key")` — Xcode кладёт в
`Localizable.xcstrings` литерал как ключ. Смена английского текста меняет
ключ, старый перевод отваливается молча. У всех 30 к тому же сейчас нет ни
одного испанского перевода — этот PR их не добавляет (это отдельная задача),
только переводит на доменные ключи, чтобы дальнейшие правки текста не рвали
переводы молча.

Исключены (по совету ревью) — чистые числовые интерполяции, их лучше собирать
форматтером: `InstructionStepRow.swift:72`, `MagicGallerySlotCard.swift:53`.

## Механика правки Localizable.xcstrings

Xcode не досинхронизирует каталог вне IDE-сборки (уже проверено в этой сессии
раньше), поэтому catalog правится вручную: для каждого литерала — убрать
старую запись (ключ = английский текст) и добавить новую (ключ = доменный),
скопировав `comment`, добавив `"localizations": {"en": {"stringUnit": {"state":
"translated", "value": "<исходный английский текст>"}}}`. Правки делаю через
Python-скрипт (json.load → мутация → `json.dump(..., indent=2, sort_keys=True,
ensure_ascii=False)`), чтобы не разъехаться с форматированием файла на ручных
Edit-правках такого размера.

## Чанки (файл = чанк)

1. `ProUpgradeButton.swift` ("Get Pro" → `pro.upgradeButton.title`) +
   `WatermarkView.swift` ("Magic Tricks · Free Trial" → `watermark.freeTrialBadge`).
2. `SettingsScreen.swift` (TestFlight-секция, 4 строки):
   `settings.proOverride.title`, `settings.proOverride.description`,
   `settings.hideWatermark.title`, `settings.hideWatermark.description`.
   Заодно (доп. находка, добавлена по просьбе) — вызов
   `SettingsActionRow(title: "Show Rate App Sheet")` (`title: String` идёт в
   `Text(variable)`, литерал мимо каталога) → `title: String(localized:
   "settings.showRateAppSheet")`. `SettingsSection(title: "TestFlight")` не
   трогаю — имя собственное (бренд Apple), не должно переводиться.
3. `PhantomDrawView.swift` (6 строк): `phantomDraw.intro.line1`,
   `phantomDraw.intro.line2`, `phantomDraw.enterCode.title`,
   `phantomDraw.enterCode.description`, `phantomDraw.codePlaceholder`,
   `phantomDraw.enterCodeOnOtherDevice`.
   Заодно (доп. находки, добавлены по просьбе):
   - `roleButton(title:subtitle:...)` — оба вызова (`title:`/`subtitle:
     String` идут в `Text(variable)`, литералы мимо каталога) → передавать
     `String(localized: "phantomDraw.role.receiver.title")` и т.д.
     (`phantomDraw.role.receiver.subtitle`, `phantomDraw.role.sender.title`,
     `phantomDraw.role.sender.subtitle`).
   - `searchingView`: `Text(viewModel.role == .sender ? "Waiting..." :
     "Connecting...")` и вторая аналогичная тернарная `Text` — литералы
     внутри тернарного выражения уже технически локализуются (Text резолвит
     `LocalizedStringKey`-перегрузку), но остаются текстом-как-ключ. Меняю
     содержимое литералов на доменные ключи прямо в тернарном выражении:
     `phantomDraw.status.waiting`, `phantomDraw.status.connecting`,
     `phantomDraw.status.waitingDescription`,
     `phantomDraw.status.connectingDescription`.
4. `PhantomDrawReceiverView.swift`: `.navigationTitle("Phantom Draw")` →
   переиспользую уже существующий `card.phantomDraw.title` (дедуп, не завожу
   новый ключ); `"Waiting for drawing..."` → `phantomDraw.waitingForDrawing`;
   `return "Connected"` → `phantomDraw.connectedFallback`.
5. `PhantomDrawSenderView.swift`: `"Draw anything"` →
   `phantomDraw.drawAnythingPlaceholder`.
6. `RateAppSheet.swift` (7 строк): `rateApp.question.title`,
   `rateApp.question.subtitle`, `rateApp.disliked.icon`,
   `rateApp.disliked.title`, `rateApp.disliked.subtitle`,
   `rateApp.disliked.writeButton`, `rateApp.disliked.laterButton`.
   Заодно (доп. находка, добавлена по просьбе): оба вызова
   `reactionButton(emoji:label:...)` (`emoji:`/`label: String` идут в
   `Text(variable)`) → `String(localized: "rateApp.reaction.likeIcon")`,
   `rateApp.reaction.like`, `rateApp.reaction.dislikeIcon`,
   `rateApp.reaction.dislike`.
7. `HapticTrainingView.swift` (4 строки, легенда): `training.legend.zero`,
   `training.legend.longVibration`, `training.legend.oneToNine`,
   `training.legend.thatManyVibrations`.
8. `TrickCardView.swift` (`"PRO"` → `trick.proBadge`) +
   `OBPaywallScreen.swift` (`"·"` → `common.dotSeparator`) +
   `OBFirstScreen.swift` (`"Step-by-step instructions for every trick."` →
   `onboarding.first.headline`).
9. Сборка + grep-проверка, что живых `Text("` с английским текстом не
   осталось (кроме двух исключённых числовых интерполяций).

## Не входит в объём (осознанно)

- Испанские переводы новых ключей — не пишу, у литералов их и не было.
- Остальные `String`-параметры, идущие в `Text(variable)` без литералов на
  вызовах (глубже искать не буду) — эта сессия покрывает только то, что
  нашёл сам при чтении файлов из основного списка ревью, не полный аудит
  всего проекта на этот класс бага.

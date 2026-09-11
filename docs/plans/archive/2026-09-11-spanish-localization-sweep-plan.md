# Испанская локализация: догнать каталог + починить обходы локализации

## Что устарело в ревью (оспорим в комменте о выполнении)

Проверил по актуальному коду — три пункта ревью описывают уже переписанный
код, не воспроизводятся:

- `RateAppSheet.swift` — уже нет захардкоженных литералов, `reactionButton`
  получает `label: String`, но это уже локализованная строка с вызова
  (`String(localized: "rateApp.reaction.like")`), не сырой текст.
- `WatermarkView.swift` — не «~20 строк», ровно одна, и та уже через
  `String(localized:)`.
- `CollectionView.swift` — нет хардкода «Get Pro»/«PRO», `ProUpgradeButton`
  не задублирован (один файл, один вызов).

## Что подтвердилось (и хуже, чем в ревью)

- Каталог: **140 из 438** ключей без `es` (ревью писалось раньше — тогда
  было 124 из 411; я сам добавил новых ключей только на `en` в недавних PR).
- `PhantomDrawView.statusView(title: String, subtitle: String, ...)` —
  параметры типизированы как `String`, а не `LocalizedStringKey` → `"Could
  Not Connect"` / `"Make sure both phones are nearby..."` вообще не попадают
  в каталог, не локализуются в принципе (это ТОТ ЖЕ механизм бага, что
  ревью описывало для `RateAppSheet`, просто в другом файле).
- `"Connect"` / `"Cancel"` (PhantomDraw), `"Camera"` / `"Photo Library"`
  (MagicGallery), `"Try Again"` (PhantomDraw) — существуют как ключи в
  каталоге (значит, `LocalizedStringKey`-механизм сработал), но без единого
  перевода — даже `en` пустой.
- `MagicGalleryCropView.swift` — это UIKit-контроллер, не SwiftUI:
  `confirmButton.setTitle("Use Photo", for: .normal)` не подхватывается
  автоэкстракцией вообще (UIKit не делает этого сам). Кнопка-крестик
  (иконка без текста) без `accessibilityLabel`.
- `OnboardingViewModel.loadingPhase1` — реально 15 `if`, перебирающих все
  непустые подмножества 4-элементного множества целей (без `.everywhere`).
  Не про локализацию, но рядом по файлу — упрощаю в этом же PR (по твоему
  решению).
- Проверил на «мусорные ключи» (кросс-референс каталога с исходниками):
  нашёл явно мёртвый кластер — `mindPattern.*` / `card.mindPattern.*` /
  `instruction.mindPattern.*` (трюк с таким именем в проекте не существует —
  видимо, остаток от переименования в GeoMentalism). Пруф ненадёжный (юз
  через `String.paywall(_:)`-подобные хелперы с интерполяцией не ловится
  простым grep, есть риск случайно снести реально используемый ключ) —
  **в этот PR не трогаю**, отдельная задача с ручной построчной проверкой
  каждого кандидата.

## Решение

### Чанк 1 — код: убрать реальные обходы локализации

1. `PhantomDrawView.swift`:
   - `statusView(title: String, subtitle: String, ...)` →
     `title: LocalizedStringKey, subtitle: LocalizedStringKey`.
   - Вызов для `.failed`: новые именованные ключи
     `phantomDraw.status.failed.title` / `.subtitle` / `.retry` (взамен
     сырых литералов и вместо голого `"Try Again"`) — сразу с `en`+`es`.
   - 2× `Button("Cancel", action: stop)` → `Button(String(localized:
     "common.cancel"), action: stop)` — этот ключ уже полностью переведён,
     дублирующий голый `"Cancel"` больше не нужен.
2. `MagicGalleryView.swift`: `Button("Cancel", role: .cancel) {}` →
   `Button(String(localized: "common.cancel"), role: .cancel) {}`;
   `"Camera"`/`"Photo Library"` → `magicGallery.source.camera` /
   `magicGallery.source.photoLibrary` (сразу с `en`+`es`).
3. `MagicGalleryCropView.swift`:
   - `confirmButton.setTitle("Use Photo", ...)` →
     `String(localized: "magicGallery.crop.usePhoto")` (новый ключ, `en`+`es`).
   - `cancelButton.accessibilityLabel = String(localized: "common.cancel")`.
   - `confirmButton.accessibilityLabel = String(localized:
     "magicGallery.crop.usePhoto")` — на случай, если VoiceOver не подхватит
     заголовок кнопки автоматически (недорого, явное — надёжнее).

Итог чанка: голый `"Cancel"` и `"Try Again"` из каталога больше не
используются нигде (можно удалить как ключи); все новые строки локализуемы
и сразу переведены.

### Чанк 2 — убрать комбинаторный взрыв в `OnboardingViewModel`

Пересмотрел после твоего замечания: таблица-словарь на все 15 комбинаций —
не решение, это тот же комбинаторный взрыв, просто без `if`. Если завтра
появится 5-я цель — вариантов станет 31 вместо 15, и так далее (`2^n - 1`).
Правильно — не хранить готовое предложение на каждую комбинацию, а
хранить короткий фрагмент на каждую ОТДЕЛЬНУЮ цель и склеивать выбранные
через `ListFormatter` (даёт грамматически верное «A, B и C» — с "and"/"y" —
сразу на обоих языках, без ручной сборки запятых).

Одиночный выбор (`.parties`/`.dates`/`.work`/`.family`) и `.everywhere` не
трогаю — там уже готовые авторские фразы на обоих языках, конкатенация им
не нужна и не нужна была изначально (проблема со взрывом была только в
комбинациях 2+ целей — 10 из 15 исходных веток).

```swift
private static let orderedGoals: [OnboardingGoal] = [.parties, .dates, .work, .family]

private var loadingPhase1: String {
    if selectedGoals.contains(.everywhere) {
        return String(localized: "onboarding.processing.phase1.everywhere")
    }
    let matched = Self.orderedGoals.filter(selectedGoals.contains)
    switch matched.count {
    case 0:
        return String(localized: "onboarding.processing.phase1")
    case 1:
        return singleGoalPhrase(matched[0])
    default:
        let fragments = matched.map(goalFragment)
        let joined = ListFormatter().string(from: fragments) ?? fragments.joined(separator: ", ")
        return String(format: String(localized: "onboarding.processing.phase1.combined"), joined)
    }
}

private func singleGoalPhrase(_ goal: OnboardingGoal) -> String {
    switch goal {
    case .parties: String(localized: "onboarding.processing.phase1.parties")
    case .dates: String(localized: "onboarding.processing.phase1.dates")
    case .work: String(localized: "onboarding.processing.phase1.work")
    case .family: String(localized: "onboarding.processing.phase1.family")
    case .everywhere: String(localized: "onboarding.processing.phase1.everywhere")
    }
}

private func goalFragment(_ goal: OnboardingGoal) -> String {
    switch goal {
    case .parties: String(localized: "onboarding.processing.goalFragment.parties")
    case .dates: String(localized: "onboarding.processing.goalFragment.dates")
    case .work: String(localized: "onboarding.processing.goalFragment.work")
    case .family: String(localized: "onboarding.processing.goalFragment.family")
    case .everywhere: ""
    }
}
```

Новые ключи (сразу с `en`+`es` в этом же чанке):
- `onboarding.processing.phase1.combined` = `"Finding tricks for %@…"` /
  es `"Buscando trucos para %@…"`
- `onboarding.processing.goalFragment.parties` = `"parties"` / es `"fiestas"`
- `.dates` = `"dates"` / es `"citas"`
- `.work` = `"work events"` / es `"eventos de trabajo"`
- `.family` = `"family time"` / es `"tiempo en familia"`

Пример: parties+dates → `ListFormatter` даёт `"parties and dates"` →
`"Finding tricks for parties and dates…"`; parties+dates+work → `"parties,
dates and work events"`.

Ключи-комбинации из старого кода (10 штук: все 2- и 3-сочетания
parties/dates/work/family) становятся неиспользуемыми — удаляю их из
каталога сразу в этом чанке (не жду отдельной задачи по мусорным ключам:
тут я точно знаю, что они больше нигде не читаются, потому что сам убираю
единственное место чтения). Это ещё и минус 10 строк для перевода в чанке 3.

**Тот же паттерн нашёлся во втором месте** — `OBFeatureSlideScreen.
noPropsSubtitle` (не названо в ревью явно, но это дословно та же 15-`if`
лесенка и ещё 10 ключей-комбинаций `onboarding.feature.noprops.subtitle.*`).
Здесь готовые фразы per-комбинация — авторский текст под каждое сочетание
("A house party or a first date. One trick and no one will forget that
night."), не сводится к конкатенации фрагментов без потери качества текста,
поэтому эти 10 ключей ОСТАЮТСЯ как есть (переведутся в чанке 3) — но саму
15-`if` лесенку убираю, ключ строю тем же общим механизмом
(`goals.orderedCombinableGoals`, дальше `rawValue`, склеенный через `.`) —
один механизм на оба места вместо двух копий:

```swift
extension OnboardingGoal { static let combinable: [OnboardingGoal] = [.parties, .dates, .work, .family] }

extension Set where Element == OnboardingGoal {
    var orderedCombinableGoals: [OnboardingGoal] { OnboardingGoal.combinable.filter(contains) }
}
```

`OnboardingGoal` получает `: String` raw value (значения `rawValue` уже
совпадают с именами case'ов — та же строка, что использовалась в ключах).

### Чанк 3 — перевести весь оставшийся список на испанский

После чанков 1-2 список "нет `es`" короче на 14 ключей (`Cancel`/`Try
Again` выпадают из каталога, `Camera`/`Photo Library` переименованы и
переведены в чанке 1; 10 ключей-комбинаций из `OnboardingViewModel`
удалены в чанке 2). Оставшиеся ~125 ключей — перевожу все разом через
python-скрипт по образцу `migrate_xcstrings.py` из PR #58
(`separators=(",", " : ")`, вставка на место без глобальной пересортировки,
чтобы диф оставался читаемым). Перевод — мой собственный (не машинный
сервис), по контексту каждого экрана; там где есть `%@`/множественное число
(`onboarding.demo.reveal.count.one/.other` — не в списке, уже переведён)
сохраняю плейсхолдеры без изменений.

## Чанк 4 (по перепроверке) — дубликаты ключей

Прогнал скрипт сравнения EN-значений по всему каталогу. Нашёл и почистил то,
что прямо относится к этому PR:

- `settings.privacyPolicy` / `settings.termsOfUse` — дубли `onboarding.
  paywall.privacy` / `.terms` (тот же текст "Privacy Policy"/"Terms of Use"),
  сам завёл их в предыдущем PR (#69). Удалил, `SettingsScreen` теперь
  ссылается на существующие paywall-ключи — один канонический перевод на
  оба места.
- Голый `"Phantom Draw"` — не используется нигде в коде (проверил grep'ом),
  дубль `card.phantomDraw.title`/`instruction.phantomDraw.title`. Удалил
  вместо того, чтобы переводить мёртвый дубль (как сделал по ошибке в
  чанке 3).
- `instruction.magicGallery.step6.title`/`.description` — байт-в-байт
  дубликат step5, но используется в коде **только step5**
  (`MagicGalleryInstruction.swift:38-39`) — step6 мёртвый код с рождения.
  Удалил.
- Голый `"“%@”"` — нигде не используется (grep по всему проекту, включая
  варианты с экранированием). Удалил.
- Голый `"Connect"` — переименовал в `phantomDraw.connect` (тот же файл уже
  трогаю в этом PR под другую правку) для единообразия с остальными
  `phantomDraw.*`.

**Найдены, но НЕ трогаю** (вне скоупа этого PR — не мой код, не относится к
ревью, риск зацепить чужой модуль без явного запроса): ещё ~20 групп
дублирующихся EN-значений в каталоге — `"Medium"`, `"Start"`, `"Tap"`,
`"Vibrations"`/`"Vibration Settings"`, `"Get Started"`, `"Learn the
signals"`/`"Hold the phone"`/`"Get the signals"` (общие для ColorSense/
CalculatorPrediction/GeoMentalism/TimeControl/MindPattern-инструкций),
описания paywall-бенефитов дублируют card-subtitle трюков и т.п. Это
отдельная задача по всему каталогу, не про испанскую локализацию.

## Чанки

1. `PhantomDrawView.swift` / `MagicGalleryView.swift` /
   `MagicGalleryCropView.swift` — убрать обходы локализации, новые ключи с
   `en`+`es`. Сборка + тесты.
2. `OnboardingViewModel.swift` — таблица вместо 15 `if`. Сборка + тесты
   (плюс раз уже открываю файл — ручная проверка на симуляторе: выбрать
   разные комбинации целей на онбординге, убедиться что фраза на экране
   загрузки не пустая и соответствует комбинации).
3. Перевод оставшихся ~135 ключей на `es` через скрипт. `plutil`/`python
   json.load` валидация, сборка + тесты.
4. Ручная проверка: переключить симулятор на испанскую локаль, пройти
   онбординг + пейволл + Settings + PhantomDraw failed-экран + MagicGallery
   crop — нигде не должно остаться английского текста (кроме случаев, где
   он и должен быть — бренд/эмодзи).

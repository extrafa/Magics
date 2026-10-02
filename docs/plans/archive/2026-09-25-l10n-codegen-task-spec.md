# Задача: механизм сокращения дублирующихся строковых ключей (L10n/asset)

## Что делаем (обновлено — заменяет прошлую версию файла)

Прошлая версия этого файла описывала другую задачу (единый сгенерированный
enum со всеми 440 ключами локализации) — это не то, что имелось в виду,
заменяю формулировку полностью.

Реальная проблема: во многих файлах несколько строковых ключей подряд делят
общий префикс, например (реальный случай, [Trick.swift](../../MagicTricks/Sources/Modules/Collection/Model/Trick.swift)):

```swift
title: "card.geo.title",
cardTitle: "card.geo.cardTitle",
subtitle: "card.geo.subtitle",
```

Префикс `card.geo` повторяется на каждой строке. Хотим механизм: один раз
объявить общий префикс, дальше обращаться к нему коротко, без повторения.

Прогнал скрипт по `MagicTricks/Sources` — мест, где 2+ строковых ключа в
одном файле делят общий префикс (2+ сегмента), оказалось ~90 групп примерно
в 30 файлах: все 6 Instruction-моделей трюков (title/effect/secret +
stepN.title/description), `Trick.swift` (5 доменов card.*), Onboarding
(pain/solution/goal/preview/feature/processing/welcome/goal), Settings
(haptics/section/proOverride/hideWatermark/exitHint/help), RateApp
(disliked/reaction/question), PhantomDraw (status/status.failed/intro/
role.receiver/role.sender/enterCode), HapticTraining (legend/digits/answer),
MagicGallery (error/gesture/standardSet/status/source), ColorSense
(colorMentalism.card), ExitHint (confirm/swipe), Instruction shared
компоненты (section/share/phase/action.*), HapticModels (haptics.intensity).

Заодно нашёл соседний случай той же природы, но не локализация: имена
ассетов (`Image("...")`) в `MagicGalleryPhotoLibrary.swift`
(`gallery.photo.one`…`ten`) и в Instruction-моделях (`step.geo.cityGrid`,
`step.time.faceDown`, `step.calculator.acNumber` и т.п.) — та же префиксная
дупликация, но значение — обычный `String`, не локализация. Механизм ниже
покрывает и это.

## Механизм

Два маленьких типа в `MagicTricks/Sources/Shared/Localization/`:

```swift
struct KeyDomain {
    private let prefix: String
    init(_ prefix: String) { self.prefix = prefix }
    func callAsFunction(_ suffix: String) -> String { "\(prefix).\(suffix)" }
}

struct L10nDomain {
    private let domain: KeyDomain
    init(_ prefix: String) { domain = KeyDomain(prefix) }
    func callAsFunction(_ suffix: String) -> LocalizedStringResource {
        LocalizedStringResource(String.LocalizationValue(stringLiteral: domain(suffix)))
    }
}
```

`LocalizedStringResource` — общий знаменатель между `String(localized:)`
(есть `init(localized: LocalizedStringResource)`) и полями, у которых уже
сейчас тип `LocalizedStringResource` напрямую (`Trick.title` и т.п.) —
оба случая работают без доп. оборачивания на месте вызова.

`KeyDomain` без локализационной обёртки — для имён ассетов (`Image(key("cityGrid"))`).

Использование — точечно, в начале файла/типа, где есть реальное дублирование:

```swift
private let key = L10nDomain("instruction.geo")
// ...
title: key("step1.title"),
description: key("step1.description"),
```

Ключи с плейсхолдерами (`%@`, `%lld`, 13 штук в проекте) этот механизм не
трогает — они не про дублирование префикса, а про форматирование, это вне
объёма задачи.

## Объём миграции

Применяем механизм во всех ~30 файлах, где скрипт нашёл реальное
дублирование префикса (2+ ключа в одном файле). Единичные ключи без
дублирующегося соседа не трогаем — сокращать нечего.

Закрепляем на будущее: если новые ключи в одном файле снова получают общий
префикс (2+) — использовать `L10nDomain`/`KeyDomain`, а не повторять префикс
вручную. Зафиксирую как отдельный тематический скилл на Этапе 7 (не в
CLAUDE.md).

## Acceptance criteria

- `KeyDomain`/`L10nDomain` существуют в `Shared/Localization/`, покрыты
  минимальным юнит-тестом (склейка префикса + суффикса).
- Все ~30 файлов со найденным дублированием мигрированы.
- Поведение локализации не меняется (те же ключи, тот же текст) — это
  чисто синтаксическая правка мест вызова.
- Проект собирается без ошибок.

# TrickCollection: привязать к TrickType, локализация — в модели ключами

## Проверка (напоминание)

Уже проверил ранее: `TrickType` на самом деле уже `CaseIterable` — эта
деталь в ревью неточная, но суть претензии верна — `TrickCollection.tricks`
никак не завязан на `TrickType.allCases`, `TrickRouterView.swift:15-28` и
`TrickType.collectionColor` — exhaustive `switch`, значит при новом кейсе
компилятор поймает только их. `String(localized:)` в `static let tricks`
резолвится один раз за процесс — тоже подтверждено. Договорились чинить
всё, что относится к `Trick`/`TrickCollection` (не трогая `Instruction` —
там та же схема, но это отдельный по объёму рефакторинг).

## Подход

**Trick.swift:**

- `title`/`cardTitle`/`subtitle` меняют тип с `String`/`String?` на
  `LocalizedStringResource`/`LocalizedStringResource?` (iOS 16+, ровно
  наш deployment target). Строковый литерал ключа (`"card.geo.title"`)
  подставляется напрямую — `LocalizedStringResource` сам
  `ExpressibleByStringLiteral`, extraction в String Catalog работает так
  же, как с `String(localized:)`. `Hashable`/`Equatable` есть из коробки,
  `Trick: Hashable` не ломается.
- Массив трюков переезжает в `extension TrickType { var trick: Trick }` —
  один `switch self` на все 6 кейсов, каждый кейс строит свой `Trick` с
  соответствующим `id`. Добавишь кейс в `TrickType` — компилятор потребует
  ветку и здесь, как и в `TrickRouterView`/`collectionColor`.
- `TrickCollection` — `struct` → `enum` (нигде не инстанцируется, только
  static), `tricks` = `TrickType.allCases.map(\.trick)`. Дубликат `id`
  становится структурно невозможным (каждый case даёт ровно один `Trick`
  с этим же `id`), тест на уникальность не нужен — считаю его избыточным.

**TrickCardView.swift** — единственное место, где `trick.title` уходит не
в `Text`, а в `String(format:)`/как `String`-параметр:
- строка 33: `String(format: ..., trick.title)` → `String(format: ..., String(localized: trick.title))`
- строка 53: `TrickCardActions(trickName: trick.title, ...)` → `TrickCardActions(trickName: String(localized: trick.title), ...)`

`Text(trick.cardTitle ?? trick.title)` (строка 73) и `Text(trick.subtitle)`
(строка 80) не трогаю — `Text` умеет `LocalizedStringResource` напрямую
(iOS 16+), и это даже честнее прежнего: теперь у `Text` реально
локале-зависимый источник, а не застывшая строка.

Больше `trick.title`/`.subtitle`/`.cardTitle` нигде не используется —
проверил грепом по всему проекту и по тестам.

## Чанк

Один чанк: `Trick.swift` (переписывается) + `TrickCardView.swift`
(2 строки). Файлы взаимозависимы, дробить нет смысла.

После правки — сборка, полный прогон тестов, ручная проверка Collection на
симуляторе (карточки трюков не съехали, PRO/лок-бейдж, локализация как была).

# Dynamic Type для фиксированных .system(size:) шрифтов

## Проверка находки

- Реальное число `.system(size:` по проекту — **133**, а не 144 (посчитано
  `grep -rn '\.system(size:' MagicTricks/Sources`). `relativeTo`/
  `dynamicTypeSize`/`ScaledMetric` — действительно 0 вхождений, тут ревью
  право.
- Все перечисленные строки в Instruction-модуле, `TrickDifficultyBadge:16`
  и `TrickCardView` — подтвердились (номера строк в `InstructionView.swift`
  и `TrickCardView.swift` сейчас сдвинуты на 1–3 строки относительно ревью —
  это из-за наших же правок accessibility в PR #71, не ошибка ревью).
- `TrickCardActions.swift:18/27` (по факту сейчас 19/30) — подтверждено,
  там `.font(.headline)`, уже масштабируется, трогать не нужно.
- `TrickCardView` header (заголовок/подзаголовок карточки) — подтверждено,
  `.title3`/`.subheadline`, уже масштабируется, трогать не нужно.
- **`CollectionView.swift:101` — находка ошибочна.** В файле вообще нет ни
  одного `.system(size:` (в файле 99 строк, строки 101 не существует).
  Ничего не меняю в этом файле.
- **`SettingsScreen.swift:59` — ссылка на строку неточная** (там просто
  `Text(...)`, а не `.font(.system(size:`) и цифра «144» — это скопированный
  общий счётчик по проекту, а не счётчик по файлу. Но сама проблема в файле
  реальная: тот же паттерн (`.system(size: 17, bold, rounded)` для
  заголовка + `.system(size: 13, medium, rounded)` для описания) повторён
  3 раза — в `exitHintSection` (боевой, всегда виден) и в `proOverride`/
  `hideWatermark` (внутри `testFlightSection`, который живёт только под
  `AppBuildEnvironment.isSandboxOrDebug` и в релиз-сборке не показывается).
  Чиню все три — правка одинаковая и дешёвая, но боевой затронутый — только
  `exitHintSection`.
- Предложенный в исходном ревью `.dynamicTypeSize(...)` как способ
  "исправить" фиксированный кегль ревью само же и отвергло (он только режет
  диапазон, а не масштабирует) — согласен, не использую для этого.

## Подход

Иконки (`Image(systemName:).font(.system(size:...))`) — не трогаю, они не
текст и не входят в жалобу про читаемость. Правлю только `Text(...)`.

Два способа в зависимости от того, есть ли точное совпадение с
семантическим text style (на iOS 16 доступен
`Font.system(_:design:weight:)`, что даёт масштабирование + сохранение
`design: .rounded` и произвольного веса):

- Есть точное совпадение по умолчанию (например 12pt = `.caption`,
  11pt = `.caption2`, 17pt = `.body`, 13pt = `.footnote`) —
  использую семантический стиль напрямую.
- Точного совпадения нет (16, 14, 22, 26, 32pt) —
  `@ScaledMetric(relativeTo:)`, чтобы сохранить текущий визуальный размер
  при обычном системном размере шрифта и масштабировать вместе с ним.

Отдельно: `TrickCardView.swift` — `.padding(.trailing, 88)` под заголовком
резервирует место под бейдж (proBadge/сложность). Бейдж сейчас 11pt, при
максимальном Accessibility-размере он вырастет заметно (почти в 2 раза) и
может наехать на заголовок — фиксированный отступ 88 этого не учитывает.
Полноценный layout на основе реальной ширины бейджа (GeometryReader) — это
уже другого масштаба переделка, не буду делать её заодно. Ограничиваю
диапазон Dynamic Type для карточки до `.accessibility1` сверху
(`.dynamicTypeSize(...DynamicTypeSize.accessibility1)`), чтобы не допустить
совсем экстремальных вариантов, где ряд поедет — это тот же приём, что
часто используют для карточных layout'ов с ограниченным местом.

## Чанки

**Чанк 1 — Instruction-модуль (6 файлов).**
`InstructionStepRow.swift`, `InstructionComponents.swift`,
`InstructionStepsSection.swift`, `InstructionStepActionsView.swift`,
`InstructionPhaseLegend.swift`, `InstructionView.swift` — заменить текстовые
`.font(.system(size: ...))` на семантические стили/`@ScaledMetric` по схеме
выше.

**Чанк 2 — карточки трюков.**
`TrickCardView.swift` (proBadge-текст → `.caption2`, + верхняя граница
`.dynamicTypeSize` на карточку) и `TrickDifficultyBadge.swift`
(→ `.caption2`).

**Чанк 3 — Settings.**
`SettingsScreen.swift` — `exitHintSection`, `proOverride`-блок,
`hideWatermark`-блок: заголовок → `.body` bold, описание → `.footnote`
medium.

После каждого чанка — сборка + прогон тестов на симуляторе, стоп на
подтверждение.

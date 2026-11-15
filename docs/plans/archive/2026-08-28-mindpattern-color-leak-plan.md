# Имя удалённой фичи mindPattern протекло в цвета — план

Task spec: два ревью uamoder про один и тот же ассет. `TrickType` (`Trick.swift`)
больше не содержит `mindPattern` — трюк удалён, но `collectionMindPattern.colorset`
остался и используется под четырьмя разными смыслами:

- `TrickPalette.Difficulty.easy` — цвет бейджа сложности «Легко»
- `TrickPalette.ColorSense.green` — зелёный в игре ColorSense
- `HapticTrainingMode.accentColor` — акцент экрана тренировки
- `OBPaywallScreen` (3 места) — акцент на пейволле

Опасность именно в связке: правка одного из четырёх смыслов молча красит
остальные три. Плюс в каталоге 5 мёртвых ассетов той же удалённой фичи
(`mindPatternBlue/Cyan/Green/Orange/Purple`) — grep по `Sources` не находит
ни одной ссылки, и их RGB отличаются от `collectionMindPattern`, так что
переиспользовать под новые имена нельзя, только удалить.

Ориентируюсь на более подробное из двух ревью — три отдельных имени
(`difficultyEasy`, `colorSenseGreen`, `accentPrimary`), а не одно общее:
`easy` и `green` — цвета конкретных трюков, которые должны меняться
независимо; `accentPrimary` — общий акцент, который HapticTraining и Paywall
осознанно делят один на двоих (не про трюк).

Имя `colorSenseGreen`/`difficultyEasy` при этом не изобретается с нуля —
у обоих уже есть братья по конвенции в каталоге: `colorSenseRed/Blue/Yellow`
и `difficultyHard`.

## Чанк 1 — Assets.xcassets

- Удалить `collectionMindPattern.colorset` и 5 мёртвых `mindPattern*.colorset`.
- Добавить `difficultyEasy.colorset`, `colorSenseGreen.colorset`,
  `accentPrimary.colorset` — все три с тем же RGB, что был у
  `collectionMindPattern` (204/780/349), чтобы визуально ничего не поменялось.

## Чанк 2 — TrickPalette.swift

- `Difficulty.easy` → `Color("difficultyEasy")`.
- `ColorSense.green` → `Color("colorSenseGreen")`.
- Новый `static let accentPrimary = Color("accentPrimary")` на верхнем уровне
  `TrickPalette` (не под-namespace — это одно значение, а не семейство).

## Чанк 3 — HapticTrainingMode.swift + OBPaywallScreen.swift

- `HapticTrainingMode.accentColor`: `Color.collectionMindPattern` (авто-сгенерированный
  символ ассета) → `TrickPalette.accentPrimary`.
- `OBPaywallScreen.swift`, 3 места: `Color("collectionMindPattern")` →
  `TrickPalette.accentPrimary`. Файл уже использует
  `private typealias Palette = TrickPalette.Collection` для трюко-специфичных
  цветов — `accentPrimary` через `Palette` не идёт (это `.Collection`, не общий
  акцент), обращаемся напрямую через `TrickPalette.accentPrimary`.

## Чанк 4 — ColorSenseInstruction.swift

Мелкая, не связанная с цветом правка из того же комментария ревью: заголовок
файла всё ещё называет его `ColorMentalismInstruction.swift` (старое имя трюка
до переименования в ColorSense).

## Out of scope

- `TrickPalette.Difficulty.medium = Color("collectionCalculatorPrediction")` —
  тоже переиспользует чужой цвет, но ревью это не упоминает, трогать не буду.

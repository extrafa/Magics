# Унификация имён ассетов в Assets.xcassets

## Задача

Каталог ассетов смешивает три схемы именования (доменные точечные
`color.step.colorGrid`, camelCase-роли `grayCard`, голые слова `noprops`).
Переводим все 42 ассета (21 colorset + 21 imageset) на единую схему
`<домен>.<роль>`.

Источник: тред ревью PR "First review" про `grayCard.colorset` (0.58
opacity thread соседний, уже закрыт).

Побочные находки (не чиним в этом плане, только зафиксировано):
- `card.colorset` — 0 использований, мёртвый ассет, поэтому удаляется, а
  не переименовывается.
- `OnboardingFeatureType.noProps`/`.vibrations` case'ы enum'а показывают
  контент не по своим именам (`.noProps` рисует "trick for every moment"
  / Trick Hub, `.vibrations` рисует "no cards no props only phone" /
  Color Sense) — сами картинки на своих местах корректны по смыслу,
  разъехались только имена enum-кейсов. Отдельная задача, не эта.

## Схема

`<домен>.<роль>`, точка — разделитель, включая `step.*` (домен `step`
теперь первый: `X.step.Y` → `step.X.Y`).

### Colorsets

| Было | Станет |
|---|---|
| accentPrimary | accent.primary |
| background | background.screen |
| button | button.primary |
| card | *(удалить, 0 использований)* |
| collectionCalculatorPrediction | collection.calculatorPrediction |
| collectionColorSense | collection.colorSense |
| collectionGeoMentalism | collection.geoMentalism |
| collectionMagicGallery | collection.magicGallery |
| collectionPhantomDraw | collection.phantomDraw |
| collectionTimeControl | collection.timeControl |
| colorSenseBlue | colorSense.blue |
| colorSenseGreen | colorSense.green |
| colorSenseRed | colorSense.red |
| colorSenseYellow | colorSense.yellow |
| defaultText | text.onOverlay |
| difficultyEasy | difficulty.easy |
| difficultyHard | difficulty.hard |
| grayBorder | card.border |
| grayCard | card.background |
| primaryText | text.primary |
| secondaryText | text.secondary |

### Imagesets

| Было | Станет |
|---|---|
| calculator.step.acNumber | step.calculator.acNumber |
| calculator.step.multiply | step.calculator.multiply |
| color.step.colorGrid | step.color.colorGrid |
| gallery.step.collection | step.gallery.collection |
| geo.step.cityGrid | step.geo.cityGrid |
| geo.step.cityList | step.geo.cityList |
| time.step.faceDown | step.time.faceDown |
| time.step.timer | step.time.timer |
| instruction | onboarding.preview.instructions |
| tricks | onboarding.preview.everyMoment |
| noprops | onboarding.preview.phoneOnly |
| one | gallery.photo.one |
| two | gallery.photo.two |
| three | gallery.photo.three |
| four | gallery.photo.four |
| five | gallery.photo.five |
| six | gallery.photo.six |
| seven | gallery.photo.seven |
| eight | gallery.photo.eight |
| nine | gallery.photo.nine |
| ten | gallery.photo.ten |

## Чанки

1. **Text-цвета** — `primaryText`→`text.primary`, `secondaryText`→`text.secondary`,
   `defaultText`→`text.onOverlay`; удалить мёртвый `card.colorset`.
2. **Card/button/background/accent** — `grayCard`→`card.background`,
   `grayBorder`→`card.border`, `button`→`button.primary`,
   `background`→`background.screen`, `accentPrimary`→`accent.primary`.
3. **Палитра трюков** — 6× `collection*`, 4× `colorSense*`, 2× `difficulty*`.
4. **step.\* imagesets** — 8 картинок инструкций.
5. **Onboarding preview + gallery photo** — `instruction`, `tricks`,
   `noprops`, `one`…`ten` (13 ассетов).

Каждый чанк: переименовать папку ассета (`git mv`), поправить
`path`/имя в `Contents.json`, обновить все вызовы в Swift (компилятор
покажет их сам после переименования), собрать проект, показать дифф.

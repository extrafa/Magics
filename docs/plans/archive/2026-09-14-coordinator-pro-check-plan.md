# План: убрать мёртвый open(trick:), перенести Pro-проверку в координатор

Источник: тред ревью PR #1, `AppFlowCoordinator.swift:46` (PRRT_kwDOQS3Urc6bY3OU).

## Чанк 1 — удалить мёртвый `open(trick:)`

Удалить неиспользуемый метод `open(trick:)` из `AppFlowCoordinator.swift`
(строки 46-48). Больше нигде в проекте не вызывается — только само
объявление.

## Чанк 2 — дать координатору ссылку на StoreManager

Добавить `AppFlowCoordinator` зависимость `store: StoreManager` (через init,
без дефолтного значения — как `preferences`/`scheduler`). Обновить все три
места создания координатора, чтобы передавали существующий `StoreManager`:

- `MagicTricksApp.swift:13` — здесь же создаётся `storeManager`, порядок
  инициализации нужно поправить (сначала store, потом flow).
- `RateAppSheet.swift:183` (preview)
- `CollectionView.swift:89` (preview)

Поведения ещё не меняем — только проводим зависимость.

## Чанк 3 — проверка Pro-доступа внутри координатора

В `openStartFlow(for:)` и `open(instruction:)` добавить проверку
`trick.id.requiresPro && !store.hasProAccess` — если трюк платный и доступа
нет, вызывать `openPaywall()` вместо открытия трюка/инструкции.

## Чанк 4 — упростить CollectionView

В `CollectionView.swift` убрать локальные ветвления
`if isLocked { flow.openPaywall() } else { flow.openStartFlow(...) }` в
`onStartTap`/`onHowToTap` — звать координатор напрямую, он сам решит.
`isLocked` в файле остаётся только там, где нужен чисто для UI (замок на
карточке, `ProUpgradeButton` оверлей).

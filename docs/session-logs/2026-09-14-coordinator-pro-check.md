# 2026-09-14 — Pro-доступ в AppFlowCoordinator вместо CollectionView

## Задача
Тред ревью PR #1 (AppFlowCoordinator.swift:46, PRRT_kwDOQS3Urc6bY3OU): мёртвый
метод `open(trick:)`, дублирующий `openStartFlow(for:)`, но не проверяющий
Pro-доступ. Проверка `requiresPro && !hasProAccess` жила только в
`CollectionView` — любая новая точка входа в трюк рисковала забыть про неё.

## Решение
- Удалён неиспользуемый `open(trick:)`.
- `AppFlowCoordinator` получил зависимость `store: StoreManager` (через init,
  без default).
- `openStartFlow(for:)` и `open(instruction:)` сами проверяют
  `isLocked(trick)` (`requiresPro && !hasProAccess`) и вызывают
  `openPaywall()`, если доступа нет. Сигнатура `open(instruction:)` сменилась
  с `Instruction` на `Trick` — иначе координатору неоткуда взять
  `requiresPro`.
- `CollectionView` упрощён: убраны дублирующие `if isLocked {...}` в
  `onStartTap`/`onHowToTap`, `isLocked` остался только для визуального замка
  на карточке.
- `MagicTricksApp.swift` получил кастомный `init()` — `@StateObject` для
  `flow` теперь зависит от `storeManager`, порядок инициализации пришлось
  развести вручную.

## Процесс
План на 4 чанка (`docs/plans/2026-09-14-coordinator-pro-check-plan.md`),
каждый чанк — отдельный коммит с дифом и стопом на подтверждение. Сборка
(`xcodebuild`, `generic/platform=iOS Simulator`) прошла. PR #89
(`fix/coordinator-pro-check` → `develop`) создан, пока не смержен.

## Грабли
`@StateObject` нельзя проинициализировать значением, которое ссылается на
другое `@StateObject`-свойство того же типа через property-initializer
expression (`self` недоступен там). Понадобился кастомный `init()` у App,
который вручную создаёт `StoreManager` и передаёт его в оба
`_storeManager`/`_flow` через `StateObject(wrappedValue:)`. Паттерн для
проекта не новый — уже используется в девяти других вью с одиночным
`@StateObject`, здесь просто впервые понадобилась зависимость между двумя
`@StateObject` в одном месте.

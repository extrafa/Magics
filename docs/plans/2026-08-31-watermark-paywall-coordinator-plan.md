# Второй путь показа пейвола мимо координатора — план

Task spec: найдено ревью uamoder. `WatermarkView` показывает пейвол сам —
локальный `@State showPaywall` + собственный `.fullScreenCover`, в обход
`AppFlowCoordinator`. Плюс модификатор презентации висит внутри контента
`ToolbarItem` (UIKit хостит его отдельно от иерархии вью), и весь `HStack`
существует только под условием `!hasProAccess && !isDismissed && !isWatermarkHidden` —
после покупки Pro прямо в этом пейволе презентующая вью исчезает вместе с
презентацией, пейвол срывается без анимации.

Фикс из ревью: убрать локальное состояние, звать `flow.openPaywall()`.

## Риск, который надо проверить перед мержем

`WatermarkView` показывается ВНУТРИ уже открытого трюка (`GeoMentalismCitiesView`
доступен только когда `AppFlowCoordinator.activeFlow` уже равен `.trick(...)`,
это тот же fullScreenCover в `CollectionView`, что показывает сам трюк).
`flow.openPaywall()` меняет `activeFlow` на `.paywall` — то есть значение
меняется значение-в-значение (`.trick` → `.paywall`), а не `nil` → значение,
пока модалка уже показана. У `.fullScreenCover(item:)` в SwiftUI это
исторически ненадёжный сценарий: не гарантировано, что смена item на другой
не-nil id корректно переведёт презентацию, а не просто подменит контент без
анимации или не обновится вовсе.

`FullScreenFlow.id` у `.trick`/`.paywall` разные строки, так что теоретически
SwiftUI должен распознать смену идентичности и перепрезентовать — но это
ровно тот случай, где стоит проверить вживую в симуляторе, а не поверить на
слово. Других мест в проекте, где `activeFlow` меняется значение-в-значение,
пока модалка уже открыта, — нет, прецедента нет.

**Проверено вживую (симулятор, автор задачи): переход ломается именно так, как
описано выше — `flow.openPaywall()` меняет `activeFlow` c `.trick` на
`.paywall`, и это ОДНА модалка с разным контентом: трюк закрывается, пейвол
открывается ВМЕСТО него, а не поверх. Дальше пользователь не может вернуться
в трюк, только в Collection. Это не то поведение, которое нужно.**

Правильный дизайн — не переиспользовать `activeFlow`. Пейвол из watermark
должен быть НЕЗАВИСИМЫМ, вложенным `fullScreenCover` поверх уже открытого
трюка: закрыл пейвол — вернулся в трюк, а не в Collection. Отдельное
свойство в координаторе `isPaywallOverlayPresented`, модификатор — на корне
`.trick`-кейса в `AppFlowCoverView` (не на тулбар-хостящем `WatermarkView`,
это и была первая поломка), не зависит от условия видимости самой вотермарки.

## Чанк 1 — AppFlowCoordinator.swift

Новое `@Published var isPaywallOverlayPresented = false` — отдельно от
`activeFlow`, чтобы не путать «сменить весь экран» с «показать поверх и дать
вернуться».

## Чанк 2 — WatermarkView.swift

- Убрать `@State private var showPaywall`, `.fullScreenCover(isPresented:)`.
- Добавить `@EnvironmentObject private var flow: AppFlowCoordinator`.
- Кнопка «Free Trial» по тапу ставит `flow.isPaywallOverlayPresented = true`.

## Чанк 3 — AppFlowCoverView.swift + CollectionView.swift

- `AppFlowCoverView` получает `@EnvironmentObject private var flow: AppFlowCoordinator`
  и вешает `.fullScreenCover(isPresented: $flow.isPaywallOverlayPresented)` на
  `NavigationStack` в кейсе `.trick` — контент: `OBPaywallScreen(onDismiss: { flow.isPaywallOverlayPresented = false })`.
  Модификатор на корне, переживает любые изменения `store.hasProAccess` внутри.
- `CollectionView.swift`: `.environmentObject(flow)` при презентации
  `AppFlowCoverView` — без этого `AppFlowCoverView` не увидит координатор
  (сейчас там только `.environmentObject(store)`).

## Чанк 4 — живая проверка

Собрать, прогнать в симуляторе: открыть GeoMentalism → зайти в город → тапнуть
по вотермарке → убедиться, что пейвол показывается ПОВЕРХ трюка (трюк не
закрывается) → закрыть пейвол → убедиться, что видно тот же трюк, не Collection.

## Чанк 5 — вотермарка без Liquid Glass (не по исходной задаче, но малое и рядом)

**Проверено.** На симуляторе доступен только рантайм iOS 26, сравнить вживую
со старой версией нельзя — но живой скриншот на iOS 26 показал ровно капсулу
со стеклянным фоном и рамкой, а в коде `WatermarkView` нет ни `.background`,
ни `Capsule`, ни материала — только `.buttonStyle(.plain)`. Значит, этот фон
рисует тулбар iOS 26 (Liquid Glass), а не сам код; без него это будет голый
текст+иконка без фона.

Добавлен `if #available(iOS 26, *) { Color.clear } else { Capsule().fill(.ultraThinMaterial).overlay(Capsule().stroke(Color.grayBorder, lineWidth: 1)) }`
в `.background` вотермарки. На iOS 26 ничего не меняется (проверено
скриншотом до/после), на более старых версиях появится explicit стеклянный
фон, похожий на нынешний.

## Out of scope

- Третий путь из ревью (шаг 6 онбординга, `OBPaywallScreen` как элемент
  `ZStack` в `OnboardingFlowView`) — ревью упоминает его как факт (три
  источника), но конкретную поломку и фикс просит только для watermark.
  Онбординг-пейвол не через координатор архитектурно оправдан: онбординг
  вообще не участвует в `AppFlowCoordinator`'ной системе (идёт до входа в
  `CollectionView`), так что "второй путь" там не баг, а другой домен.

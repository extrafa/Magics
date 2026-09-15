# Прореживание точек DragGesture и live-стрим рисунка — план

Task spec: ревью uamoder. `addPoint` (`PhantomDrawViewModel.swift`) вызывается
на каждый `onChanged` `DragGesture` — до 120 раз в секунду на ProMotion — и
пишет в `@Published var currentStroke` без фильтра по расстоянию. Каждая такая
запись шлёт `objectWillChange` у `PhantomDrawViewModel`, а его наблюдает не
только `Canvas`, но и `body` `PhantomDrawView` целиком (`@StateObject`) — со
`.animation(...)` и toolbar-ом. 10-секундная закорючка — больше тысячи точек
и больше тысячи полных проходов layout/render; на старых устройствах рисование
отстаёт от пальца. Второй эффект: `send` происходит только в `commitStroke`,
получатель не видит рисунок, пока зритель не оторвёт палец.

## Решение (все три пункта из (в) ревью — по согласованию, включая
## опциональный пункт 2)

1. Отбрасывать точку, если она ближе ~2pt к предыдущей — используем уже
   существующий расчёт расстояния в `addPoint`.
2. Слать частичный (ещё не завершённый) stroke раз в ~50мс — новый case
   `.strokeProgress(DrawingStroke)` в `PhantomDrawMessage`, тот же id на всё
   время одного росчерка (переиспользуется и в финальном `.stroke` на
   `commitStroke`).
3. Не пробрасывать `objectWillChange` сессии в `objectWillChange` вью-модели.
   `PhantomDrawReceiverView` наблюдает `PhantomDrawSessionManager` напрямую
   (`@ObservedObject var session`, без `PhantomDrawViewModel` вообще —
   больше он ей не нужен). `PhantomDrawView` (верхний уровень, стейт-машина)
   тоже переходит на прямое наблюдение `session` — своим `@ObservedObject`,
   рядом с `@StateObject viewModel` (тот же паттерн: `init()` пробрасывает
   `viewModel.session` во второй `@ObservedObject`).

## Не входит в объём (осознанно)

Даже после пункта 3 `PhantomDrawView` продолжает держать `@StateObject
viewModel` — а `currentStroke` живёт на самой `viewModel`, так что каждая
(уже прореженная) точка всё равно инвалидирует `body` `PhantomDrawView`
целиком, не только `Canvas`. Полное устранение потребовало бы вынести
рисование в отдельный `ObservableObject`, который наблюдает только
`PhantomDrawSenderView` — это заметно больше, чем «три мелких правки» из
текста ревью, и в этот PR не входит.

## Чанк 1 — PhantomDrawViewModel.swift: прореживание точек

`addPoint`: гвард на `distance < minPointDistance` (именованная константа,
2pt) — новая точка (кроме самой первой в росчерке, где `lastStrokePoint ==
nil`) отбрасывается, если ближе порога. `totalDrawnLength` считается только
для принятых точек.

## Чанк 2 — протокол: PhantomDrawMessage.strokeProgress + троттлинг на sender

- `PhantomDrawModels.swift`: новый case `.strokeProgress(DrawingStroke)`.
- `PhantomDrawViewModel.swift`: `currentStrokeID` генерируется заново в
  начале росчерка (когда `currentStroke` пуст перед добавлением точки),
  переиспользуется и в `.strokeProgress`, и в финальном `.stroke`.
  `lastProgressSentAt` + именованная константа интервала (~50мс, `0.05`) —
  после каждой принятой точки шлём `.strokeProgress`, если с прошлой
  отправки прошло достаточно времени.

## Чанк 3 — receiver: приём и отрисовка live-preview

- `PhantomDrawSessionManager.swift`: `@Published var inProgressStroke:
  DrawingStroke?`. В свитче `receiveLoop`: `.strokeProgress` → кладём в
  `inProgressStroke`; `.stroke` → как раньше добавляем в `receivedStrokes`,
  плюс сбрасываем `inProgressStroke = nil` (черновик заменился финальным);
  `.clear`/`.sync` — тоже сбрасывают `inProgressStroke`.
- `PhantomDrawReceiverView.swift`: `Canvas` дополнительно рисует
  `session.inProgressStroke`, если есть; плейсхолдер "Waiting for
  drawing..." скрывается и на пустых `receivedStrokes`, но живом
  `inProgressStroke`.

## Чанк 4 — разрыв objectWillChange forwarding

- `PhantomDrawViewModel.swift`: убрать `sessionCancellable`/форвардинг в
  `init()` — сессия больше не форвардит свой `objectWillChange` наружу.
- `PhantomDrawReceiverView.swift`: `@ObservedObject var session:
  PhantomDrawSessionManager` вместо `viewModel: PhantomDrawViewModel`,
  внутри — `session.receivedStrokes`/`session.inProgressStroke`/
  `session.connectionState` напрямую.
- `PhantomDrawView.swift`: добавить `@ObservedObject private var session:
  PhantomDrawSessionManager`, инициализировать в `init()` из
  `viewModel.session` (`_session = ObservedObject(wrappedValue:
  viewModel.session)`), `state`/`pairingCode` читать через `session`
  напрямую. `connectedView` передаёт `PhantomDrawReceiverView(session:
  session)` вместо `viewModel`.

## Чанк 5 — сборка + живая проверка

Обычное подключение sender/receiver, рисование на sender-е — расстояние
между принятыми точками не меньше ~2pt, receiver должен видеть линию
вживую (не только после отрыва пальца), после отрыва — линия остаётся
такой же (финальный stroke заменяет preview без "скачка"). Проверить, что
подключение/бейдж имени по-прежнему работают после разрыва forwarding.

## Итог живой проверки: найдено и исправлено сверх исходного плана

Чанк 4 (план выше) описывал `@ObservedObject session`, инициализированный
из `viewModel.session` внутри `init()` — на практике это оказалось багом:
`init()` вызывается на каждый ререндер, `@ObservedObject` (в отличие от
`@StateObject`) не защищён от пересоздания — `session` рассинхронизировался
с реальной (используемой `viewModel`) сессией уже после первого ререндера,
из-за чего подключение переставало отражаться в UI. Исправлено: `session`
тоже стал отдельным `@StateObject` в `PhantomDrawView`, `PhantomDrawViewModel`
принимает его через DI (`init(session:)`) вместо создания внутри себя.

Дополнительно по итогам живой проверки на реальных устройствах:

- **Нав-тайтл "Phantom Draw" убран у `PhantomDrawView`** — мелькал на белом
  холсте sender-а; у receiver-а свой `.navigationTitle` остался отдельно.
- **`ExitHintView` у sender-а** — был приклеен через `.overlay(alignment:
  .topLeading)`, из-за вложенности во view с уже настроенным nav bar
  съезжал ниже статус-бара. Тот же воркэраунд, что в `GeoMentalismView`
  (`statusBarHeight` + `.ignoresSafeArea(edges: .top)`), только считается
  один раз в `.onAppear` в `@State`, а не пересчитывается на каждый рендер.
- **`results.first` у `NWBrowser` — реальный баг, не только гипотетический
  (вернулись к находке ревью #47)**: на устройстве обнаружены две Bonjour
  записи одновременно (`_phantomdraw._tcp`, без кода в типе/имени), код
  проверяется только на уровне PSK/TLS уже после TCP-коннекта. Ни TXT-запись
  (не резолвилась, `metadata=<none>` в логах), ни код в service type
  (`NoAuth` — iOS требует статически перечислять типы в `NSBonjourServices`)
  не сработали. Финальное решение: receiver подключается **параллельно ко
  всем** найденным записям и оставляет ту, что реально дошла до `.ready`
  (несовпадающий код проваливает PSK-handshake за доли секунды).
- **Разрыв соединения не долетал до receiver-а** — баг в свежей логике гонки
  кандидатов: `guard connection == nil` не пропускал случай, когда падало
  именно активное (уже установленное) соединение. Исправлено.
- **Race condition при `teardown()` во время гонки** — асинхронный
  `.cancelled`-колбэк от уже отменённого кандидата мог прилететь после
  `stop()` и откатить `connectionState` обратно в `.searching`. Добавлена
  проверка принадлежности `candidateConnections` перед реакцией.
- **`activate(_:)` → `activateIncomingConnection(_:)`**: после перехода
  receiver-а на гонку кандидатов эта функция вызывается только из
  sender-пути (`newConnectionHandler`) — `switch currentRole` внутри стал
  мёртвым кодом, убран вместе с самим `currentRole`/`CurrentRole`.
- **Кнопка trash у sender-а**: убран `.disabled(...)` (всегда активна),
  фиксированный чёрный цвет вместо системного адаптивного фона toolbar-кнопки
  (iOS 26 Liquid Glass фон некорректно долго подстраивался под белый холст).
- **Дедупликация**: кнопки "Connect" и "Try Again" в `PhantomDrawView`
  имели идентичную структуру — вынесены в `primaryButton(_:disabled:action:)`.

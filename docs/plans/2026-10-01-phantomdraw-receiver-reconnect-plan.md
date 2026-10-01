# PhantomDraw: реальное переподключение приёмника (мага)

## Задача

Сейчас при обрыве активного соединения у receiver'а (экран мага)
`PhantomDrawSessionManager` сразу переводит `connectionState` в `.idle` —
экран пропадает, маг оказывается на выборе роли, `receivedStrokes` теряются
вместе с экраном. Бейдж "Reconnecting..." на `PhantomDrawReceiverView` и
флаг `isReconnecting` существуют, но недостижимы: `isReconnecting = true`
сейчас выставляется только в ветке отправителя (`activateIncomingConnection`),
никогда — в ветке получателя.

Нужно: при обрыве активного соединения получатель остаётся на экране,
автоматически ищет того же отправителя заново по сохранённому коду, и либо
восстанавливает связь в течение тайм-аута, либо после тайм-аута показывает
понятный экран ошибки с Retry.

## Acceptance criteria

1. При обрыве активного соединения `connectionState` остаётся `.connected`
   (экран не пропадает), `isReconnecting` становится `true`.
2. Автоматически перезапускается поиск того же отправителя
   (`startBrowsing(code: receiverCode)`).
3. Если переподключение происходит до истечения тайм-аута — связь
   восстанавливается, `isReconnecting` снимается, актуальный рисунок
   приходит через уже работающий безусловный `.sync`.
4. Если тайм-аут истёк — `connectionState` переходит в `.failed` (экран
   "Could Not Connect" с Retry), а не молча в `.idle`.
5. Логика обёрнута так, что её можно покрыть юнит-тестами без реальной сети
   — для этого потребуется минимальная абстракция поверх `NWConnection` и
   инъекция таймера (переиспользуя уже существующий `DelayedActionScheduling`
   из `AppFlowCoordinator`).
6. Поведение отправителя (sender) не меняется — он уже корректно шлёт
   безусловный `.sync` и уже готов принять новое входящее соединение во
   время переподключения.
7. Ручная проверка на двух устройствах/симуляторах: кратковременный обрыв
   Wi-Fi у получателя не выбрасывает мага на выбор роли, рисунок на месте
   после восстановления.

## Чанки

### Чанк 1 — Тестируемость: абстракция над соединением + инъекция таймера

Без изменения поведения, только рефакторинг:

- `protocol PhantomDrawConnectable: AnyObject { var endpoint: NWEndpoint { get }; func cancel() }`,
  `NWConnection` соответствует ему через extension.
- `connection: NWConnection?` → `connection: (any PhantomDrawConnectable)?`,
  `candidateConnections: [NWConnection]` → `[any PhantomDrawConnectable]`.
- `handleCandidateState(_ state: NWConnection.State, for conn: NWConnection)`
  → параметр `conn: any PhantomDrawConnectable`, убрать `private` (нужен
  доступ из тестов через `@testable import`).
- Добавить `scheduler: DelayedActionScheduling` параметром `init`
  (дефолт `DispatchQueueScheduler()`), сохранить как `private let`.
- Билд зелёный, существующее поведение не меняется.

### Чанк 2 — Поведение переподключения

- В ветке `.failed`/`.cancelled` для уже активного соединения (сейчас:
  `connection = nil; connectionState = .idle; return`) — заменить на:
  `connection = nil`, `isReconnecting = true`, перезапуск
  `startBrowsing(code: receiverCode)`, планирование тайм-аута через
  `scheduler.schedule(after: Self.reconnectTimeout) { ... }`.
- В замыкании тайм-аута — проверять, не восстановилась ли уже связь
  (`isReconnecting` всё ещё `true` и `connection == nil`) перед тем как
  переводить `connectionState` в `.failed`; если уже подключились —
  ничего не делать (без отдельного механизма отмены).
- В ветке `.ready` (успешное переподключение) — `isReconnecting = false`
  уже обрабатывается существующим кодом, достаточно, чтобы замыкание
  тайм-аута само себя отключало через проверку состояния.
- Тайм-аут: 15 секунд (между существующими 10 сек на отдельное TCP-соединение
  и достаточно, чтобы пережить случайный обрыв, не превращаясь в вечное
  ожидание).

### Чанк 3 — Тесты

- `MockPhantomDrawConnection: PhantomDrawConnectable` и приватный
  `FakeScheduler: DelayedActionScheduling` (хранит незапущенные действия,
  тест запускает их вручную) в `PhantomDrawSessionManagerTests.swift`.
- Тесты:
  - обрыв активного соединения → `isReconnecting == true`,
    `connectionState` остался `.connected`, браузер перезапущен;
  - успешное переподключение до тайм-аута → `isReconnecting == false`,
    `connectionState == .connected` с новым peer;
  - тайм-аут истёк, переподключения не было → `connectionState == .failed`.

### Чанк 4 — Ручная проверка

- Собрать, запустить на двух устройствах/симуляторах, оборвать связь
  у получателя (выключить Wi-Fi на несколько секунд), убедиться что бейдж
  появляется и сам пропадает после восстановления, а рисунок не теряется.
- Если тайм-аут истёк — убедиться, что показывается экран "Could Not
  Connect" с рабочим Retry.

---

Строки с `///` — твои правки, учту при следующем проходе.

# PhantomDraw: вынести кадрирование+кодек в чистый тип, покрыть тестами

## Проблема

Протокол обмена (4-байтный big-endian префикс длины + JSON `PhantomDrawMessage`)
живёт в private `sendFramed`/`receiveLoop`, оба принимают `NWConnection`.
`@testable import` до private не даёт, реальный NWListener в юнит-тесте не
поднять — самая хрупкая часть фичи непроверяема.

Замечание: `receiveLoop` уже использует `loadUnaligned` (не `load`), и при
некорректной длине уже делает `conn.cancel()` — эти два пункта из ревью
устарели. Актуальна только непроверяемость.

## Чанки

1. Новый `PhantomDrawFraming.swift` в `Sources/Services/PhantomDraw/`:
   ```
   enum PhantomDrawFraming {
       static let maxBodyLength: UInt32 = 1_000_000
       static func encode(_ message: PhantomDrawMessage) throws -> Data   // header + body
       static func bodyLength(header: Data) -> UInt32?                     // nil если размер != 4 / вне (0, max)
       static func decode(_ body: Data) throws -> PhantomDrawMessage
   }
   ```
   Плюс `Equatable` на `PhantomDrawMessage` (все ассоциированные значения уже
   Equatable — синтезируется). `sendFramed`/`receiveLoop` в
   `PhantomDrawSessionManager` делегируют в этот тип, поведение не меняется.
2. Новый `PhantomDrawFramingTests.swift`: round-trip encode → (снять header) →
   decode даёт равное сообщение; header ровно 4 байта и совпадает с длиной
   тела; мусорный/нулевой/огромный header → `bodyLength` nil; `.clear` и
   `.sync([])` переживают round-trip.
3. Сборка + прогон новых и всех тестов.

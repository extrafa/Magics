# Частичный выход из @MainActor: nonisolated + Task { @MainActor in }

Использовано в `PhantomDrawSessionManager` (PR #101) — класс целиком
`@MainActor`, но decode сетевых кадров нужно было увести с главного потока,
не переписывая весь lifecycle соединения на другую модель изоляции.

## Приём

1. Метод/статическая константа, которые не трогают `@Published`/хранимые
   свойства класса напрямую, помечаются `nonisolated` — их можно звать с
   любой очереди/потока:
   ```swift
   nonisolated private func receiveLoop(_ conn: NWConnection) { ... }
   nonisolated func sanitized(_ stroke: DrawingStroke) -> DrawingStroke? { ... }
   nonisolated static let maxStrokes = 500
   ```
2. Внутри такого метода, когда всё же нужно записать в `@MainActor`-состояние
   (например `@Published`), это делается явным хопом:
   ```swift
   Task { @MainActor [weak self] in
       guard let self else { return }
       self.receivedStrokes.append(sanitized)
   }
   ```
3. Объект, чьи колбэки реально хотят гонять этот `nonisolated`-код (в этом
   случае — `NWConnection`), стартуется на отдельной `DispatchQueue`, а не на
   `.main`: `conn.start(queue: netQueue)`.

## Почему не `DispatchQueue.main.async`

`DispatchQueue.main.async { ... }` внутри колбэка, который сам объект вызывает
на `.main`, компилируется без предупреждений в Swift 5, но это ложная
корректность: она держится ровно на том, что объект настроен на `.main`.
Поменяли очередь колбэка на фоновую — обращение к `@MainActor`-состоянию
внутри `DispatchQueue.main.async` всё ещё "работает" (хопает на main), но само
условие `guard let self` и любые обращения к состоянию ДО хопа выполняются уже
не на main, и компилятор об этом не скажет (в Swift 6 language mode — уже
скажет, отсюда предупреждения `"this is an error in the Swift 6 language
mode"`, которые встречались в проекте и до этого PR в других файлах).
`Task { @MainActor in }` корректен независимо от того, с какой очереди его
запустили.

## Масштаб фикса

Не весь класс уводился на другую модель изоляции — только объект, который
реально в hot path (`connection`, не `listener`/`browser` — они handshake/
discovery, не производительность). Это резко снижает риск: не пришлось
разбирать, что из lifecycle-состояния (`candidateConnections`, таймауты,
переключение `connection`) можно безопасно мутировать вне MainActor.

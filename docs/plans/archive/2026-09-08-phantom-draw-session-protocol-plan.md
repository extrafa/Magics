# PhantomDrawSessionManager: протокол для DI в PhantomDrawViewModel

## Проблема

`PhantomDrawSessionManager` — сетевой сервис на Network.framework (NWListener/
NWBrowser/NWConnection), но лежит в `PhantomDraw/ViewModel/`, а не в
`Sources/Services`, где уже есть `Store`. `PhantomDrawViewModel.session`
типизирован конкретным классом — протокола нет, подменить транспорт в тесте
или превью нельзя.

## Чанки

1. **Протокол `PhantomDrawSessioning`** — только то, что реально использует
   `PhantomDrawViewModel` (не то, что использует View — Views держат свой
   `@StateObject session` конкретного типа для `@Published`-биндингов, их не
   трогаем):
   ```swift
   @MainActor
   protocol PhantomDrawSessioning: AnyObject {
       var connectionState: PhantomDrawConnectionState { get set }
       var onNewConnection: (() -> Void)? { get set }

       func startAsReceiver(code: String)
       func startAsSender()
       func send(_ message: PhantomDrawMessage)
       func stop()
   }
   ```
   `PhantomDrawSessionManager: PhantomDrawSessioning` — добавить conformance,
   методы/свойства уже подходят по сигнатурам.

2. **`PhantomDrawViewModel`**: `let session: PhantomDrawSessionManager` →
   `let session: PhantomDrawSessioning`, `init(session:)` принимает протокол.
   `PhantomDrawView.swift` передаёт туда свой конкретный `session` как раньше
   (конкретный тип соответствует протоколу) — изменений в View не требуется.

3. Сборка + быстрая ручная проверка, что Phantom Draw по-прежнему коннектится
   и рисует (само поведение не меняется, чисто типизация).

## Не входит в объём (осознанно)

- **Физический перенос файла в `Sources/Services/PhantomDraw/`** — этот
  проект использует классический `project.pbxproj` (явные `PBXFileReference`
  + `PBXGroup`, не file-system-synchronized groups), поэтому перенос файла
  между группами требует ручной правки pbxproj — хрупко, легко сломать сборку
  правкой руками. Если нужно — лучше сделать перетаскиванием в самом Xcode
  (это одна операция и правит структуру корректно), не через меня. Сообщаю
  отдельно, не блокирую этим протокольный фикс.
- Полноценная протокольная абстракция для Views (`ObservableObject`-протокол
  под `@StateObject`) — не нужна, Views и так работают с конкретным типом
  напрямую и это нормально (реактивные `@Published`-биндинги для UI не нужно
  подменять в тестах).

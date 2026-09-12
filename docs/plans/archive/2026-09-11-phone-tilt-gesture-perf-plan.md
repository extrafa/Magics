# PhoneTiltGestureManager: дешёвый датчик вместо device motion

## Проблема (подтверждено по коду `PhoneTiltGestureManager.swift`)

- Используется только `motion.gravity.z` (строка 77), но запущен
  `startDeviceMotionUpdates` — сенсорный фьюжн акселерометр+гироскоп+
  магнитометр, самый дорогой режим CoreMotion. Гироскоп крутится всё время
  ожидания жеста (`waitForScreenDownGesture` может ждать десятки секунд).
- 20 Гц (`deviceMotionUpdateInterval = 0.05`), и на КАЖДЫЙ сэмпл — новый
  `Task { @MainActor in ... }` (строки 78-80) ради сравнения одного `Double` с
  порогом — 20 аллокаций Task и переключений на главный поток в секунду.
- `OperationQueue()` создаётся заново на каждый вызов `startMonitoring`
  (строки 70-72), старая не переиспользуется.
- Бонус, найден при чтении: `monitoringTask` (строка 9) объявлен, в
  `stopMonitoring()` вызывается `.cancel()`/`= nil`, но нигде не
  присваивается — мёртвый код, эти строки всегда работают с `nil`.

## Решение

1. `startDeviceMotionUpdates` → `startAccelerometerUpdates`,
   `motion.gravity.z` → `data.acceleration.z`. В покое (а жест — это именно
   удержание в покое) сырое ускорение по Z практически равно гравитации;
   отдельный гироскоп/магнитометр не нужны. `isDeviceMotionAvailable` →
   `isAccelerometerAvailable`, `stopDeviceMotionUpdates` →
   `stopAccelerometerUpdates`.
2. `deviceMotionUpdateInterval = 0.05` (20 Гц) → `accelerometerUpdateInterval
   = 0.1` (10 Гц) — порог держится ≥ секунды, чаще не нужно.
3. `OperationQueue` — в `let`-свойство класса, создаётся один раз, а не на
   каждый `startMonitoring`.
4. Сравнение порога — прямо в фоновом блоке колбэка (капчур локальных
   `screenDownSince`/`didFire`, очередь serial, `maxConcurrentOperationCount
   = 1` — мутировать локальные переменные из одного и того же серийного
   потока безопасно). `Task { @MainActor }` создаётся один раз — только когда
   жест реально сработал, а не на каждый сэмпл. `screenDownSince` перестаёт
   быть полем класса (не нужно синхронизировать с main actor на каждый тик).
5. Заодно убрать мёртвый `monitoringTask`.

Логика успеха/отмены (кто кого резолвит, `stopMonitoring()` резолвит `false`,
успешное срабатывание явно захватывает `handler` до `stopMonitoring()`)
сохраняется один в один — меняется только ГДЕ считается сэмпл (фон, без
хопа) и КОГДА хопаем на main actor (один раз, по факту срабатывания).

## Чанки

1. Переписать `PhoneTiltGestureManager.swift` по пунктам 1-5 выше. Сборка +
   тесты.
2. Ручная проверка на устройстве: секретный жест «экраном вниз» в
   TimeControl всё ещё срабатывает по истечении `screenDownHoldDuration`, не
   вызывает по неверным поворотам/тряске.

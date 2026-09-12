# Scheduled vibrations can't be cancelled — plan

Task spec: см. переписку в чате (2026-08-24). Bug: `HapticScheduler.schedule(after:action:)`
использует `DispatchQueue.main.asyncAfter`, ничего не сохраняет для отмены. Нигде
в модуле Haptics нет метода отмены вообще. Два подтверждённых сценария: (1) уход
с экрана трюка во время сигнала — вибрации продолжают идти на другом экране;
(2) повторный запуск сигнала до завершения первого — расписания накладываются.

Решение — вариант А (глобальная отмена по счётчику поколений), обсуждено и
согласовано в чате: `HapticManager` — обёртка над одним физическим ресурсом
устройства (Taptic Engine), не универсальный планировщик независимых задач,
поэтому "отменить всё" — корректная операция для этого домена, а не срезание
угла (по аналогии с `AVSpeechSynthesizer.stopSpeaking()`).

## Чанк 1 — HapticScheduler.swift + HapticProtocols.swift

`HapticScheduler`: приватный `generation: Int = 0`. `schedule(after:action:)`
запоминает текущее значение при постановке, сверяет перед выполнением через
`[weak self]`; несовпадение — action не вызывается. Новый метод `cancelAll()`
инкрементит `generation`. Остальные методы (`scheduleCompletion`, `scheduleImpact`,
`scheduleImpactSequence`, `scheduleTimeDigit`) не меняются — все и так идут через
`schedule`.

`HapticScheduling` (протокол): добавить `func cancelAll()`.

## Чанк 2 — HapticManager.swift

Новый метод `func cancelPendingHaptics() { scheduler.cancelAll() }`.
`playCount` и `playTimeValue` зовут `cancelPendingHaptics()` в самом начале,
до постановки нового расписания — фиксирует сценарий "наложение при повторном
запуске" независимо от UI-гардов конкретного экрана.

## Чанк 3 — HapticProtocols.swift (продолжение) + ColorSenseViewModel.swift + TimeControlSignalTransmitter.swift

Добавить `func cancelPendingHaptics()` в `CountHapticPlaying` и `TimeHapticPlaying`.

`ColorSenseViewModel.cancel()` — добавить вызов `haptics.cancelPendingHaptics()`.
`TimeControlSignalTransmitter.cancel()` — добавить вызов `haptics.cancelPendingHaptics()`.
У обоих `cancel()` уже подключён к `onDisappear` соответствующих View — новых
UI-правок в этих двух местах не требуется.

## Чанк 4 — HapticTrainingViewModel.swift + HapticTrainingView.swift

У `HapticTrainingViewModel` сейчас нет вообще никакой очистки. Добавить
`func cancel() { countHaptics.cancelPendingHaptics() }`. В `HapticTrainingView`
добавить `.onDisappear { viewModel.cancel() }` (сейчас `onDisappear` там нет).

## Чанк 5 — HapticSettingsScreen.swift

Тоже нет очистки. Добавить `.onDisappear { haptics.cancelPendingHaptics() }`
(экран использует `@State`, не ObservableObject-вьюмодель — отмена вызывается
напрямую на `haptics`).

## Out of scope
- Токенизированная (per-call) отмена — рассмотрели как альтернативу, отклонили
  в пользу простоты, раз в приложении физически один активный экран трюка.
- `playSuccessNotification` — immediate-вызов, не идёт через scheduler, не
  затронут этим багом.

# Экран не гаснет во время выступления

## Проблема

`UIApplication.shared.isIdleTimerDisabled` нигде в проекте не выставляется
(подтверждено `rg`). У трёх трюков есть фаза, когда телефон долго лежит без
касаний, а именно в этот момент идёт передача:

- `TimeControlView` — пока `viewModel.isRunning`, идёт вибро-передача;
- `PhantomDrawReceiverView` — весь экран целиком ждёт штрихи от зрителя;
- `MagicGalleryPerformView` — весь экран целиком ждёт жест зрителя.

Стандартный автолок (обычно 30 c) гасит экран посреди этого ожидания.
`scenePhase`-обработчик в `TimeControlView` (`handleSceneBecameActive`) лечит
последствие (перезапускает haptic engine после возврата), а не причину.

## Решение

Общий ref-counted лок вместо точечных `onAppear`/`onDisappear` в каждом
экране — так безопаснее держать несколько экранов/состояний одновременно
(не нужно вручную следить, кто последний снял флаг) и легче не забыть
снять его при выходе.

`MagicTricks/Sources/Shared/Motion/IdleTimerLock.swift`:

```swift
@MainActor
enum IdleTimerLock {
    private static var holderCount = 0

    static func acquire() {
        holderCount += 1
        UIApplication.shared.isIdleTimerDisabled = true
    }

    static func release() {
        guard holderCount > 0 else { return }
        holderCount -= 1
        UIApplication.shared.isIdleTimerDisabled = holderCount > 0
    }
}
```

Два вьюмодификатора поверх него в том же файле:

- `.keepsScreenAwake()` — держит лок всё время, пока экран на месте
  (`onAppear`/`onDisappear`). Для `PhantomDrawReceiverView` и
  `MagicGalleryPerformView`.
- `.keepsScreenAwake(while: Bool)` — держит лок, только пока условие истинно
  (`onChange` + гарантированный release в `onDisappear`, если условие было
  true на момент ухода с экрана). Для `TimeControlView`, привязано к
  `viewModel.isRunning` — не держим экран во время простой настройки
  таймера, только во время самой передачи.

Оба модификатора идемпотентны (внутренний `@State private var isHolding`),
чтобы двойной `acquire`/`release` не сбивал счётчик.

## Почему не точечно в каждом экране

Три копии одинаковых `onAppear { UIApplication.shared.isIdleTimerDisabled = true }`
+ `onDisappear { ... = false }` из сниппета ревью работают только пока
экраны не пересекаются. Общий счётчик безопаснее и это один переиспользуемый
модификатор в духе уже существующего `.exitHint()`.

## Чанки

1. `IdleTimerLock` + `keepsScreenAwake()`/`keepsScreenAwake(while:)` в новом
   файле `Shared/Motion/IdleTimerLock.swift`. Сборка.
2. Подключить `.keepsScreenAwake(while: viewModel.isRunning)` в
   `TimeControlView`. Сборка.
3. Подключить `.keepsScreenAwake()` в `PhantomDrawReceiverView` и
   `MagicGalleryPerformView`. Сборка + тесты.
4. Ручная проверка: включить трюк, дождаться автолока дольше системного
   таймаута — экран не должен погаснуть, пока экран трюка на месте; выйти —
   автолок должен снова работать как обычно.

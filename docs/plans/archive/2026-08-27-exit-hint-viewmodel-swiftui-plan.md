# ExitHintViewModel тянет Binding и withAnimation — план

Task spec: найдено ревью uamoder. `ExitHintViewModel.configurePresentation` принимает
`Binding<Bool>`, а `withAnimation` вызывается прямо из VM в 6 местах (48, 63, 73, 90,
104, 110). Анимация и Binding — забота View, не VM. Из-за этого VM невозможно
протестировать без SwiftUI и нельзя переиспользовать. Ориентир — `MagicGalleryViewModel`,
где нет ни одного SwiftUI-типа, только чистое состояние + протоколы.

Решение — обсуждено и подтверждено в чате: полное разделение. Timing-логика
(`Task.sleep`-последовательности auto-fade и flash) остаётся в VM как чистая,
тестируемая последовательность мгновенных присваиваний `@Published`-свойств —
никакого `withAnimation` внутри. Конкретную кривую анимации для каждого перехода
View выбирает сама через `.animation(_:value:)`, вычисляя её по ЦЕЛЕВОМУ значению
свойства (например: `hintOpacity == .dimmed` → `.easeOut(duration: 2.2)`,
`hintOpacity == .hidden` → `.easeOut(duration: 0.8)`). Это позволяет держать разные
длительности для одного и того же свойства на разных этапах, не пряча анимацию
внутри VM. Общие пороговые значения (0.18, 0 и т.д.) выносятся в именованные
константы, чтобы VM и View не дублировали "магические числа" independently.

`Binding<Bool>` в `configurePresentation` заменяется на completion-closure —
в файле уже есть точно такой установленный паттерн (`confirmHintDismiss(onConfirmExit:)`).

## Чанк 1 — ExitHintViewModel.swift

- Убрать `import SwiftUI` (оставить `import Foundation`; если `@Published`/`CGFloat`
  перестанут резолвиться — добавить нужный минимальный импорт, но не SwiftUI).
- Добавить `enum OpacityStep { static let visible = 1.0; static let dimmed = 0.18;
  static let hidden = 0.0 }` — общие константы для VM и View.
- `configurePresentation(isVisible: Bool, isHintVisible: Binding<Bool>)` →
  `configurePresentation(isVisible: Bool, onAutoFadeComplete: @escaping () -> Void)`.
  Тело — та же `Task`-последовательность, но без `withAnimation`: просто
  `hintOpacity = OpacityStep.dimmed`, затем `= OpacityStep.hidden`, в конце
  `onAutoFadeComplete()` вместо `isHintVisible.wrappedValue = false`.
- `confirmHintDismiss(onConfirmExit: @escaping () -> Void)` →
  `confirmHintDismiss()` — просто `didLearnExitHint = true; isConfirmAlertPresented = false`,
  без `withAnimation`/колбэка (сам колбэк и обёртку анимацией берёт на себя View,
  вызывающая этот метод).
- `holdStarted()`/`holdCancelled()` — убрать `withAnimation`, оставить только
  присваивание `holdScale`.
- `flashHint()` — убрать оба `withAnimation`, оставить только присваивания
  `flashBrightness` внутри `Task`-цикла.

## Чанк 2 — ExitHintView.swift

- Добавить вычисляемые `hintOpacityAnimation: Animation?`, `holdScaleAnimation: Animation`,
  `flashBrightnessAnimation: Animation` — каждая выбирает кривую/длительность по
  текущему значению соответствующего свойства VM (сохраняя те же цифры, что были
  в удалённых `withAnimation` вызовах).
- Применить их через `.animation(_:value:)` рядом с `.opacity`/`.scaleEffect`/`.brightness`.
- `onAppear`/`onChange(of: isVisible)`: заменить `viewModel.configurePresentation(isVisible:isHintVisible:)`
  на новую сигнатуру с closure (`{ isVisible = false }`).
- Кнопка `"common.gotIt"` первого алерта: обернуть `viewModel.confirmHintDismiss()` +
  `isVisible = false` + `dismiss()` в `withAnimation(.easeOut(duration: 0.22))` —
  ровно то же самое место, где анимация была раньше, просто на уровне View.

## Out of scope

- Юнит-тесты на `ExitHintViewModel` — тестовый таргет проекта всё ещё не собирается
  из-за отдельной, не связанной проблемы (6 отсутствующих файлов в pbxproj),
  упомянутой ранее в сессии. Делаем VM тестируемым архитектурно, тесты сами не пишем.

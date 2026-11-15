# ExitHintGestureState — глобальный синглтон с колбэками — план

Task spec: найдено ревью uamoder. `ExitHintGestureState.shared` — изменяемое
глобальное состояние: `globalRect`, `isTrainingActive` и пять колбэков, которые
пишет `ExitHintView`, а читают UIKit-жесты в `ExitHintGestureCaptureView`
(строки 82, 85, 90, 93, 100, 130, 135, 136, 156, 160, 166, 176, 178, 184).

Конкретный вред: два экрана с ExitHint одновременно затрут колбэки друг друга
(ничто не мешает второму `.onAppear` перезаписать замыкания первого, пока
оба экрана существуют, например во время transition-анимации); класс не
изолирован статически в местах чтения — UIKit-колбэки распознавателей жестов
формально не `@MainActor`, хотя фактически всегда выполняются на главном
потоке (тот же паттерн, что уже чинили в `PhantomDrawSessionManager` в этой
сессии); плюс это в принципе не тестируется, раз состояние — глобальный
синглтон, а не инжектируемая зависимость.

Решение — обсуждено и подтверждено в чате, взят ровно предложенный ревью
подход: `PreferenceKey` для передачи рамки вверх по дереву SwiftUI (от
`hintOverlay`, где она измеряется, до `ExitHintView`, который её читает) и
`EnvironmentObject` для колбэков + `isTrainingActive` (общая конфигурация,
раздаваемая вниз по поддереву). `ExitHintGestureState` удаляется целиком.

Ключевой архитектурный эффект: `EnvironmentObject`-объект создаётся как
`@StateObject` персонально для каждого экземпляра `ExitHintView` — то есть
одновременное существование двух экранов с ExitHint больше не может привести
к перезаписи чужих колбэков, потому что у каждого своя копия. Заодно
`.onDisappear`, который сейчас вручную обнуляет пять полей синглтона,
становится не нужен — SwiftUI сам освобождает `@StateObject` вместе с view.

## Чанк 1 — ExitHintConfiguration.swift (новые типы вместо синглтона)

- Удалить `final class ExitHintGestureState` целиком.
- Добавить `struct ExitHintRectPreferenceKey: PreferenceKey` (`defaultValue = .zero`,
  `reduce` берёт `nextValue()`).
- Добавить `final class ExitHintGestureCoordinator: ObservableObject` с теми же
  полями, что были в `ExitHintGestureState`, кроме `globalRect` (она уходит
  через PreferenceKey, а не через этот объект): `isTrainingActive`,
  `onTrainingHold`, `onOutsideTap`, `onHoldStarted`, `onHoldCancelled`, `onSwipe`.

## Чанк 2 — ExitHintGestureCaptureView.swift

- `ExitHintGestureCaptureView` (и обёртка `ExitHintLongPressModifier` +
  `exitHintLongPressEnabled`) получают новый параметр `rect: CGRect`,
  прокидываемый в `Coordinator` через `updateUIView` (по тому же паттерну,
  что уже используется для `onExit`).
- `Coordinator` получает `@EnvironmentObject`-подобный доступ: сама структура
  `ExitHintGestureCaptureView` объявляет `@EnvironmentObject var gestureCoordinator:
  ExitHintGestureCoordinator`, значение прокидывается в `Coordinator` через
  `updateUIView` в отдельное хранимое свойство (Coordinator — обычный
  `NSObject`, `@EnvironmentObject` напрямую в нём недоступен).
- Все обращения `ExitHintGestureState.shared.X` внутри `Coordinator` меняются
  на `self.rect` / `self.gestureCoordinator?.X`.
- `GestureInstallerView.point(inside:with:)` (обычный `UIView`, тоже вне
  SwiftUI-дерева) получает собственное хранимое `var isTrainingActive = false`,
  обновляемое из `updateUIView` — тем же способом, что и `Coordinator`.

## Чанк 3 — ExitHintView.swift

- `@StateObject private var gestureCoordinator = ExitHintGestureCoordinator()`
  — персональный экземпляр на весь View.
- `@State private var hintGlobalRect: CGRect = .zero`.
- `hintOverlay`'s background `GeometryReader` вместо записи в синглтон
  публикует `.preference(key: ExitHintRectPreferenceKey.self, value: proxy.frame(in: .global))`.
- На теле `ExitHintView` добавить `.onPreferenceChange(ExitHintRectPreferenceKey.self) { hintGlobalRect = $0 }`.
- `.exitHintLongPressEnabled(onExit:)` → `.exitHintLongPressEnabled(rect: hintGlobalRect, onExit:)`,
  плюс `.environmentObject(gestureCoordinator)` на том же поддереве.
- `syncGestureState()` пишет в `gestureCoordinator.X` вместо `ExitHintGestureState.shared.X`.
- Убрать `.onDisappear`-блок, обнуляющий пять полей синглтона — больше не нужен.

## Out of scope

- Юнит-тесты на новую конфигурацию — тестовый таргет проекта всё ещё не
  собирается из-за отдельной, не связанной проблемы (6 отсутствующих файлов
  в pbxproj), упомянутой ранее в сессии. Делаем код тестируемым архитектурно,
  тесты сами не пишем.
- Сценарий одновременных двух экранов с ExitHint физически не воспроизводим
  прямо сейчас (в приложении показывается один трюк за раз), но фикс всё
  равно устраняет саму возможность класса багов, а не конкретный воспроизводимый случай.

# ViewModel создаётся внутри View без точки инъекции

## Проблема

Экраны создают свою ViewModel конкретным типом прямо в свойстве, без init —
подменить её снаружи (тест, превью, host-экран) негде, хотя сами ViewModel
уже написаны тестопригодно (зависимости в их собственных init опциональны):

- `TimeControlView.swift:12`
- `MagicGalleryView.swift:12`
- `CalculatorPredictionView.swift:12`
- `GeoMentalismCitiesView.swift:11`

`ColorSenseView` уже делает правильно (`init(haptics:)` +
`StateObject(wrappedValue:)`) — переносим тот же паттерн на эти четыре.

## Чанки (один экран = один чанк)

Буквальный пример из ревью (`init(viewModel: X = X())`) не компилируется —
`X()` как default value параметра вызывается в non-isolated контексте
объявления, а VM помечены `@MainActor`. Паттерн: `viewModel: X? = nil` +
`_viewModel = StateObject(wrappedValue: viewModel ?? X())` внутри тела init
(так же как остальные VM в проекте уже делают для своих зависимостей).

1. `TimeControlView`: `init(viewModel: TimeControlViewModel? = nil)`.
2. `MagicGalleryView`: `init(vm: MagicGalleryViewModel? = nil)`.
3. `CalculatorPredictionView`: `init(vm: CalculatorPredictionViewModel? = nil)`.
4. `GeoMentalismCitiesView`: `init(city:, viewModel: GeoMentalismViewModel? = nil)` —
   у неё уже есть `city` в сигнатуре и `@Binding isExitHintVisible`, добавляем
   параметр в общий init.
5. Сборка + быстрая ручная проверка, что все четыре экрана по-прежнему
   открываются нормально (чисто механическая правка, поведение не меняется).

## Не входит в объём (осознанно)

- **`PhantomDrawView`** — у него уже есть свой `init()` (добавлен раньше в
  этой сессии для фикса session-desync), но снаружи viewModel всё равно не
  подставить, так как init сам строит `session` и передаёт его в
  `PhantomDrawViewModel`. Расширять этот init внешним параметром — риск
  ради небольшой пользы: реальная тестируемость алгоритмической логики
  (`addPoint`/`commitStroke`/т.д.) уже достигнута прошлым PR — тест
  строит `PhantomDrawViewModel(session: mockSession)` напрямую, без View.
- Сами unit-тесты на TimeControl/CalculatorPrediction не пишу — просьба
  только про точку инъекции, не про покрытие тестами.

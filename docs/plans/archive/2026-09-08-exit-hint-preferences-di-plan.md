# Экран не должен читать AppPreferences.shared напрямую (ExitHint isVisible)

## Проблема

Пять экранов трюков инициализируют локальный `@State` прямо из синглтона:

```
@State private var isVisible = AppPreferences.shared.isExitHintEnabled
```

- `ColorSenseView.swift:13`
- `TimeControlView.swift:13`
- `CalculatorPredictionView.swift:13`
- `GeoMentalismView.swift:11`
- `PhantomDrawSenderView.swift:11` (тут ещё и имя другое — `exitHintVisible`)

Экран напрямую знает про хранилище настроек, минуя ViewModel. Значение
нельзя переопределить ни в Preview, ни в тесте. Плюс разнобой в имени
(`isVisible` читается как «виден сам экран», а не «видна подсказка»).

## Чанки

1. **Переименование** (5 файлов, без изменения поведения):
   `isVisible` → `isExitHintVisible` в ColorSenseView/TimeControlView/
   CalculatorPredictionView/GeoMentalismView, `exitHintVisible` →
   `isExitHintVisible` в PhantomDrawSenderView.

2. **Протокол**: добавить `var isExitHintEnabled: Bool { get }` в
   `ExitHintPreferenceManaging` (AppPreferences.swift) — `AppPreferences`
   уже физически хранит это свойство, просто открываем его через протокол
   для DI.

3. **Модификатор** `.exitHint(style:)` в модуле ExitHint (новый файл или
   в ExitHintView.swift) — сам владеет `@State` и читает
   `preferences.isExitHintEnabled` (инъекция с дефолтом `AppPreferences.shared`).
   Применить к ColorSenseView, TimeControlView, CalculatorPredictionView —
   у них `ExitHintView` не используется больше нигде в файле, чистая замена.
   Эти три экрана перестают вообще знать про `AppPreferences`.

4. **GeoMentalismView и PhantomDrawSenderView** — оставить явный
   `@State`/`@Binding` (первому нужен шаринг с `GeoMentalismCitiesView`,
   второму — своя доп. отступная логика через `statusBarHeight`), но
   убрать прямое чтение синглтона: значение приходит через
   `init(preferences: ExitHintPreferenceManaging = AppPreferences.shared)`,
   как уже сделано в других экранах проекта (например, ColorSenseView с
   `haptics:`).

5. Сборка + ручная проверка, что подсказка выхода по-прежнему появляется
   на всех пяти экранах.

## Не входит в объём (осознанно)

Полноценная ViewModel для GeoMentalismView ради одного Bool — избыточно,
у экрана сейчас нет своей ViewModel и заводить её только для этого не
стоит риска для уже отлаженной в этой сессии логики позиционирования.
Инъекция через `init` даёт ту же тестируемость с меньшим риском.

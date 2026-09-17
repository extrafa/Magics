# AppFlowCoordinator: шедулер за протоколом + первые тесты

## Проблема

DI (`preferences: AppPreferences`) и вынос `seenTrickIds` в `AppPreferences`
уже сделаны раньше. Осталось два реальных пункта: `recordTrickClose()`
использует голый `DispatchQueue.main.asyncAfter(deadline: .now() + 0.7)` —
тест либо усыпляется на секунду, либо не может проверить показ rateApp
синхронно; и тестов на координатор нет вообще, хотя логика (счётчик,
порог, снуз, seen/unseen) нетривиальная.

## Чанки

1. Новый протокол `DelayedActionScheduling` (+ `DispatchQueueScheduler` —
   продакшн-реализация через `DispatchQueue.main.asyncAfter`), по образцу
   `HapticScheduling`. `AppFlowCoordinator.init` получает третий параметр
   `scheduler: DelayedActionScheduling = DispatchQueueScheduler()`,
   `recordTrickClose()` зовёт `scheduler.schedule(after: 0.7) { ... }`
   вместо прямого `DispatchQueue`.
2. Новый `AppFlowCoordinatorTests.swift`: мок-scheduler, выполняющий action
   синхронно (без реальной задержки), мок `PreferenceStoring` (тот же
   паттерн, что в `StoreManagerTests`). Тесты:
   - три `recordTrickClose()` → `activeSheet == .rateApp`
   - `hasRespondedToRating == true` → счётчик не растёт, sheet не показывается
   - `openStartFlow` для невиденного трюка → `.instructionFirstLaunch`
   - `openStartFlow` для виденного трюка → `.trick`
3. Сборка + прогон новых и всех тестов.

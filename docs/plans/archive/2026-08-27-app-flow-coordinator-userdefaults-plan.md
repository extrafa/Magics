# AppFlowCoordinator пишет в UserDefaults напрямую — план

Task spec: найдено ревью uamoder. `AppFlowCoordinator.markTrickAsSeen`/`hasSeenTrick`
работают с `UserDefaults.standard` напрямую по строковому литералу `"seenTrickIds"`,
продублированному трижды — в обход `AppPreferences`/`PreferenceStoring`, которым
пользуется весь остальной код (в том числе соседние `trickLaunchCount` и
`hasRespondedToRating` в этом же координаторе).

Два конкретных последствия:
1. Ключ трюка получается через `String(describing: trick.id)` — рефлексия над
   `enum TrickType` без `RawValue`. Переименование кейса компилятор пропустит
   молча, но у всех существующих пользователей прогресс "просмотрено" обнулится.
2. `preferences = AppPreferences.shared` и `UserDefaults.standard` зашиты
   намертво в свойство — `AppFlowCoordinator` невозможно протестировать с
   подменным стором, хотя весь остальной проект это умеет
   (`SettingsStore(preferences: AppPreferences(store: store))`).

## Чанк 1 — Trick.swift

`enum TrickType: String, CaseIterable` — автосинтезированный `rawValue` для
кейсов без явных значений совпадает 1-в-1 с текущим `String(describing:)`
(`"colorSense"`, `"magicGallery"` и т.д.), так что прогресс у пользователей,
уже видевших трюк, не сотрётся.

## Чанк 2 — AppPreferences.swift

- В `PreferenceStoring` добавить `func stringArray(forKey defaultName: String) -> [String]?`
  и `func set(_ value: [String], forKey defaultName: String)` — у `UserDefaults`
  такие методы уже есть нативно, протокол их просто не объявлял.
- `Key.seenTrickIds = "seenTrickIds"`.
- Новое свойство `seenTrickIds: [String]` (get через `store.stringArray(forKey:) ?? []`,
  set через `store.set(newValue, forKey:)`), по образцу соседних свойств файла.

## Чанк 3 — AppFlowCoordinator.swift

- `private let preferences = AppPreferences.shared` → `init(preferences: AppPreferences = .shared)`.
  Все 3 места создания координатора (`MagicTricksApp.swift`, `RateAppSheet.swift`,
  `CollectionView.swift`) зовут `AppFlowCoordinator()` без аргументов — ничего
  не ломается.
- `markTrickAsSeen`/`hasSeenTrick` переписать на `preferences.seenTrickIds` и
  `trick.id.rawValue` вместо прямого `UserDefaults.standard` и
  `String(describing:)`.

## Чанк 4 — SettingsStoreTests.swift

У `MockSettingsPreferenceStore: PreferenceStoring` нет новых методов протокола
из чанка 2 — добавить, иначе конформанс молча ломается (тот же паттерн, что
уже ловили в этой сессии с другим моком). Тестовый таргет всё ещё не собирается
из-за отдельной, не связанной с этим проблемы (6 отсутствующих на диске файлов
тестов в pbxproj) — правим мок ради корректности на будущее, а не потому что
можем сейчас прогнать тесты.

## Out of scope

- Починка теста-таргета (missing files в pbxproj) — отдельная, не связанная
  проблема, упомянута ранее в сессии.
- Миграция уже сохранённых значений `seenTrickIds` — не нужна, ключ и формат
  хранения (массив строк) не меняются, меняется только откуда берётся сама
  строка (rawValue вместо reflection), а для всех текущих кейсов эти строки
  совпадают.

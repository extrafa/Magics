# Убрать Calculator Prediction из релиза и почистить мёртвые строки

Пункты 1 и 14 из `docs/achievements.md`. Калькулятор в прод не идёт, код остаётся
под рукой в ветке-архиве на GitHub.

## Формулировка

Полностью убрать трюк Calculator Prediction из приложения (хаб, онбординг, пейвол,
инструкции, роутер, ресурсы, строки, тесты, проект), сохранив его код в ветке
`archive/calculator-prediction`, и отдельной задачей удалить неиспользуемые строки.

Готово, когда: нет следов калькулятора в приложении и проекте, сборка и тесты
зелёные, пейвол сам показывает "4 more tricks" (число из каталога), цвет сложности
"средняя" и иконки онбординга выглядят как раньше.

## Решения

- Архив: ветка `archive/calculator-prediction` на GitHub, снимок `develop` перед
  удалением (весь репозиторий, калькулятор работает). Не обновляется. Код калькулятора
  и так лежит в публичной истории, ветка лишь удобная ссылка.
- Иконка на приветственном экране вместо калькулятора: значок Phantom Draw
  (антенна, розовый).
- Две ветки и два PR: сначала удаление калькулятора (чанки 1-5), потом чистка
  строк (чанки 6-9).

## Перед ветками

0. Создать и запушить `archive/calculator-prediction` от текущего `develop`
   (без изменений кода, не часть PR). Проверить, что ветка собирается и в ней есть
   модуль `CalculatorPrediction`.

## PR А: удаление калькулятора (ветка `feature/remove-calculator`)

1. Развязать цвет сложности "средняя" от калькулятора.
   `TrickPalette.Difficulty.medium` сейчас равен `Collection.calculatorPrediction`.
   Завести цвет `difficulty.medium` (те же значения, светлая и тёмная), перенаправить
   на него. Внешне ничего не меняется. Файлы: `Assets.xcassets`, `TrickPalette.swift`.
   Проверка: сборка, бейдж "Medium" в хабе того же оранжевого.

2. Приветственный экран онбординга без калькулятора.
   В `OnboardingWelcomeScreen` значок `ipad` с цветом калькулятора заменить на
   антенну с цветом Phantom Draw, сетка 2×2 остаётся. Проверка: скриншот
   в светлой и тёмной темах.

3. Убрать трюк из кода.
   - `TrickType.calculatorPrediction`, его запись в `requiresPro`, запись каталога
     в `Trick.swift`, символ `.ipad` в `SFSymbol`;
   - `TrickRouterView`, `TrickPalette` (цвет коллекции и ветка `collectionColor`);
   - превью в `InstructionView` и `PaywallScreen`;
   - папка `Modules/CalculatorPrediction` (7 файлов), тесты
     `CalculatorPredictionViewModelTests`, `CalculatorPredictionEngineTests`,
     упоминания в `InstructionModelsTests`;
   - 35 записей в `project.pbxproj`.
   Проверка: сборка Debug и Release, все тесты.

4. Убрать ресурсы, которые стали мёртвыми.
   Цвет `collection.calculatorPrediction`, картинки `step.calculator.acNumber`
   и `step.calculator.multiply`, 20 строк `*.calculatorPrediction.*` из каталога
   (точечно, от версии из `HEAD`, `git diff --stat`). Проверка: сборка, поиск
   "calculator" по проекту без совпадений (кроме истории и архивных планов).

5. Проверка целиком (без кода): хаб (4 карточки Pro и Geo), пейвол общий и
   контекстный ("4 more tricks"), онбординг, настройки; полный прогон тестов;
   обновить `docs/achievements.md` (1 исправлено). Затем PR.

## PR Б: чистка строк (ветка `chore/remove-dead-strings`, пункт 14)

Кандидаты найдены скриптом и проверены вручную, перед каждым удалением перепроверять
по коду.

6. Остатки трюка Mind Pattern: `card.mindPattern.*`, `instruction.mindPattern.*`,
   `mindPattern.animal.*`.
7. Остатки экранов онбординга: `onboarding.proof.*` (выдуманные отзывы),
   `onboarding.demo.*`, `onboarding.first.headline`.
8. Прочие неиспользуемые: `training.*`, `magicGallery.capture.*`,
   `magicGallery.progress.*`, `magicGallery.saveToGallery`, `magicGallery.saveNumberToGallery`,
   `magicGallery.status.selected`, `settings.rateUs`, `settings.holdDuration`,
   `settings.motion.*`, `color.*`, `instruction.action.*`, `app.name`, пустой ключ ''.
   Строки, которые читаются динамически (`settings.help.*`, `paywall.*`),
   не трогать.
9. Две строки `onboarding.goal.*` со статусом `needs_review`: проверить текст
   и перевести в `translated`. Затем PR.

## Не делаем

Переписывание инструкций, экранов онбординга и скриншотов (пункты 2 и 4), тексты
App Store, данные в `UserDefaults` пользователей (старое значение безвредно).

## Риски

- Правки `Localizable.xcstrings` делать от версии из `HEAD`, Xcode на твоей машине
  портит файл шумом. Сразу `git diff --stat`.
- Удаление ассета до удаления кода сломает сборку, поэтому ресурсы идут после кода.

/// Здесь твои правки к плану.

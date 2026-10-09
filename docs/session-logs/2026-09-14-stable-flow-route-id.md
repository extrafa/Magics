# Стабильный id маршрутов SheetFlow/FullScreenFlow

Задача пришла из треда ревью PR #1 (First review): `Identifiable.id` для
`.instruction`/`.instructionFirstLaunch` в `SheetFlow` собирался из
`instruction.title` — локализованной строки, а `FullScreenFlow.trick` строил
id через `"\(trick.id)"` — интерполяцию enum без `rawValue` (рефлексия).
Оба варианта делают идентичность SwiftUI-маршрута зависимой от текста/имени
кейса вместо стабильного технического ключа.

## Что сделано

- В `Instruction` добавлено поле `trickType: TrickType`, проставлено во всех
  6 местах создания (`GeoMentalismInstruction`, `ColorSenseInstruction`,
  `CalculatorPredictionInstruction`, `TimeControlInstruction`,
  `MagicGalleryInstruction`, `PhantomDrawInstruction`) — имена статических
  констант 1:1 совпадали с кейсами `TrickType`, так что связь очевидна.
- `SheetFlow.id` теперь строится из `instruction.trickType.rawValue`.
- `FullScreenFlow.id` теперь строится из `trick.id.rawValue` вместо
  интерполяции через рефлексию.

Реализовано одним чанком (без отдельного файла плана — задача маленькая).
PR [#88](https://github.com/extrafa/Magics/pull/88), squash-merge в develop.
Исходный тред в PR #1 зарезолвен, комментарий опубликован.

## Побочная находка и правка процесса

По ходу дела обнаружились 2 незакоммиченных файла саммари из прошлых сессий
(`docs/session-logs/2026-09-14-haptic-engine-auto-shutdown.md` и
`...-trick-close-in-coordinator.md`) — код по ним был давно смержен, а сам
файл саммари так и остался лежать незакоммиченным. Причина — в Этапе 7
скилла не было явного шага "закоммить" после сохранения файла. Закоммитил
оба файла отдельным коммитом на develop и поправил
`feature-workflow/SKILL.md` (Этап 7, пункт 2): теперь там явно сказано
закоммитить файл саммари сразу после сохранения.

## Грабли

Не встретилось — задача простая, план подтвердился сразу, сборка прошла с
первого раза. SourceKit показывал ложные диагностики "Cannot find type X in
scope" на изменённых файлах (побочный эффект построчного анализа без полного
контекста модуля) — не помешало реальной сборке через xcodebuild.

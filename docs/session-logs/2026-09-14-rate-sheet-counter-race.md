# 2026-09-14 — Rate sheet counter race condition

## Задача
Разбор нерешённых тредов ревью из PR #1 ("First review"). Взят первый по
порядку (все треды помечены severity `minor`, критичных не было) —
[AppFlowCoordinator.swift](../../MagicTricks/Sources/Shared/Navigation/AppFlowCoordinator.swift):
`recordTrickClose()` сбрасывал `trickLaunchCount` в 0 сразу при достижении
порога, ещё до того как rate-шит реально показывался (показ отложен на 0.7с
и защищён guard'ом по `activeFlow`/`activeSheet`). Если за это время
открывался другой флоу, guard отменял показ, но счётчик уже был потерян.

## Что сделано
- Перенесли сброс `trickLaunchCount = 0` внутрь отложенного замыкания, после
  guard-проверки — счётчик обнуляется только тогда, когда шит реально показан.
- Обновили тест `test_recordTrickClose_threeTimes_whenAnotherFlowIsActive_...`
  (переименован в `...doesNotShowSheetAndKeepsCount`) — теперь проверяет ещё
  и то, что счётчик не потерян в этом сценарии.
- PR [#86](https://github.com/extrafa/Magics/pull/86), смержен squash'ем в
  develop.
- Исходный тред в PR #1 зарезолвлен, оставлен комментарий с сутью фикса.

## Решения по ходу дела
- Исходный текст треда предлагал ещё и заменить `DispatchQueue.main.asyncAfter`
  на отменяемый `Task`. Это уже было сделано в отдельном PR раньше — появилась
  абстракция `DelayedActionScheduling` с `DispatchQueueScheduler` и
  `ImmediateScheduler` в тестах. Трогать сам scheduler не стали, фикса
  race condition оказалось достаточно перестановкой одной строки.

## Грабли
Нет — ничего нового не встретилось, использовали уже задокументированные
паттерны (GraphQL-пагинация тредов, resolve/reply мутации — все в
docs/references/github-pr-review-threads-graphql.md).

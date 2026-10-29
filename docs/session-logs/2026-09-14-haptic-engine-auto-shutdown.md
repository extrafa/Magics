# 2026-09-14 — авто-остановка CHHapticEngine по фазе сцены

## Что решалось

Тред из PR #1 ("First review"): `CHHapticEngine` никогда не останавливался —
`engine.stop()` нигде не вызывался, `isAutoShutdownEnabled` не был выставлен,
а `HapticManager.handleScenePhase` реагировал только на `.active`, полностью
игнорируя `.background`. Движок держал ресурсы весь жизненный цикл приложения.

## Что сделано

- `HapticEnginePlayer.configureEngine()` — выставлен `engine.isAutoShutdownEnabled = true`.
- Добавлен `stopEngine()` в `HapticEnginePlayer` и в протокол `HapticEnginePlaying`
  (+ реализация в тестовом `MockHapticEnginePlayer`).
- `HapticManager.handleScenePhase` переписан через `switch`: `.active` →
  `restartEngineIfNeeded()` (как было), `.background` → `enginePlayer.stopEngine()`.
- `restartEngineIfNeeded()` внутри `playEvents` оставлен без изменений — это
  защита от неожиданной смерти движка в активной фазе (прерывание аудиосессии
  и т.п.), автор треда её убирать не просил.
- PR #85, смержен squash-мерджем в develop. Вместе с ним закоммичены и
  посторонние незакоммиченные правки пользователя (CLAUDE.md, docs/references,
  docs/session-logs) — по его явной просьбе объединить всё в один PR.

## Грабли / решения по ходу

Без сюрпризов — тред был однозначным, автор дал готовый код-сниппет с
решением, скоуп чанка совпал с предложением ревьюера один в один.

# Единая подложка карточки вместо 9 копий

## Проблема

Блок «RoundedRectangle/Capsule + fill(grayCard) + overlay той же формы
.stroke(grayBorder, lineWidth: 1)» скопирован в живых файлах с пятью разными
радиусами (16, 18, 20, 22, 30) плюс Capsule-вариант. `SettingsComponents.swift`
уже содержит правильное решение — `settingsCard()` — но применено только
внутри Settings.

## Проверка находок ревью

- Совпадает буквально в 9 живых местах (пересчитано, отличается от ревью на
  одну позицию): TrickCardView (22), MagicGalleryCapturePanel (22),
  settingsCard() × 10 вызовов (20), PhantomDrawView роль-кнопка (18),
  **PhantomDrawView code-entry (16) — ревью этот пропустил**, HapticTrainingView
  deckBackground (30), CityCapsule (Capsule).
- **MagicGallerySlotCard.swift — НЕ совпадает**, вопреки ревью: там `fill`
  без парного `overlay/stroke(grayBorder)`, бордер отдельно
  (`Color.primaryText.opacity(0.08)`, `strokeBorder`) и добавлены значки
  поверх — трогать не буду, это другая форма, не дубликат.
- `OBSolutionScreen.swift` / `OBSocialProofScreen.swift` — подтверждено
  grep'ом, нигде не используются. Удаляю, а не рефакторю (как и просит ревью).

## Чанки

1. Новый файл `Shared/Components/CardSurface.swift`: `cardSurface(cornerRadius:)`
   (RoundedRectangle, дефолт 22) + `cardSurface(_ shape:)` (generic
   `InsettableShape`, для Capsule в CityCapsule). Пока без замены вызовов.
2. `SettingsComponents.swift`: убрать `settingsCard()`, заменить 10 вызовов
   в Settings-модуле на `.cardSurface(cornerRadius: 20)` (везде явно, чтобы
   не полагаться на дефолт=22 и не сдвинуть радиус случайно).
3. `TrickCardView.swift` → `.cardSurface(cornerRadius: 22)`.
4. `MagicGalleryCapturePanel.swift` → `.cardSurface(cornerRadius: 22)`.
5. `PhantomDrawView.swift` — оба места (18 и 16) → `.cardSurface(cornerRadius:)`.
6. `HapticTrainingView.swift` — `.background(deckBackground)` →
   `.cardSurface(cornerRadius: 30)`, удалить саму `deckBackground`.
7. `CityCapsule.swift` → `.cardSurface(Capsule())`.
8. Удалить `OBSolutionScreen.swift` и `OBSocialProofScreen.swift` (мёртвый код).
9. Сборка + визуальная проверка пары экранов (Settings, Collection).

## Не входит в объём (осознанно)

`MagicGallerySlotCard.swift` не трогаю — не тот же паттерн.

# План: KeyDomain/L10nDomain — сокращение дублирующихся префиксов ключей

Формулировка задачи: [2026-09-25-l10n-codegen-task-spec.md](2026-09-25-l10n-codegen-task-spec.md)

Чанк = файл (по аналогии с [архивным планом localization-domain-keys](archive/2026-09-09-localization-domain-keys-plan.md),
где так же было принято 1 файл = 1 чанк). Итого 36 чанков — много, но каждый
маленький и механический (замена префикса на `key(...)`, без смены типов и
поведения). Если хочешь укрупнить (например, все 6 Instruction-моделей
одним чанком, раз они однотипны) — отметь `///` под нужными пунктами, объединю.

## 1. Сам механизм

`MagicTricks/Sources/Shared/Localization/KeyDomain.swift`:
```swift
struct KeyDomain {
    private let prefix: String
    init(_ prefix: String) { self.prefix = prefix }
    func callAsFunction(_ suffix: String) -> String { "\(prefix).\(suffix)" }
}

struct L10nDomain {
    private let domain: KeyDomain
    init(_ prefix: String) { domain = KeyDomain(prefix) }
    func callAsFunction(_ suffix: String) -> LocalizedStringResource {
        LocalizedStringResource(String.LocalizationValue(stringLiteral: domain(suffix)))
    }
}
```
+ юнит-тест (склейка префикса и суффикса для обоих типов) в
`MagicTricksTests/Shared/Localization/`.

## 2. `Trick.swift` — домены `card.geo`, `card.color`, `card.calculatorPrediction`, `card.time`, `card.magicGallery`, `card.phantomDraw`

## 3. `GeoMentalismInstruction.swift` — `instruction.geo` (+ steps 1-6), `step.geo` (имена ассетов)
## 4. `ColorSenseInstruction.swift` — `instruction.color` (+ steps 1-6)
## 5. `CalculatorPredictionInstruction.swift` — `instruction.calculatorPrediction` (+ steps 1-7), `step.calculator`
## 6. `TimeControlInstruction.swift` — `instruction.time` (+ steps 1-5), `step.time`
## 7. `MagicGalleryInstruction.swift` — `instruction.magicGallery` (+ steps 1-5)
## 8. `PhantomDrawInstruction.swift` — `instruction.phantomDraw` (+ steps 1-5)

## 9. `OnboardingState.swift` — `onboarding.pain`, `onboarding.solution`, `onboarding.goal`
## 10. `OnboardingViewModel.swift` — `onboarding.processing` (phase1/2/3)
## 11. `OnboardingProcessingScreen.swift` — `onboarding.processing` (cta/done/title)
## 12. `OnboardingFeatureSlideScreen.swift` — `onboarding.preview`, `onboarding.feature.*`
## 13. `OnboardingWelcomeScreen.swift` — `onboarding.welcome`
## 14. `OnboardingGoalScreen.swift` — `onboarding.goal` (headline/subheadline)

## 15. `HapticSignalSettingsSection.swift` — `settings.haptics`
## 16. `SettingsScreen.swift` — `settings.section`, `settings.proOverride`, `settings.hideWatermark`, `settings.exitHint`, `onboarding.paywall`
## 17. `HapticHelpSection.swift` — `settings.help.exitHint`
## 18. `MotionSettingsSection.swift` — `settings.haptics` (faceDown/holdDuration)
## 19. `HapticPreviewSection.swift` — `settings.haptics` (testNumber/tryVibration)

## 20. `RateAppSheet.swift` — `rateApp.disliked`, `rateApp.reaction`, `rateApp.question`

## 21. `PhantomDrawView.swift` — `phantomDraw.status`, `phantomDraw.status.failed`, `phantomDraw.intro`, `phantomDraw.role.receiver`, `phantomDraw.role.sender`, `phantomDraw.enterCode`

## 22. `HapticTrainingView.swift` — `training.legend`
## 23. `HapticTrainingMode.swift` — `training.digits`
## 24. `HapticAnswerSectionView.swift` — `training.answer`

## 25. `MagicGalleryViewModel.swift` — `magicGallery.error`
## 26. `MagicGalleryCapturePanel.swift` — `magicGallery.gesture`, `magicGallery.standardSet`
## 27. `MagicGallerySlotCard.swift` — `magicGallery.status`
## 28. `MagicGalleryView.swift` — `magicGallery.source`
## 29. `MagicGalleryPhotoLibrary.swift` — `gallery.photo` (имена ассетов, `KeyDomain` без локализационной обёртки)

## 30. `ColorSenseViewModel.swift` — `colorMentalism.card`

## 31. `ExitHintView.swift` — `exitHint.confirm`, `exitHint.swipe`

## 32. `InstructionShareFormatter.swift` — `instruction.section`, `instruction.share`
## 33. `InstructionComponents.swift` — `instruction.section`
## 34. `InstructionPhaseLegend.swift` — `instruction.phase`
## 35. `InstructionStepActionPresentation.swift` — `instruction.action.hapticTraining`, `instruction.action.hapticSettings`

## 36. `HapticModels.swift` — `settings.haptics.intensity`

## Не входит в объём

- Ключи с плейсхолдерами (`%@`, `%lld`) — не про дублирование префикса, отдельная тема.
- Одиночные ключи без дублирующегося соседа в том же файле — сокращать нечего.
- Единый сгенерированный enum ключей — это была предыдущая, отклонённая идея.

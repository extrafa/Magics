# Единая анимация появления в онбординге вместо 16 копий

## Проблема

`.opacity(appeared ? 1 : 0)` + `.offset(y: appeared ? 0 : N)` +
`.animation(.spring(response: 0.55, dampingFraction: 0.82).delay(D), value: appeared)`
собирается вручную 13 раз (подтверждено grep'ом) в `OBProcessingScreen`,
`OBGoalScreen`, `OBFeatureSlideScreen`, `OBPaywallScreen`. При копировании
разъехались: `OBProcessingScreen.swift:50-51` — забыли `.offset`, а в
`OBWelcomeScreen.swift:40,49` и `OBGoalScreen.swift:58` та же анимация
записана с чуть другими числами (`0.8` вместо `0.82`, `0.5` вместо `0.55`) —
итого 16 мест той же самой смысловой анимации, а не 13.

Отдельная категория — bounce-появление иконок (`scaleEffect` + `opacity`,
`dampingFraction: 0.65`, используется в `OBWelcomeScreen` для превью-иконок
и в `OBProcessingScreen`/`OBPaywallScreen` для hero-иконки) — это осознанно
другая, более "прыгучая" физика, не трогаю.

## Чанки

1. Новый файл `Modules/Onboarding/View/OnboardingAppearTransition.swift`:
   `Animation.onboardingAppear` (константа) + `OnboardingAppearTransition`
   (ViewModifier) + `View.onboardingAppear(_:offset:delay:)`.
2. `OBProcessingScreen.swift` — 3 места, плюс возвращаю потерянный `offset`
   у текста фазы (10, по аналогии с соседними подзаголовками).
3. `OBGoalScreen.swift` — 3 места, включая унификацию `0.5`→`0.55` в
   ForEach-строке целей.
4. `OBFeatureSlideScreen.swift` — 3 места.
5. `OBPaywallScreen.swift` — 5 opacity+offset мест; у hero-иконки (scale,
   не offset) просто заменяю литерал `.spring(...)` на `.onboardingAppear`
   (константу), не оборачивая в модификатор — она не про opacity+offset.
6. `OBWelcomeScreen.swift` — 2 места, унификация `0.8`→`0.82`.
7. Сборка + визуальная проверка нескольких экранов онбординга (визуально
   разница должна быть незаметна — это унификация уже почти одинаковых
   значений, а не редизайн).

## Не входит в объём (осознанно)

Bounce-анимации иконок (`dampingFraction: 0.65`) в `OBWelcomeScreen` (превью
иконок), `OBProcessingScreen`/`OBPaywallScreen` (hero-иконка при isDone) —
другая физика, другое назначение, не унифицирую.

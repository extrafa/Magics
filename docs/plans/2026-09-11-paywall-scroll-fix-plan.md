# Пейволл обрезается на iPhone SE

## Проблема

Подтверждено (пересчитал по актуальному коду `OBPaywallScreen.swift`):
жёсткий `VStack(spacing: 0)` без `ScrollView`, единственный `Spacer()` —
сразу после `closeButton`. Сумма intrinsic-высот closeButton (~80) + heroIcon
(~152) + titleBlock (~90) + benefitsList (~266) + bottomBlock (~279) ≈ 867 pt
при доступной высоте экрана iPhone SE ≈ 647 pt (667 − статус-бар). При
нехватке места `Spacer()` схлопывается в 0, а `VStack` не скроллится — низ
(`bottomBlock`: цена, CTA-кнопка, restore, ссылки Terms/Privacy) уезжает за
пределы экрана. Экран открывается через `.fullScreenCover`/полноэкранный кейс
`AppFlowCoverView` — фиксированный размер, контенту деться некуда.

Строки Spacer'ов из текста ревью (36 и 30) не совпадают с текущим кодом
(сейчас один `Spacer()` на строке 63) — ревью, видимо, писалось по чуть более
старой версии файла, но сама проблема (переполнение, нет скролла) актуальна
и воспроизводится на актуальном коде.

## Решение

- `heroIcon` + `titleBlock` + `benefitsList` — в `ScrollView`.
- `bottomBlock` (цена + CTA + restore + ссылки) — в `.safeAreaInset(edge: .bottom)`
  на корневом `VStack`: всегда на экране, никогда не скроллится, что бы ни
  случилось с текстом/шрифтами выше.
- `closeButton` остаётся вне `ScrollView`, как сейчас — всегда виден сверху.
- Чтобы не потерять текущую вертикальную центровку hero+title+benefits на
  высоких экранах (сейчас за это отвечает `Spacer()`), меряю доступную высоту
  через `GeometryReader` и задаю группе `.frame(minHeight:)` с
  `Spacer(minLength: 0)` сверху и снизу внутри неё: если контент помещается —
  выглядит как сейчас (по центру), если нет — Spacer'ы схлопываются и
  `ScrollView` скроллит.

```swift
VStack(spacing: 0) {
    closeButton

    GeometryReader { proxy in
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                heroIcon.padding(.bottom, 16)
                titleBlock...
                benefitsList...
                Spacer(minLength: 0)
            }
            .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
        }
    }

    bottomBlock
}
```

`bottomBlock` — обычный sibling в `VStack`, НЕ `.safeAreaInset`. Проверено на
симуляторе: `.safeAreaInset(edge: .bottom)` вместо этого ломает расчёт —
`GeometryReader.proxy.size` не учитывает вычет на safe-area-inset (это не тот
view, к которому применён модификатор), `minHeight` завышается на высоту
`bottomBlock`, и скроллящийся контент наезжает на зону под подвалом (без
непрозрачного фона там текст читается вперемешку). Обычный sibling решает то
же самое — `VStack` сам отдаёт `GeometryReader` остаток после вычета высоты
`bottomBlock`, без всяких скрытых допущений про safe area.

## Что не трогаю

Замечание ревью про `.system(size:)` и Dynamic Type — технически неверное:
`Font.system(size:)` в SwiftUI сам масштабируется под Dynamic Type (в отличие
от `UIFont.systemFont(ofSize:)` в UIKit), явного "не спасает" нет. Но вывод
ревью от этого не меняется в другую сторону — раз шрифты и так масштабируются,
при крупном Dynamic Type контента станет только больше, и уязвимость к
переполнению — тем более причина чинить именно скроллом, а не под шрифты
отдельно.

## Чанки

1. Обернуть `heroIcon` + `titleBlock` + `benefitsList` в `GeometryReader` +
   `ScrollView`, вынести `bottomBlock` в `.safeAreaInset(edge: .bottom)`.
   Сборка.
2. Проверка на симуляторе iPhone SE (3rd gen): цена/CTA/restore/ссылки всегда
   видны без скролла; на iPhone 16 Pro (высокий экран) — визуально то же самое
   центрирование, что и сейчас, скролла не появляется.

Готово: прогнал на симуляторах iPhone SE (3rd gen, 375×667) и iPhone 17
(402×874) вручную. На SE список бенефитов и подвал (Retry/Restore/Terms/
Privacy) скроллятся и остаются доступны без наложений; на iPhone 17 всё
помещается почти без скролла. В процессе поймал и починил баг первой версии
фикса (`.safeAreaInset` вместо sibling) — см. выше.

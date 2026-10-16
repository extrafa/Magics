# Accessibility-лейблы для кнопок-иконок

## Проверено

`grep -r 'accessibilityLabel|accessibilityHidden|...'` даёт не 0, а 2
совпадения — но это `UIButton.accessibilityLabel` (UIKit-свойство) в
`MagicGalleryCropView.swift`, добавленные мной в PR #70. Ни одного
SwiftUI-модификатора accessibility в проекте по-прежнему нет — суть
находки не меняется.

Поправка к формулировке (в) самого ревью верна: `xmark` в кнопке обычно
озвучивается VoiceOver как «Close» по системному описанию SF Symbol — не
«кнопка немая», а «смысл не под нашим контролем». Разобрал все места:

| Место | Реально ли икон-онли (без текста рядом) |
|---|---|
| `PhantomDrawView` — X выхода из трюка | да |
| `CollectionView.swift` — `gearshape`, вход в Settings | да |
| `MagicGallerySlotCard.swift` — `trash`, удаление фото | да, + удаляет без подтверждения |
| `InstructionView.swift` — `square.and.arrow.up`, шер | да |
| `OBPaywallScreen.swift` — `xmark`, закрыть пейволл | да — критично, иначе VoiceOver-пользователь не закроет экран оплаты |
| `WatermarkView.swift` — `xmark`, скрыть плашку | да |
| `GeoMentalismCitiesView.swift` — `shuffle` | **нет** — рядом уже есть `Text("geo.shuffle")`, VoiceOver и так озвучит «Shuffle»; иконка просто лишний раз дублирует то же слово |

`TrickCardActions.swift` — подтверждено: `collection.start`/`collection.
howTo` — статичный текст «Start»/«Learn» без привязки к трюку, VoiceOver на
экране из 6 карточек читает одно и то же 6 раз подряд, не давая понять,
к какому трюку относится кнопка.

`CollectionView.swift` (второе упоминание) — про «заблокированная карточка
недоступна»: проверил `TrickCardView` — locked-оверлей это `Color.clear
.onTapGesture{}` (не `Button`), и правда не в accessibility-дереве как
единый элемент. Но **степень серьёзности в ревью завышена**: под оверлеем
лежат настоящие `Button`-ы (Start/How To из `TrickCardActions`), которые
VoiceOver видит и может активировать напрямую, а их `onStartTap`/
`onHowToTap` в locked-состоянии и так ведут на пейволл
(`CollectionView.swift:29-42`) — то есть карточка не «вообще недоступна»,
просто не даёт большой единой зоны тапа, которая есть у зрячих. Дособеру
до паритета (один комбинированный элемент с явным лейблом), но это
второстепенная полировка, не критичный баг.

## Что не трогаю

«144 фиксированных размера шрифта» (Dynamic Type) — ревью упоминает это
вскользь в одном пункте вместе с TrickCardActions, но это отдельная,
гораздо более крупная задача (весь проект использует `.font(.system(size:))`
без поддержки масштабирования) — не про accessibilityLabel, отдельная
работа.

## Решение

1. Новый общий ключ `common.close` (не плодить третий дубль "Close"/"Cancel"
   — PhantomDraw/Paywall/Watermark используют его один на троих):
   `.accessibilityLabel(String(localized: "common.close"))` на все три X.
2. `CollectionView` gearshape → `.accessibilityLabel(String(localized:
   "settings.title"))` (ключ уже есть, ничего нового заводить не нужно).
3. `InstructionView` share → новый `common.share` = "Share"/"Compartir".
4. `MagicGallerySlotCard` trash:
   - `.accessibilityLabel` — новый `magicGallery.deletePhoto` =
     "Delete Photo"/"Eliminar Foto".
   - Добавляю `.confirmationDialog` перед вызовом `onDelete` — сейчас фото
     удаляется по одному тапу без возможности передумать; ревью явно просит
     подтверждение именно здесь. Кнопки: Delete (`.destructive`) / Cancel
     (переиспользую `common.cancel`).
5. `GeoMentalismCitiesView` shuffle-иконка — `.accessibilityHidden(true)`
   (декоративная, рядом уже читаемый текст).
6. `TrickCardActions`: `onStartTap`/`onHowToTap` кнопки получают
   `.accessibilityLabel` с названием трюка — новые format-ключи
   `collection.start.accessibilityLabel` = "Start %@"/"Empezar %@",
   `collection.howTo.accessibilityLabel` = "Learn %@"/"Aprender %@". Трюк
   передаю параметром в `TrickCardActions` (сейчас там только колбэки).
7. `TrickCardView` (locked-паритет): на `Color.clear` оверлей —
   `.accessibilityElement(children: .combine)` +
   `.accessibilityAddTraits(.isButton)` + `.accessibilityLabel` с названием
   трюка и «locked»/пейволл-подсказкой, чтобы у VoiceOver тоже была одна
   большая зона активации, как у зрячих.

## Чанки

1. Точечные `.accessibilityLabel`/`.accessibilityHidden` — `PhantomDrawView`,
   `OBPaywallScreen`, `WatermarkView` (общий `common.close`),
   `CollectionView` (`settings.title`), `InstructionView` (`common.share`),
   `GeoMentalismCitiesView` (hidden). Новые ключи с `en`+`es` сразу. Сборка +
   тесты.
2. `MagicGallerySlotCard` — лейбл + `.confirmationDialog` на удаление.
   Сборка + тесты.
3. `TrickCardActions`/`TrickCardView` — лейблы с названием трюка + паритет
   locked-карточки для VoiceOver. Сборка + тесты.
4. Ручная проверка: VoiceOver (или Accessibility Inspector) на симуляторе —
   пейволл закрывается, Trick Hub различает карточки по имени, удаление
   фото спрашивает подтверждение.

Готово: прогнал на симуляторе функционально (не полный VoiceOver-прогон) —
locked-карточка (теперь настоящий `Button` вместо голого tap-жеста)
по-прежнему открывает пейволл, X пейволла по-прежнему закрывает экран.
Диалог удаления фото не гонял вживую (нужен Pro-доступ + добавление
кастомного фото ради проверки стандартного `.confirmationDialog`,
паттерн уже есть в этом же модуле) — полагаюсь на сборку. Полную
озвучку VoiceOver/Accessibility Inspector нужно проверить отдельно.

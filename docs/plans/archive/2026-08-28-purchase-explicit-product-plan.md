# purchase() покупает «первый попавшийся» продукт — план

Task spec: найдено ревью uamoder. `StoreManager.purchase()` не принимает
параметров и сам берёт `products.first` — порядок, в котором `Product.products(for:)`
возвращает массив, StoreKit не гарантирует. Пока продукт один
(`StoreProducts.all` = `[.lifetime]`) это работает случайно. `priceLabel`
в `OBPaywallScreen.swift` берёт `products.first` отдельным, никак не связанным
обращением — с появлением второго продукта показанная цена и списанная сумма
могут разойтись.

## Почему не просто передать `productID` в замыкание кнопки

Мало поменять сигнатуру на `purchase(productID: String)` — если внутри
`action: { Task { await store.purchase(productID: store.products.first!.id) } }`
кнопка снова САМА лезет в `store.products.first` в момент тапа, а не в момент
показа цены, — баг просто переезжает на один уровень: между рендером
`priceLabel` и фактическим тапом (человек может держать открытым экран
секунды-минуты) список продуктов может обновиться (`reloadProductsIfNeeded()`
дёргается при каждом открытии пейволла), и купится не то, что было
показано в цене.

Нужно ОДНО обращение к `store.products.first` за рендер, результат которого
идёт и в `priceLabel`, и в замыкание покупки — без re-derive в момент тапа.
Беру локальное значение внутри `bottomBlock`, не `@State`: `@State` потребовал
бы `.onChange(of: store.products)` для синхронизации при перезагрузке списка —
лишняя механика ради экрана, где выбирать пока не из чего (один продукт).
Если появится реальный picker с несколькими товарами — тогда и заведётся
`@State` под конкретный UI выбора, не раньше.

## Чанк 1 — StoreManager.swift

`purchase()` → `purchase(productID: String) async`. Убрать внутренний
`guard let id = products.first?.id` — идентификатор теперь всегда приходит
явно от вызывающей стороны, `StoreManager` больше не решает, что покупать.

## Чанк 2 — OBPaywallScreen.swift

`bottomBlock` вычисляет `let product = store.products.first` один раз и
передаёт его в `priceLabel(for:)` и `purchaseSection(for:)` (были вычисляемыми
свойствами без параметров — становятся функциями). Кнопка покупки берёт
`product.id` из этого же захваченного значения, не из `store.products` заново.

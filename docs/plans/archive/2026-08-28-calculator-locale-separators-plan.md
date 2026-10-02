# Разделители в калькуляторе зашиты как европейские — план

Task spec: найдено ревью uamoder. `CalculatorPredictionViewModel.formatNumber`
руками ставит `.` разделителем тысяч и `,` десятичным разделителем — жёстко,
без учёта локали. Приложение поставляется на en/es. Для en-локали системный
калькулятор показывает `1,234.5`, наш — `1.234,5`. Форматирование должно идти
через `NumberFormatter` с текущей `Locale`, а не ручной цикл.

При разборе баг оказался шире одной функции: клавиша decimal тоже жёстко
показывает `","` (`CalculatorPredictionButton.decimal.rawValue`), и этот же
rawValue используется `CalculatorPredictionButtonView` для обратного поиска
цвета кнопки (`CalculatorPredictionButton(rawValue: label)`). Если поправить
только форматирование чисел, экран всё равно выдаст себя клавишей запятой
в en-локали — то же самое "зритель заметит подмену", о котором пишет ревью.

## Чанк 1 — CalculatorPredictionViewModel.swift

- Разделители текут из `Locale.current` (`decimalSeparator`/`groupingSeparator`,
  с фолбэком на `.`/`,` если система вдруг не вернула значение) — вычисляемые
  свойства, не кэш, чтобы не тащить устаревшую локаль в долгоживущей vm.
- Все места, где сейчас жёстко сравнивают/добавляют `","` и `"."`
  (`rawDisplay`, `appendOperator`, `appendDecimal`, `calculate`, `formatResult`,
  `formatNumber`) — переходят на эти два свойства.
- Ручной цикл группировки тысяч в `formatNumber` заменяется на `NumberFormatter`
  (`.decimal`, `usesGroupingSeparator = true`, `locale = .current`,
  `maximumFractionDigits = 0`) — форматируется только целая часть числа,
  дробная часть (уже включающая разделитель) подставляется как есть.

## Чанк 2 — CalculatorPrediction.swift + CalculatorPredictionButtonView.swift + CalculatorPredictionView.swift

- `CalculatorPredictionButton` получает `displayLabel: String` — для `.decimal`
  берёт `Locale.current.decimalSeparator`, для остальных кейсов равен `rawValue`.
  Сам `rawValue` не трогаем — это внутренний идентификатор кнопки (switch в
  `buttonPressed`, `CalculatorPrediction.buttons`), путать его с тем, что видно
  на экране, и есть первопричина бага.
- `CalculatorPredictionButtonView` сейчас принимает `label: String` и
  восстанавливает кнопку через `CalculatorPredictionButton(rawValue: label)?.buttonColor` —
  если `label` перестанет совпадать с `rawValue` для decimal, поиск цвета
  молча сломается. Меняем сигнатуру на `button: CalculatorPredictionButton`:
  цвет и `== .delete` проверка идут напрямую по кейсу, без обратного поиска
  по строке; текст берётся через `button.displayLabel`.
- `CalculatorPredictionView.swift` — вызов `CalculatorPredictionButtonView(label: label.rawValue, ...)`
  меняется на `CalculatorPredictionButtonView(button: label, ...)`.

## Out of scope

- `CalculatorPredictionEngine.swift` — его токенайзер понимает только `.` и
  получает строку через `evaluate(_:)`, которая сама жёстко конвертирует
  `,` → `.`. Для en (разделитель `.`) это no-op, для es (разделитель `,`) —
  как раз то, что нужно. Для двух текущих локалей приложения этого достаточно,
  трогать движок не нужно — но если появится локаль с другим десятичным
  разделителем (не `.` и не `,`), эта конвертация в движке перестанет работать
  и её тоже придётся параметризовать через `Locale.current`.
- Локализация текста самих кнопок с цифрами/операторами — не нужна, они и
  так локале-независимые символы.

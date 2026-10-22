# Синхронное чтение фото на main thread в init — план

Task spec: ревью uamoder. `loadStoredPhotos()` зовётся из `init`
`MagicGalleryViewModel`, `loadCustomPhotos()` — синхронный
(`contentsOfDirectory` + `Data(contentsOf:)` + `UIImage(data:)` на каждый
файл), весь сервис/вьюмодель `@MainActor` — чтение блокирует main thread в
момент открытия экрана. Плюс каждое фото декодируется в полный размер
(JPEG q=0.92 с полнокадровой камеры, ~2-4 МБ/слот) ради карточки высотой
184pt (`MagicGallerySlotCard.swift:28`). `saveCustomPhoto`/`deleteCustomPhoto`
уже асинхронны через `Task.detached` — только `loadCustomPhotos` выбивается.

## Решение

1. `loadCustomPhotos()` — асинхронный, уходит на фон (тот же `Task.detached`
   паттерн, что уже есть у save/delete), зовётся из `.task` во View вместо
   `init`.
2. В `customPhotos` хранится ПРЕВЬЮ (`UIImage.preparingThumbnail(of:)`,
   доступен с iOS 15, деплой-таргет 16.0 — подходит), а не полный кадр —
   и при загрузке с диска, и сразу после новой съёмки в `saveCustomPhoto`
   (иначе после каждой съёмки в памяти всё равно копится полный размер).
3. Полный размер нужен только в одном месте — `savePhoto(number:)`
   (сохранение в системную Фотоплёнку при показе зрителю). Для `.custom`
   фото это отдельный async-метод, перечитывающий оригинальный JPEG с
   диска в момент показа; для `.standard` (маленькие бандл-ассеты) отдельный
   fetch не нужен — `photo.image` и так лёгкий.

## Чанк 1 — MagicGalleryPhotoLibrary.swift + протокол

- `loadCustomPhotos() throws -> [MagicGalleryPhoto]` →
  `loadCustomPhotos() async throws -> [MagicGalleryPhoto]`, тело — в
  `Task.detached(priority: .userInitiated)`, каждое фото уменьшается через
  `preparingThumbnail(of:)` перед тем как попасть в `MagicGalleryPhoto`.
- `saveCustomPhoto`: JPEG на диск пишется из полного `image`, как сейчас, но
  в возвращаемый `MagicGalleryPhoto` кладётся превью, а не исходник.
- Новый метод протокола `fullResolutionImage(for photo: MagicGalleryPhoto) async throws -> UIImage`:
  для `.custom` — перечитать `storageDirectoryURL()/fileName` и
  задекодировать полный размер (в `Task.detached`); для `.standard` —
  вернуть `photo.image` без похода на диск.
- Общий приватный хелпер для генерации превью (используется и в load, и в
  save), целевой размер — `CGSize(width: 400, height: 400)` (карточка 184pt
  высотой, с запасом под @3x).

## Чанк 2 — MagicGalleryViewModel.swift

- `loadStoredPhotos()` становится `async`, `init` больше её не зовёт.

## Чанк 3 — MagicGalleryView.swift

- `.task { await vm.loadStoredPhotos() }` на корневом View — грузит один раз
  при первом появлении, автоматически отменяется, если экран закрыли раньше.

## Чанк 4 — MagicGalleryViewModel+Actions.swift

- `savePhoto(number:)`: вместо `photo(for: number)?.image` — сначала
  получить `photo`, затем `try await photoLibrary.fullResolutionImage(for: photo)`
  для реального сохранения в Фотоплёнку.

## Чанк 5 — сборка + живая проверка

Снять фото, убедиться что в сетке появляется превью без фриза; сохранить в
Фотоплёнку через показ, убедиться что сохранённое фото полного размера (не
уменьшенное превью).

## Out of scope

- Тестовый файл `MagicGalleryViewModelTests.swift` уже не компилируется по
  не связанной причине (см. заведённые ранее задачи) — сигнатуры мока
  `MockMagicGalleryPhotoLibrary` при необходимости поправит тот, кто будет
  чинить тест-таргет целиком.

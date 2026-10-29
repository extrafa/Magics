# Magics.storekit не должен уезжать в бандл и быть единственной схемой

## Проблема

`Magics.storekit` лежит в Copy Bundle Resources — файл (с мусорным `eula`)
копируется в `.app` и уезжает в IPA. Плюс единственная shared-схема `Magics`
жёстко ссылается на этот StoreKit-конфиг в LaunchAction, поэтому любой обычный
запуск/тест на реальном устройстве идёт против локального теста-стора, а не
против sandbox — реальный путь покупки (App Store Connect, отказ, ошибка сети)
никогда не проверяется случайно.

## Чанки

1. `project.pbxproj`: убрать `Magics.storekit` из `PBXResourcesBuildPhase`
   (Copy Bundle Resources) — `PBXFileReference` и группу оставить, файл
   по-прежнему нужен как ссылка для схемы.
2. `Magics.storekit`: обнулить `eula` (пустая строка вместо мусора).
3. Новая shared-схема `Magics (StoreKit Test).xcscheme` — копия текущей
   `Magics.xcscheme` целиком, с оставленным `StoreKitConfigurationFileReference`.
   Из `Magics.xcscheme` этот блок убрать — обычный запуск идёт через sandbox.
4. Сборка + проверка, что в собранном `.app` `Magics.storekit` больше нет
   (`ls` внутри `Build/Products/.../MagicTricks.app`), и что схема `Magics`
   по-прежнему нормально собирается и запускается.

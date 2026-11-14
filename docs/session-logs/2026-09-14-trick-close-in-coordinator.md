# 2026-09-14 — Перенос закрытия трюка в координатор

## Задача
Тред ревью PR #1 (CollectionView.swift:85): факт закрытия трюка вычислялся
диффом `@State previousActiveFlow` во вью через `.onChange`, а не самим
`AppFlowCoordinator`. Дублирование состояния координатора во вью, нельзя
покрыть юнит-тестом.

## Решение
`AppFlowCoordinator.activeFlow` получил `didSet`: при переходе из `.trick` в
`nil` сам вызывает `recordTrickClose()`. Работает одинаково для программного
закрытия и системного swipe-dismiss шторки — `CollectionView` больше не
следит за этим состоянием, `@State previousActiveFlow` и `.onChange` удалены
целиком.

## Процесс
Одна правка на один чанк, без файла плана (маленькая задача). PR #87,
squash-merge в develop. Исходный тред в PR #1 зарезолвлен, ответ опубликован.

## Грабли
Нет — паттерн `@Published { didSet }` уже использовался в проекте
(StoreManager), ничего нового.

# Каталог драйверов Blade

[English](README.md) | [简体中文](README.zh-CN.md) | Русский

Здесь можно найти пакет драйверов Razer для своей модели Blade. Для каждой записи указано исходное устройство и способ проверки файлов.

OpenBlade не связан с Razer. Исходные подписанные файлы драйверов сохраняются без изменений.

<a id="blade-models"></a>
## Модели Blade

Сверьте номер модели на ноутбуке.

| Модель | Сведения о драйверах | Загрузка |
| --- | --- | --- |
| Blade 16 (2026), RZ09-0581 | [Стек драйверов Razer 02E0](devices/rz09-0581/1532-02e0/1.0.0.78-1.0.0.76/manifest.json) | [Предварительный выпуск](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0581-1532-02e0-driver-stack-1.0.0.78-1.0.0.76) |
| Blade 16 (2025), RZ09-0528 | [Стек драйверов Razer 02C6](devices/rz09-0528/1532-02c6/1.0.0.78-1.0.0.76/manifest.json) | [Предварительный выпуск](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0528-1532-02c6-driver-stack-1.0.0.78-1.0.0.76) |

Следуйте [руководству по установке](docs/ru-RU/installing.md) для своей модели.

<a id="upstream-components"></a>
## Компоненты от производителя

OpenBlade может использовать отдельные компоненты напрямую с сайта Razer, не
публикуя их повторно. В [каталоге компонентов](docs/ru-RU/upstream-components.md)
указаны точные модели, хеши, сведения о подписанте и ссылка на загрузку с сайта
производителя.

<a id="add-your-blade"></a>
## Добавление модели Blade

Если нужной модели нет в каталоге, [руководство по экспорту](docs/ru-RU/exporting.md) объясняет, как собрать установленные пакеты драйверов. Для отправки сведений о модели и файлах используйте [шаблон доказательств](templates/driver-stack-evidence.template.json). Не включайте в отправляемые материалы файлы драйверов или личные сведения об устройстве.

Порядок публикации загрузок описан в разделе [ресурсов выпусков и границ репозитория](docs/ru-RU/release-assets.md).

<a id="license"></a>
## Лицензия

Текст и инструменты репозитория распространяются по [лицензии Apache 2.0](LICENSE). Файлы драйверов Razer принадлежат Razer. Подробности приведены в [NOTICE](NOTICE) и [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

<a id="run-the-checks"></a>
## Запуск проверок

В Windows выполните:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File .\tests\Run-All.ps1
```

В [каталоге драйверов THX](docs/ru-RU/thx-audio-stacks.md) перечислены подходящие драйверы и конфигурации, а также недостающие пакеты, без которых полная установка невозможна.

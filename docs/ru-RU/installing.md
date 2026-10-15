# Установка драйверов Razer для Blade

[English](../installing.md) | [简体中文](../zh-CN/installing.md) | Русский

Сначала сверьте номер модели. Эти две модели Blade 16 используют разные пакеты драйверов Razer; пакеты нельзя переносить между моделями.

| Модель Blade | Встроенное устройство Razer | Загрузка драйверов |
| --- | --- | --- |
| 2026, RZ09-0581 | `1532:02E0` | [Предварительный выпуск драйверов 2026](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0581-1532-02e0-driver-stack-1.0.0.78-1.0.0.76) |
| 2025, RZ09-0528 | `1532:02C6` | [Предварительный выпуск драйверов 2025](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0528-1532-02c6-driver-stack-1.0.0.78-1.0.0.76) |

Модель, которую сообщает Windows, можно проверить в PowerShell:

```powershell
(Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS').SystemProductName
```

Если номер модели не совпадает ни с одной строкой таблицы, не используйте эти пакеты.

<a id="install-through-razer-synapse"></a>
## Установка через Razer Synapse

Установите [Razer Synapse](https://www.razer.com/synapse-4) на Blade и запустите его один раз. Synapse установит стек драйверов Razer для подключённого ноутбука. Порядок установки приведён в [инструкции Razer](https://mysupport.razer.com/app/answers/detail/a_id/1834/). Перед повторным запуском OpenBlade закройте Synapse.

Установщик OpenBlade не устанавливает и не удаляет драйверы Razer. Если драйвер недоступен, OpenBlade использует путь яркости WMI и собственное всплывающее окно.

<a id="use-a-catalog-download"></a>
## Использование пакета из каталога

Выберите ZIP в выпуске, соответствующем модели. ZIP с исходным кодом на GitHub не является пакетом драйверов. В [записи 2026](../../releases/rz09-0581-02e0-1.0.0.78-1.0.0.76.json) или [записи 2025](../../releases/rz09-0528-02c6-1.0.0.78-1.0.0.76.json) указаны ожидаемые имя файла и SHA-256. До распаковки сверьте хеш загруженного ZIP.

```powershell
Get-FileHash -LiteralPath 'path-to-the-driver-zip' -Algorithm SHA256
```

Для модели 2026 после проверки ноутбука и архива следуйте [процедуре отдельной установки пакета](installing-rz09-0581.md). Для каталога 2025 отдельная процедура ещё не проверена; на этой модели используйте Synapse.

<a id="check-the-result"></a>
## Проверка результата

Для штатного управления яркостью Windows на обеих моделях требуется OpenBlade 0.24.3 или новее. После установки проверьте встроенное устройство Razer в диспетчере устройств, перезапустите OpenBlade и проверьте клавиши яркости. В строке драйвера яркости Razer на странице **About > Device information** должно отображаться `Available · Windows OSD`, а клавиши должны вызывать всплывающее окно яркости Windows. Для каждого ноутбука нужен стек драйверов, соответствующий его модели.

<a id="install-the-razer-brightness-driver-on-rz09-0581"></a>
# Установка драйвера яркости Razer на RZ09-0581

[English](../installing-rz09-0581.md) | [简体中文](../zh-CN/installing-rz09-0581.md) | Русский

Эта отдельная инструкция предназначена для пакета Blade 16 RZ09-0581 (`1532:02E0`), указанного в [руководстве по установке](installing.md). Пакет позволяет OpenBlade использовать системный индикатор яркости Windows. Установщик OpenBlade не устанавливает и не удаляет драйверы Razer.
Если драйвер недоступен, клавиши яркости используют WMI и индикатор OpenBlade.

<a id="package-details"></a>
## Сведения о пакете

| Идентификатор оборудования | Версии драйверов |
| --- | --- |
| `1532:02E0` | RzDev `1.0.0.78`, RzCommon `1.0.0.76` |

Microsoft Windows SDK SignTool проверил все пять подписей каталогов и принадлежность всех десяти файлов INF и SYS к каталогам в соответствии с политикой режима ядра. Пакет не поддерживает RZ09-0528 (`02C6`) или аксессуары Razer.

<a id="install-through-synapse"></a>
## Установка через Synapse

Установите [Razer Synapse](https://www.razer.com/synapse-4) и один раз запустите его на ноутбуке, чтобы установить набор драйверов. Razer предоставляет [инструкцию по установке Synapse](https://mysupport.razer.com/app/answers/detail/a_id/1834/). После этого закройте Synapse перед перезапуском OpenBlade. Если вы хотите оставить Synapse запущенным для других устройств, выполните [настройку Synapse Blade Blocker](https://github.com/OpenBladeProject/synapse-blade-blocker/blob/main/README.ru-RU.md). Проверьте состояние драйвера, как описано в разделе [Проверка результата](#5-check-the-result).

<a id="1-download-the-standalone-package"></a>
## 1. Скачивание отдельного пакета

Откройте [предварительный выпуск драйвера](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0581-1532-02e0-driver-stack-1.0.0.78-1.0.0.76) и скачайте из его файлов `Razer-02E0-Driver-Stack-1.0.0.78-1.0.0.76.zip`. ZIP-файл с исходным кодом не является пакетом драйверов.

Ожидаемые имя архива и SHA-256 приведены в [записи выпуска](../../releases/rz09-0581-02e0-1.0.0.78-1.0.0.76.json), а идентификаторы пакетов — в [манифесте каталога](../../devices/rz09-0581/1532-02e0/1.0.0.78-1.0.0.76/manifest.json). Распакуйте проверенный ZIP-файл в новую папку. Используйте эту папку как `$packageRoot` в приведённых ниже командах; в ней должны находиться пять подпапок пакетов. Не используйте этот пакет на RZ09-0528 или другой модели.

В состав Windows входит PnPUtil для размещения подписанных пакетов в Driver Store и их установки на соответствующие устройства. Microsoft описывает параметры `/add-driver`, `/install`, `/subdirs` и `/reboot` в [справочнике команд PnPUtil](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax).

Проверка чистой установки этого отдельного пакета ещё не завершена. Выполняйте приведённую ниже процедуру только на RZ09-0581, который можно восстановить. Набор устанавливает фильтрующие драйверы в цепочки встроенных клавиатуры и мыши, перезапускает части дерева USB-устройств и может потребовать перезагрузки. Подключите питание от сети, оставьте подключёнными внешние USB-клавиатуру и мышь и перед проверкой убедитесь, что доступ к среде восстановления работает.

<a id="2-verify-the-laptop-and-package"></a>
## 2. Проверка ноутбука и пакета

Откройте PowerShell с правами администратора и перед установкой выполните следующие проверки:

1. `HKLM:\HARDWARE\DESCRIPTION\System\BIOS` должен указывать Razer как производителя и `Blade 16 - RZ09-0581` как `SystemProductName`.
2. Windows должна сообщать об одном подключённом устройстве `USB\VID_1532&PID_02E0&MI_01` и одном подключённом устройстве `USB\VID_1532&PID_02E0&MI_02`. Остановитесь, если идентификатор отсутствует, дублируется или отличается.
3. Имя ZIP-файла и его SHA-256 должны совпадать с проверенной аттестацией выпуска. В той же аттестации должны быть указаны путь к манифесту каталога в репозитории и его SHA-256.
   После распаковки каждый файл должен совпадать с `SHA256SUMS.txt`, а каждая подпись INF, CAT и SYS должна быть действительной и выданной Microsoft Windows Hardware Compatibility Publisher. На компьютере для проверки с SignTool выполните `signtool verify /kp /c <catalog> <INF-or-SYS>`, чтобы подтвердить принадлежность к каталогу. Параметр `/c` описан Microsoft в [справочнике SignTool](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/signtool).

<a id="3-record-the-current-drivers"></a>
## 3. Запись текущих драйверов

Перед размещением пакетов создайте журнал за пределами пакета и репозитория. Запишите идентификатор BIOS, подключённые экземпляры устройств с нужными идентификаторами, вывод `pnputil /enum-drivers /files`, их текущие привязки и стеки, а также текущее дерево `RZVIRTUAL` и `RZCONTROL`. Сохраните исходный вывод, а не составленное вручную резюме.

Приведённая ниже вспомогательная функция добавляет в журнал каждую команду PnPUtil, её вывод и код завершения. Сначала задайте `$packageRoot` и `$journalDirectory`. Остановитесь после любого ненулевого кода завершения. Не повторяйте операцию с неоднозначным результатом.

```powershell
$packageRoot = Read-Host 'Full path to the extracted driver package'
$journalDirectory = Read-Host 'Full path to a new journal folder outside the package and repository'
$pnp = "$env:WINDIR\System32\pnputil.exe"
$transcript = Join-Path $journalDirectory 'pnputil-transcript.txt'
New-Item -ItemType Directory -Path $journalDirectory -ErrorAction Stop | Out-Null

function Invoke-PnpLogged {
    param([Parameter(Mandatory)][string[]]$Arguments)

    "`r`n> pnputil $($Arguments -join ' ')" |
        Out-File -LiteralPath $transcript -Append -Encoding utf8
    & $pnp @Arguments 2>&1 |
        Tee-Object -FilePath $transcript -Append
    $exitCode = $LASTEXITCODE
    "Exit code: $exitCode" |
        Out-File -LiteralPath $transcript -Append -Encoding utf8
    if ($exitCode -ne 0) {
        throw "PnPUtil failed with exit code $exitCode."
    }
}
```

<a id="4-stage-and-install-the-packages"></a>
## 4. Размещение и установка пакетов

Сначала разместите все пять подписанных пакетов, не привязывая их к устройствам:

```powershell
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_vcon\rzdevu_02e0_vcon.inf")
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzcommonu\rzcommonu.inf")
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_dkm\rzdevu_02e0_dkm.inf")
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_kbd\rzdevu_02e0_kbd.inf")
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_mou\rzdevu_02e0_mou.inf")
```

После каждой команды запишите в журнал новое опубликованное имя и идентификатор пакета из вывода. Отметьте, присутствовал ли пакет в инвентаризации до установки, чтобы при откате можно было определить пакеты, добавленные этой проверкой.

После успешного размещения всех пяти пакетов привяжите их в порядке зависимостей:

```powershell
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_dkm\rzdevu_02e0_dkm.inf", '/install')
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_vcon\rzdevu_02e0_vcon.inf", '/install')
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_kbd\rzdevu_02e0_kbd.inf", '/install')
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_mou\rzdevu_02e0_mou.inf", '/install')
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzcommonu\rzcommonu.inf", '/install')
```

Во время проверки не добавляйте `/reboot` к этим командам. Если Windows запросит перезагрузку, остановитесь и выполните её осознанно после безопасного сохранения журнала. PnPUtil не назначает устройству принудительно драйвер с более низким приоритетом, поэтому нулевой код завершения не заменяет проверку после установки.

<a id="5-check-the-result"></a>
## 5. Проверка результата

После установки проверьте точные дочерние устройства `RZVIRTUAL` и `RZCONTROL`, их службы и стеки, а также отсутствие проблем в Диспетчере устройств. Перезапустите OpenBlade и откройте About > Device information. В строке драйвера яркости Razer должно отображаться `Available · Windows OSD`; в русской локализации — «Доступно · системный индикатор Windows». Физическое нажатие клавиши яркости, её удержание и отпускание должны изменять яркость и использовать системный индикатор Windows.

<a id="roll-back-a-validation-attempt"></a>
## Откат попытки проверки

Не используйте широкое удаление устройств, `/force` или команды перезапуска всего класса. При откате можно удалять только те опубликованные пакеты, которые были добавлены этой проверкой, что подтверждается надёжно сохранённым журналом исходного состояния. Удалите эти пакеты в следующем порядке: RzCommon, VCon, мышь, клавиатура, затем DKM. Выполните `pnputil /delete-driver <journal-owned-oem.inf> /uninstall` и остановитесь, если Windows сообщит, что пакет используется или требуется перезагрузка.

<a id="technical-reference"></a>
## Технический справочник

Эта процедура соответствует [руководству по драйверу яркости Razer](https://github.com/OpenBladeProject/openblade-core/blob/main/docs/ru-RU/razer-brightness-driver-package.md#native-windows-installation-path) в OpenBlade. В этом руководстве также перечислены проверки, необходимые перед публикацией установщика в одно нажатие. Правила распространения приведены в разделе [файлов выпуска](release-assets.md).

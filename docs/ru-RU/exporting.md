<a id="exporting-an-installed-razer-driver-stack"></a>
# Экспорт установленного набора драйверов Razer

[English](../exporting.md) | [简体中文](../zh-CN/exporting.md) | Русский

Выполняйте эту процедуру на устройстве Razer, где официальное программное обеспечение уже установило драйверы. Процедура читает состояние устройств и Driver Store, затем копирует явно выбранные пакеты с помощью Windows PnPUtil. Она не устанавливает, не привязывает, не перезапускает, не отключает, не удаляет и не обновляет драйверы или устройства.

Экспорт фиксирует пакеты, установленные на одном компьютере. Он не доказывает совместимость с другой моделью, безопасность чистой установки или работоспособность функции; каждое из этих свойств требует отдельной проверки.

<a id="keep-the-raw-package-private"></a>
## Храните исходный пакет в закрытом доступе

Храните архив за пределами репозитория в закрытой рабочей папке или закрытом хранилище для передачи. Никогда не добавляйте его в историю Git или публичную задачу.

Добавляйте в коммиты только проверенный манифест в папке `devices/`. Манифест может содержать модель и неуникальные идентификаторы оборудования, версии пакетов, роли зависимостей, хеши и результаты проверки подписей. Удалите серийные номера, имена пользователей, локальные пути, полные идентификаторы экземпляров устройств, пути интерфейсов, идентификаторы контейнеров и используемые только на этом компьютере имена `oem###.inf`.

<a id="requirements"></a>
## Требования

- Windows 11, установленная непосредственно на исследуемом устройстве Razer
- Уже установленные официальные программы и драйверы Razer
- Windows PowerShell 5.1, открытый с правами администратора
- Новая закрытая папка для результата за пределами Git
- SignTool из Windows SDK, WDK или пакета Microsoft [`Microsoft.Windows.SDK.BuildTools`](https://www.nuget.org/packages/Microsoft.Windows.SDK.BuildTools) для проверки каталогов

PnPUtil входит в состав Windows. Microsoft описывает как [структурированную инвентаризацию драйверов](https://learn.microsoft.com/en-us/windows-hardware/drivers/driversecurity/create-a-driver-inventory), так и параметр [`/export-driver`](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax).

<a id="1-create-a-private-workspace"></a>
## 1. Создание закрытой рабочей папки

Выберите новую папку. Не используйте повторно старый экспорт.

```powershell
$model = 'RZ09-XXXX'
$targetVid = '1532'
$targetPid = 'XXXX'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$privateRoot = Join-Path `
    $env:TEMP `
    "Blade-$model-driver-evidence-$timestamp"

if ($model -eq 'RZ09-XXXX' -or $targetPid -eq 'XXXX') {
    throw 'Set the exact model number and target VID/PID before collection.'
}
if ($targetVid -notmatch '^[0-9A-Fa-f]{4}$' -or
    $targetPid -notmatch '^[0-9A-Fa-f]{4}$') {
    throw 'VID and PID must contain exactly four hexadecimal digits.'
}
if (Test-Path -LiteralPath $privateRoot) {
    throw "The private output already exists: $privateRoot"
}

New-Item -ItemType Directory -Path $privateRoot -ErrorAction Stop | Out-Null
```

Запишите неуникальные поля идентификации системы. Команда не включает системный UUID, серийный номер BIOS и серийный номер системной платы.

```powershell
$system = Get-ItemProperty `
    -LiteralPath 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' `
    -ErrorAction Stop

$identity = [ordered]@{
    systemManufacturer = [string]$system.SystemManufacturer
    systemProductName = [string]$system.SystemProductName
    biosVersion = [string]$system.BIOSVersion
    windowsBuild = [Environment]::OSVersion.Version.Build
    architecture = [string]$env:PROCESSOR_ARCHITECTURE
}

$identity |
    ConvertTo-Json -Depth 3 |
    Set-Content -LiteralPath `
        (Join-Path $privateRoot 'system-identity.json') `
        -Encoding UTF8
```

Остановитесь, если производитель или номер модели не соответствует устройству, которое вы собираетесь исследовать.

<a id="2-record-the-private-driver-and-device-inventory"></a>
## 2. Сбор закрытых сведений о драйверах и устройствах

Следующие отчёты содержат полные идентификаторы экземпляров и локальные пути интерфейсов. Храните их в закрытом доступе.

Используйте структурированный XML-вывод PnPUtil, а не разбирайте локализованный текст:

```powershell
$pnp = Join-Path $env:WINDIR 'System32\pnputil.exe'
$driverInventory = Join-Path $privateRoot 'driver-store-private.xml'

& $pnp /enum-drivers /devices /files /format xml /output-file $driverInventory
if ($LASTEXITCODE -ne 0) {
    throw "PnPUtil driver inventory failed with exit code $LASTEXITCODE."
}
```

Запишите граф подключённых устройств Razer. Фильтр только находит возможные устройства. Он не определяет, какой пакет предоставляет функцию.

```powershell
$escapedVid = [regex]::Escape($targetVid)
$escapedPid = [regex]::Escape($targetPid)
$physicalPattern = "^(USB|HID)\\VID_$escapedVid&PID_$escapedPid(?=&|\\|$)"
$virtualPattern = "^RZ(CONTROL|VIRTUAL)\\VID_$escapedVid&PID_$escapedPid(?=&|\\|$)"

$razerNodes = @(
    Get-PnpDevice -PresentOnly -ErrorAction Stop |
        Where-Object {
            $_.InstanceId -match $physicalPattern -or
            $_.InstanceId -match $virtualPattern
        }
)

if ($razerNodes.Count -eq 0) {
    throw "No present device matches VID $targetVid and PID $targetPid."
}

$razerNodes |
    Select-Object Class, FriendlyName, Status, InstanceId |
    ConvertTo-Json -Depth 4 |
    Set-Content -LiteralPath `
        (Join-Path $privateRoot 'razer-nodes-private.json') `
        -Encoding UTF8

$deviceTranscript = Join-Path $privateRoot 'razer-device-graph-private.txt'
foreach ($node in $razerNodes) {
    "`r`n### $($node.InstanceId)" |
        Out-File -LiteralPath $deviceTranscript -Append -Encoding utf8

    $output = @(
        & $pnp /enum-devices /instanceid $node.InstanceId `
            /deviceids /relations /services /stack /drivers /interfaces 2>&1
    )
    $exitCode = $LASTEXITCODE
    $output | Out-File -LiteralPath $deviceTranscript -Append -Encoding utf8
    "Exit code: $exitCode" |
        Out-File -LiteralPath $deviceTranscript -Append -Encoding utf8

    if ($exitCode -ne 0) {
        throw "PnPUtil could not inspect $($node.InstanceId)."
    }
}
```

Граф начинается с узлов с точными целевыми VID/PID. Проследите указанные связи до любого дочернего устройства общего типа `RAZER` и отдельно запишите его в закрытый журнал. Не расширяйте начальный фильтр на все подключённые аксессуары Razer. Отсутствие RZVIRTUAL, RZCONTROL или дочернего устройства общего типа является допустимым результатом. Не создавайте отсутствующий узел и не подставляйте идентификатор другой модели.

<a id="3-select-packages-proved-by-the-graph"></a>
## 3. Выбор пакетов, подтверждённых графом

Проверьте `driver-store-private.xml` вместе с записью устройств. Выбирайте опубликованный OEM INF только тогда, когда граф показывает, что он привязан к физическому устройству Razer или соответствующему дочернему устройству.

Не выбирайте каждый пакет, в поле поставщика которого есть `Razer`. Не выбирайте неиспользуемый пакет только потому, что его версия новее. Не переносите количество пакетов, имя SYS, службу или топологию виртуальных устройств из другой записи каталога.

Сохраните опубликованные имена, используемые только на этом компьютере, в закрытом журнале:

```powershell
$publishedInfs = @(
    # Add only OEM INF names proved by this machine's exact target graph.
)

if ($publishedInfs.Count -eq 0) {
    throw 'No device-bound Razer packages were selected.'
}
```

Если связь пакета с устройством неясна, запросите проверку до экспорта. Экспорт не изменяет систему, но при неполном выборе можно пропустить необходимый фильтр или пакет виртуального устройства.

<a id="4-export-complete-driver-store-packages"></a>
## 4. Экспорт полных пакетов Driver Store

Экспортируйте каждый выбранный опубликованный INF в отдельную папку. Не копируйте отдельный файл SYS из `System32\drivers` или `FileRepository`. Подписанный пакет также включает INF, каталог и все остальные файлы, указанные в INF.

```powershell
$packageRoot = Join-Path $privateRoot 'packages'
New-Item -ItemType Directory -Path $packageRoot -ErrorAction Stop | Out-Null

foreach ($publishedInf in $publishedInfs) {
    if ($publishedInf -notmatch '^oem[0-9]+\.inf$') {
        throw "Unexpected published INF name: $publishedInf"
    }

    $destination = Join-Path $packageRoot `
        ([IO.Path]::GetFileNameWithoutExtension($publishedInf))
    New-Item -ItemType Directory -Path $destination -ErrorAction Stop | Out-Null

    & $pnp /export-driver $publishedInf $destination
    if ($LASTEXITCODE -ne 0) {
        throw "Export of $publishedInf failed with exit code $LASTEXITCODE."
    }
}
```

Не используйте `/export-driver *`. Широкий экспорт собирает несвязанные проприетарные драйверы и скрывает связь пакета с устройством.

<a id="5-hash-and-inspect-the-export"></a>
## 5. Хеширование и проверка экспорта

Создайте закрытый манифест файлов с относительными путями. Состояние Authenticode полезно для инвентаризации, но не заменяет проверку принадлежности к каталогу.

```powershell
$files = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File)
$fileManifest = foreach ($file in $files | Sort-Object FullName) {
    $signature = Get-AuthenticodeSignature -LiteralPath $file.FullName
    [pscustomobject]@{
        path = $file.FullName.Substring($packageRoot.Length + 1).Replace('\', '/')
        length = $file.Length
        sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        fileVersion = $file.VersionInfo.FileVersion
        signatureStatus = [string]$signature.Status
        signerSubject = $signature.SignerCertificate.Subject
        signerThumbprint = $signature.SignerCertificate.Thumbprint
    }
}

$fileManifest |
    ConvertTo-Json -Depth 5 |
    Set-Content -LiteralPath `
        (Join-Path $privateRoot 'package-files-private.json') `
        -Encoding UTF8
```

Прочитайте каждый INF. Запишите его исходное имя файла, поставщика, класс, `DriverVer`, имя каталога, службы, объявления фильтров, копируемые двоичные файлы и точные совпадения оборудования Razer. Не изменяйте экспортированный файл. Microsoft объясняет, что [изменение файла, включённого в каталог, делает подпись пакета недействительной](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/catalog-files).

Используйте SignTool для проверки каждого каталога и каждого INF, SYS, DLL или другого файла пакета по этому каталогу. Повторите команду проверки принадлежности для каждого файла пакета:

```powershell
$sdkBin = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
$signTool = Get-ChildItem -LiteralPath $sdkBin -Recurse -Filter signtool.exe |
    Where-Object { (Split-Path -Leaf (Split-Path -Parent $_.FullName)) -eq 'x64' } |
    Sort-Object FullName -Descending |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $signTool) { throw 'Install or extract Windows SDK SignTool first.' }
$catalog = Join-Path $packageRoot '<package>\package.cat'
$inf = Join-Path $packageRoot '<package>\package.inf'
$driver = Join-Path $packageRoot '<package>\driver.sys'

& $signTool verify /kp /v $catalog
if ($LASTEXITCODE -ne 0) { throw 'Catalog signature verification failed.' }

& $signTool verify /kp /v /c $catalog $inf
if ($LASTEXITCODE -ne 0) { throw 'INF catalog membership verification failed.' }

& $signTool verify /kp /v /c $catalog $driver
if ($LASTEXITCODE -ne 0) { throw 'Driver catalog membership verification failed.' }
```

Если SignTool не установлен, скачайте принадлежащий Microsoft пакет NuGet `Microsoft.Windows.SDK.BuildTools` в закрытую папку инструментов. Проверьте пакет перед распаковкой:

```powershell
dotnet nuget verify --all .\Microsoft.Windows.SDK.BuildTools.<version>.nupkg
tar -xf .\Microsoft.Windows.SDK.BuildTools.<version>.nupkg -C .\sdk-build-tools
$signTool = Get-ChildItem -LiteralPath .\sdk-build-tools `
    -Recurse -Filter signtool.exe |
    Where-Object { (Split-Path -Leaf (Split-Path -Parent $_.FullName)) -eq 'x64' } |
    Select-Object -First 1 -ExpandProperty FullName
```

Запишите имя и версию пакета SDK, SHA-256, версию продукта SignTool, политику проверки, время UTC и число успешно проверенных каталогов и их элементов в очищенном манифесте каталога. Не записывайте локальные пути к инструменту или пакету.

<a id="6-create-the-private-evidence-archive"></a>
## 6. Создание закрытого архива собранных данных

Создайте архив собранных данных после проверки выбранных пакетов, хешей, подписей и принадлежности к каталогам. Этот архив включает закрытые инвентаризации и никогда не должен становиться файлом выпуска, даже если распространение драйвера разрешено.

```powershell
$privateEvidenceArchive = "$privateRoot-private-evidence.zip"
if (Test-Path -LiteralPath $privateEvidenceArchive) {
    throw "The archive already exists: $privateEvidenceArchive"
}

Compress-Archive `
    -LiteralPath $privateRoot `
    -DestinationPath $privateEvidenceArchive `
    -CompressionLevel Optimal

Get-FileHash -LiteralPath $privateEvidenceArchive -Algorithm SHA256
```

Запишите хеш архива собранных данных в закрытый журнал. Не прикладывайте его к публичной задаче, запросу на включение изменений или выпуску.

Для распространяемого файла требуется отдельный экспортёр, предназначенный для конкретной модели. Этот экспортёр должен начинать с проверенного манифеста, копировать только разрешённые файлы пакетов, удалять псевдонимы, используемые только на этом компьютере, и закрытые инвентаризации, проверять зафиксированные хеши и данные подписантов и добавлять необходимое уведомление о сторонних компонентах. Экспортёр для точного идентификатора `02E0` в OpenBlade core является одной разрешённой реализацией. Не превращайте эту общую процедуру сбора в средство создания выпуска.

Требования к проверке и разрешениям для распространяемого архива приведены в разделе [Файлы выпуска и границы репозитория](release-assets.md).

<a id="7-prepare-a-commit-safe-catalog-entry"></a>
## 7. Подготовка записи каталога, безопасной для коммита

Скопируйте `templates/driver-stack-evidence.template.json` в путь точной модели и оборудования внутри `devices/`, затем замените заполнители проверенными фактами. Сохраните:

- модель, название продукта, BIOS, сборку Windows и архитектуру;
- идентификаторы VID, PID, MI и COL без уникальных суффиксов экземпляров;
- связи устройств с пакетами и отношения между родительскими и дочерними устройствами;
- исходные имена INF, поставщика, класс, `DriverVer`, службы, фильтры, двоичные файлы и роли пакетов;
- относительные имена файлов пакета, размеры, версии, хеши SHA-256, данные подписанта, состояние подписи и результаты проверки принадлежности к каталогу;
- версию приложения поставщика, которое предоставило установленный набор;
- время сбора в формате ISO-8601 UTC или `Unavailable`, если оно не было сохранено;
- имя и SHA-256 проверенного архива только с пакетами, но никогда не хеш закрытого архива собранных данных;
- происхождение экспортёра, если экспортёр для конкретной модели прошёл проверку;
- указанное лицо или организацию, предоставившую разрешение, основание для этих сведений и результат независимой проверки документа с разрешением; и
- явные ограничения и проверки конфиденциальности.

Удалите псевдонимы `oem###.inf`, используемые только на этом компьютере, и все локальные или уникальные значения. Запись каталога содержит только хеши и метаданные.

Для неопубликованной записи инвентаризации без проверенного экспортёра не добавляйте `collection.exporterProvenance` и задайте для `redistribution.status` значение `NotPublished`. Добавляйте происхождение экспортёра только при наличии точного проверенного экспортёра.

Используйте путь такого вида:

```text
devices/rz09-xxxx/1532-xxxx/driver-version/manifest.json
```

Сначала рецензенты проверяют, могут ли пакеты предоставлять нужную функцию. Анализ работы драйверов, физическая проверка, перезапуск хоста драйвера, перезагрузка, переход в спящий режим, чистая установка и откат требуют отдельных проверок.

<a id="commands-that-are-out-of-scope"></a>
## Команды за пределами этой процедуры

В этой процедуре никогда не используются параметры PnPUtil `/add-driver`, `/install`, `/delete-driver`, `/uninstall`, `/force`, `/disable-device`, `/enable-device`, `/restart-device`, `/remove-device` или `/scan-devices`. Она не открывает интерфейс управления Razer и не отправляет IOCTL или отчёт HID.

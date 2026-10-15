<a id="exporting-an-installed-razer-driver-stack"></a>

# 导出已安装的 Razer 驱动栈

[English](../exporting.md) | 简体中文 | [Русский](../ru-RU/exporting.md)

如果 Razer 设备已通过官方软件安装驱动，可按此流程导出。
工具先读取设备和 Driver Store 状态，再用 Windows PnPUtil 复制明确选中的驱动包。
它不会安装、绑定、重启、禁用、移除或更新驱动或设备。

导出结果只记录这台机器上已安装的驱动包。其他型号是否兼容、能否安全全新安装、是否具备某项运行时功能，都需要单独验证。

<a id="keep-the-raw-package-private"></a>

## 原始包必须保密

请将归档放在仓库之外的私密工作目录或传输位置。
绝不要加入 Git 历史或公开议题。

只提交 `devices/` 下经过审核的清单。
清单可包含型号、非唯一硬件 ID、包版本、依赖用途、哈希和签名结果。
删除序列号、用户名、本地路径、完整设备实例 ID、接口路径、容器 ID，
以及机器本地的 `oem###.inf` 名称。

<a id="requirements"></a>

## 要求

- 在待调查的 Razer 设备上原生运行 Windows 11
- 已安装官方 Razer 软件和驱动
- 以管理员身份打开 Windows PowerShell 5.1
- Git 之外的新私密输出目录
- 来自 Windows SDK、WDK 或 Microsoft
  [`Microsoft.Windows.SDK.BuildTools`](https://www.nuget.org/packages/Microsoft.Windows.SDK.BuildTools)
  包的 SignTool，用于验证签名目录

PnPUtil 随 Windows 提供。Microsoft 记录了
[结构化驱动清单](https://learn.microsoft.com/en-us/windows-hardware/drivers/driversecurity/create-a-driver-inventory)
和 [`/export-driver`](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax)。

<a id="1-create-a-private-workspace"></a>

## 1. 创建私密工作目录

选择一个新目录。不要复用旧导出。

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

记录不能唯一识别这台机器的系统身份字段。命令省略系统 UUID、BIOS 序列号和主板序列号。

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

如果制造商或型号不匹配要调查的设备，请停止。

<a id="2-record-the-private-driver-and-device-inventory"></a>

## 2. 记录私密驱动和设备清单

接下来的报告包含完整实例 ID 和本地接口路径，必须保密。

使用 PnPUtil 的结构化 XML 输出，不要解析已本地化的文本：

```powershell
$pnp = Join-Path $env:WINDIR 'System32\pnputil.exe'
$driverInventory = Join-Path $privateRoot 'driver-store-private.xml'

& $pnp /enum-drivers /devices /files /format xml /output-file $driverInventory
if ($LASTEXITCODE -ne 0) {
    throw "PnPUtil driver inventory failed with exit code $LASTEXITCODE."
}
```

记录已连接 Razer 设备的关系图。
筛选结果只是候选项，不能据此判断某项功能由哪个驱动包实现。

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

关系图从精确目标 VID/PID 的节点开始。
根据所报告的关系查找通用 `RAZER` 子设备，并在私密日志中单独记录该子设备。
不要将初始筛选扩大到所有已连接 Razer 配件。
没有 RZVIRTUAL、RZCONTROL 或通用子设备也是有效结果。
不要创建缺失节点，也不要用其他型号的身份替代。

<a id="3-select-packages-proved-by-the-graph"></a>

## 3. 根据设备关系图选择驱动包

对照 `driver-store-private.xml` 和设备日志进行检查。
仅当关系图显示某个已发布 OEM INF 绑定到该 Razer 物理设备或相关后代设备时，才选择它。

不要选择提供者包含 `Razer` 的所有包，也不要因为版本较新就选择未使用的包。
不要套用其他目录条目中的包数量、SYS 名称、服务或虚拟设备拓扑。

将机器本地的已发布名称保存在私密日志中：

```powershell
$publishedInfs = @(
    # Add only OEM INF names proved by this machine's exact target graph.
)

if ($publishedInfs.Count -eq 0) {
    throw 'No device-bound Razer packages were selected.'
}
```

包与设备关系不明确时，请先请求审核，再导出。
导出是只读操作，但不完整的选择可能漏掉必要的筛选器或虚拟设备包。

<a id="4-export-complete-driver-store-packages"></a>

## 4. 导出完整 Driver Store 包

将每个选中的已发布 INF 导出到独立目录。
不要从 `System32\drivers` 或 `FileRepository` 只复制 SYS 文件。
签名包还包括 INF、签名目录，以及 INF 声明的其他文件。

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

不要使用 `/export-driver *`。
大范围导出会混入无关的专有驱动，也会让包与设备的对应关系难以辨认。

<a id="5-hash-and-inspect-the-export"></a>

## 5. 计算哈希并检查导出

创建使用相对路径的私密文件清单。
Authenticode 状态是有用的清单信息，但不能代替签名目录成员关系检查。

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

阅读每个 INF，记录原始文件名、提供者、类别、`DriverVer`、签名目录名称、
服务、筛选器声明、复制的二进制文件，以及精确 Razer 硬件匹配。
不要修改导出文件。Microsoft 说明了
[修改签名目录中的文件会使包签名失效](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/catalog-files)。

使用 SignTool 验证每个签名目录，并对照该目录验证每个 INF、SYS、DLL 或其他负载文件。
对包中的每个文件都运行下面的成员关系验证命令：

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

如果未安装 SignTool，请将 Microsoft 发布的 `Microsoft.Windows.SDK.BuildTools`
NuGet 包下载到私密工具目录，解压前先验证包：

```powershell
dotnet nuget verify --all .\Microsoft.Windows.SDK.BuildTools.<version>.nupkg
tar -xf .\Microsoft.Windows.SDK.BuildTools.<version>.nupkg -C .\sdk-build-tools
$signTool = Get-ChildItem -LiteralPath .\sdk-build-tools `
    -Recurse -Filter signtool.exe |
    Where-Object { (Split-Path -Leaf (Split-Path -Parent $_.FullName)) -eq 'x64' } |
    Select-Object -First 1 -ExpandProperty FullName
```

在脱敏后的目录清单中记录 SDK 包名称、版本、SHA-256、SignTool 产品版本、
验证策略、UTC 时间，以及验证成功的签名目录和成员数量。
不要记录本地工具或包路径。

<a id="6-create-the-private-evidence-archive"></a>

## 6. 创建私密证据归档

审核选中包、哈希、签名和签名目录成员关系后，再创建证据归档。
此归档包含私密清单，即使已获驱动再分发授权，也绝不能作为发布附件。

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

在私密日志中记录证据归档哈希。
不要将它附到公开议题、拉取请求或版本发布中。

要生成可分发的附件，必须使用独立的型号专用导出器。
该导出器必须从经过审核的清单开始，只复制已准入包文件、
移除机器本地别名和私密清单、验证固定哈希和签名者身份，并加入必需的第三方声明。
OpenBlade 核心中仅适用于 `02E0` 的导出器已通过准入审核。
不要把此通用收集流程变成发布构建器。

可分发归档的审核和授权要求见[发布附件与仓库边界](release-assets.md)。

<a id="7-prepare-a-commit-safe-catalog-entry"></a>

## 7. 准备可安全提交的目录条目

将 `templates/driver-stack-evidence.template.json` 复制到 `devices/` 下精确型号和硬件路径，
再用经过审核的事实替换占位符。保留以下信息：

- 型号、产品名称、BIOS、Windows 构建版本和架构；
- 不含唯一实例后缀的 VID、PID、MI 和 COL 标识；
- 设备与包的关系，以及父子关系；
- 厂商原始 INF 名称、提供者、类别、`DriverVer`、服务、筛选器、二进制文件和包用途；
- 相对包文件名、大小、版本、SHA-256 哈希、签名者身份、签名状态及签名目录成员关系结果；
- 提供已安装驱动栈的厂商应用版本；
- ISO-8601 UTC 格式的收集时间，未保留时填写 `Unavailable`；
- 经过审核的纯包归档文件名和 SHA-256，绝不填写私密证据归档哈希；
- 型号专用导出器经过审核时，记录其来源；
- 据报告授予授权的一方、报告依据，以及授权文件是否经过独立审核；
- 明确的限制和隐私检查。

移除本机的 `oem###.inf` 别名，以及所有本地信息和唯一标识。
目录条目只包含哈希和元数据。

未公开且没有经过审核导出器的清单条目，应省略 `collection.exporterProvenance`，
并将 `redistribution.status` 设为 `NotPublished`。
只有存在精确、经过审核的导出器时，才添加导出器来源。

路径示例：

```text
devices/rz09-xxxx/1532-xxxx/driver-version/manifest.json
```

审核者先检查这些包是否可能提供目标功能。
运行时分析、物理验证、驱动宿主重启、系统重启、睡眠、全新安装和回滚均需独立检查。

<a id="commands-that-are-out-of-scope"></a>

## 范围之外的命令

此流程绝不使用 PnPUtil `/add-driver`、`/install`、`/delete-driver`、`/uninstall`、
`/force`、`/disable-device`、`/enable-device`、`/restart-device`、`/remove-device`
或 `/scan-devices`。它不打开 Razer 控制接口，也不发送 IOCTL 或 HID 报告。

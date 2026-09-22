# Exporting an installed Razer driver stack

Use this workflow on a Razer device whose official software has already
installed the drivers. It reads device and Driver Store state, then copies
explicitly selected packages with Windows PnPUtil. It does not install, bind,
restart, disable, remove, or update a driver or device.

An export is candidate evidence from one machine. It does not prove that
another model uses the same package, that the package is safe to install on a
clean machine, or that it provides a particular runtime feature.

## Keep the raw package private

The private archive belongs in neither Git history nor a public issue. Keep it
outside the repository in a private working directory or transfer location.

Commit only a reviewed manifest under `devices/`. The manifest may contain
model and non-unique hardware IDs, package versions, dependency roles, hashes,
and signature results. Remove serials, usernames, local paths, full
device-instance IDs, interface paths, container IDs, and machine-local
`oem###.inf` names.

## Requirements

- Native Windows 11 on the Razer device being investigated
- Official Razer software and drivers already installed
- Windows PowerShell 5.1 opened as administrator
- A new private output directory outside Git
- SignTool from the Windows SDK, WDK, or Microsoft's
  [`Microsoft.Windows.SDK.BuildTools`](https://www.nuget.org/packages/Microsoft.Windows.SDK.BuildTools)
  package for catalog verification

PnPUtil is included with Windows. Microsoft documents both the
[structured driver inventory](https://learn.microsoft.com/en-us/windows-hardware/drivers/driversecurity/create-a-driver-inventory)
and [`/export-driver`](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax).

## 1. Create a private workspace

Choose a new directory. Do not reuse an old export.

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

Record non-unique system identity fields. This block deliberately omits the
system UUID, BIOS serial, and baseboard serial.

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

Stop if the manufacturer or model number does not match the device you intend
to investigate.

## 2. Record the private driver and device inventory

The next reports contain full instance IDs and local interface paths. Keep them
private.

Use PnPUtil's structured XML output instead of parsing localized text:

```powershell
$pnp = Join-Path $env:WINDIR 'System32\pnputil.exe'
$driverInventory = Join-Path $privateRoot 'driver-store-private.xml'

& $pnp /enum-drivers /devices /files /format xml /output-file $driverInventory
if ($LASTEXITCODE -ne 0) {
    throw "PnPUtil driver inventory failed with exit code $LASTEXITCODE."
}
```

Record the connected Razer device graph. The filter discovers candidates only.
It does not decide which package provides a feature.

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

The graph starts from exact target VID/PID nodes. Follow the reported relations
to any generic `RAZER` child and record that child separately in the private
journal. Do not broaden the initial filter to every attached Razer accessory.
Absence of RZVIRTUAL, RZCONTROL, or a generic child is a valid result. Do not
create a missing node or substitute an identity from a different model.

## 3. Select packages proved by the graph

Review `driver-store-private.xml` together with the device transcript. Select a
published OEM INF only when the graph shows that it is bound to the physical
Razer device or a relevant descendant.

Do not select every package whose provider contains `Razer`. Do not select an
unused package because its version is newer. Do not assume a package count,
SYS name, service, or virtual-device topology from another catalog entry.

Keep the machine-local published names in the private journal:

```powershell
$publishedInfs = @(
    # Add only OEM INF names proved by this machine's exact target graph.
)

if ($publishedInfs.Count -eq 0) {
    throw 'No device-bound Razer packages were selected.'
}
```

Ask for review before export if a package-to-device relationship is unclear.
Exporting is read-only, but an incomplete selection can hide a required filter
or virtual-device package.

## 4. Export complete Driver Store packages

Export each selected published INF into its own directory. Do not copy a bare
SYS file from `System32\drivers` or `FileRepository`. The signed package also
includes its INF, catalog, and any other files declared by the INF.

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

Do not use `/export-driver *`. A broad export collects unrelated proprietary
drivers and obscures the package-to-device relationship.

## 5. Hash and inspect the export

Create a private file manifest with relative paths. Authenticode status is
useful inventory, but it does not replace catalog membership checks.

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

Read each INF. Record its original filename, provider, class, `DriverVer`,
catalog name, services, filter declarations, copied binaries, and exact Razer
hardware matches. Do not edit an exported file. Microsoft explains that
[changing a cataloged file invalidates the package signature](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/catalog-files).

Use SignTool to verify each catalog and every INF, SYS, DLL, or other payload
against that catalog. Repeat the membership command for every package file:

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

If SignTool is not installed, download the Microsoft-owned
`Microsoft.Windows.SDK.BuildTools` NuGet package to a private tools directory.
Verify the package before extracting it:

```powershell
dotnet nuget verify --all .\Microsoft.Windows.SDK.BuildTools.<version>.nupkg
tar -xf .\Microsoft.Windows.SDK.BuildTools.<version>.nupkg -C .\sdk-build-tools
$signTool = Get-ChildItem -LiteralPath .\sdk-build-tools `
    -Recurse -Filter signtool.exe |
    Where-Object { (Split-Path -Leaf (Split-Path -Parent $_.FullName)) -eq 'x64' } |
    Select-Object -First 1 -ExpandProperty FullName
```

Record the SDK package name, version, SHA-256, SignTool product version,
verification policy, UTC time, and successful catalog and member counts in the
sanitized catalog manifest. Do not record the local tool or package paths.

## 6. Create the private evidence archive

Create an evidence archive after reviewing the selected packages, hashes,
signatures, and catalog membership. This archive includes private inventories
and must never become a release asset, even when driver redistribution is
authorized.

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

Record the evidence archive hash in the private journal. Do not attach it to a
public issue, pull request, or release.

A distributable asset needs a separate, model-specific exporter. That exporter
must start from the reviewed manifest, copy only admitted package files, remove
machine-local aliases and private inventories, verify fixed hashes and signer
identities, and add the required third-party notice. The exact `02E0` exporter
in OpenBlade core is one admitted implementation. Do not turn this generic
collection workflow into a release builder.

See [Release assets and repository boundaries](release-assets.md) for the
review and permission requirements that apply to a distributable archive.

## 7. Prepare a commit-safe catalog entry

Copy `templates/driver-stack-evidence.template.json` to an exact model and
hardware path under `devices/`, then replace its placeholders with reviewed
facts. Keep:

- the model, product name, BIOS, Windows build, and architecture;
- VID, PID, MI, and COL identifiers without unique instance suffixes;
- device-to-package and parent-child relationships;
- original vendor INF names, provider, class, `DriverVer`, services, filters,
  binaries, and package roles;
- relative package filenames, sizes, versions, SHA-256 hashes, signer identity,
  signature status, and catalog membership results;
- the vendor application version that supplied the installed stack;
- the collection time in ISO-8601 UTC form, or `Unavailable` when it was not
  retained;
- the reviewed package-only archive filename and SHA-256, never the private
  evidence archive hash;
- the reported permission grantor, the basis for that report, and whether the
  permission document received an independent review; and
- explicit limitations and privacy checks.

Remove machine-local `oem###.inf` aliases and every local or unique value. The
catalog entry contains hashes and metadata only.

Use a path such as:

```text
devices/rz09-xxxx/1532-xxxx/driver-version/manifest.json
```

The first review decides whether the packages identify a candidate feature
path. Runtime analysis, physical validation, driver-host recycle, reboot,
sleep, clean installation, and rollback are separate gates.

## Commands that are out of scope

This workflow never uses PnPUtil `/add-driver`, `/install`, `/delete-driver`,
`/uninstall`, `/force`, `/disable-device`, `/enable-device`, `/restart-device`,
`/remove-device`, or `/scan-devices`. It does not open a Razer control
interface or send an IOCTL or HID report.

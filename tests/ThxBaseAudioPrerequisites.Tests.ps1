[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot

function Assert-ThxBaseAudioPrerequisites($Entry) {
    if ($Entry.manifestType -cne 'OpenBlade.ThxBaseAudioPrerequisites' -or
        $Entry.schemaVersion -ne 1 -or
        $Entry.'$schema' -cne '../../schemas/thx-base-audio-prerequisites.schema.json') {
        throw 'Unknown THX base-audio prerequisite evidence type.'
    }
    if ($Entry.status.evidence -cne 'SourceVerified' -or
        $Entry.status.installation -cne 'InstallationUnvalidated' -or
        $Entry.status.provisioningImplemented -ne $false) {
        throw 'THX base-audio evidence overstated installation or provisioning status.'
    }

    $expectedIntelSource =
        '04ff47e5-1b36-42e9-bc4a-af4954a217be|' +
        'https://www.catalog.update.microsoft.com/ScopedViewInline.aspx?updateid=04ff47e5-1b36-42e9-bc4a-af4954a217be|' +
        'https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/2026/02/6980ba42-6b23-4156-8c81-ab8ec2466d12_7f51f5eabbc0ee293e12ac3c2980a64d2d994651.cab|' +
        '33406870|BC77F3E1371C05BFE4EE68E70E4BE6A06F352143043FF0195FF92F23B8B6CDF3'
    $actualIntelSource = '{0}|{1}|{2}|{3}|{4}' -f
        $Entry.intel.source.updateId, $Entry.intel.source.detailUrl,
        $Entry.intel.source.downloadUrl, $Entry.intel.source.cabSize,
        $Entry.intel.source.cabSha256
    if ($actualIntelSource -cne $expectedIntelSource) {
        throw 'Official Intel source URL, size or digest drifted.'
    }

    $expectedCatalogIds = @(
        'INTELAUDIO\DIF_0005&UIF_0000&SDW_CTLR_DEV_E328&VEN_8086&DEV_0333',
        'INTELAUDIO\SDW_CTLR_DEV_E328&VEN_8086&DEV_0333')
    if ((@($Entry.intel.catalogHardwareIds) -join '|') -cne ($expectedCatalogIds -join '|')) {
        throw 'Official Intel Catalog applicability is not the reviewed generic E328 set.'
    }

    $expectedChain = @(
        'PCI\VEN_8086&DEV_E328&SUBSYS_30101A58&REV_00',
        'INTELAUDIO\DSP_CTLR_DEV_E328&VEN_8086&DEV_0222&SUBSYS_30101A58&REV_0000',
        'INTELAUDIO\SDW_CTLR_DEV_E328&VEN_8086&DEV_0333&SUBSYS_30101A58')
    if ((@($Entry.intel.exactObservedChain) -join '|') -cne ($expectedChain -join '|')) {
        throw 'Exact RZ09-0581 E328 controller chain drifted.'
    }
    if ((@($Entry.intel.models) -join '|') -cne 'RZ09-0581' -or
        $Entry.intel.activeInfByteMatchesOfficialCab -ne $true -or
        $Entry.intel.root -cne 'IntcAudioBus.inf' -or
        $Entry.intel.limit -notmatch 'generic E328' -or
        $Entry.intel.limit -notmatch 'does not establish SUBSYS_30101A58') {
        throw 'Intel model, byte identity, root or admission boundary drifted.'
    }

    $expectedBindings = @(
        'IntcAudioBus.inf=20.43.12634.0',
        'IntcOED.inf=20.43.12634.0',
        'IntcSdwBus.inf=20.43.12634.0')
    if ((@($Entry.intel.activePublishedInfBindings) -join '|') -cne
        ($expectedBindings -join '|')) {
        throw 'Active Intel INF version evidence drifted.'
    }

    $expectedCopyInf = @(
        'IntcOED.inf', 'IntcSdwBus.inf', 'IntcUSB.inf', 'IntcBTAu.inf',
        'IntcDMic.inf', 'IntcSST.inf', 'DetectionVerificationDrv.inf',
        'IntcSSDW.inf', 'IntcSBtLe.inf')
    if ((@($Entry.intel.copyInf) -join '|') -cne ($expectedCopyInf -join '|')) {
        throw 'Intel CopyINF closure drifted.'
    }

    $packages = @($Entry.intel.packages)
    $files = @($packages | ForEach-Object { $_.files })
    $expectedPackages = @('IntcAudioBus.inf') + $expectedCopyInf
    if ($packages.Count -ne 10 -or $files.Count -ne 65 -or
        (@($packages.inf) -join '|') -cne ($expectedPackages -join '|') -or
        @($files | Where-Object { $_.catalogMembership -cne 'Verified' }).Count -ne 0) {
        throw 'Intel signed package closure is incomplete.'
    }
    foreach ($package in $packages) {
        if ($package.catalog.status -cne 'Valid' -or
            $package.catalog.signer -notmatch '^CN=Microsoft Windows Hardware Compatibility Publisher,' -or
            $package.catalog.issuer -notmatch '^CN=Microsoft Windows Third Party Component CA 2012,' -or
            $package.catalog.thumbprint -cne '32B4E7CE92A59C722B8BDF7AE3E66520CFB9DE21' -or
            $package.catalog.size -lt 1 -or
            $package.catalog.sha256 -cnotmatch '^[A-F0-9]{64}$') {
            throw "Intel catalog evidence is incomplete for '$($package.inf)'."
        }
    }

    $expectedExcluded = @(
        'IntcAcaCxSensor.inf', 'IntcNldCxSensor.inf',
        'IntcAudioSensorProxyDriver.inf', 'LT6911Au.inf')
    if ((@($Entry.intel.sameCabNotInRootClosure) -join '|') -cne
        ($expectedExcluded -join '|')) {
        throw 'Unrelated same-CAB Intel packages drifted into the root closure.'
    }

    $expectedRealtekSource =
        'f71ce91f-b0b5-429f-bfff-b543346235ad|0f83ef46-311d-40c7-8994-f44bae577952|' +
        'https://www.catalog.update.microsoft.com/ScopedViewInline.aspx?updateid=f71ce91f-b0b5-429f-bfff-b543346235ad|' +
        'https://www.catalog.update.microsoft.com/ScopedViewInline.aspx?updateid=0f83ef46-311d-40c7-8994-f44bae577952|' +
        'https://catalog.s.download.windowsupdate.com/c/msdownload/update/driver/drvs/2025/12/1c966046-ecd6-45e9-925f-082db468dd12_7e26b6d172655b467d0ed11a646dc2fba919dab2.cab|' +
        '13640113|6B82AB54C802FECED29BDEAF2248FC861B48DECD94AFD236AB652A19584B3FF9'
    $actualRealtekSource = '{0}|{1}|{2}|{3}|{4}|{5}|{6}' -f
        $Entry.realtek.source.updateIds[0], $Entry.realtek.source.updateIds[1],
        $Entry.realtek.source.detailUrls[0], $Entry.realtek.source.detailUrls[1],
        $Entry.realtek.source.downloadUrl, $Entry.realtek.source.cabSize,
        $Entry.realtek.source.cabSha256
    if ($actualRealtekSource -cne $expectedRealtekSource) {
        throw 'Official Realtek source URLs, size or digest drifted.'
    }
    if ($Entry.realtek.models.RZ09_0528 -cne
        'HDAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A58300E' -or
        $Entry.realtek.models.RZ09_0530 -cne
        'HDAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A582023' -or
        $Entry.realtek.driverVer -cne '10/28/2025,6.0.9906.1' -or
        $Entry.realtek.inf -cne 'HDXACPRazer.inf' -or
        $Entry.realtek.catalog.status -cne 'Valid' -or
        $Entry.realtek.catalog.thumbprint -cne '4208374A9DBBCD92CBC4814EEE5234BC0E2EA94B') {
        throw 'Exact Realtek model or catalog evidence drifted.'
    }

    $realtekFiles = @($Entry.realtek.files)
    $expectedRealtekFiles = @(
        'HDXACPRazer.inf', 'hdxrt.cat', 'RTKVHD64.sys',
        'RTAIODAT.DAT', 'RtEventLog.dll')
    if ($realtekFiles.Count -ne 5 -or
        (@($realtekFiles.path) -join '|') -cne ($expectedRealtekFiles -join '|') -or
        @($realtekFiles | Where-Object {
                $_.path -ne 'hdxrt.cat' -and $_.catalogMembership -cne 'Verified'
            }).Count -ne 0) {
        throw 'Exact-model Realtek five-file closure is incomplete.'
    }

    foreach ($file in @($files) + $realtekFiles) {
        if ($file.size -lt 1 -or $file.sha256 -cnotmatch '^[A-F0-9]{64}$') {
            throw "Invalid file pin for '$($file.path)'."
        }
    }
    if ($Entry.verification.intelCatalogs -ne 10 -or
        $Entry.verification.intelMemberChecks -ne 65 -or
        $Entry.verification.intelFailures -ne 0 -or
        $Entry.verification.realtekMemberChecks -ne 4 -or
        $Entry.verification.realtekFailures -ne 0 -or
        $Entry.verification.synapseReferences -ne 0) {
        throw 'Verification counts failed or a Synapse dependency was introduced.'
    }
}

$schemaPath = Join-Path $repository 'schemas\thx-base-audio-prerequisites.schema.json'
$entryPath = Join-Path $repository 'evidence\thx-base-audio\prerequisites.json'
$raw = Get-Content -LiteralPath $entryPath -Raw
$entry = $raw | ConvertFrom-Json
Assert-ThxBaseAudioPrerequisites $entry

# Windows PowerShell 5.1 runs the semantic validator above. PowerShell 7 adds
# strict JSON Schema validation when Test-Json is available.
if ((Get-Command Test-Json -ErrorAction SilentlyContinue) -and
    -not (Test-Json -Json $raw -SchemaFile $schemaPath)) {
    throw 'THX base-audio prerequisite evidence does not satisfy its strict schema.'
}

$mutations = @(
    { param($x) $x.status.installation = 'InstallationValidated' },
    { param($x) $x.status.provisioningImplemented = $true },
    { param($x) $x.intel.source.downloadUrl = 'https://example.invalid/intel.cab' },
    { param($x) $x.intel.source.cabSize++ },
    { param($x) $x.intel.source.cabSha256 = 'A' * 64 },
    { param($x) $x.intel.catalogHardwareIds[0] = $x.intel.exactObservedChain[2] },
    { param($x) $x.intel.exactObservedChain[2] = 'INTELAUDIO\SDW_CTLR_DEV_E328&VEN_8086&DEV_0333' },
    { param($x) $x.intel.copyInf = @($x.intel.copyInf | Select-Object -Skip 1) },
    { param($x) $x.intel.packages[0].files[0].catalogMembership = 'Unknown' },
    { param($x) $x.realtek.source.detailUrls[0] = 'https://example.invalid/detail' },
    { param($x) $x.realtek.source.cabSize++ },
    { param($x) $x.realtek.source.cabSha256 = 'B' * 64 },
    { param($x) $x.realtek.models.RZ09_0528 = $x.realtek.models.RZ09_0530 },
    { param($x) $x.verification.synapseReferences = 1 }
)
foreach ($mutation in $mutations) {
    $changed = $raw | ConvertFrom-Json
    & $mutation $changed
    $rejected = $false
    try { Assert-ThxBaseAudioPrerequisites $changed } catch { $rejected = $true }
    if (-not $rejected) {
        throw 'THX base-audio validator accepted an unsafe evidence mutation.'
    }
}

$pathSeparator = [regex]::Escape([string][char]92)
if ($raw -match "(?i)[A-Z]:$pathSeparator|oem\d+\.inf") {
    throw 'Published evidence contains a local path or machine-local OEM INF name.'
}

Write-Output 'THX base-audio prerequisite contracts passed: 10 Intel catalogs, 65 Intel members, 5 Realtek files and 14 rejection checks.'

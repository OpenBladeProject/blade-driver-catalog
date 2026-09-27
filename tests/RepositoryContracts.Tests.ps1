[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot

function Assert-True {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-RequiredProperties {
    param(
        [Parameter(Mandatory)]$Value,
        [Parameter(Mandatory)][string[]]$Names,
        [Parameter(Mandatory)][string]$Context
    )

    foreach ($name in $Names) {
        Assert-True ($Value.PSObject.Properties.Name -contains $name) `
            "$Context is missing '$name'."
    }
}

function Get-PrivacyViolation {
    param(
        [Parameter(Mandatory)][string]$Text
    )

    $literalBackslash = [regex]::Escape([string][char]92)
    $twoBackslashes = "(?:$literalBackslash){2}"
    $fourBackslashes = "(?:$literalBackslash){4}"
    $stringBoundary = '(?:^|["''\s(=:])'

    if ($Text -match '(?i)oem[0-9]+\.inf') {
        return 'machine-local published INF'
    }
    if ($Text -match '(?i)(?<![A-Z0-9])[A-Z]:[\\/]') {
        return 'local drive path'
    }
    if ($Text -match
        "(?m)$stringBoundary(?:$fourBackslashes|$twoBackslashes)[?.]") {
        return 'device-interface path'
    }
    if ($Text -match
        "(?m)$stringBoundary(?:$fourBackslashes|$twoBackslashes)(?![?.$literalBackslash])") {
        return 'UNC path'
    }
    if ($Text -match
        "(?i)(?:$literalBackslash){1,2}[0-9]+&[0-9A-F]{4,}&[0-9]+(?:&[0-9A-F]+)?") {
        return 'full device-instance suffix'
    }
    $instanceSeparator = "(?:$literalBackslash){1,2}"
    $fullInstancePattern =
        '(?i)(?:USB|HID|RZVIRTUAL|RZCONTROL|RAZER)' +
        $instanceSeparator + '[^\s\\"]+' +
        $instanceSeparator + '[^\s\\"]+'
    if ($Text -match $fullInstancePattern) {
        return 'full device-instance suffix'
    }

    return $null
}

$readme = [IO.File]::ReadAllText((Join-Path $repository 'README.md'))
$licensePath = Join-Path $repository 'LICENSE'
$notice = [IO.File]::ReadAllText((Join-Path $repository 'NOTICE'))
$thirdParty = [IO.File]::ReadAllText((Join-Path $repository 'THIRD-PARTY-NOTICES.md'))
$guide = [IO.File]::ReadAllText((Join-Path $repository 'docs\exporting.md'))
$ignore = [IO.File]::ReadAllText((Join-Path $repository '.gitignore'))
$template = Get-Content `
    -LiteralPath (Join-Path $repository 'templates\driver-stack-evidence.template.json') `
    -Raw | ConvertFrom-Json
$manifestPath = Join-Path $repository (
    'devices\rz09-0581\1532-02e0\1.0.0.78-1.0.0.76\manifest.json')
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

Assert-True ($readme.Contains('[docs/exporting.md](docs/exporting.md)')) `
    'README.md must link to the export guide.'
Assert-True ((Get-Item -LiteralPath $licensePath).Length -eq 11358) `
    'LICENSE must be the canonical LF-encoded Apache-2.0 text.'
Assert-True ((Get-FileHash -LiteralPath $licensePath -Algorithm SHA256).Hash -eq
    'CFC7749B96F63BD31C3C42B5C471BF756814053E847C10F3EB003417BC523D30') `
    'LICENSE does not match the canonical Apache-2.0 text.'
foreach ($link in '[Apache License 2.0](LICENSE)','[NOTICE](NOTICE)',
        '[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)') {
    Assert-True ($readme.Contains($link)) `
        "README.md must contain the license boundary link '$link'."
}
Assert-True ($readme.Contains('The Razer driver files belong to Razer.')) `
    'README.md must keep the Razer driver ownership boundary.'
Assert-True ($notice.Contains('Copyright 2026 OSSBlade contributors') -and
    $notice.Contains('Razer driver packages') -and
    $notice.Contains('not covered by that license')) `
    'NOTICE must retain the OSSBlade copyright and Razer asset exclusion.'
Assert-True ($thirdParty.Contains('Apache-2.0 applies only to original') -and
    $thirdParty.Contains('grants no') -and
    $thirdParty.Contains('rights to Razer package bytes')) `
    'THIRD-PARTY-NOTICES.md must retain the Apache-2.0 boundary.'
Assert-True ($guide.Contains('/enum-drivers /devices /files /format xml')) `
    'The guide must use structured PnPUtil inventory.'
Assert-True ($guide.Contains('/export-driver $publishedInf $destination')) `
    'The guide must export explicitly selected Driver Store packages.'
Assert-True ($guide.Contains('Do not use `/export-driver *`')) `
    'The guide must prohibit broad Driver Store export.'
Assert-True ($guide.Contains('does not prove')) `
    'The guide must distinguish candidate evidence from admission.'
Assert-True ($guide.Contains('Microsoft.Windows.SDK.BuildTools') -and
    $guide.Contains('dotnet nuget verify --all') -and
    $guide.Contains('${env:ProgramFiles(x86)}')) `
    'The guide must document verified SDK SignTool acquisition and discovery.'
Assert-True (-not $guide.Contains([char]0x2013)) `
    'The guide contains an en dash.'
Assert-True (-not $guide.Contains([char]0x2014)) `
    'The guide contains an em dash.'

foreach ($pattern in '*.cat','*.cab','*.bin','*.dll','*.exe','*.inf','*.msi','*.msix',
        '*.pnf','*.rar','*.sys','*.7z','*.zip','*-private.*','*-private-evidence.*',
        'system-identity.json','raw/','work/') {
    Assert-True ($ignore.Contains($pattern)) `
        ".gitignore must exclude proprietary package pattern '$pattern'."
}

foreach ($property in 'manifestType','schemaVersion','scope','collection','deviceTopology','packages',
        'featureEvidence','redistribution','privacy','limitations') {
    Assert-True ($template.PSObject.Properties.Name -contains $property) `
        "The driver evidence template is missing '$property'."
}
Assert-True ($template.manifestType -eq 'OpenBlade.RazerDriverCatalogEntry') `
    'The driver evidence template has the wrong manifest type.'
Assert-True ($template.collection.collectedAtUtc -eq 'YYYY-MM-DDTHH:MM:SSZ') `
    'The driver evidence template must request an ISO-8601 UTC timestamp.'
Assert-RequiredProperties $template.scope @(
    'modelNumber','productName','biosVersion','windowsBuild','architecture',
    'usbIdentities') 'The driver evidence template scope'
Assert-RequiredProperties $template.collection @(
    'collectedAtUtc','vendorSoftwareVersion','privateInventoryReviewed',
    'packageArchiveFileName','packageArchiveSize','packageArchiveSha256',
    'exporterProvenance','catalogVerification') `
    'The driver evidence template collection'
Assert-RequiredProperties $template.collection.exporterProvenance @(
    'repository','pullRequest','revision','reachability','path','gitBlobSha1',
    'gitBlobContentSha256') `
    'The driver evidence template exporter provenance'
Assert-RequiredProperties $template.collection.catalogVerification @(
    'status','tool','toolProductVersion','acquisitionPackage','acquisitionVersion',
    'acquisitionSha256','verificationPolicy','catalogsVerified','membersVerified',
    'verifiedAtUtc') 'The driver evidence template catalog verification'
foreach ($deprecatedProperty in 'privateArchiveFileName','privateArchiveSha256') {
    Assert-True ($template.collection.PSObject.Properties.Name -notcontains
        $deprecatedProperty) `
        "The driver evidence template must not model '$deprecatedProperty'."
}
Assert-RequiredProperties $template.deviceTopology[0] @(
    'instancePrefix','class','service','filters','parentPrefix','originalInf','role') `
    'The driver evidence template topology node'
Assert-RequiredProperties $template.packages[0] @(
    'directory','originalInf','provider','class','classGuid','driverVer',
    'binaryFileVersion','catalog','catalogSignatureStatus','signerSubject',
    'signerThumbprint','services','hardwareMatches','files') `
    'The driver evidence template package'
Assert-RequiredProperties $template.packages[0].files[0] @(
    'path','length','fileVersion','sha256','signatureStatus','catalogRole',
    'catalogMembershipStatus') 'The driver evidence template package file'
Assert-RequiredProperties $template.featureEvidence @(
    'candidatePaths','physicalValidation','lifecycleValidation','cleanInstallation',
    'rollback') 'The driver evidence template feature evidence'
Assert-RequiredProperties $template.redistribution @(
    'status','authorizationStoredOutsideRepository','reportedPermissionGrantor',
    'permissionBasis','independentDocumentReview') `
    'The driver evidence template redistribution'
Assert-RequiredProperties $template.privacy @(
    'containsDriverBytes','containsSerial','containsUsername','containsLocalPath',
    'containsFullInstanceId','containsMachineLocalPublishedInf') `
    'The driver evidence template privacy declaration'

Assert-True ($manifest.scope.modelNumber -eq 'RZ09-0581') `
    'The initial entry has the wrong model.'
Assert-True ($manifest.scope.usbIdentities[0].pid -eq '02E0') `
    'The initial entry has the wrong product ID.'
Assert-True ($manifest.packages.Count -eq 5) `
    'The admitted 02E0 stack must contain five packages.'
Assert-True ($manifest.collection.packageArchiveSha256 -eq
    '715045E146971D3AD851E84433A76282E7FF7D407A0C22C0507427AF22ACDBE0') `
    'The initial entry has the wrong package archive hash.'
Assert-True ($manifest.collection.packageArchiveSize -eq 227111) `
    'The initial entry has the wrong package archive size.'
Assert-True (-not $manifest.privacy.containsDriverBytes) `
    'A catalog manifest must not contain proprietary driver bytes.'
Assert-True (-not $manifest.privacy.containsFullInstanceId) `
    'A catalog manifest must not contain full instance IDs.'

$blade2025Path = Join-Path $repository (
    'devices\rz09-0528\1532-02c6\1.0.0.78-1.0.0.76\manifest.json')
$blade2025 = Get-Content -LiteralPath $blade2025Path -Raw | ConvertFrom-Json
Assert-True ($blade2025.scope.modelNumber -eq 'RZ09-0528' -and
    $blade2025.scope.usbIdentities[0].pid -eq '02C6') `
    'The Blade 16 (2025) entry has the wrong hardware scope.'
Assert-True ($blade2025.packages.Count -eq 5 -and
    $blade2025.collection.catalogVerification.membersVerified -eq 10) `
    'The Blade 16 (2025) entry does not cover the verified five-package stack.'
Assert-True ($blade2025.redistribution.status -eq 'NotPublished' -and
    $blade2025.collection.PSObject.Properties.Name -notcontains 'exporterProvenance') `
    'The Blade 16 (2025) entry must remain an unpublished inventory.'

$manifestPaths = @(
    Get-ChildItem -LiteralPath (Join-Path $repository 'devices') `
        -Recurse -Filter 'manifest.json' -File)
Assert-True ($manifestPaths.Count -ge 1) `
    'The catalog must contain at least one device manifest.'

foreach ($path in $manifestPaths) {
    $raw = Get-Content -LiteralPath $path.FullName -Raw
    $entry = $raw | ConvertFrom-Json
    $context = "Manifest '$($path.FullName)'"
    Assert-RequiredProperties $entry @(
        'manifestType','schemaVersion','scope','collection','deviceTopology','packages',
        'featureEvidence','redistribution','privacy','limitations') $context
    Assert-True ($entry.manifestType -eq 'OpenBlade.RazerDriverCatalogEntry') `
        "$context has the wrong manifest type."
    Assert-True ($entry.schemaVersion -eq 1) `
        "$context has an unsupported schema version."
    Assert-RequiredProperties $entry.scope @(
        'modelNumber','productName','biosVersion','windowsBuild','architecture',
        'usbIdentities') "$context scope"
    Assert-True (@($entry.scope.usbIdentities).Count -gt 0) `
        "$context has no USB identities."
    foreach ($identity in $entry.scope.usbIdentities) {
        Assert-RequiredProperties $identity @('vid','pid','interfaces') `
            "$context USB identity"
        Assert-True ($identity.vid -match '^[0-9A-F]{4}$' -and
            $identity.pid -match '^[0-9A-F]{4}$') `
            "$context has an invalid USB VID or PID."
        Assert-True (@($identity.interfaces).Count -gt 0) `
            "$context has a USB identity without interfaces."
    }

    Assert-RequiredProperties $entry.collection @(
        'collectedAtUtc','vendorSoftwareVersion','privateInventoryReviewed',
        'packageArchiveFileName','packageArchiveSize','packageArchiveSha256',
        'catalogVerification') "$context collection"
    foreach ($deprecatedProperty in 'privateArchiveFileName','privateArchiveSha256') {
        Assert-True ($entry.collection.PSObject.Properties.Name -notcontains
            $deprecatedProperty) `
            "$context must not model '$deprecatedProperty'."
    }
    $collectedAtUtc = [string]$entry.collection.collectedAtUtc
    $parsedCollectionTime = [DateTimeOffset]::MinValue
    $dateStyles = [Globalization.DateTimeStyles]::AssumeUniversal -bor
        [Globalization.DateTimeStyles]::AdjustToUniversal
    $hasIsoCollectionTime =
        $collectedAtUtc -match
            '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z$' -and
        [DateTimeOffset]::TryParse(
            $collectedAtUtc,
            [Globalization.CultureInfo]::InvariantCulture,
            $dateStyles,
            [ref]$parsedCollectionTime)
    Assert-True ($collectedAtUtc -eq 'Unavailable' -or $hasIsoCollectionTime) `
        "$context has an invalid collection timestamp."
    Assert-True ($entry.collection.privateInventoryReviewed -is [bool]) `
        "$context has a non-Boolean private inventory review flag."
    Assert-True ($entry.collection.packageArchiveFileName -match '^[^\\/]+\.zip$' -and
        $entry.collection.packageArchiveFileName -notmatch
            '(?i)(?:^|[-_.])private(?:[-_.]|$)') `
        "$context has an invalid package archive filename."
    Assert-True ($entry.collection.packageArchiveSize -is [long] -or
        $entry.collection.packageArchiveSize -is [int]) `
        "$context has a non-integer package archive size."
    Assert-True ($entry.collection.packageArchiveSize -gt 0) `
        "$context has an invalid package archive size."
    Assert-True ($entry.collection.packageArchiveSha256 -match '^[0-9A-F]{64}$') `
        "$context has an invalid package archive SHA-256."
    if ($entry.collection.PSObject.Properties.Name -contains 'exporterProvenance') {
    Assert-RequiredProperties $entry.collection.exporterProvenance @(
        'repository','pullRequest','revision','reachability','path','gitBlobSha1',
        'gitBlobContentSha256') `
        "$context exporter provenance"
    $exporter = $entry.collection.exporterProvenance
    Assert-True ($exporter.repository -match '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') `
        "$context has an invalid exporter repository."
    Assert-True ($exporter.pullRequest -match '^https://github\.com/.+/pull/[0-9]+$') `
        "$context has an invalid exporter pull-request reference."
    Assert-True ($exporter.revision -match '^[0-9a-f]{40}$') `
        "$context has an invalid exporter revision."
    Assert-True ($exporter.reachability -in @('MergedCommit','ReleaseTag','UnmergedPullRequest')) `
        "$context has an invalid exporter reachability state."
    Assert-True ($exporter.path -match '^[^\\/]+(?:/[^\\/]+)+$' -and
        $exporter.path -notmatch '(?:^|/)\.\.?(?:/|$)') `
        "$context has an invalid exporter path."
    Assert-True ($exporter.gitBlobSha1 -match '^[0-9a-f]{40}$') `
        "$context has an invalid exporter Git blob SHA-1."
    Assert-True ($exporter.gitBlobContentSha256 -match '^[0-9A-F]{64}$') `
        "$context has an invalid exporter blob-content SHA-256."
    }
    else {
        Assert-True ($entry.redistribution.status -eq 'NotPublished') `
            "$context has no exporter provenance but is marked for publication."
    }
    $catalogVerification = $entry.collection.catalogVerification
    Assert-RequiredProperties $catalogVerification @(
        'status','tool','toolProductVersion','acquisitionPackage','acquisitionVersion',
        'acquisitionSha256','verificationPolicy','catalogsVerified','membersVerified',
        'verifiedAtUtc') "$context catalog verification"
    Assert-True ($catalogVerification.status -in @('Pending','Verified')) `
        "$context has an invalid catalog verification status."
    Assert-True ($catalogVerification.tool -eq 'Microsoft Windows SDK SignTool') `
        "$context has an unexpected catalog verification tool."
    Assert-True ($catalogVerification.verificationPolicy -eq 'KernelMode') `
        "$context has an unexpected catalog verification policy."
    if ($catalogVerification.status -eq 'Verified') {
        Assert-True ($catalogVerification.toolProductVersion -match '^\d+(?:\.\d+){3}$') `
            "$context has an invalid SignTool product version."
        Assert-True ($catalogVerification.acquisitionPackage -in @(
                'Microsoft.Windows.SDK.BuildTools','Installed Windows SDK')) `
            "$context has an unexpected SignTool acquisition source."
        Assert-True ($catalogVerification.acquisitionVersion -match
            '^\d+(?:\.\d+){3}$') `
            "$context has an invalid SignTool acquisition version."
        Assert-True ($catalogVerification.acquisitionSha256 -match '^[0-9A-F]{64}$' -or
            ($catalogVerification.acquisitionPackage -eq 'Installed Windows SDK' -and
             $catalogVerification.acquisitionSha256 -eq 'Unavailable')) `
            "$context has an invalid SignTool acquisition SHA-256."
        Assert-True ($catalogVerification.verifiedAtUtc -match
            '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$') `
            "$context has an invalid catalog verification timestamp."
    }

    Assert-True (@($entry.deviceTopology).Count -gt 0) `
        "$context has no device topology."
    foreach ($node in $entry.deviceTopology) {
        Assert-RequiredProperties $node @(
            'instancePrefix','class','service','filters','parentPrefix','originalInf',
            'role') "$context device topology node"
        Assert-True ($node.filters -is [Array]) `
            "$context has a device topology node whose filters value is not an array."
    }
    Assert-True (@($entry.packages).Count -gt 0) `
        "$context has no packages."
    Assert-True (@($entry.limitations).Count -gt 0) `
        "$context has no limitations."

    Assert-RequiredProperties $entry.featureEvidence @(
        'candidatePaths','physicalValidation','lifecycleValidation',
        'cleanInstallation','rollback') "$context feature evidence"
    Assert-RequiredProperties $entry.redistribution @(
        'status','authorizationStoredOutsideRepository','reportedPermissionGrantor',
        'permissionBasis','independentDocumentReview') "$context redistribution"
    Assert-True ($entry.redistribution.status -in @(
            'NotPublished','WrittenPermissionReportedFromRazerUSLtd')) `
        "$context has an unsupported permission status."
    Assert-True (-not [string]::IsNullOrWhiteSpace(
            $entry.redistribution.reportedPermissionGrantor)) `
        "$context has no reported permission grantor."
    Assert-True (-not [string]::IsNullOrWhiteSpace(
            $entry.redistribution.permissionBasis)) `
        "$context has no permission basis."
    Assert-True ($entry.redistribution.independentDocumentReview -is [bool]) `
        "$context has an invalid permission-review flag."
    if ($entry.redistribution.PSObject.Properties.Name -contains 'release') {
        Assert-True ($entry.redistribution.status -eq
            'WrittenPermissionReportedFromRazerUSLtd') `
            "$context release has an inaccurate permission status."
        Assert-True ($entry.redistribution.reportedPermissionGrantor -eq
            'Razer US Ltd') `
            "$context release has an inaccurate reported permission grantor."
        Assert-True ($entry.redistribution.permissionBasis -eq
            'ProjectOwnerStatement') `
            "$context release has an inaccurate permission basis."
        Assert-True (-not $entry.redistribution.independentDocumentReview) `
            "$context must not claim independent permission-document review."
        Assert-RequiredProperties $entry.redistribution.release @(
            'tag','asset','sha256','publicationStatus',
            'repositoryVisibilityAtPublication','authorizedAudience','record') `
            "$context release"
        Assert-True ($entry.redistribution.release.publicationStatus -in @(
                'Prerelease','Release')) `
            "$context release has an invalid publication status."
    }

    foreach ($property in 'containsDriverBytes','containsSerial','containsUsername',
            'containsLocalPath','containsFullInstanceId','containsMachineLocalPublishedInf') {
        Assert-True ($entry.privacy.PSObject.Properties.Name -contains $property) `
            "Manifest '$($path.FullName)' is missing privacy flag '$property'."
        Assert-True (-not $entry.privacy.$property) `
            "Manifest '$($path.FullName)' has unsafe privacy flag '$property'."
    }

    $catalogCount = 0
    $memberCount = 0
    $verifiedMemberCount = 0
    foreach ($package in $entry.packages) {
        Assert-RequiredProperties $package @(
            'directory','originalInf','provider','class','classGuid','driverVer',
            'binaryFileVersion','catalog','catalogSignatureStatus','signerSubject',
            'signerThumbprint','services','hardwareMatches','files') `
            "$context package"
        Assert-True ($package.directory -match '^[A-Za-z0-9._-]+$' -and
            $package.directory -notin @('.','..')) `
            "Manifest '$($path.FullName)' has an unsafe package directory."
        Assert-True (@($package.files).Count -gt 0) `
            "Manifest '$($path.FullName)' has an empty package."

        foreach ($file in $package.files) {
            Assert-RequiredProperties $file @(
                'path','length','fileVersion','sha256','signatureStatus','catalogRole',
                'catalogMembershipStatus') "$context package file"
            Assert-True (-not [IO.Path]::IsPathRooted([string]$file.path)) `
                "Manifest '$($path.FullName)' contains a rooted package path."
            $normalizedPath = ([string]$file.path).Replace('\', '/')
            $segments = @($normalizedPath.Split('/'))
            Assert-True ($normalizedPath.StartsWith(
                    "$($package.directory)/",
                    [StringComparison]::Ordinal) -and
                $segments.Count -ge 2 -and
                @($segments | Where-Object { $_ -in @('','.', '..') }).Count -eq 0) `
                "Package file '$($file.path)' escapes its package directory."
            Assert-True ($file.length -gt 0) `
                "Package file '$($file.path)' has no positive byte length."
            Assert-True ($file.sha256 -match '^[0-9A-F]{64}$') `
                "Package file '$($file.path)' has an invalid SHA-256."
            Assert-True ($file.catalogRole -in @('Catalog','Member')) `
                "Package file '$($file.path)' has an invalid catalog role."
            if ($file.catalogRole -eq 'Catalog') {
                $catalogCount++
                Assert-True ($file.catalogMembershipStatus -eq 'NotApplicable') `
                    "Catalog '$($file.path)' must not claim membership in itself."
            }
            else {
                $memberCount++
                if ($file.catalogMembershipStatus -eq 'Verified') {
                    $verifiedMemberCount++
                }
                Assert-True ($file.catalogMembershipStatus -in @('Pending','Verified')) `
                    "Package member '$($file.path)' has invalid catalog status."
            }
        }
    }
    if ($catalogVerification.status -eq 'Verified') {
        Assert-True ($catalogVerification.catalogsVerified -eq $catalogCount) `
            "$context catalog verification count does not match the manifest."
        Assert-True ($catalogVerification.membersVerified -eq $memberCount -and
            $verifiedMemberCount -eq $memberCount) `
            "$context member verification count does not match the manifest."
    }
}

$releaseRecordPaths = @(
    Get-ChildItem -LiteralPath (Join-Path $repository 'releases') `
        -Recurse -Filter '*.json' -File)
Assert-True ($releaseRecordPaths.Count -ge 1) `
    'The catalog must contain at least one checked release record.'

foreach ($recordPath in $releaseRecordPaths) {
    $record = Get-Content -LiteralPath $recordPath.FullName -Raw | ConvertFrom-Json
    $context = "Release record '$($recordPath.FullName)'"
    Assert-RequiredProperties $record @(
        'manifestType','schemaVersion','release','catalogManifest','exporter') $context
    Assert-True ($record.manifestType -eq 'OpenBlade.RazerDriverReleaseRecord') `
        "$context has the wrong manifest type."
    Assert-True ($record.schemaVersion -eq 1) `
        "$context has an unsupported schema version."
    Assert-RequiredProperties $record.release @(
        'repository','tag','url','prerelease','repositoryVisibility',
        'authorizedAudience','reportedPermissionGrantor','permissionBasis',
        'independentDocumentReview','asset') "$context release"
    Assert-RequiredProperties $record.release.asset @('name','size','sha256') `
        "$context asset"
    Assert-RequiredProperties $record.catalogManifest @(
        'manifestType','path','sha256') "$context catalog manifest"
    Assert-RequiredProperties $record.exporter @(
        'repository','pullRequest','revision','reachability','path','gitBlobSha1',
        'gitBlobContentSha256') `
        "$context exporter"

    Assert-True ($record.release.repository -eq 'OSSBlade/blade-driver-catalog') `
        "$context names the wrong release repository."
    $expectedReleaseUrl =
        "https://github.com/$($record.release.repository)/releases/tag/$($record.release.tag)"
    Assert-True ($record.release.url -eq $expectedReleaseUrl) `
        "$context has an inconsistent release URL."
    Assert-True ($record.release.prerelease -is [bool]) `
        "$context has an invalid prerelease flag."
    Assert-True ($record.release.repositoryVisibility -in @('Private','Public')) `
        "$context has an invalid repository visibility."
    Assert-True (-not [string]::IsNullOrWhiteSpace($record.release.authorizedAudience)) `
        "$context has no authorized audience."
    Assert-True (-not [string]::IsNullOrWhiteSpace(
            $record.release.reportedPermissionGrantor)) `
        "$context has no reported permission grantor."
    Assert-True (-not [string]::IsNullOrWhiteSpace(
            $record.release.permissionBasis)) `
        "$context has no permission basis."
    Assert-True ($record.release.independentDocumentReview -is [bool]) `
        "$context has an invalid permission-review flag."
    Assert-True ($record.release.asset.name -match '^[^\\/]+\.zip$') `
        "$context has an invalid asset name."
    Assert-True ($record.release.asset.size -gt 0) `
        "$context has an invalid asset size."
    Assert-True ($record.release.asset.sha256 -match '^[0-9A-F]{64}$') `
        "$context has an invalid asset SHA-256."

    $normalizedManifestPath = ([string]$record.catalogManifest.path).Replace('\', '/')
    $manifestSegments = @($normalizedManifestPath.Split('/'))
    Assert-True (-not [IO.Path]::IsPathRooted($normalizedManifestPath) -and
        $manifestSegments.Count -ge 2 -and
        @($manifestSegments | Where-Object { $_ -in @('','.', '..') }).Count -eq 0) `
        "$context has an unsafe catalog manifest path."
    $boundManifestPath = Join-Path $repository $normalizedManifestPath
    Assert-True (Test-Path -LiteralPath $boundManifestPath -PathType Leaf) `
        "$context points to a missing catalog manifest."
    $boundManifestHash = (Get-FileHash `
        -LiteralPath $boundManifestPath `
        -Algorithm SHA256).Hash
    Assert-True ([string]::Equals(
            $boundManifestHash,
            $record.catalogManifest.sha256,
            [StringComparison]::Ordinal)) `
        "$context does not match the catalog manifest SHA-256."
    $boundManifest = Get-Content -LiteralPath $boundManifestPath -Raw | ConvertFrom-Json
    Assert-True ($boundManifest.manifestType -eq $record.catalogManifest.manifestType) `
        "$context does not match the catalog manifest type."
    Assert-True ($boundManifest.collection.packageArchiveFileName -eq
        $record.release.asset.name) `
        "$context asset name does not match the catalog manifest."
    Assert-True ($boundManifest.collection.packageArchiveSize -eq
        $record.release.asset.size) `
        "$context asset size does not match the catalog manifest."
    Assert-True ($boundManifest.collection.packageArchiveSha256 -eq
        $record.release.asset.sha256) `
        "$context asset SHA-256 does not match the catalog manifest."
    Assert-True ($boundManifest.redistribution.release.tag -eq $record.release.tag) `
        "$context tag does not match the catalog manifest."
    $expectedPublicationStatus = if ($record.release.prerelease) {
        'Prerelease'
    }
    else {
        'Release'
    }
    Assert-True ($boundManifest.redistribution.release.publicationStatus -eq
        $expectedPublicationStatus) `
        "$context prerelease flag does not match the catalog manifest."
    Assert-True ($boundManifest.redistribution.release.repositoryVisibilityAtPublication -eq
        $record.release.repositoryVisibility) `
        "$context repository visibility does not match the catalog manifest."
    Assert-True ($boundManifest.redistribution.release.authorizedAudience -eq
        $record.release.authorizedAudience) `
        "$context authorized audience does not match the catalog manifest."
    Assert-True ($boundManifest.redistribution.reportedPermissionGrantor -eq
        $record.release.reportedPermissionGrantor) `
        "$context permission grantor does not match the catalog manifest."
    Assert-True ($boundManifest.redistribution.permissionBasis -eq
        $record.release.permissionBasis) `
        "$context permission basis does not match the catalog manifest."
    Assert-True ($boundManifest.redistribution.independentDocumentReview -eq
        $record.release.independentDocumentReview) `
        "$context permission review status does not match the catalog manifest."
    $recordRelativePath = (
        $recordPath.FullName.Substring($repository.Length + 1)).Replace('\', '/')
    Assert-True ($boundManifest.redistribution.release.record -eq $recordRelativePath) `
        "$context path is not recorded by the catalog manifest."
    foreach ($property in 'repository','pullRequest','revision','reachability','path',
            'gitBlobSha1','gitBlobContentSha256') {
        Assert-True ($boundManifest.collection.exporterProvenance.$property -eq
            $record.exporter.$property) `
            "$context exporter '$property' does not match the catalog manifest."
    }
}

$powershellBlocks = [regex]::Matches(
    $guide,
    '(?ms)^```powershell\s*\r?\n(?<code>.*?)^```\s*$')
Assert-True ($powershellBlocks.Count -ge 7) `
    'The guide is missing its PowerShell examples.'

foreach ($block in $powershellBlocks) {
    $tokens = $null
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseInput(
        $block.Groups['code'].Value,
        [ref]$tokens,
        [ref]$errors)
    if ($errors.Count -ne 0) {
        throw "A guide PowerShell block does not parse: $($errors[0].Message)"
    }
}

$candidatePaths = @(
    & git -c core.quotepath=false -C $repository `
        ls-files --cached --others --exclude-standard |
        Sort-Object -Unique)
if ($LASTEXITCODE -ne 0) {
    throw 'Git could not enumerate tracked and unignored files.'
}
Assert-True ($candidatePaths.Count -gt 0) `
    'Git did not return any repository candidates.'

foreach ($path in $candidatePaths) {
    $normalizedRepositoryPath = $path.Replace('\', '/')
    $leaf = Split-Path -Leaf $normalizedRepositoryPath
    Assert-True ($leaf -notmatch '(?i)(?:^|[-_.])private(?:[-_.]|$)' -and
        $leaf -notin @('system-identity.json')) `
        "Private evidence filename is not allowed: $path"
    Assert-True ($path -notmatch '\.(bin|cab|cat|dll|exe|inf|msi|msix|pnf|rar|sys|7z|zip)$') `
        "Proprietary driver artifact is tracked or unignored: $path"

    $extension = [IO.Path]::GetExtension($leaf)
    $allowed = @('.md','.json','.ps1','.yml','.yaml')
    Assert-True (
        ($leaf -in @('.gitattributes','.gitignore','LICENSE','NOTICE')) -or
        ($extension -in $allowed)) `
        "Unexpected tracked or unignored file type: $path"

    $fullPath = Join-Path $repository $normalizedRepositoryPath
    Assert-True (Test-Path -LiteralPath $fullPath -PathType Leaf) `
        "Repository candidate does not exist as a file: $path"
    $text = [IO.File]::ReadAllText($fullPath)
    $privacyViolation = Get-PrivacyViolation -Text $text
    Assert-True ($null -eq $privacyViolation) `
        "Repository candidate '$path' contains a $privacyViolation."
}

$slash = [string][char]92
$unsafeUnc = 'value=' + $slash + $slash + 'server' + $slash + 'share'
$unsafeInterface = 'value=' + $slash + $slash + '?' + $slash + 'hid#device'
$unsafeInstance = 'value=USB' + $slash + '7&1234ABCD&0&1'
$unsafeSerialInstance =
    'value=USB' + $slash + 'VID_1532&PID_02E0' + $slash + 'ABC123456'
$unsafeUrlInstance =
    'https://example.test/device/USB' + $slash +
    'VID_1532&PID_02E0' + $slash + 'ABC123456'
$unsafeDrive = 'value=C:' + $slash + 'Users' + $slash + 'example'
Assert-True ((Get-PrivacyViolation -Text $unsafeUnc) -eq 'UNC path') `
    'The privacy scanner did not detect a UNC path.'
Assert-True ((Get-PrivacyViolation -Text $unsafeInterface) -eq 'device-interface path') `
    'The privacy scanner did not detect a device-interface path.'
Assert-True ((Get-PrivacyViolation -Text $unsafeInstance) -eq 'full device-instance suffix') `
    'The privacy scanner did not detect a full device-instance suffix.'
Assert-True ((Get-PrivacyViolation -Text $unsafeSerialInstance) -eq
    'full device-instance suffix') `
    'The privacy scanner did not detect a serial-style full device-instance suffix.'
Assert-True ((Get-PrivacyViolation -Text $unsafeUrlInstance) -eq
    'full device-instance suffix') `
    'The privacy scanner did not inspect a URL-contained full device-instance ID.'
Assert-True ((Get-PrivacyViolation -Text $unsafeDrive) -eq 'local drive path') `
    'The privacy scanner did not detect a local drive path.'
Assert-True ($null -eq (Get-PrivacyViolation -Text 'https://example.test/path')) `
    'The privacy scanner treated a URL as a local path.'

Write-Output 'Repository contracts passed.'

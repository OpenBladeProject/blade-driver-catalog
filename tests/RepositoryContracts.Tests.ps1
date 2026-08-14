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

$readme = [IO.File]::ReadAllText((Join-Path $repository 'README.md'))
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
Assert-True ($guide.Contains('/enum-drivers /devices /files /format xml')) `
    'The guide must use structured PnPUtil inventory.'
Assert-True ($guide.Contains('/export-driver $publishedInf $destination')) `
    'The guide must export explicitly selected Driver Store packages.'
Assert-True ($guide.Contains('Do not use `/export-driver *`')) `
    'The guide must prohibit broad Driver Store export.'
Assert-True ($guide.Contains('does not prove')) `
    'The guide must distinguish candidate evidence from admission.'
Assert-True (-not $guide.Contains([char]0x2013)) `
    'The guide contains an en dash.'
Assert-True (-not $guide.Contains([char]0x2014)) `
    'The guide contains an em dash.'

foreach ($pattern in '*.cat','*.cab','*.bin','*.dll','*.exe','*.inf','*.msi','*.msix',
        '*.pnf','*.rar','*.sys','*.7z','*.zip') {
    Assert-True ($ignore.Contains($pattern)) `
        ".gitignore must exclude proprietary package pattern '$pattern'."
}

foreach ($property in 'scope','collection','deviceTopology','packages','featureEvidence','redistribution','privacy','limitations') {
    Assert-True ($template.PSObject.Properties.Name -contains $property) `
        "The driver evidence template is missing '$property'."
}

Assert-True ($manifest.scope.modelNumber -eq 'RZ09-0581') `
    'The initial entry has the wrong model.'
Assert-True ($manifest.scope.usbIdentities[0].pid -eq '02E0') `
    'The initial entry has the wrong product ID.'
Assert-True ($manifest.packages.Count -eq 5) `
    'The admitted 02E0 stack must contain five packages.'
Assert-True ($manifest.collection.privateArchiveSha256 -eq
    '2286405641678B664BE537B666673613043A19A9A78127E8880F349A2691A5A8') `
    'The initial entry has the wrong private archive hash.'
Assert-True (-not $manifest.privacy.containsDriverBytes) `
    'A catalog manifest must not contain proprietary driver bytes.'
Assert-True (-not $manifest.privacy.containsFullInstanceId) `
    'A catalog manifest must not contain full instance IDs.'

$manifestPaths = @(
    Get-ChildItem -LiteralPath (Join-Path $repository 'devices') `
        -Recurse -Filter 'manifest.json' -File)
Assert-True ($manifestPaths.Count -ge 1) `
    'The catalog must contain at least one device manifest.'

foreach ($path in $manifestPaths) {
    $raw = Get-Content -LiteralPath $path.FullName -Raw
    $entry = $raw | ConvertFrom-Json
    foreach ($property in 'schemaVersion','scope','collection','deviceTopology','packages',
            'featureEvidence','redistribution','privacy','limitations') {
        Assert-True ($entry.PSObject.Properties.Name -contains $property) `
            "Manifest '$($path.FullName)' is missing top-level field '$property'."
    }
    Assert-True ($entry.schemaVersion -eq 1) `
        "Manifest '$($path.FullName)' has an unsupported schema version."
    Assert-True (@($entry.deviceTopology).Count -gt 0) `
        "Manifest '$($path.FullName)' has no device topology."
    Assert-True (@($entry.packages).Count -gt 0) `
        "Manifest '$($path.FullName)' has no packages."
    Assert-True (@($entry.limitations).Count -gt 0) `
        "Manifest '$($path.FullName)' has no limitations."

    foreach ($property in 'containsDriverBytes','containsSerial','containsUsername',
            'containsLocalPath','containsFullInstanceId','containsMachineLocalPublishedInf') {
        Assert-True ($entry.privacy.PSObject.Properties.Name -contains $property) `
            "Manifest '$($path.FullName)' is missing privacy flag '$property'."
        Assert-True (-not $entry.privacy.$property) `
            "Manifest '$($path.FullName)' has unsafe privacy flag '$property'."
    }

    Assert-True ($raw -notmatch '(?i)oem[0-9]+\.inf') `
        "Manifest '$($path.FullName)' contains a machine-local published INF."
    Assert-True ($raw -notmatch '(?i)[A-Z]:[\\/]') `
        "Manifest '$($path.FullName)' contains a local drive path."
    Assert-True ($raw -notmatch '\\\\\\\\[?.]') `
        "Manifest '$($path.FullName)' contains a device-interface path."
    Assert-True ($raw -notmatch '"\\\\\\\\') `
        "Manifest '$($path.FullName)' contains a UNC path."
    Assert-True ($raw -notmatch '(?i)\\\\[0-9]+&[0-9A-F]{4,}&[0-9]+(?:&[0-9A-F]+)?') `
        "Manifest '$($path.FullName)' contains a full device-instance suffix."

    foreach ($package in $entry.packages) {
        foreach ($property in 'directory','originalInf','provider','class','classGuid',
                'driverVer','binaryFileVersion','catalog','catalogSignatureStatus',
                'signerSubject','signerThumbprint','services','hardwareMatches','files') {
            Assert-True ($package.PSObject.Properties.Name -contains $property) `
                "Manifest '$($path.FullName)' package is missing '$property'."
        }
        Assert-True ($package.directory -match '^[A-Za-z0-9._-]+$' -and
            $package.directory -notin @('.','..')) `
            "Manifest '$($path.FullName)' has an unsafe package directory."
        Assert-True (@($package.files).Count -gt 0) `
            "Manifest '$($path.FullName)' has an empty package."

        foreach ($file in $package.files) {
            foreach ($property in 'path','length','fileVersion','sha256','signatureStatus',
                    'catalogRole','catalogMembershipStatus') {
                Assert-True ($file.PSObject.Properties.Name -contains $property) `
                    "Manifest '$($path.FullName)' file is missing '$property'."
            }
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
                Assert-True ($file.catalogMembershipStatus -eq 'NotApplicable') `
                    "Catalog '$($file.path)' must not claim membership in itself."
            }
            else {
                Assert-True ($file.catalogMembershipStatus -in @('Pending','Verified')) `
                    "Package member '$($file.path)' has invalid catalog status."
            }
        }
    }
}

$allHashes = @(
    $manifest.packages |
        ForEach-Object { $_.files } |
        ForEach-Object { $_.sha256 })
foreach ($hash in $allHashes) {
    Assert-True ($hash -match '^[0-9A-F]{64}$') `
        "Invalid package SHA-256 '$hash'."
}

$matches = [regex]::Matches(
    $guide,
    '(?ms)^```powershell\s*\r?\n(?<code>.*?)^```\s*$')
Assert-True ($matches.Count -ge 7) `
    'The guide is missing its PowerShell examples.'

foreach ($match in $matches) {
    $tokens = $null
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseInput(
        $match.Groups['code'].Value,
        [ref]$tokens,
        [ref]$errors)
    if ($errors.Count -ne 0) {
        throw "A guide PowerShell block does not parse: $($errors[0].Message)"
    }
}

$tracked = @(& git -C $repository ls-files)
if ($LASTEXITCODE -ne 0) {
    throw 'Git could not enumerate tracked files.'
}
foreach ($path in $tracked) {
    Assert-True ($path -notmatch '\.(bin|cab|cat|dll|exe|inf|msi|msix|pnf|rar|sys|7z|zip)$') `
        "Proprietary driver artifact is tracked: $path"

    $leaf = Split-Path -Leaf $path
    $extension = [IO.Path]::GetExtension($leaf)
    $allowed = @('.md','.json','.ps1','.yml','.yaml')
    Assert-True (
        ($leaf -in @('.gitattributes','.gitignore','LICENSE')) -or
        ($extension -in $allowed)) `
        "Unexpected tracked file type: $path"
}

$worktreeFiles = @(
    Get-ChildItem -LiteralPath $repository -Recurse -File |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' })
foreach ($file in $worktreeFiles) {
    $leaf = $file.Name
    $extension = $file.Extension
    $allowed = @('.md','.json','.ps1','.yml','.yaml')
    Assert-True (
        ($leaf -in @('.gitattributes','.gitignore','LICENSE')) -or
        ($extension -in $allowed)) `
        "Unexpected worktree file type: $($file.FullName)"
}

Write-Output 'Repository contracts passed.'

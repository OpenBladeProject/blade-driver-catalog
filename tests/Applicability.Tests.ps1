[CmdletBinding()]
param()
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot

function Assert-Applicability($Ledger, $Artifacts) {
    if ($Ledger.schemaVersion -ne 1 -or $Ledger.coreSource.commit -notmatch '^[a-f0-9]{40}$') {
        throw 'Applicability ledger must pin a core source revision.'
    }
    $models = @($Ledger.profiles.modelNumber)
    if ($models.Count -eq 0 -or @($models | Sort-Object -Unique).Count -ne $models.Count) {
        throw 'Applicability profiles must be nonempty and unique.'
    }
    foreach ($profile in $Ledger.profiles) {
        if ($profile.modelNumber -notmatch '^RZ09-[0-9]{4}$' -or
            $profile.usbIdentity.vid -ne '1532' -or
            $profile.usbIdentity.pid -notmatch '^[0-9A-F]{4}$' -or
            $profile.vendorProductId -le 0 -or [string]::IsNullOrWhiteSpace($profile.productName)) {
            throw 'Applicability profile identity is incomplete.'
        }
    }
    $paths = @($Ledger.entries.path)
    if (@($paths | Sort-Object -Unique).Count -ne $paths.Count -or
        (($paths | Sort-Object) -join '|') -cne (($Artifacts.Keys | Sort-Object) -join '|')) {
        throw 'Every discovered catalog artifact needs exactly one applicability entry.'
    }
    foreach ($entry in $Ledger.entries) {
        if (((@($entry.review.modelNumber) | Sort-Object) -join '|') -cne (($models | Sort-Object) -join '|')) {
            throw 'Every artifact needs exactly one review for every supported model.'
        }
        foreach ($review in $entry.review) {
            if ($review.status -notin @('Applicable','NotEstablished') -or
                [string]::IsNullOrWhiteSpace($review.reason) -or
                [string]::IsNullOrWhiteSpace($review.evidence)) {
                throw 'Every applicability decision needs a supported status, reason and evidence.'
            }
        }
        $artifact = $Artifacts[$entry.path]
        $applicable = @($entry.review | Where-Object status -eq Applicable | ForEach-Object modelNumber)
        if ($artifact.manifestType -eq 'OpenBlade.RazerDriverCatalogEntry') {
            if ($entry.kind -ne 'DriverStack' -or $applicable.Count -ne 1 -or
                $applicable[0] -ne $artifact.scope.modelNumber) {
                throw 'Driver stack applicability must retain its exact manifest scope.'
            }
            $profile = $Ledger.profiles | Where-Object modelNumber -eq $artifact.scope.modelNumber
            if ($profile.productName -cne $artifact.scope.productName -or
                $profile.usbIdentity.pid -cne $artifact.scope.usbIdentities[0].pid) {
                throw 'Driver stack and coverage identities disagree.'
            }
        }
        elseif ($artifact.manifestType -in @('OpenBlade.RazerUpstreamComponentCatalogEntry','OpenBlade.RazerUpstreamAudioStackCatalogEntry')) {
            $expectedKind = if ($artifact.manifestType -eq 'OpenBlade.RazerUpstreamAudioStackCatalogEntry') { 'UpstreamAudioStack' } else { 'UpstreamComponent' }
            if ($entry.kind -ne $expectedKind -or
                (($applicable | Sort-Object) -join '|') -cne
                ((@($artifact.applicableProfiles.modelNumber) | Sort-Object) -join '|')) {
                throw 'Component applicableProfiles must equal the applicable review set.'
            }
            foreach ($profile in $artifact.applicableProfiles) {
                $covered = $Ledger.profiles | Where-Object modelNumber -eq $profile.modelNumber
                if ($covered.productName -cne $profile.productName -or
                    $covered.vendorProductId -ne $profile.vendorProductId -or
                    $covered.usbIdentity.vid -cne $profile.usbIdentity.vid -or
                    $covered.usbIdentity.pid -cne $profile.usbIdentity.pid) {
                    throw 'Component and coverage identities disagree.'
                }
            }
        }
        else { throw 'Unreviewed catalog artifact type.' }
    }
}

$ledgerText = Get-Content (Join-Path $repository 'catalog/applicability.json') -Raw
$ledger = $ledgerText | ConvertFrom-Json
$artifacts = @{}
foreach ($directory in 'devices','components') {
    foreach ($file in Get-ChildItem (Join-Path $repository $directory) -Recurse -File -Filter '*.json') {
        $value = Get-Content $file.FullName -Raw | ConvertFrom-Json
        # Discover by content, so a new entry cannot evade coverage by renaming its file.
        if ($value.PSObject.Properties.Name -contains 'manifestType') {
            $path = $file.FullName.Substring($repository.Length + 1).Replace('\','/')
            $artifacts[$path] = $value
        }
    }
}
Assert-Applicability $ledger $artifacts
$mutations = @(
    { param($x) $x.profiles += $x.profiles[0] },
    { param($x)
        $added = $x.profiles[0] | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $added.modelNumber = 'RZ09-9999'
        $x.profiles += $added
    },
    { param($x) $x.entries = @($x.entries | Select-Object -Skip 1) },
    { param($x) $x.entries[0].review = @($x.entries[0].review | Select-Object -Skip 1) },
    { param($x) $x.entries[0].review[0].status = 'Universal' },
    { param($x) $x.entries[0].review[0].reason = '' },
    { param($x) $x.entries[-1].review[2].status = 'Applicable' },
    { param($x) $x.profiles[0].usbIdentity.pid = '0000' }
)
foreach ($mutation in $mutations) {
    $changed = $ledgerText | ConvertFrom-Json
    & $mutation $changed
    $rejected = $false
    try { Assert-Applicability $changed $artifacts } catch { $rejected = $true }
    if (-not $rejected) { throw 'Applicability validator accepted a broken coverage mutation.' }
}
$extra = $artifacts.Clone()
$extra['components/new/component.json'] = $artifacts.Values | Select-Object -First 1
$rejected = $false
try { Assert-Applicability $ledger $extra } catch { $rejected = $true }
if (-not $rejected) { throw 'A new artifact bypassed the applicability review.' }
Write-Output "Applicability contracts passed: $($ledger.profiles.Count) models, $($artifacts.Count) artifacts, 9 rejection checks."

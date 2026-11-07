[CmdletBinding()]
param()
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot

function Get-ProfileIdentityKeys($Profiles) {
    @($Profiles | ForEach-Object {
        '{0}|{1}|{2}|{3}' -f $_.modelNumber, $_.productName,
            $_.usbIdentity.vid, $_.usbIdentity.pid
    } | Sort-Object)
}

function Assert-CoreSourceCoverage($Ledger, $Coverage) {
    if ($Coverage.schemaVersion -ne 1 -or
        $Coverage.source.commit -cnotmatch '^[a-f0-9]{40}$') {
        throw 'The offline core model source fixture is invalid.'
    }
    foreach ($property in 'repository','commit','path') {
        if ($Ledger.coreSource.$property -cne $Coverage.source.$property) {
            throw 'The ledger must match the reviewed offline core source pin.'
        }
    }
    $source = [string]$Coverage.source.content
    $bytes = [Text.Encoding]::UTF8.GetBytes($source)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    $sha1 = [Security.Cryptography.SHA1]::Create()
    try {
        $sourceHash = [BitConverter]::ToString($sha256.ComputeHash($bytes)).Replace('-','')
        $header = [Text.Encoding]::UTF8.GetBytes("blob $($bytes.Length)`0")
        $gitBytes = [byte[]]::new($header.Length + $bytes.Length)
        [Array]::Copy($header, 0, $gitBytes, 0, $header.Length)
        [Array]::Copy($bytes, 0, $gitBytes, $header.Length, $bytes.Length)
        $blobHash = [BitConverter]::ToString($sha1.ComputeHash($gitBytes)).Replace('-','').ToLowerInvariant()
    }
    finally { $sha256.Dispose(); $sha1.Dispose() }
    if ($sourceHash -cne $Coverage.source.sha256 -or
        $blobHash -cne $Coverage.source.gitBlobSha1) {
        throw 'The offline core metadata bytes do not match their captured source hashes.'
    }

    # Decode only the reviewed metadata initializer shape, failing closed if it
    # changes. The source is inert fixture data; it is never compiled or executed.
    $constants = @{}
    foreach ($match in [regex]::Matches($source,
            'public const string (?<name>\w+) = "(?<value>RZ09-[0-9]{4})";')) {
        $constants[$match.Groups['name'].Value] = $match.Groups['value'].Value
    }
    $definitions = [regex]::Match($source,
        '(?s)RazerBladeModelInfo\[\] Models\s*=\s*\[(?<models>.*?)\];').Groups['models'].Value
    $constructors = [regex]::Matches($definitions,
        '(?s)new\(\s*(?<model>"RZ09-[0-9]{4}"|\w+)\s*,\s*"(?<name>[^"]+)"\s*,\s*(?<year>[0-9]{4})\s*\)\s*\{(?<properties>[^}]*)\}')
    if ($constructors.Count -eq 0 -or $constructors.Count -ne
        [regex]::Matches($definitions, '(?m)^\s*new\b').Count) {
        throw 'The pinned core metadata initializer needs a reviewed fixture decoder update.'
    }
    $sourceProfiles = @(foreach ($match in $constructors) {
        $identity = $match.Groups['model'].Value
        $number = if ($identity.StartsWith('"')) { $identity.Trim('"') } else { $constants[$identity] }
        $properties = $match.Groups['properties'].Value
        $vid = [regex]::Match($properties, 'UsbVendorId\s*=\s*"(?<value>[0-9A-F]{4})"').Groups['value'].Value
        $usbProductId = [regex]::Match($properties, 'UsbProductId\s*=\s*"(?<value>[0-9A-F]{4})"').Groups['value'].Value
        if ($number -notmatch '^RZ09-[0-9]{4}$' -or $vid -cne '1532' -or
            $usbProductId -cnotmatch '^[0-9A-F]{4}$') {
            throw 'The pinned core metadata has an undecoded model identity.'
        }
        [pscustomobject]@{
            modelNumber = $number
            productName = '{0} ({1})' -f $match.Groups['name'].Value, $match.Groups['year'].Value
            usbIdentity = [pscustomobject]@{ vid = $vid; pid = $usbProductId }
        }
    })
    $expected = (Get-ProfileIdentityKeys $sourceProfiles) -join '|'
    if (((Get-ProfileIdentityKeys $Coverage.profiles) -join '|') -cne $expected) {
        throw 'The offline fixture profiles must decode exactly from the pinned core source.'
    }
    if (((Get-ProfileIdentityKeys $Ledger.profiles) -join '|') -cne $expected) {
        throw 'Ledger profiles must equal every exact identity in the pinned core model catalog.'
    }
}

function Assert-Applicability($Ledger, $Artifacts, $CoreCoverage) {
    if ($Ledger.schemaVersion -ne 1 -or $Ledger.coreSource.commit -notmatch '^[a-f0-9]{40}$') {
        throw 'Applicability ledger must pin a core source revision.'
    }
    Assert-CoreSourceCoverage $Ledger $CoreCoverage
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
            if ($review.status -notin @(
                    'Applicable','CandidateOnly','NotApplicable','NotEstablished') -or
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
            $sourceReviewPending = $artifact.manifestType -eq 'OpenBlade.RazerUpstreamAudioStackCatalogEntry' -and
                $artifact.provisioning.status -eq 'SourceReviewPending'
            $reviewedProfiles = if ($sourceReviewPending) {
                @($entry.review | Where-Object status -eq CandidateOnly | ForEach-Object modelNumber)
            }
            else { $applicable }
            if ($entry.kind -ne $expectedKind -or ($sourceReviewPending -and $applicable.Count -ne 0) -or
                (($reviewedProfiles | Sort-Object) -join '|') -cne
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
        elseif ($artifact.manifestType -eq 'OpenBlade.RazerLegacyThxStackEvidence') {
            if ($entry.kind -ne 'LegacyAudioEvidence') {
                throw 'Legacy THX evidence needs its distinct applicability kind.'
            }
            $candidateOnly = @($entry.review |
                Where-Object status -eq CandidateOnly |
                ForEach-Object modelNumber)
            if ((($candidateOnly | Sort-Object) -join '|') -cne
                ((@($artifact.candidateProfiles.modelNumber) | Sort-Object) -join '|')) {
                throw 'Legacy component candidates must equal the candidate-only review set.'
            }
            foreach ($profile in $artifact.candidateProfiles) {
                $covered = $Ledger.profiles |
                    Where-Object modelNumber -eq $profile.modelNumber
                if ($covered.productName -cne $profile.productName -or
                    $covered.vendorProductId -ne $profile.vendorProductId -or
                    $covered.usbIdentity.vid -cne $profile.usbIdentity.vid -or
                    $covered.usbIdentity.pid -cne $profile.usbIdentity.pid) {
                    throw 'Legacy THX candidate and coverage identities disagree.'
                }
            }
            foreach ($profile in $artifact.knownNonThxProfiles) {
                $review = $entry.review |
                    Where-Object modelNumber -eq $profile.modelNumber
                if ($review.status -ne 'NotApplicable') {
                    throw 'Known non-THX evidence must remain explicitly not applicable.'
                }
            }
        }
        else { throw 'Unreviewed catalog artifact type.' }
    }
}

$ledgerText = Get-Content (Join-Path $repository 'catalog/applicability.json') -Raw
$ledger = $ledgerText | ConvertFrom-Json
$coverageText = Get-Content (Join-Path $PSScriptRoot 'fixtures/core-model-catalog.json') -Raw
$coreCoverage = $coverageText | ConvertFrom-Json
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
Assert-Applicability $ledger $artifacts $coreCoverage
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
    { param($x) $x.profiles[0].usbIdentity.pid = '0000' },
    { param($x)
        $x.profiles = @($x.profiles | Where-Object modelNumber -ne 'RZ09-0508')
        foreach ($entry in $x.entries) {
            $entry.review = @($entry.review | Where-Object modelNumber -ne 'RZ09-0508')
        }
    },
    { param($x)
        $added = $x.profiles[-1] | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $added.modelNumber = 'RZ09-9999'
        $x.profiles += $added
        foreach ($entry in $x.entries) {
            $review = $entry.review[-1] | ConvertTo-Json -Depth 5 | ConvertFrom-Json
            $review.modelNumber = 'RZ09-9999'
            $entry.review += $review
        }
    },
    { param($x) $x.coreSource.commit = '0000000000000000000000000000000000000000' },
    { param($x) ($x.profiles | Where-Object modelNumber -eq 'RZ09-0508').productName = 'Other model' }
)
foreach ($mutation in $mutations) {
    $changed = $ledgerText | ConvertFrom-Json
    & $mutation $changed
    $rejected = $false
    try { Assert-Applicability $changed $artifacts $coreCoverage } catch { $rejected = $true }
    if (-not $rejected) { throw 'Applicability validator accepted a broken coverage mutation.' }
}
$extra = $artifacts.Clone()
$extra['components/new/component.json'] = $artifacts.Values | Select-Object -First 1
$rejected = $false
try { Assert-Applicability $ledger $extra $coreCoverage } catch { $rejected = $true }
if (-not $rejected) { throw 'A new artifact bypassed the applicability review.' }
$fixtureMutations = @(
    { param($x) $x.source.content += "`n" },
    { param($x) $x.source.gitBlobSha1 = '0000000000000000000000000000000000000000' },
    { param($x) $x.profiles = @($x.profiles | Select-Object -Skip 1) }
)
foreach ($mutation in $fixtureMutations) {
    $changedCoverage = $coverageText | ConvertFrom-Json
    & $mutation $changedCoverage
    $rejected = $false
    try { Assert-Applicability $ledger $artifacts $changedCoverage } catch { $rejected = $true }
    if (-not $rejected) { throw 'An inconsistent offline source fixture was accepted.' }
}
$rejectionCount = $mutations.Count + $fixtureMutations.Count + 1
Write-Output "Applicability contracts passed: $($ledger.profiles.Count) models, $($artifacts.Count) artifacts, $rejectionCount rejection checks."

[CmdletBinding()]
param()
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot

function Assert-AudioStack($Stack) {
    if ($Stack.manifestType -ne 'OpenBlade.RazerUpstreamAudioStackCatalogEntry' -or $Stack.schemaVersion -ne 1) { throw 'Unknown audio stack type.' }
    $family = $Stack.stack.productId
    $driverVersion = $Stack.stack.driverVersion
    $isCachedRznb12 = $family -eq 'rznb12' -and $driverVersion -eq '4.2.37.1621'
    if ($family -notin @('rznb11','rznb12') -or $Stack.stack.id -cne "thx-$family" -or
        $Stack.stack.serviceName -cne "thx_${family}_service" -or $Stack.stack.serviceExecutable -cne "thx_${family}_svc.exe") { throw 'THX family identities disagree.' }
    $expectedModels = if ($family -eq 'rznb11') { @('RZ09-0528','RZ09-0530') } else { @('RZ09-0581') }
    if ((($Stack.applicableProfiles.modelNumber | Sort-Object) -join '|') -cne (($expectedModels | Sort-Object) -join '|')) { throw 'THX applicability is not universal.' }
    foreach ($profile in $Stack.applicableProfiles) {
        if (@($profile.codecHardwareIds).Count -eq 0 -or @($profile.codecHardwareIds | Sort-Object -Unique).Count -ne @($profile.codecHardwareIds).Count) { throw 'Missing exact codec matches.' }
    }
    if (@($Stack.driverPackages).Count -ne 3 -or (@($Stack.driverPackages.infName | Sort-Object -Unique)).Count -ne 3) { throw 'THX needs its APO, extension and service packages.' }
    foreach ($package in $Stack.driverPackages) {
        if ($package.infName -cnotmatch "^thx_${family}_(apo4|ext|svc)[.]inf$" -or
            $package.catalogFile -cne ($package.infName -replace '[.]inf$','.cat')) { throw 'Mixed driver family or catalog.' }
        $files = @($package.files.name)
        if ($files -notcontains $package.infName -or $files -notcontains $package.catalogFile -or
            ($files | Sort-Object -Unique).Count -ne $files.Count) { throw 'Incomplete package members.' }
        foreach ($file in $package.files) {
            if ($file.name -match '[/\\]' -or $file.sha256 -cnotmatch '^[0-9A-F]{64}$') { throw 'Invalid package member pin.' }
        }
    }
    $roles = @($Stack.artifacts.role)
    $expectedRoles = if ($family -eq 'rznb11' -or $isCachedRznb12) { @('BaseInstaller','PropertiesUpdater','SurroundUpdater') } else { @('PropertiesUpdater','SurroundUpdater') }
    if (($roles -join '|') -cne ($expectedRoles -join '|')) { throw 'Missing, repeated or unordered vendor artifacts.' }
    foreach ($artifact in $Stack.artifacts) {
        if ($artifact.id -cne $artifact.role -or $artifact.fileName -notmatch $family -or
            $artifact.size -le 0 -or $artifact.sha256 -cnotmatch '^[0-9A-F]{64}$' -or
            $artifact.authenticode.status -ne 'Valid' -or
            $artifact.authenticode.signerThumbprint -cne 'B23FAAE4D5ADEDA77BCCD9F12F32C92D3FF755D5') { throw 'Invalid vendor artifact identity or trust pin.' }
        if ($artifact.role -eq 'BaseInstaller') {
            $expectedEmbedded = if ($family -eq 'rznb11') {
                'RawDeflate|569682|50445093|thx-rznb11-base.exe|51037408|819B1504B025105589B5899CC09BB612B7AD83F8DED8DE0D087F81D4085542ED'
            } else {
                'RawDeflate|577088|52553413|thx-rznb12-base.exe|53145160|DE47E110A3E528249EAF59FA7932C1A568183A38F7B52246EE395A0418B14620'
            }
            $actualEmbedded = '{0}|{1}|{2}|{3}|{4}|{5}' -f
                $artifact.embeddedInstaller.containerFormat,
                $artifact.embeddedInstaller.compressedOffset,
                $artifact.embeddedInstaller.compressedLength,
                $artifact.embeddedInstaller.fileName,
                $artifact.embeddedInstaller.size,
                $artifact.embeddedInstaller.sha256
            if ($actualEmbedded -cne $expectedEmbedded -or
                $artifact.embeddedInstaller.authenticode.status -cne 'Valid' -or
                $artifact.embeddedInstaller.authenticode.signerSubject -cne $artifact.authenticode.signerSubject -or
                $artifact.embeddedInstaller.authenticode.signerThumbprint -cne 'B23FAAE4D5ADEDA77BCCD9F12F32C92D3FF755D5' -or
                (@($artifact.embeddedInstaller.arguments) -join '|') -cne '/quiet|/norestart' -or
                $artifact.embeddedInstaller.carrierExecutionAllowed -ne $false -or
                $artifact.embeddedInstaller.extractionDestination -cne 'ProtectedComponentDirectory' -or
                $artifact.embeddedInstaller.outputCreation -cne 'CreateNew') {
                throw 'Protected inner Burn extraction or execution pins drifted.'
            }
        }
        elseif ($artifact.PSObject.Properties.Name -contains 'embeddedInstaller') {
            throw 'Only the signed base carrier may define an embedded installer.'
        }
        if ($isCachedRznb12 -and $artifact.role -eq 'BaseInstaller') {
            $expectedName = 'THXAPO_rznb12_v4.2.37.1621-5117e8e-i2546a_MSHLKSIGN-2255eea3.3219a439.exe'
            $expectedUrl = "https://github.com/OpenBladeProject/blade-driver-catalog/releases/download/thx-rznb12-4.2.37.1621/$expectedName"
            if ($artifact.version -cne '4.2.37.1621' -or $artifact.fileName -cne $expectedName -or
                $artifact.size -ne 53720208 -or
                $artifact.sha256 -cne '32392A63FC704DFC4BFBE4F33ED038773BBDE21AC88C61BAEEA013E3F98E8CF2' -or
                $artifact.sourceUrl -cne $expectedUrl -or @($artifact.manifestReferences).Count -ne 0 -or
                $artifact.sourceEvidence.acquisition -cne 'WindowsInstallerCache' -or
                $artifact.sourceEvidence.publicVendorDownloadEstablished -ne $false -or
                $artifact.sourceEvidence.catalogMembershipVerified -ne $true -or
                $artifact.sourceEvidence.catalogMembersVerified -ne 9 -or
                $artifact.sourceEvidence.vendorCodeExecuted -ne $false) {
                throw 'Cached base installer provenance or authorized mirror identity drifted.'
            }
            continue
        }
        if ($artifact.sourceUrl -cne ('https://app-assets.razer.com/files/synapse/devices/common/THX/' + $artifact.fileName) -or
            $artifact.PSObject.Properties.Name -contains 'sourceEvidence') {
            throw 'Direct vendor artifact source boundary changed.'
        }
        if ((($artifact.manifestReferences.vendorProductId | Sort-Object) -join '|') -cne
            (($Stack.applicableProfiles.vendorProductId | Sort-Object) -join '|')) { throw 'Artifact vendor references do not cover its profiles.' }
        foreach ($reference in $artifact.manifestReferences) {
            if ($reference.resourceVersion -cne $artifact.version) { throw 'Vendor resource version drift.' }
            if ($artifact.role -eq 'BaseInstaller' -and $reference.runOnInstall -cne '/s /norestart') { throw 'Base installer arguments must match vendor source.' }
        }
    }
    if (@($Stack.activeConfiguration).Count -ne 2) { throw 'Both active immutable configuration pins are required.' }
    foreach ($configuration in $Stack.activeConfiguration) {
        if ($configuration.sourceArtifactId -notin $roles -or $configuration.size -le 0 -or $configuration.sha256 -cnotmatch '^[0-9A-F]{64}$') { throw 'Active configuration has no reviewed source.' }
    }
    if ($isCachedRznb12) {
        $updaters = @($Stack.artifacts | Where-Object role -ne BaseInstaller)
        $expectedDriverHashes = @(
            'A3E707295B5D83274F6CC2957B6620280D581B89D6EA91F1244898D90AC2B71A',
            'E927352ADDE3055777956FD14B7F7C59F3B213B04632F198CCE5B8C9A34101C7',
            '0CCD88E5DABA6C9C6788B4F623CEDB94FEB2239DB8296A5363199B590D99AC7B',
            'B33AD0EF245F8E78C697E239CD21CE3485AD76E1A207918B440F574DA1BD9D9C',
            '467F2BF8FBAB6049003DAFBAE7C8BB47CD9251BEB46A9AF3F41DE236C19E1488',
            'A7698D49CC930770674D5EA223B5EBDF1E3546F3CC6D1AFF441D40E6FB55F4BF',
            'D336ADC5A91F2A54CC0E1596FCFE2F3F6A8FF2F9E8AD29F700AAD07FC28B7DA9',
            'FF587D74CE7763FCB2B0150B62A67237844B688647CE0434219B814608E12C07',
            '0943D5D4EA86911313A479BE8B341F28A1547F671796E640EA59CE61A8751679',
            'B03977363841C14406F90883B93852CD37765B173930040CDE338DF5721797D7',
            '20349EFE0BAD4ADE84BF57EFC38A7D7B7DF82CCEF3555D17DC1B34142840F6DF',
            '2402A0E8DCF6BA2756D2803BDE6C858FF0D8859B12988163C229BCB94A6DDBC3')
        if ((@($Stack.driverPackages.files.sha256) -join '|') -cne ($expectedDriverHashes -join '|') -or
            ($updaters.version -join '|') -cne '4.2.37.1846|4.2.37.1846' -or
            ($updaters.sha256 -join '|') -cne '5BBD258C599720B8C81ABB623CA512613081CD913BB2BDA68357F8C7713F845B|1F542677BCE9CE0D3235D9A441C6FD9C8182DC364180B5E8632B3A67A591895F' -or
            ($Stack.activeConfiguration.sha256 -join '|') -cne 'E2E69163AFFEAE1F4FD19E347EB92E63CA7CAA32C13E8E1500AA459D76823031|1AC5DC1DD9B6E60843E6E3076DC94F4C2492D9DB02600442AF276FD6A9CCFD6C') {
            throw 'The cached base must retain the reviewed 1846 updater and active-configuration pins.'
        }
    }
    $status = if ($family -eq 'rznb11' -or $isCachedRznb12) { 'FreshInstallCandidate' } else { 'BaseInstallerUnavailable' }
    if ($Stack.provisioning.status -cne $status -or -not $Stack.provisioning.requiresMatchingBaseAudioDriver -or
        $Stack.provisioning.baseAudioDriverIncluded -or $Stack.provisioning.existingStackReplacementAllowed -or
        $Stack.provisioning.physicalInstallationValidation -ne 'Pending') { throw 'Provisioning boundary was widened.' }
    if ($status -eq 'FreshInstallCandidate') {
        if ($Stack.provisioning.freshInstallAdmission.mode -cne 'ConditionalWholeStack' -or
            $Stack.provisioning.freshInstallAdmission.existingStackRequiredState -cne 'Absent' -or
            $Stack.provisioning.freshInstallAdmission.completePinnedStackRequired -ne $true -or
            @($Stack.provisioning.blockers).Count -ne 0) {
            throw 'Fresh-install whole-stack admission was widened.'
        }
        $hasEndpointRead = $Stack.provisioning.freshInstallAdmission.PSObject.Properties.Name -contains 'requiredPreMutationEndpointReads'
        if ($isCachedRznb12) {
            if (-not $hasEndpointRead -or
                (@($Stack.provisioning.freshInstallAdmission.requiredPreMutationEndpointReads) -join '|') -cne 'Speakers|Headphones') {
                throw 'Cached rznb12 must read both endpoints before runtime mutation.'
            }
        }
        elseif ($hasEndpointRead) {
            throw 'The rznb12 both-endpoint probe must not be attributed to rznb11.'
        }
    }
    elseif ($Stack.provisioning.PSObject.Properties.Name -contains 'freshInstallAdmission' -or
        @($Stack.provisioning.blockers).Count -eq 0) {
        throw 'Unavailable stack must keep its blocker and omit fresh-install admission.'
    }
    if ($Stack.nativeClient -cne 'components/thx-v4-native/1.1.1.0/component.json' -or $Stack.redistribution.catalogContainsArtifact) { throw 'Client or distribution boundary changed.' }
    if ($isCachedRznb12) {
        $expectedUrl = 'https://github.com/OpenBladeProject/blade-driver-catalog/releases/download/thx-rznb12-4.2.37.1621/THXAPO_rznb12_v4.2.37.1621-5117e8e-i2546a_MSHLKSIGN-2255eea3.3219a439.exe'
        if ($Stack.delivery.method -cne 'CatalogReleaseAsset' -or
            $Stack.redistribution.status -cne 'WrittenPermissionReportedFromRazerUSLtd' -or
            $Stack.redistribution.reportedPermissionGrantor -cne 'Razer US Ltd' -or
            $Stack.redistribution.permissionBasis -cne 'ProjectOwnerStatement' -or
            $Stack.redistribution.independentDocumentReview -ne $false -or
            $Stack.redistribution.catalogReleaseAsset -ne $true -or
            $Stack.redistribution.authorizedDeliveryMethod -cne 'GitHub release asset' -or
            $Stack.redistribution.release.repository -cne 'OpenBladeProject/blade-driver-catalog' -or
            $Stack.redistribution.release.tag -cne 'thx-rznb12-4.2.37.1621' -or
            $Stack.redistribution.release.asset -cne 'THXAPO_rznb12_v4.2.37.1621-5117e8e-i2546a_MSHLKSIGN-2255eea3.3219a439.exe' -or
            $Stack.redistribution.release.url -cne $expectedUrl -or
            $Stack.redistribution.release.publicationStatus -cne 'Published' -or
            $Stack.redistribution.release.authorizedAudience -cne 'Public users') {
            throw 'Cached installer mirror authorization or exact published release identity drifted.'
        }
    }
    elseif ($Stack.delivery.method -cne 'DirectVendorDownload' -or
        $Stack.redistribution.status -cne 'NotPublished' -or
        $Stack.redistribution.catalogReleaseAsset) {
        throw 'Direct vendor download was confused with a catalog mirror.'
    }
}

$schemaPath = Join-Path $repository 'schemas/upstream-audio-stack.schema.json'
$paths = @(
    'components/thx-rznb11/4.2.29.1159/stack.json',
    'components/thx-rznb12/4.2.37.1621/stack.json',
    'components/thx-rznb12/4.2.41.2499/stack.json')
foreach ($path in $paths) {
    $raw = Get-Content -LiteralPath (Join-Path $repository $path) -Raw
    $stack = $raw | ConvertFrom-Json
    Assert-AudioStack $stack
    if ((Get-Command Test-Json -ErrorAction SilentlyContinue) -and
        -not (Test-Json -Json $raw -SchemaFile $schemaPath)) {
        throw "Audio stack '$path' does not satisfy its strict JSON schema."
    }
    foreach ($mutate in @(
        { param($x) $x.driverPackages = @($x.driverPackages | Select-Object -Skip 1) },
        { param($x) $x.driverPackages[0].files[0].sha256 = 'bad' },
        { param($x) $x.driverPackages[0].infName = 'thx_other_apo4.inf' },
        { param($x) $x.artifacts = @($x.artifacts | Select-Object -Skip 1) },
        { param($x) $x.artifacts[0].authenticode.signerThumbprint = 'bad' },
        { param($x) $x.artifacts[0].sourceUrl = 'https://example.invalid/file.exe' },
        { param($x) $x.activeConfiguration[0].sourceArtifactId = 'Missing' },
        { param($x) $x.applicableProfiles += $x.applicableProfiles[0] },
        { param($x) $x.provisioning.baseAudioDriverIncluded = $true },
        { param($x) $x.provisioning.existingStackReplacementAllowed = $true },
        { param($x) if ($x.provisioning.status -eq 'FreshInstallCandidate') { if ($x.provisioning.freshInstallAdmission.PSObject.Properties.Name -contains 'requiredPreMutationEndpointReads') { $x.provisioning.freshInstallAdmission.requiredPreMutationEndpointReads = @('Speakers') } else { $x.provisioning.freshInstallAdmission.completePinnedStackRequired = $false } } else { $x.provisioning.blockers = @() } },
        { param($x) if ($x.artifacts[0].role -eq 'BaseInstaller') { $x.artifacts[0].embeddedInstaller.carrierExecutionAllowed = $true } else { $x.artifacts[0].sourceUrl = 'https://example.invalid/file.exe' } },
        { param($x) $x.provisioning.status = 'Ready' }
    )) {
        $changed = $raw | ConvertFrom-Json
        & $mutate $changed
        $rejected = $false
        try { Assert-AudioStack $changed } catch { $rejected = $true }
        if (-not $rejected) { throw 'Audio stack validator accepted an unsafe descriptor mutation.' }
    }
}

$cachedRaw = Get-Content -LiteralPath (Join-Path $repository 'components/thx-rznb12/4.2.37.1621/stack.json') -Raw
$currentRaw = Get-Content -LiteralPath (Join-Path $repository 'components/thx-rznb12/4.2.41.2499/stack.json') -Raw
$cachedMutationIndex = 0
foreach ($mutate in @(
    { param($x) $x.artifacts[0].sourceUrl = $x.artifacts[0].sourceUrl.Replace('OpenBladeProject','other') },
    { param($x) $x.artifacts[0].sourceUrl = 'http://release-assets.githubusercontent.com/evil/file.exe' },
    { param($x) $x.redistribution.release.repository = 'other/blade-driver-catalog' },
    { param($x) $x.redistribution.release.tag = 'thx-rznb12-latest' },
    { param($x) $x.redistribution.release.asset = 'renamed.exe' },
    { param($x) $x.redistribution.catalogReleaseAsset = $false },
    { param($x) $x.redistribution.status = 'NotPublished' },
    { param($x) $x.artifacts[0].manifestReferences = @($x.artifacts[1].manifestReferences[0]) },
    { param($x) $x.stack.driverVersion = '4.2.41.2499' },
    { param($x) $x.driverPackages = @(($currentRaw | ConvertFrom-Json).driverPackages) },
    { param($x) $x.artifacts[0].embeddedInstaller.sha256 = '819B1504B025105589B5899CC09BB612B7AD83F8DED8DE0D087F81D4085542ED' },
    { param($x) $x.artifacts[0].embeddedInstaller.compressedOffset = 569682 },
    { param($x) $x.provisioning.freshInstallAdmission.existingStackRequiredState = 'Installed' },
    { param($x) $x.provisioning.physicalInstallationValidation = 'Complete' }
)) {
    $cachedMutationIndex++
    $changed = $cachedRaw | ConvertFrom-Json
    & $mutate $changed
    $rejected = $false
    try { Assert-AudioStack $changed } catch { $rejected = $true }
    if (-not $rejected) { throw "Audio stack validator accepted unsafe cached-installer mutation $cachedMutationIndex." }
}
Write-Output 'Upstream audio stack contracts passed: 3 stacks and 53 rejection checks.'

[CmdletBinding()]
param()
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot

function Assert-AudioStack($Stack) {
    if ($Stack.manifestType -ne 'OpenBlade.RazerUpstreamAudioStackCatalogEntry' -or $Stack.schemaVersion -ne 1) { throw 'Unknown audio stack type.' }
    $family = $Stack.stack.productId
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
    $expectedRoles = if ($family -eq 'rznb11') { @('BaseInstaller','PropertiesUpdater','SurroundUpdater') } else { @('PropertiesUpdater','SurroundUpdater') }
    if (($roles -join '|') -cne ($expectedRoles -join '|')) { throw 'Missing, repeated or unordered vendor artifacts.' }
    foreach ($artifact in $Stack.artifacts) {
        if ($artifact.id -cne $artifact.role -or $artifact.fileName -notmatch $family -or
            $artifact.sourceUrl -cne ('https://app-assets.razer.com/files/synapse/devices/common/THX/' + $artifact.fileName) -or
            $artifact.size -le 0 -or $artifact.sha256 -cnotmatch '^[0-9A-F]{64}$' -or
            $artifact.authenticode.status -ne 'Valid' -or
            $artifact.authenticode.signerThumbprint -cne 'B23FAAE4D5ADEDA77BCCD9F12F32C92D3FF755D5') { throw 'Invalid vendor artifact identity or trust pin.' }
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
    $status = if ($family -eq 'rznb11') { 'FreshInstallCandidate' } else { 'BaseInstallerUnavailable' }
    if ($Stack.provisioning.status -cne $status -or -not $Stack.provisioning.requiresMatchingBaseAudioDriver -or
        $Stack.provisioning.baseAudioDriverIncluded -or $Stack.provisioning.existingStackReplacementAllowed -or
        $Stack.provisioning.physicalInstallationValidation -ne 'Pending') { throw 'Provisioning boundary was widened.' }
    if ($family -eq 'rznb12' -and @($Stack.provisioning.blockers).Count -eq 0) { throw 'Missing rznb12 base installer must remain explicit.' }
    if ($Stack.nativeClient -cne 'components/thx-v4-native/1.1.1.0/component.json' -or
        $Stack.redistribution.catalogContainsArtifact -or $Stack.redistribution.catalogReleaseAsset) { throw 'Client or distribution boundary changed.' }
}

$paths = @('components/thx-rznb11/4.2.29.1159/stack.json','components/thx-rznb12/4.2.41.2499/stack.json')
foreach ($path in $paths) {
    $raw = Get-Content -LiteralPath (Join-Path $repository $path) -Raw
    $stack = $raw | ConvertFrom-Json
    Assert-AudioStack $stack
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
        { param($x) $x.provisioning.status = 'Ready' }
    )) {
        $changed = $raw | ConvertFrom-Json
        & $mutate $changed
        $rejected = $false
        try { Assert-AudioStack $changed } catch { $rejected = $true }
        if (-not $rejected) { throw 'Audio stack validator accepted an unsafe descriptor mutation.' }
    }
}
Write-Output 'Upstream audio stack contracts passed: 2 stacks and 22 rejection checks.'

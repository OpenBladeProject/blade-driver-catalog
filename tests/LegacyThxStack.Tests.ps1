[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot

function Assert-LegacyThxStack($Stack) {
    if ($Stack.manifestType -cne 'OpenBlade.RazerLegacyThxStackEvidence' -or
        $Stack.schemaVersion -ne 1 -or
        $Stack.'$schema' -cne '../../../schemas/legacy-thx-stack.schema.json') {
        throw 'Unknown legacy THX evidence type.'
    }
    if ($Stack.stack.id -cne 'thx-legacy-2.6.5' -or
        $Stack.stack.driverVersion -cne '2.6.5.0' -or
        $Stack.stack.generation -cne 'LegacyThxSpatialAudioControl' -or
        $Stack.stack.controlApplicationProductId -cne '9NC521C2JHDK') {
        throw 'Legacy THX stack identity drifted.'
    }

    $expectedProfiles = @(
        '669|RZ09-0482|029D|HDAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A582020|6.0.9484.1|d5987bbd-d8bd-4ebe-95e6-2c521b13baaa|6340FE3A2730FA7469D09BA5F8029F9492A8CF745562A66B2842154DE5726EF2|RTAIODAT.DAT|54704172|E84591EF1106343CE3200795CDFADDC4D6347F6F86E8E28012CEC82F130E5A32|Razer_2020|RealtekCodec|NotEstablished',
        '671|RZ09-0483|029F|INTELAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A583006|6.0.9601.1|fc8c3fe8-290e-4984-af52-75020538e18d|27AE05348EBB066F3F7FD4896A1E40416E565841ED76CEA38D039A2241905C78|RTAIODAT.DAT|57817855|98509C3F66CA9D20B12DE14A8063C25502C439840193D501E80A857EA510F08B|Razer_3006|RealtekCodec|NotEstablished',
        '672|RZ09-0484|02A0|INTELAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A583007|6.0.9601.1|01c12b71-a0f8-40ff-8be0-7b9c4225ed5a|27AE05348EBB066F3F7FD4896A1E40416E565841ED76CEA38D039A2241905C78|RTAIODAT.DAT|57817855|98509C3F66CA9D20B12DE14A8063C25502C439840193D501E80A857EA510F08B|Razer_3007|RealtekCodec|NotEstablished')
    $actualProfiles = @($Stack.candidateProfiles | ForEach-Object {
            '{0}|{1}|{2}|{3}|{4}|{5}|{6}|{7}|{8}|{9}|{10}|{11}|{12}' -f $_.vendorProductId, $_.modelNumber,
                $_.usbIdentity.pid, $_.baseAudioPackage.hardwareId,
                $_.baseAudioPackage.driverVersion, $_.baseAudioPackage.updateId,
                $_.baseAudioPackage.cab.sha256, $_.baseAudioPackage.oemCodecTuning.fileName,
                $_.baseAudioPackage.oemCodecTuning.size, $_.baseAudioPackage.oemCodecTuning.sha256,
                $_.baseAudioPackage.oemCodecTuning.profileName, $_.baseAudioPackage.oemCodecTuning.scope,
                $_.baseAudioPackage.oemCodecTuning.thxIntegration
        } | Sort-Object)
    if (($actualProfiles -join ',') -cne ($expectedProfiles -join ',')) {
        throw 'Legacy THX candidates are not the exact reviewed profile set.'
    }
    foreach ($profile in $Stack.candidateProfiles) {
        $base = $profile.baseAudioPackage
        if ($profile.usbIdentity.vid -cne '1532' -or
            $base.updateId -cnotmatch '^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$' -or
            $base.cab.fileName -cnotmatch '^[a-f0-9_-]+[.]cab$' -or
            $base.cab.size -le 0 -or
            $base.cab.sha256 -cnotmatch '^[0-9A-F]{64}$' -or
            $base.cab.downloadUrl -cnotmatch '^https://catalog[.]s[.]download[.]windowsupdate[.]com/.+[.]cab$' -or
            $base.infSha256 -cnotmatch '^[0-9A-F]{64}$' -or
            $base.catalogSha256 -cnotmatch '^[0-9A-F]{64}$' -or
            $base.oemCodecTuning.fileName -cne 'RTAIODAT.DAT' -or
            $base.oemCodecTuning.size -le 0 -or
            $base.oemCodecTuning.sha256 -cnotmatch '^[0-9A-F]{64}$' -or
            $base.oemCodecTuning.scope -cne 'RealtekCodec' -or
            $base.oemCodecTuning.thxIntegration -cne 'NotEstablished' -or
            $base.catalogSigner.status -cne 'Valid' -or
            $base.catalogSigner.thumbprint -cnotmatch '^[0-9A-F]{40}$') {
            throw 'Exact Realtek base package evidence is incomplete.'
        }
    }

    if (@($Stack.knownNonThxProfiles).Count -ne 1 -or
        $Stack.knownNonThxProfiles[0].modelNumber -cne 'RZ09-0328' -or
        $Stack.knownNonThxProfiles[0].audioTechnology -cne 'DolbyAtmos' -or
        $Stack.knownNonThxProfiles[0].officialProductEvidenceUrl -cne
            'https://mysupport.razer.com/app/answers/detail/a_id/3641/') {
        throw 'The reviewed Dolby-only model evidence drifted.'
    }

    $expectedPackages = @(
        'Apo|07c8c7dc-edbe-4a21-a228-4821eaaaf727|5964AF8DF1082680D54326EBA859C735EA80AA1BCA3C0E51DD71A0D51B718289',
        'Configuration|d7c9ca5f-77ae-4681-a1b4-78453818d1c4|C8273CCE2258582519EE9A8CEC92E41D4BE990733044F00EEF6DF51997D41F79',
        'Hsa|2d6cda10-f6d5-4f44-acb1-71bb84653d0c|90A0BB7CA17F04605C5599A77E33B466366ACF3FA816D62B1944D3F15FF0600F',
        'Service|9a0052d8-8511-47b4-80d4-6dc4abf83d97|3E7ACA4C7BA6ABC44750FDD226BD9BAD7EA2848045E1BE0C6FEA619C2AA28389')
    $actualPackages = @($Stack.genericComponentPackages | ForEach-Object {
            '{0}|{1}|{2}' -f $_.role, $_.updateId, $_.cab.sha256
        } | Sort-Object)
    if (($actualPackages -join ',') -cne ($expectedPackages -join ',')) {
        throw 'All four exact generic THX component packages are required.'
    }
    if (@($Stack.genericComponentPackages.updateId | Sort-Object -Unique).Count -ne 4) {
        throw 'Generic THX packages need unique Microsoft Update Catalog identities.'
    }
    foreach ($package in $Stack.genericComponentPackages) {
        if ($package.driverVersion -cne '2.6.5.0' -or
            $package.updateId -cnotmatch '^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$' -or
            $package.cab.fileName -cnotmatch '^[a-f0-9_-]+[.]cab$' -or
            $package.cab.size -le 0 -or
            $package.cab.sha256 -cnotmatch '^[0-9A-F]{64}$' -or
            $package.catalogSigner.status -cne 'Valid' -or
            $package.catalogSigner.thumbprint -cne
                'B878D8EB696CF3D4505E2F6641C57AF9062EC51A') {
            throw 'Generic THX package identity or catalog trust pin drifted.'
        }
        if (@($package.files | Where-Object {
                    $_.role -eq 'Inf' -and $_.name -ceq $package.infName
                }).Count -ne 1 -or
            @($package.files | Where-Object {
                    $_.role -eq 'Catalog' -and $_.name -ceq $package.catalogFile
                }).Count -ne 1 -or
            @($package.files.name | Sort-Object -Unique).Count -ne @($package.files).Count) {
            throw 'Generic THX package member pins are incomplete or repeated.'
        }
        foreach ($file in $package.files) {
            if ($file.name -match '[/\\]' -or $file.size -le 0 -or
                $file.sha256 -cnotmatch '^[0-9A-F]{64}$') {
                throw 'Generic THX package has an invalid member pin.'
            }
        }
        $expectedAuthenticodeFiles = @($package.files |
            Where-Object { $_.role -eq 'Payload' -and $_.name -match '[.](?:dll|exe)$' } |
            ForEach-Object name |
            Sort-Object)
        if ((@($package.authenticodeFiles | Sort-Object) -join ',') -cne
            ($expectedAuthenticodeFiles -join ',')) {
            throw 'Generic THX Authenticode file scope is incomplete or overclaimed.'
        }
        if ($expectedAuthenticodeFiles.Count -gt 0 -and
            ($package.authenticodeSigner.status -cne 'Valid' -or
             $package.authenticodeSigner.thumbprint -cne
                '4BB8A04FDA0285FB9A7ACC812422559A120107C6')) {
            throw 'Generic THX payload trust pin drifted.'
        }
    }

    if ($Stack.modelBinding.status -cne 'Blocked' -or
        $Stack.modelBinding.exactOemChildEnumerationPackage -cne 'NotEstablished' -or
        $Stack.modelBinding.exactModelTuning -cne 'NotEstablished' -or
        $Stack.modelBinding.genericComponentsAreModelBindingEvidence -or
        $Stack.modelBinding.installableCandidate -or
        @($Stack.modelBinding.blockers).Count -lt 2) {
        throw 'Legacy THX provisioning blocker was widened or obscured.'
    }
    if ($Stack.delivery.method -cne 'MicrosoftUpdateCatalog' -or
        $Stack.delivery.packagePurpose -cne 'ComponentCandidatesOnly' -or
        $Stack.redistribution.catalogContainsArtifact -or
        $Stack.redistribution.catalogReleaseAsset) {
        throw 'Legacy component delivery or redistribution boundary changed.'
    }
}

$schemaPath = Join-Path $repository 'schemas\legacy-thx-stack.schema.json'
$schema = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json
if ($schema.'$schema' -cne 'https://json-schema.org/draft/2020-12/schema' -or
    $schema.additionalProperties -ne $false -or
    $schema.properties.manifestType.const -cne 'OpenBlade.RazerLegacyThxStackEvidence' -or
    $schema.properties.modelBinding.properties.installableCandidate.const -ne $false) {
    throw 'Legacy THX JSON schema lost its strict evidence boundary.'
}

$path = Join-Path $repository 'components\thx-legacy\2.6.5.0\stack.json'
$raw = Get-Content -LiteralPath $path -Raw
$stack = $raw | ConvertFrom-Json
Assert-LegacyThxStack $stack
if ((Get-Command Test-Json -ErrorAction SilentlyContinue) -and
    -not (Test-Json -Json $raw -SchemaFile $schemaPath)) {
    throw 'Legacy THX manifest does not satisfy its strict JSON schema.'
}

$mutations = @(
    { param($x) $x.candidateProfiles = @($x.candidateProfiles | Select-Object -Skip 1) },
    { param($x) $x.candidateProfiles[0].baseAudioPackage.hardwareId = 'HDAUDIO\OTHER' },
    { param($x) $x.candidateProfiles[0].baseAudioPackage.cab.sha256 = 'bad' },
    { param($x) $x.candidateProfiles[0].baseAudioPackage.oemCodecTuning.profileName = 'Razer_3007' },
    { param($x) $x.candidateProfiles[0].baseAudioPackage.oemCodecTuning.sha256 = '98509C3F66CA9D20B12DE14A8063C25502C439840193D501E80A857EA510F08B' },
    { param($x) $x.candidateProfiles[0].baseAudioPackage.oemCodecTuning.thxIntegration = 'Established' },
    { param($x) $x.knownNonThxProfiles[0].audioTechnology = 'THX' },
    { param($x) $x.genericComponentPackages = @($x.genericComponentPackages | Select-Object -Skip 1) },
    { param($x) $x.genericComponentPackages[0].files[0].sha256 = 'bad' },
    { param($x) $x.genericComponentPackages[0].catalogSigner.thumbprint = 'bad' },
    { param($x) $x.genericComponentPackages[0].driverVersion = '4.2.29.1159' },
    { param($x) $x.modelBinding.status = 'Ready' },
    { param($x) $x.modelBinding.installableCandidate = $true },
    { param($x) $x.modelBinding.genericComponentsAreModelBindingEvidence = $true },
    { param($x) $x.delivery.packagePurpose = 'Installer' }
)
foreach ($mutation in $mutations) {
    $changed = $raw | ConvertFrom-Json
    & $mutation $changed
    $rejected = $false
    try { Assert-LegacyThxStack $changed } catch { $rejected = $true }
    if (-not $rejected) {
        throw 'Legacy THX validator accepted an unsafe evidence mutation.'
    }
}

Write-Output 'Legacy THX contracts passed: 3 candidate models, 4 generic packages and 15 rejection checks.'

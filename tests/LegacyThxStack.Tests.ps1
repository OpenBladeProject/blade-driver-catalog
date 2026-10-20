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
        '669|RZ09-0482|029D|HDAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A582020|6.0.9484.1|d5987bbd-d8bd-4ebe-95e6-2c521b13baaa|6340FE3A2730FA7469D09BA5F8029F9492A8CF745562A66B2842154DE5726EF2|RTAIODAT.DAT|54704172|E84591EF1106343CE3200795CDFADDC4D6347F6F86E8E28012CEC82F130E5A32|Razer_2020|RealtekCodec|NotEstablished|2020|PI490|profile-20230502|A694CC6E87985CF3EF58AAA2CF1E00FCCA4F24FE02EE464AC164C72986F4AF68|devices-V2|False',
        '671|RZ09-0483|029F|INTELAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A583006|6.0.9601.1|fc8c3fe8-290e-4984-af52-75020538e18d|27AE05348EBB066F3F7FD4896A1E40416E565841ED76CEA38D039A2241905C78|RTAIODAT.DAT|57817855|98509C3F66CA9D20B12DE14A8063C25502C439840193D501E80A857EA510F08B|Razer_3006|RealtekCodec|NotEstablished|3006|SO690|profile-20221107|94A947281EF38E06C8C81F26BBAA3A64640323FD50F264E171FC52401EBD36E2|devices-V2|False',
        '672|RZ09-0484|02A0|INTELAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A583007|6.0.9601.1|01c12b71-a0f8-40ff-8be0-7b9c4225ed5a|27AE05348EBB066F3F7FD4896A1E40416E565841ED76CEA38D039A2241905C78|RTAIODAT.DAT|57817855|98509C3F66CA9D20B12DE14A8063C25502C439840193D501E80A857EA510F08B|Razer_3007|RealtekCodec|NotEstablished|3007|KI890|profile-20221122-PVT-red|ECECE0925FC8FA43D4102A9E49BB7EE1A7F8A9B3F6233F4D50A71C788A0FC767|devices-V2|False')
    $actualProfiles = @($Stack.candidateProfiles | ForEach-Object {
            '{0}|{1}|{2}|{3}|{4}|{5}|{6}|{7}|{8}|{9}|{10}|{11}|{12}|{13}|{14}|{15}|{16}|{17}|{18}' -f $_.vendorProductId, $_.modelNumber,
                $_.usbIdentity.pid, $_.baseAudioPackage.hardwareId,
                $_.baseAudioPackage.driverVersion, $_.baseAudioPackage.updateId,
                $_.baseAudioPackage.cab.sha256, $_.baseAudioPackage.oemCodecTuning.fileName,
                $_.baseAudioPackage.oemCodecTuning.size, $_.baseAudioPackage.oemCodecTuning.sha256,
                $_.baseAudioPackage.oemCodecTuning.profileName, $_.baseAudioPackage.oemCodecTuning.scope,
                $_.baseAudioPackage.oemCodecTuning.thxIntegration,
                $_.thxScuTuning.subsystemSelector, $_.thxScuTuning.profileId,
                $_.thxScuTuning.profileVersion, $_.thxScuTuning.speakerPathSha256,
                $_.thxScuTuning.schema, $_.thxScuTuning.genericFallbackAccepted
        } | Sort-Object)
    if (($actualProfiles -join ',') -cne ($expectedProfiles -join ',')) {
        throw 'Legacy THX candidates are not the exact reviewed profile set.'
    }
    $expectedPayloads = @(
        'RZ09-0482|2428|137132|53267534|6900|BAC1AC6C25DC7AF6B51EC7AD0A474FA4D87E54B0096E9A1A334F7776B4A43D3C|1|RTKAMPI',
        'RZ09-0483|2397|140436|53506474|18324|42D19433C85388ABE861BF4A850D6B39B193905F60FA7B0824F99BBAABCDFC6E|1|RTKAMPI',
        'RZ09-0484|2394|140352|53436686|27748|BD0731A047C8EA9F68F82212CB8320AC2CD2995CEBE478C4BF896908AD1480E7|1|RTKAMPI')
    $actualPayloads = @($Stack.candidateProfiles | ForEach-Object {
            $payload = $_.baseAudioPackage.oemCodecTuning.profilePayload
            '{0}|{1}|{2}|{3}|{4}|{5}|{6}|{7}' -f $_.modelNumber,
                $payload.profileIndex, $payload.descriptorOffset, $payload.payloadOffset,
                $payload.size, $payload.sha256, $payload.recordCount, $payload.recordType
        })
    if (($actualPayloads -join '|') -cne ($expectedPayloads -join '|')) {
        throw 'Realtek payload evidence must use the selected descriptor, not the next profile.'
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

    $child = $Stack.modelBinding.oemChildExtensionEvidence
    $expectedChildMatches = @(
        'RZ09-0482|HDAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A582020|DeviceExtension_Install_RT_SKU_C',
        'RZ09-0483|INTELAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A583006|DeviceExtension_Install_RT_SKU_A',
        'RZ09-0484|INTELAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A583007|DeviceExtension_Install_RT_SKU_A')
    $actualChildMatches = @($child.exactMatches | ForEach-Object {
            '{0}|{1}|{2}' -f $_.modelNumber, $_.hardwareId, $_.installSection
        })
    if ($Stack.modelBinding.status -cne 'Blocked' -or
        $Stack.modelBinding.exactOemChildEnumerationPackage -cne 'Established' -or
        $child.source.repositoryUrl -cne 'https://github.com/Torahime3/razer-blade-14-thx-driver-restore' -or
        $child.source.commit -cne '4f3451e246a93d48dabf8e2140ce3aebbd2a08f4' -or
        $child.source.infPath -cne 'drivers/thxhdaudio.inf_amd64_a639441cfa75798e/THXHDAudio.inf' -or
        $child.source.catalogPath -cne 'drivers/thxhdaudio.inf_amd64_a639441cfa75798e/THXHDAudio.cat' -or
        $child.packageIdentity.infName -cne 'THXHDAudio.inf' -or
        $child.packageIdentity.catalogFile -cne 'THXHDAudio.cat' -or
        $child.packageIdentity.extensionId -cne '17B56683-7F95-4BAB-8031-AB5DE114A4CC' -or
        $child.packageIdentity.driverDate -cne '2023-06-17' -or
        $child.packageIdentity.driverVersion -cne '2.6.5.0' -or
        $child.gitNormalizedInf.lineEndings -cne 'LF' -or
        $child.gitNormalizedInf.size -ne 28868 -or
        $child.gitNormalizedInf.sha256 -cne '5E800A76DD0DC284A048E7301433765D114640CFF82EC87D65D44DC375AF3D14' -or
        $child.gitNormalizedInf.catalogMemberVerification -cne 'Invalid' -or
        $child.recoveredSignedInf.lineEndings -cne 'CRLF' -or
        $child.recoveredSignedInf.size -ne 29311 -or
        $child.recoveredSignedInf.sha256 -cne '6FE831463C60FD2C1ADA9207FD63607491BEA87F70AE5D48B9982F32B6571D72' -or
        $child.recoveredSignedInf.recovery -cne 'RestoreGitNormalizedLineEndingsOnly' -or
        $child.recoveredSignedInf.directiveModifications -ne $false -or
        $child.recoveredSignedInf.catalogMemberVerification -cne 'Valid' -or
        $child.catalog.size -ne 25994 -or
        $child.catalog.sha256 -cne 'FB496566667F6AE7C415A96BFE3D97B14BD63C1681C19B9906A21EBF0AFFE799' -or
        $child.catalog.signatureVerification -cne 'Valid' -or
        $child.catalog.signerThumbprint -cne 'B878D8EB696CF3D4505E2F6641C57AF9062EC51A' -or
        $child.catalog.signatureTimestampDate -cne '2023-06-21' -or
        (($actualChildMatches -join '|') -cne ($expectedChildMatches -join '|')) -or
        ((@($child.componentIds) -join '|') -cne
            'VEN_THX&CID_THXAPO|VEN_THX&PID_THXSVC|VEN_THX&PID_THXHSA|VEN_THX&PID_THXSCU') -or
        $child.componentVariant -cne 'Avx2Subsystem' -or
        ((@($child.renderEndpointSettings) -join '|') -cne 'OutAPO|HPAPO') -or
        $child.configurationPath -cne '%ProgramData%\THX\thx_spatial.conf.json' -or
        $Stack.modelBinding.exactModelTuning -cne 'Established' -or
        $Stack.modelBinding.genericFallbackAccepted -ne $false -or
        $Stack.modelBinding.ordinaryAudioIncludeNeedsPresent -ne $true -or
        $Stack.modelBinding.thxSpecificIncludeNeedsPresent -ne $false -or
        $Stack.modelBinding.endpointFxApoBinding -cne 'NotEstablished' -or
        $Stack.modelBinding.apoRegistration.hostClsid -cne '68650828-CA0F-4196-9096-5F50931AF10A' -or
        $Stack.modelBinding.apoRegistration.offloadClsid -cne 'E6769B7D-B58F-45CA-B6F2-964B83EDCB76' -or
        $Stack.modelBinding.e82GuidEvidence.guid -cne 'E82A5EE8-44D2-44C1-897E-AA5AFBF146BA' -or
        (@($Stack.modelBinding.e82GuidEvidence.presentIn) -join '|') -cne 'RZ09-0482 HDXACPRazer.inf' -or
        (@($Stack.modelBinding.e82GuidEvidence.absentFrom) -join '|') -cne 'RZ09-0483 HDXSSTRazer.inf|RZ09-0484 HDXSSTRazer.inf' -or
        $Stack.modelBinding.e82GuidEvidence.equalsThxApoClsid -ne $false -or
        $Stack.modelBinding.e82GuidEvidence.role -cne 'NotEstablished' -or
        $Stack.modelBinding.genericComponentsAreModelBindingEvidence -or
        $Stack.modelBinding.installableCandidate -or
        @($Stack.modelBinding.blockers).Count -ne 2 -or
        $Stack.modelBinding.blockers[0] -cnotmatch 'CompositeFX' -or
        $Stack.modelBinding.blockers[1] -cnotmatch 'installation order') {
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
    $schema.properties.modelBinding.properties.exactOemChildEnumerationPackage.const -cne 'Established' -or
    $schema.properties.modelBinding.properties.oemChildExtensionEvidence.'$ref' -cne '#/$defs/oemChildExtensionEvidence' -or
    $schema.properties.modelBinding.properties.exactModelTuning.const -cne 'Established' -or
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
    { param($x) $x.candidateProfiles[0].thxScuTuning.profileId = 'SO690' },
    { param($x) $x.candidateProfiles[0].thxScuTuning.genericFallbackAccepted = $true },
    { param($x) $x.knownNonThxProfiles[0].audioTechnology = 'THX' },
    { param($x) $x.genericComponentPackages = @($x.genericComponentPackages | Select-Object -Skip 1) },
    { param($x) $x.genericComponentPackages[0].files[0].sha256 = 'bad' },
    { param($x) $x.genericComponentPackages[0].catalogSigner.thumbprint = 'bad' },
    { param($x) $x.genericComponentPackages[0].driverVersion = '4.2.29.1159' },
    { param($x) $x.candidateProfiles[0].baseAudioPackage.oemCodecTuning.profilePayload.descriptorOffset += 12 },
    { param($x) $x.candidateProfiles[0].baseAudioPackage.oemCodecTuning.profilePayload.sha256 = '78B9E87CD7DCF5965BF576C23805B61BBBFC2548B230853BE69D4ACA18EEEB9D' },
    { param($x) $x.modelBinding.status = 'Ready' },
    { param($x) $x.modelBinding.exactOemChildEnumerationPackage = 'NotEstablished' },
    { param($x) $x.modelBinding.oemChildExtensionEvidence.gitNormalizedInf.catalogMemberVerification = 'Valid' },
    { param($x) $x.modelBinding.oemChildExtensionEvidence.recoveredSignedInf.sha256 = 'bad' },
    { param($x) $x.modelBinding.oemChildExtensionEvidence.exactMatches[0].installSection = 'DeviceExtension_Install_RT_SKU_A' },
    { param($x) $x.modelBinding.oemChildExtensionEvidence.componentIds[0] = 'VEN_THX&CID_THXAPO_SSE2' },
    { param($x) $x.modelBinding.oemChildExtensionEvidence.componentVariant = 'Sse2IsstSsp' },
    { param($x) $x.modelBinding.exactModelTuning = 'NotEstablished' },
    { param($x) $x.modelBinding.endpointFxApoBinding = 'Established' },
    { param($x) $x.modelBinding.e82GuidEvidence.absentFrom = @('RZ09-0484 HDXSSTRazer.inf') },
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

Write-Output 'Legacy THX contracts passed: 3 candidate models, 4 generic packages, signed child-extension evidence and 28 rejection checks.'

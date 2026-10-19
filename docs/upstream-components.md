# Upstream components

English | [简体中文](zh-CN/upstream-components.md) | [Русский](ru-RU/upstream-components.md)

The catalog can record a vendor-hosted component that OpenBlade needs without
turning it into a Driver Store package or republishing the proprietary file.
These entries use the separate
[`OpenBlade.RazerUpstreamComponentCatalogEntry`](../schemas/upstream-component.schema.json)
schema.

## THX V4 Native component

The [THX V4 Native 1.1.1.0 entry](../components/thx-v4-native/1.1.1.0/component.json)
records the exact vendor URL, file size, SHA-256, Authenticode signer, and the
three exact Razer profiles whose current Synapse manifests name the same file.
The catalog does not contain or publish the DLL.

OpenBlade may offer the vendor URL as a direct download. It must verify both
the recorded SHA-256 and Authenticode signature before using the file. The
download provides only the standalone DLL; it does not install an APO stack or
other THX components.

The metadata is source evidence, not an installation or compatibility claim.
OpenBlade core owns exact-device admission, destination handling, runtime
validation, and recovery behavior. See
[OpenBlade issue #808](https://github.com/OpenBladeProject/openblade-core/issues/808),
which motivated the component-detection work and this entry.

## Review every supported model

[`catalog/applicability.json`](../catalog/applicability.json) records the reviewed
OpenBlade model set and a decision for every catalog artifact against every
model. `Applicable` means the cited source supports catalog applicability;
`NotEstablished` means evidence is insufficient, not that the model is incompatible.
Neither status grants runtime admission or installation authority.

The 2026-10-19 review covered all seven OpenBlade models. THX V4 Native 1.1.1.0
is named by the manifests for RZ09-0530, RZ09-0528 and RZ09-0581. The reviewed
manifests for RZ09-0328, RZ09-0482, RZ09-0483 and RZ09-0484 contain no THX native
client resource. Their manifest build and revision are recorded in the ledger.
The evidence does not establish a universal THX package.

Both cataloged driver stacks remain scoped to their own PID. Their DKM, virtual
consumer, keyboard and mouse INF targets name that PID. The RzCommon INF, CAT
and SYS hashes are identical in both stacks, and its INF matches the generic
`RAZER\DeviceContol` child. That shared dependency does not make either complete
stack universal or establish support for the five other models.

When OpenBlade adds or changes a model, review every driver stack and upstream
component against that model's vendor definitions. Update the ledger's pinned
core source and profiles, add an evidenced decision to every entry, and update
component `applicableProfiles` for all established matches. Then refresh core's
pinned coverage fixture and run both repositories' contract tests. Core's model
coverage guard must fail until this review and fixture refresh are complete.

New catalog entries also require decisions for every listed model. The catalog
suite discovers entries by manifest type, checks complete coverage and exact
identity agreement, and rejects missing reviews, unsupported statuses and
component applicability drift. A source-reviewed recovered installer uses
`Applicable` only when its exact model, carrier, protected inner installer,
complete stack and admission conditions are pinned. This catalog status does
not grant runtime admission or physical validation.

## THX driver stacks

The [THX audio stack entries](thx-audio-stacks.md) cover all seven supported
models: exact rznb11 and rznb12 packages, blocked legacy 2.6.5 component
candidates for the three 2023 THX models, and the Dolby-only RZ09-0328. The
legacy entry includes exact Realtek codec OEM tuning and model-specific THX SCU
SpeakerPath profiles. It remains unprovisionable because generic THX
software-component association and endpoint FX/APO binding are not established.
The rznb12 4.2.41.2499 installed reference still lacks a
matching base installer. A separate recovered 4.2.37.1621 base is recorded with
Windows Installer cache provenance and an exact published catalog release URL.
Its project-owner-reported redistribution permission, different driver hashes,
protected inner Burn recipe, conditional whole-stack and both-endpoint admission,
and lack of physical validation remain explicit.

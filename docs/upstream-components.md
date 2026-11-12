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
reviewed exact Razer profiles whose Synapse manifests name the same file.
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

The 2026-11-12 review covers twenty-one OpenBlade models and all seven catalog
artifacts, with 147 model/artifact decisions. RZ09-0508, RZ09-0510 and RZ09-0509
name THX V3 resources, so the cataloged V4/legacy stacks remain unestablished for
them. RZ09-0529 names the exact V4 Native DLL, but its complete rznb11 codec
binding and installation recipe remain unestablished.

RZ09-0409 / PID 0276 and RZ09-0287 / PID 0234 declare separate driver
carriers at versions 0.1.1.0 and 0.1.2.0 respectively, plus BladeNative
1.0.10.1 and no THX resources. Their [product 630](../evidence/source-reviews/rz09-0409.json)
and [product 564](../evidence/source-reviews/rz09-0287.json) source pins retain
the reviewed manifest identities. All fourteen decisions are `NotEstablished`;
shared components do not establish complete driver or audio stack applicability.
No runtime, driver-installation or physical-validation authority is added.

The exact-model manifests for RZ09-0370, RZ09-0427, RZ09-0421 and RZ09-0423 name
their own PID-specific 0.1.2.0 driver carrier and the shared BladeNative 1.0.10.1
DLL, with no THX resource declarations. All seven existing artifacts remain
`NotEstablished` for these four models. Absent THX declarations do not prove
incompatibility; exact-codec bindings, tuning and complete installation recipes
remain unreviewed. No new runtime or driver-setup admission follows from this
review.

RZ09-0300, RZ09-0330 and RZ09-0351 also have separate exact-PID carriers
(0.1.0.0, 0.1.2.0 and 0.0.1.0 respectively), plus the same BladeNative DLL and
no THX resource declarations. Their installer manifests point to separate
model-specific resource manifests. All 21 decisions for these three models are
`NotEstablished`; no cataloged whole driver or audio stack, native THX artifact,
codec tuning or installation recipe has been established for them.

RZ09-0301 / PID 0245 has its own 0.1.0.0 driver carrier and BladeNative
1.0.10.1. Its [pinned product 581 manifest](../evidence/source-reviews/rz09-0301.json)
declares no THX resources. All seven existing artifacts remain `NotEstablished`
for this model; no complete cataloged driver or audio stack is admitted.

The 2026-10-19 review covered the original seven OpenBlade models. THX V4 Native 1.1.1.0
is named by the manifests for RZ09-0530, RZ09-0528 and RZ09-0581. The reviewed
manifests for RZ09-0328, RZ09-0482, RZ09-0483 and RZ09-0484 contain no THX native
client resource. Their manifest build and revision are recorded in the ledger.
The evidence does not establish a universal THX package.

Both cataloged driver stacks remain scoped to their own PID. Their DKM, virtual
consumer, keyboard and mouse INF targets name that PID. The RzCommon INF, CAT
and SYS hashes are identical in both stacks, and its INF matches the generic
`RAZER\DeviceContol` child. That shared dependency does not make either complete
stack universal or establish support for the other models.

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

## Installed driver APIs

Catalog versions, SHA-256 values and signer evidence identify exact artifacts
for download, export and installation. They do not whitelist installed driver
builds. Runtime API admission belongs to core: retain exact model and device
scope, verify actual package/service bindings and Windows trust, and validate the
typed interface. Compatible updates must not require a new OpenBlade release.
Observed hashes may invalidate cached runtime state. Changed API contracts still
require review; artifact hashes and installer verification remain exact.

## THX driver stacks

The [THX audio stack entries](thx-audio-stacks.md) describe exact rznb11 and
rznb12 packages, blocked legacy 2.6.5 component
candidates for the three 2023 THX models, and the Dolby-only RZ09-0328. The
legacy entry includes exact Realtek codec OEM tuning and model-specific THX SCU
SpeakerPath profiles. Its recovered signed OEM extension exactly matches the
three codec IDs and enumerates the normal THX components. It remains
unprovisionable because the complete endpoint CompositeFX chain and the safe
install, rescan and restart sequence are not established.
The rznb12 4.2.41.2499 installed reference still lacks a
matching base installer. A separate recovered 4.2.37.1621 base is recorded with
Windows Installer cache provenance and an exact published catalog release URL.
Its project-owner-reported redistribution permission, different driver hashes,
protected inner Burn recipe, conditional whole-stack and both-endpoint admission,
and lack of physical validation remain explicit.

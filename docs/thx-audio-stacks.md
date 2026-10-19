# THX audio stacks

The catalog records two modern THX driver families and separate legacy 2.6.5
evidence. OpenBlade must select by the exact Blade model and codec hardware ID.
Shared clients and generic software-component packages do not make a stack
universal.

| Model | Audio scope | Provisioning status |
| --- | --- | --- |
| RZ09-0581 | [rznb12 4.2.41.2499](../components/thx-rznb12/4.2.41.2499/stack.json) installed reference; [recovered rznb12 4.2.37.1621 candidate](../components/thx-rznb12/4.2.37.1621/stack.json); configuration 4.2.37.1846 | Source-backed fresh-install candidate with conditional whole-stack admission and both-endpoint read admission before runtime mutation; installation and physical behavior remain unvalidated. The 4.2.41.2499 reference is still blocked because it has no matching base installer. |
| RZ09-0528 | [rznb11 4.2.29.1159](../components/thx-rznb11/4.2.29.1159/stack.json), configuration 4.2.37.1845 | Source-backed fresh-install candidate; physical installation remains pending. |
| RZ09-0484 | [Legacy THX 2.6.5 evidence](../components/thx-legacy/2.6.5.0/stack.json) | Blocked: exact THX SCU tuning is established; THX component association and endpoint FX/APO binding remain unestablished. |
| RZ09-0483 | [Legacy THX 2.6.5 evidence](../components/thx-legacy/2.6.5.0/stack.json) | Blocked: exact THX SCU tuning is established; THX component association and endpoint FX/APO binding remain unestablished. |
| RZ09-0482 | [Legacy THX 2.6.5 evidence](../components/thx-legacy/2.6.5.0/stack.json) | Blocked: exact THX SCU tuning is established; THX component association and endpoint FX/APO binding remain unestablished. |
| RZ09-0530 | [rznb11 4.2.29.1159](../components/thx-rznb11/4.2.29.1159/stack.json), configuration 4.2.37.1845 | Source-backed fresh-install candidate; physical installation remains pending. |
| RZ09-0328 | Dolby Atmos in the [exact-model specification](https://mysupport.razer.com/app/answers/detail/a_id/3641/) | THX is not applicable. |

Each modern entry pins the artifact sizes, SHA-256 values and Authenticode
signer, all APO/extension/service package files, and the two immutable active
configuration files. It also links to the separately cataloged native DLL.
The direct-download artifacts remain on Razer's servers. The recovered rznb12
base installer is recorded as a planned catalog release asset; no binary bytes
are stored in this repository and the release has not been published.

A matching Realtek base audio driver must already be installed. The THX installer
does not contain it. Razer documents restoring audio through
[Windows Update or system recovery](https://mysupport.razer.com/app/answers/detail/a_id/3985).
The rznb11 installer must not be used for rznb12.

The legacy entry pins the exact RZ09-0482, RZ09-0483 and RZ09-0484 Realtek
codec IDs, base packages and `RTAIODAT.DAT` OEM profiles, plus four signed
Windows 11 THX 2.6.5 component CABs: service, HSA, configuration and APO. The
signed SCU contains the actual model selector and THX SpeakerPath tuning:
`2020` selects PI490 `profile-20230502`, `3006` selects SO690
`profile-20221107`, and `3007` selects KI890
`profile-20221122-PVT-red`. It uses the V2 schema and explicitly rejects the
generic fallback. What remains unestablished is creation or association of the
generic `SWC\VEN_THX` components and the endpoint FX/APO binding. These
packages remain component candidates, not a complete or installable stack.

The reviewed Realtek INFs have the ordinary `ks.inf`/`wdmaudio.inf`
`Include`/`Needs` dependencies, but no THX-specific `Include`/`Needs` rule. GUID
`E82A5EE8-44D2-44C1-897E-AA5AFBF146BA` appears in the RZ09-0482 AMD INF and is
absent from the RZ09-0483/RZ09-0484 Intel INF. It is neither the THX host APO
CLSID `68650828-CA0F-4196-9096-5F50931AF10A` nor the offload CLSID
`E6769B7D-B58F-45CA-B6F2-964B83EDCB76`; its exact role remains unresolved.

The vendor manifests were rechecked on 2026-10-19. The rznb11 base resource names
are `THXAPO0709-02C5` and `THXAPO0710-02C6`; both specify `/s /norestart`.
The two updater resources have no manifest installation arguments. Separate
static inspection of their signed entry paths establishes zero-argument execution:
properties first, then surround configuration. Both restart the THX service and
ignore its command result. A consuming installer must verify each output and
the running service independently.

The recovered rznb12 4.2.37.1621 base package came from a Windows Installer
cache through read-only static extraction. The original signed installer is
`THXAPO_rznb12_v4.2.37.1621-5117e8e-i2546a_MSHLKSIGN-2255eea3.3219a439.exe`
(53,720,208 bytes; SHA-256
`32392A63FC704DFC4BFBE4F33ED038773BBDE21AC88C61BAEEA013E3F98E8CF2`).
All nine payload members covered by its three driver catalogs were verified.
No public Razer download or Synapse manifest reference was established for the
base installer, so the descriptor uses empty base `manifestReferences` and
records the cache provenance explicitly. It retains the reviewed official
4.2.37.1846 updater and active-configuration pins from the current rznb12
descriptor. Its driver hashes differ from 4.2.41.2499, and it does not admit or
provision that separate installed reference.

The project owner reports that the existing written permission from Razer US
Ltd also covers this exact THX installer version as a public GitHub release
asset. That statement is recorded as owner-reported permission and has not been
independently checked against the authorization document. The planned asset is
bound to repository `OpenBladeProject/blade-driver-catalog`, tag
`thx-rznb12-4.2.37.1621`, and the original filename. Arbitrary repositories,
tags, filenames, or versions are not authorized by this entry.

Both modern base executables are managed carriers around signed inner Burn
bundles. The outer carriers must never be executed. A consuming installer must
verify the carrier, extract raw DEFLATE bytes from the fixed offset into a
protected component directory using create-new semantics, then verify the
inner length, SHA-256 and THX signer before running the inner bundle with only
`/quiet /norestart`:

| Family | Raw DEFLATE offset | Compressed bytes | Protected file | Inner bytes | Inner SHA-256 |
| --- | ---: | ---: | --- | ---: | --- |
| rznb11 | 569682 (`0x8B152`) | 50,445,093 | `thx-rznb11-base.exe` | 51,037,408 | `819B1504B025105589B5899CC09BB612B7AD83F8DED8DE0D087F81D4085542ED` |
| rznb12 4.2.37.1621 | 577088 (`0x8CE40`) | 52,553,413 | `thx-rznb12-base.exe` | 53,145,160 | `DE47E110A3E528249EAF59FA7932C1A568183A38F7B52246EE395A0418B14620` |

Both inner bundles have valid THX LTD. Authenticode signatures with thumbprint
`B23FAAE4D5ADEDA77BCCD9F12F32C92D3FF755D5`. These pins establish a protected
execution recipe, not successful installation or physical audio behavior.

The rznb11 installer can remove matching legacy 2.x/3.x THX drivers before its
support check, and does not propagate every per-INF failure. A success exit code
therefore cannot establish success. A consuming installer needs exact host and
codec checks, protected staging, hash/signature validation, a durable transaction
record, and independent package/catalog/configuration/service checks afterward.
Uncertain submission must stop the sequence without automatic replay.

These entries do not authorize replacing or repairing an existing THX stack.
Fresh-install admission requires a pristine THX state and the complete pinned
base/updater/configuration stack. The recovered rznb12 path additionally
requires successful reads of both Speakers and Headphones before any runtime
mutation. Fresh installation remains physically unvalidated. Mutable user
settings and presets are separate from the immutable configuration pins; an
updater's output hash does not prove preservation of those settings.

See the [core investigation](https://github.com/OpenBladeProject/openblade-core/blob/942c620e0c2b52be274e2ef99ea629ab1cb8dbb4/docs/thx-installation-investigation.md)
for the static inspection and [issue #808](https://github.com/OpenBladeProject/openblade-core/issues/808)
for the affected-user report. New models require an explicit review in
[the applicability ledger](../catalog/applicability.json), including models for
which applicability has not been established.

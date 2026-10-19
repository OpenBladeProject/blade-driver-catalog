# THX audio stacks

The catalog records two modern THX driver families and separate legacy 2.6.5
evidence. OpenBlade must select by the exact Blade model and codec hardware ID.
Shared clients and generic software-component packages do not make a stack
universal.

| Model | Audio scope | Provisioning status |
| --- | --- | --- |
| RZ09-0581 | [rznb12 4.2.41.2499](../components/thx-rznb12/4.2.41.2499/stack.json), configuration 4.2.37.1846 | Blocked: the reviewed manifest has no base APO installer. |
| RZ09-0528 | [rznb11 4.2.29.1159](../components/thx-rznb11/4.2.29.1159/stack.json), configuration 4.2.37.1845 | Source-backed fresh-install candidate; physical installation remains pending. |
| RZ09-0484 | [Legacy THX 2.6.5 evidence](../components/thx-legacy/2.6.5.0/stack.json) | Blocked: exact Realtek codec package found, but exact OEM child enumeration and model tuning are missing. |
| RZ09-0483 | [Legacy THX 2.6.5 evidence](../components/thx-legacy/2.6.5.0/stack.json) | Blocked: exact Realtek codec package found, but exact OEM child enumeration and model tuning are missing. |
| RZ09-0482 | [Legacy THX 2.6.5 evidence](../components/thx-legacy/2.6.5.0/stack.json) | Blocked: exact Realtek codec package found, but exact OEM child enumeration and model tuning are missing. |
| RZ09-0530 | [rznb11 4.2.29.1159](../components/thx-rznb11/4.2.29.1159/stack.json), configuration 4.2.37.1845 | Source-backed fresh-install candidate; physical installation remains pending. |
| RZ09-0328 | Dolby Atmos in the [exact-model specification](https://mysupport.razer.com/app/answers/detail/a_id/3641/) | THX is not applicable. |

Each modern entry pins the original download sizes, SHA-256 values and
Authenticode signer, all APO/extension/service package files, and the two
immutable active configuration files. It also links to the separately
cataloged native DLL.
The repository publishes metadata only; downloads remain on Razer's servers.

A matching Realtek base audio driver must already be installed. The THX installer
does not contain it. Razer documents restoring audio through
[Windows Update or system recovery](https://mysupport.razer.com/app/answers/detail/a_id/3985).
The rznb11 installer must not be used for rznb12.

The legacy entry pins the exact RZ09-0482, RZ09-0483 and RZ09-0484 Realtek
codec IDs and base packages, plus four signed Windows 11 THX 2.6.5 component
CABs: service, HSA, configuration and APO. Those THX packages expose only
generic `SWC\VEN_THX` IDs. Their configuration is
`generic-config-fallback-V2`; neither it nor the Realtek packages supplies the
missing exact OEM child-enumeration and model-tuning layer. They are component
candidates only, not a complete or installable stack.

The vendor manifests were rechecked on 2026-10-19. The rznb11 base resource names
are `THXAPO0709-02C5` and `THXAPO0710-02C6`; both specify `/s /norestart`.
The two updater resources have no manifest installation arguments. Separate
static inspection of their signed entry paths establishes zero-argument execution:
properties first, then surround configuration. Both restart the THX service and
ignore its command result. A consuming installer must verify each output and
the running service independently.

The rznb11 installer can remove matching legacy 2.x/3.x THX drivers before its
support check, and does not propagate every per-INF failure. A success exit code
therefore cannot establish success. A consuming installer needs exact host and
codec checks, protected staging, hash/signature validation, a durable transaction
record, and independent package/catalog/configuration/service checks afterward.
Uncertain submission must stop the sequence without automatic replay.

These entries do not authorize replacing or repairing an existing THX stack.
Fresh installation remains physically unvalidated. Mutable user settings and
presets are separate from the immutable configuration pins; an updater's output
hash does not prove preservation of those settings.

See the [core investigation](https://github.com/OpenBladeProject/openblade-core/blob/942c620e0c2b52be274e2ef99ea629ab1cb8dbb4/docs/thx-installation-investigation.md)
for the static inspection and [issue #808](https://github.com/OpenBladeProject/openblade-core/issues/808)
for the affected-user report. New models require an explicit review in
[the applicability ledger](../catalog/applicability.json), including models for
which applicability has not been established.

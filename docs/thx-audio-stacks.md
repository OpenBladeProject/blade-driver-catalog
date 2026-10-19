# THX audio stacks

The catalog records two separate THX driver families. OpenBlade must select the
stack by the exact Blade model and codec hardware ID, then verify the complete
installed stack. The shared native client does not make these drivers universal.

| Models | Stack | Vendor download coverage |
| --- | --- | --- |
| RZ09-0528, RZ09-0530 | [rznb11 4.2.29.1159](../components/thx-rznb11/4.2.29.1159/stack.json), configuration 4.2.37.1845 | Base APO installer and both configuration updaters are available directly from Razer. Fresh installation is a source-backed experimental candidate. |
| RZ09-0581 | [rznb12 4.2.41.2499](../components/thx-rznb12/4.2.41.2499/stack.json), configuration 4.2.37.1846 | The reviewed manifest supplies configuration updaters, but no base APO installer. Complete provisioning is unavailable. |

Each entry pins the original download sizes, SHA-256 values and Authenticode
signer, all APO/extension/service package files, and the two immutable active
configuration files. It also links to the separately cataloged native DLL.
The repository publishes metadata only; downloads remain on Razer's servers.

A matching Realtek base audio driver must already be installed. The THX installer
does not contain it. Razer documents restoring audio through
[Windows Update or system recovery](https://mysupport.razer.com/app/answers/detail/a_id/3985).
The rznb11 installer must not be used for rznb12.

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

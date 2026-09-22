# Blade driver catalog

This repository records original signed Razer driver packages for exact Blade
models and hardware identities. It contains package metadata, hashes, signature
results, evidence templates, and read-only export instructions.

OpenBlade does not author, modify, or re-sign these drivers. This is an
independent project and is not an official Razer repository.

## Install the brightness driver

The cataloged driver enables the native Windows brightness flyout in OpenBlade
on the Razer Blade 16 RZ09-0581 (`1532:02E0`). OpenBlade's installer does not
install it.

- To install through Razer, install and run [Razer Synapse](https://www.razer.com/synapse-4)
  once on the laptop so it can install the driver stack.
- To install the standalone ZIP, follow the [installation guide](docs/installing.md).
  It covers downloading, verifying, installing, checking the result, and rollback.
  This manual route is still a clean-install validation procedure.

After installation, restart OpenBlade and check **About > Device information**.
The Razer brightness driver row should show **Available · Windows OSD**.
Brightness keys still work through OpenBlade's own flyout when the driver is
unavailable.

## Current catalog

| Device | Hardware identity | Driver versions | Status |
|---|---|---|---|
| Razer Blade 16 RZ09-0581 | `1532:02E0` | RzDev `1.0.0.78`, RzCommon `1.0.0.76` | [Private-repository package prerelease](https://github.com/OSSBlade/blade-driver-catalog/releases/tag/rz09-0581-1532-02e0-driver-stack-1.0.0.78-1.0.0.76); clean installation remains pending |

Microsoft Windows SDK SignTool verified all five catalog signatures and all ten
INF and SYS catalog memberships under kernel-mode policy.

The `02E0` package covers only the listed RZ09-0581 hardware. It does not cover
RZ09-0528 (`02C6`) or Razer accessories. Each device needs its own package
inventory and validation.

## Use the catalog

- [docs/exporting.md](docs/exporting.md) explains the read-only
  collection workflow and how to prepare a commit-safe catalog entry.
- [Release assets and repository boundaries](docs/release-assets.md) explains
  what belongs in Git, how release archives are controlled, and how this
  catalog relates to other OpenBlade repositories.
- [The evidence template](templates/driver-stack-evidence.template.json) lists
  the facts required for a new device entry.

A catalog entry records evidence from one machine. It does not prove that a
package works on another model, is safe to install on a clean machine, or
provides a particular runtime feature. OpenBlade core reviews those claims
separately before enabling a driver path.

## License

Repository-authored documentation, metadata, templates, tests, and tooling are
licensed under the [Apache License 2.0](LICENSE). See [NOTICE](NOTICE) for the
scope statement.

Razer ZIP, INF, CAT, SYS, and other proprietary release assets are excluded from
Apache-2.0. They remain governed by Razer's rights and the separately recorded
redistribution permission described in
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

## Validate changes

Run the offline checks with Windows PowerShell 5.1:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File .\tests\Run-All.ps1
```

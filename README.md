# Blade driver catalog

This repository catalogs original signed Razer driver packages by exact Blade
model and hardware identity. It provides read-only export instructions,
commit-safe evidence templates, hashes, signatures, and device-to-package
relationships.

It is not an official Razer repository. OpenBlade does not author, modify, or
re-sign the cataloged drivers.

## Repository boundary

Git contains metadata and tooling only. INF, CAT, SYS, PNF, ZIP, and other
proprietary package files are ignored and must not be committed.

See [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) before publishing an
archive.

A separately built, package-only driver archive can be attached to a release
after its model-specific exporter and manifest are reviewed. Never publish the
private collection archive because it also contains full device identities and
local inventory. The release must identify the matching catalog manifest by
path and SHA-256. Written redistribution authorization must cover the exact
files and delivery method.
The repository license, once selected, will apply only to original repository
content and will not replace Razer's rights in its files.

OpenBlade repositories have separate responsibilities:

- [`openblade-core`](https://github.com/OSSBlade/openblade-core) owns runtime
  admission, exact-device checks, fallback behavior, and validated installation
  policy.
- [`openblade-captures`](https://github.com/OSSBlade/openblade-captures) owns
  protocol captures and hardware behavior evidence.
- This repository owns driver package inventory, export instructions, sanitized
  manifests, and any permission-governed release assets.

## Current catalog

| Device | Hardware identity | Driver versions | Status |
|---|---|---|---|
| Razer Blade 16 RZ09-0581 | `1532:02E0` | RzDev `1.0.0.78`, RzCommon `1.0.0.76` | [Authorized package prerelease](https://github.com/OSSBlade/blade-driver-catalog/releases/tag/rz09-0581-1532-02e0-driver-stack-1.0.0.78-1.0.0.76); clean installation remains pending |

The `02E0` package does not cover RZ09-0528 (`02C6`) or Razer accessories.
Those devices need their own installed-package inventory and validation.

## Contributing an installed package

Start with [docs/exporting.md](docs/exporting.md). It explains how to:

1. record a private device and Driver Store inventory;
2. select only packages proved by that device graph;
3. export complete packages with Windows PnPUtil;
4. verify hashes, signatures, and catalog membership;
5. create a private archive; and
6. submit a sanitized manifest without proprietary bytes or local identifiers.

Copy [the evidence template](templates/driver-stack-evidence.template.json) for
the new device. A reviewer must confirm the package topology before any runtime
or installation claim moves to OpenBlade core.

## Validation

Run the offline repository checks with Windows PowerShell 5.1:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File .\tests\Run-All.ps1
```

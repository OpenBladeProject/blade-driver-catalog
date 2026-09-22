# Blade driver catalog

Find original signed Razer driver packages and installation instructions for
Razer Blade laptops. The catalog records each package's hardware matches,
versions, file hashes, and signature checks. Contributors can also use it to
document drivers installed on other Blade models.

This is an independent OpenBlade project. OpenBlade does not author, modify,
or re-sign Razer drivers.

## Find and install a driver

Choose your laptop from the catalog below, then follow its installation guide.
Each guide explains where to download the package, how to check it, how to
install it, and how to recover if installation fails. Packages apply only to
the hardware listed in their entry; check the guide's validation status before
installing.

| Laptop | Package | Installation |
| --- | --- | --- |
| Razer Blade 16 RZ09-0581 | Razer driver stack for native Windows brightness controls | [Installation guide](docs/installing.md) |

## Add a device

Follow [docs/exporting.md](docs/exporting.md) to collect an installed package
and prepare a catalog entry. Start with the
[evidence template](templates/driver-stack-evidence.template.json), and submit
reviewed metadata without driver files or private machine details.

A new entry records what was found on that device. Installation testing and
OpenBlade feature support are reviewed separately. See
[release assets and repository boundaries](docs/release-assets.md) for
publication requirements and the relationship to other OpenBlade repositories.

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

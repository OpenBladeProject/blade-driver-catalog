# Blade driver catalog

Find the Razer driver package for your Blade model. Each catalog entry shows
which device it came from and how to check the files.

OpenBlade is independent of Razer. We keep the original signed driver files
intact.

## Blade models

Match the model number on your laptop.

| Model | Driver details | Download |
| --- | --- | --- |
| Blade 16 (2026), RZ09-0581 | [Razer 02E0 driver stack](devices/rz09-0581/1532-02e0/1.0.0.78-1.0.0.76/manifest.json) | [Prerelease download](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0581-1532-02e0-driver-stack-1.0.0.78-1.0.0.76) |
| Blade 16 (2025), RZ09-0528 | [Razer 02C6 driver stack](devices/rz09-0528/1532-02c6/1.0.0.78-1.0.0.76/manifest.json) | [Prerelease download](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0528-1532-02c6-driver-stack-1.0.0.78-1.0.0.76) |

For the 2026 model, follow the [installation guide](docs/installing.md).

## Add your Blade

Missing a model? [docs/exporting.md](docs/exporting.md) shows how to collect its
installed driver packages. Use the
[evidence template](templates/driver-stack-evidence.template.json) to submit
the model and file details. Keep the driver files and personal device details
out of the submission.

See [release assets and repository boundaries](docs/release-assets.md) for how
we make driver downloads available.

## License

The text and tools in this repository use the
[Apache License 2.0](LICENSE). The Razer driver files belong to Razer. See
[NOTICE](NOTICE) and [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) for details.

## Run the checks

On Windows, run:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File .\tests\Run-All.ps1
```

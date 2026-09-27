# Install Razer drivers for your Blade

Start by checking your model number. The Razer driver packages for these Blade
16 models are different and must stay with their matching laptops.

| Blade model | Built-in Razer device | Driver download |
| --- | --- | --- |
| 2026, RZ09-0581 | `1532:02E0` | [2026 driver prerelease](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0581-1532-02e0-driver-stack-1.0.0.78-1.0.0.76) |
| 2025, RZ09-0528 | `1532:02C6` | [2025 driver prerelease](https://github.com/OpenBladeProject/blade-driver-catalog/releases/tag/rz09-0528-1532-02c6-driver-stack-1.0.0.78-1.0.0.76) |

You can check the model reported by Windows in PowerShell:

```powershell
(Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS').SystemProductName
```

If the model number does not match a row above, do not use either download.

## Install through Razer Synapse

Install [Razer Synapse](https://www.razer.com/synapse-4) on the Blade and run it
once. Synapse installs the Razer driver stack for the connected laptop. Razer's
[installation instructions](https://mysupport.razer.com/app/answers/detail/a_id/1834/)
cover the setup. Exit Synapse before restarting OpenBlade.

The OpenBlade installer does not install or remove Razer drivers. When the
driver is unavailable, OpenBlade uses its WMI brightness path and its own
flyout.

## Use a catalog download

Choose the ZIP from the release that matches your model. The source-code ZIP
on GitHub is not the driver package. The release's
[record for 2026](../releases/rz09-0581-02e0-1.0.0.78-1.0.0.76.json) or
[record for 2025](../releases/rz09-0528-02c6-1.0.0.78-1.0.0.76.json) gives
the expected filename and SHA-256 hash. Check the downloaded ZIP against that
hash before extracting it.

```powershell
Get-FileHash -LiteralPath 'path-to-the-driver-zip' -Algorithm SHA256
```

For the 2026 model, follow the
[standalone package procedure](installing-rz09-0581.md) after checking the
laptop and archive. The 2025 catalog has no validated standalone installation
procedure yet; use Synapse for that model.

## Check the result

After installation, check Device Manager for problems with the built-in Razer
device, then restart OpenBlade and test the brightness keys. On the 2026 model,
OpenBlade's About > Device information should show the Razer brightness driver
as `Available · Windows OSD`, and the keys should use the Windows brightness
flyout.

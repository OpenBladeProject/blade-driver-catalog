# Install the Razer brightness driver

This guide is for the Blade 16 RZ09-0581 (`1532:02E0`) package listed in the
[README](../README.md). It enables OpenBlade to use the Windows brightness
flyout. The OpenBlade installer does not install or remove Razer drivers.
When the driver is unavailable, brightness keys use WMI and the OpenBlade
flyout.

## Package details

| Hardware identity | Driver versions |
| --- | --- |
| `1532:02E0` | RzDev `1.0.0.78`, RzCommon `1.0.0.76` |

Microsoft Windows SDK SignTool verified all five catalog signatures and all ten
INF and SYS catalog memberships under kernel-mode policy. Clean installation
of the standalone package remains pending. The package does not cover
RZ09-0528 (`02C6`) or Razer accessories.

## Install through Synapse

Install [Razer Synapse](https://www.razer.com/synapse-4) and run it once on the
laptop to install its driver stack. Razer provides [Synapse installation
instructions](https://mysupport.razer.com/app/answers/detail/a_id/1834/).
Afterward, exit Synapse before restarting OpenBlade, or follow the
[Synapse Blade Blocker setup](https://github.com/OpenBladeProject/synapse-blade-blocker)
if you want to keep Synapse running for your other devices. Check the driver
status as described under [Check the result](#5-check-the-result).

## 1. Download the standalone package

Open the [driver prerelease](https://github.com/OSSBlade/blade-driver-catalog/releases/tag/rz09-0581-1532-02e0-driver-stack-1.0.0.78-1.0.0.76)
and download `Razer-02E0-Driver-Stack-1.0.0.78-1.0.0.76.zip` from its assets.
The source-code ZIP is not the driver package.

Use the [release record](../releases/rz09-0581-02e0-1.0.0.78-1.0.0.76.json)
for the expected archive name and SHA-256, and the
[catalog manifest](../devices/rz09-0581/1532-02e0/1.0.0.78-1.0.0.76/manifest.json)
for package identities. Extract the verified ZIP into a new folder. Use that
folder for `$packageRoot` below; it must contain the five package subfolders.
Do not use this package on RZ09-0528 or another model.

Windows includes PnPUtil for staging signed packages in Driver Store and
installing them on matching devices. Microsoft documents `/add-driver`,
`/install`, `/subdirs`, and `/reboot` in the
[PnPUtil command reference](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax).

Clean installation of this standalone package is still awaiting validation.
Use the procedure below only on a recoverable RZ09-0581. The stack filters the
integrated keyboard and mouse paths, restarts parts of the USB device tree, and may require
a reboot. Use AC power, keep an external USB keyboard and mouse connected, and
make sure recovery access works before testing it.

## 2. Verify the laptop and package

Open PowerShell as administrator and complete these checks before installing:

1. `HKLM:\HARDWARE\DESCRIPTION\System\BIOS` must report Razer as the
   manufacturer and `Blade 16 - RZ09-0581` as `SystemProductName`.
2. Windows must report one connected `USB\VID_1532&PID_02E0&MI_01` device and
   one connected `USB\VID_1532&PID_02E0&MI_02` device. Stop on missing,
   duplicate, or different identities.
3. The ZIP name and SHA-256 must match the checked release attestation. The
   same attestation must identify the catalog manifest by repository path and
   SHA-256.
   After extraction, every file must match `SHA256SUMS.txt`, and every INF,
   CAT, and SYS signature must be valid and issued by Microsoft Windows
   Hardware Compatibility Publisher. On a validation host with SignTool, use
   `signtool verify /kp /c <catalog> <INF-or-SYS>` to prove catalog membership.
   Microsoft documents `/c` in the
   [SignTool reference](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/signtool).

## 3. Record the current drivers

Create a journal outside the package and repository before staging anything.
Record the BIOS identity, connected matching instances, the output of
`pnputil /enum-drivers /files`, their current bindings and stacks, and the
current `RZVIRTUAL` and `RZCONTROL` tree. Keep the original output, not a
hand-written summary.

The helper below appends every PnPUtil command, output, and exit code to the
journal. Set `$packageRoot` and `$journalDirectory` first. Stop after any
nonzero exit code. Do not retry an ambiguous result.

```powershell
$packageRoot = Read-Host 'Full path to the extracted driver package'
$journalDirectory = Read-Host 'Full path to a new journal folder outside the package and repository'
$pnp = "$env:WINDIR\System32\pnputil.exe"
$transcript = Join-Path $journalDirectory 'pnputil-transcript.txt'
New-Item -ItemType Directory -Path $journalDirectory -ErrorAction Stop | Out-Null

function Invoke-PnpLogged {
    param([Parameter(Mandatory)][string[]]$Arguments)

    "`r`n> pnputil $($Arguments -join ' ')" |
        Out-File -LiteralPath $transcript -Append -Encoding utf8
    & $pnp @Arguments 2>&1 |
        Tee-Object -FilePath $transcript -Append
    $exitCode = $LASTEXITCODE
    "Exit code: $exitCode" |
        Out-File -LiteralPath $transcript -Append -Encoding utf8
    if ($exitCode -ne 0) {
        throw "PnPUtil failed with exit code $exitCode."
    }
}
```

## 4. Stage and install the packages

First stage all five signed packages without binding them:

```powershell
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_vcon\rzdevu_02e0_vcon.inf")
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzcommonu\rzcommonu.inf")
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_dkm\rzdevu_02e0_dkm.inf")
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_kbd\rzdevu_02e0_kbd.inf")
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_mou\rzdevu_02e0_mou.inf")
```

After each command, copy the newly reported published name and package identity
into the journal. Mark whether it existed in the pre-install inventory. This is
the ownership proof used by rollback.

After all five packages stage successfully, bind them in dependency order:

```powershell
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_dkm\rzdevu_02e0_dkm.inf", '/install')
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_vcon\rzdevu_02e0_vcon.inf", '/install')
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_kbd\rzdevu_02e0_kbd.inf", '/install')
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzdevu_02e0_mou\rzdevu_02e0_mou.inf", '/install')
Invoke-PnpLogged @('/add-driver', "$packageRoot\rzcommonu\rzcommonu.inf", '/install')
```

Do not add `/reboot` to these commands during validation. If Windows requests a
restart, stop for a deliberate reboot after the journal is safely stored.
PnPUtil does not force a lower-ranked driver onto a device, so a zero exit code
does not replace post-install inspection.

## 5. Check the result

After installation, verify the exact `RZVIRTUAL` and `RZCONTROL` children,
their services and stacks, and the absence of Device Manager problems. Restart
OpenBlade and check About > Device information. The Razer brightness driver row
should read `Available · Windows OSD`. A physical brightness press, hold, and
release must change brightness and use the Windows flyout.

## Roll back a validation attempt

Do not use broad device removal, `/force`, or class-wide restart commands. A
rollback may remove only published packages that a durable pre-install journal
proves were introduced by that test. Remove those packages in this order:
RzCommon, VCon, mouse, keyboard, then DKM. Use
`pnputil /delete-driver <journal-owned-oem.inf> /uninstall` and stop if Windows
reports that a package is in use or a reboot is required.


## Technical reference

This procedure follows OpenBlade's [Razer brightness driver guide](https://github.com/OpenBladeProject/openblade-core/blob/main/docs/razer-brightness-driver-package.md#native-windows-installation-path).
That guide also records the checks required before publishing a one-click
installer. See [release assets](release-assets.md) for distribution rules.

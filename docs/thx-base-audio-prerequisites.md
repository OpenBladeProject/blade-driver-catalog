# THX base-audio prerequisites

This page records signed base-audio evidence for the three modern THX models.
The metadata is `SourceVerified`, installation is `InstallationUnvalidated`,
and prerequisite provisioning is not implemented. The complete machine-readable
pins are in [`prerequisites.json`](../evidence/thx-base-audio/prerequisites.json).

## RZ09-0581: Intel SST E328 and SoundWire SDCA

The official Microsoft Update Catalog package uses `IntcAudioBus.inf` as its
PCI root. That INF uses `CopyINF` to stage nine related Intel packages. Staging
those packages is not a request to install every generic INF with a wildcard;
Windows PnP binds only matching devices. A future recipe must stage the one
pinned root package and let its declared `CopyINF` closure be imported.

The reviewed CAB contains all files declared by the root and the nine staged
packages. All ten catalogs have valid Microsoft Windows Hardware Compatibility
Publisher signatures, and all 65 unique INF/payload membership checks passed.
The packages depend on Windows inbox `wdmaudio.inf`, `ks.inf`, and `WUDFRD.inf`.

The active exact-model chain is:

1. `PCI\VEN_8086&DEV_E328&SUBSYS_30101A58&REV_00` — `IntcAudioBus.inf`.
2. `INTELAUDIO\DSP_CTLR_DEV_E328&VEN_8086&DEV_0222&SUBSYS_30101A58&REV_0000` — `IntcOED.inf`.
3. `INTELAUDIO\SDW_CTLR_DEV_E328&VEN_8086&DEV_0333&SUBSYS_30101A58` — `IntcSdwBus.inf`.

The three active INF files are byte-identical to version `20.43.12634.0` in the
pinned official CAB. The Catalog entry itself lists generic E328 controller IDs;
it does not name `SUBSYS_30101A58` or RZ09-0581. Any future admission therefore
needs both the exact RZ09-0581 host gate and the exact controller chain above.

The codec side is Windows inbox SoundWire SDCA (`sdcaclass.inf`, `sdcamfd.inf`,
`sdcaaggregator.inf`, and `sdcahid.inf`). These packages are OS prerequisites,
not files supplied by the Intel CAB. Their presence and compatible Windows
version must be checked rather than copying or redistributing them.

## RZ09-0528 and RZ09-0530: Realtek HDA

Both models use the same official Catalog CAB and the exact
`HDXACPRazer.inf` package at version `6.0.9906.1`:

| Model | Exact codec hardware ID |
| --- | --- |
| RZ09-0528 | `HDAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A58300E` |
| RZ09-0530 | `HDAUDIO\FUNC_01&VEN_10EC&DEV_0298&SUBSYS_1A582023` |

The complete exact-model closure has five pinned files:
`HDXACPRazer.inf`, `hdxrt.cat`, `RTKVHD64.sys`, `RTAIODAT.DAT`, and
`RtEventLog.dll`. The catalog signature is valid and all four non-catalog files
passed catalog-membership verification. The only external dependencies are the
Windows inbox `ks.inf` and `wdmaudio.inf` registration sections.

## Boundary

No reviewed INF references Synapse or Razer App Engine. This evidence proves
source completeness and signatures. It does not prove clean-install ordering,
reboot behavior, runtime audio behavior, redistribution rights, or rollback.
OpenBlade does not currently provision these prerequisites.

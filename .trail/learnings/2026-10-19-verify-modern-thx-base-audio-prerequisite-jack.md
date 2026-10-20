---
title: verify modern THX base audio prerequisite closures
author: Jack
date: 2026-10-19
branch: feat/thx-audio-stacks
touches:
  - docs/ru-RU/thx-audio-stacks.md
  - docs/thx-audio-stacks.md
  - docs/zh-CN/thx-audio-stacks.md
  - docs/thx-base-audio-prerequisites.md
  - evidence/thx-base-audio/prerequisites.json
  - schemas/thx-base-audio-prerequisites.schema.json
  - tests/ThxBaseAudioPrerequisites.Tests.ps1
---

## Decided
Modern THX prerequisites have official Microsoft Catalog sources independent of Synapse. RZ09-0528 and RZ09-0530 share the exact HDXACPRazer.inf 6.0.9906.1 five-file closure with distinct HDAUDIO subsystem IDs. RZ09-0581 uses Windows inbox SDCA over Intel SST E328 20.43.12634.0. The Intel root IntcAudioBus.inf stages nine CopyINF packages; all ten original Microsoft WHCP catalogs and 65 INF/payload memberships passed kernel-policy verification. Complete metadata is evidence/thx-base-audio/prerequisites.json.

## Tried and ruled out
Do not call the 0581 foundation a Realtek HDA package. The Intel Catalog listing is generic E328; exact-model evidence comes separately from the observed SUBSYS_30101A58 ancestry and active INF bytes matching the official CAB. Do not install every INF in the CAB: four unrelated packages are excluded from the root CopyINF closure. Source verification does not establish clean-install order, reboot behavior, runtime audio, rollback or redistribution rights. No binaries are hosted by this metadata change.

## Watch out
Keep Windows inbox SDCA and wdmaudio/ks/WUDFRD as checked OS prerequisites, not redistributed files. Microsoft documents that CopyINF recursively imports the complete dependency packages during root import; extra preliminary staging writes need a concrete reason. A future root-only PnPUtil recipe needs independent actual bound-driver and child/ancestry readback, durable intent and stop-on-ambiguity recovery. Preserve/refuse unreviewed installed base drivers instead of forcing a downgrade. Provisioning remains unimplemented in this source-evidence revision. Catalog tests must run on documented Windows PowerShell 5.1; Test-Json is only an additive PowerShell 7 check.

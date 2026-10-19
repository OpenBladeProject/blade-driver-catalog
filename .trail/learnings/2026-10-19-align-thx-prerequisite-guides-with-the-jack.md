---
title: align THX prerequisite guides with the implemented draft candidate
author: Jack
date: 2026-10-19
branch: feat/thx-audio-stacks
touches:
  - docs/ru-RU/thx-audio-stacks.md
  - docs/thx-audio-stacks.md
  - docs/zh-CN/thx-audio-stacks.md
---

## Decided

Describe the implemented THX base-audio candidate consistently in the English, Chinese and Russian stack guides. Draft core PR819 can provision the reviewed Realtek or Intel packages for the three modern models after exact-model/package checks; Windows inbox SDCA remains an independently trusted OS prerequisite. Candidate implementation is separate from merged/shipped support and from clean-install validation with Synapse absent.

## Tried and ruled out

The stack overview still said the current recipe did not install base prerequisites even after prerequisites.json recorded provisioningImplemented=true and the detailed base-audio guide described the candidate. Corrected only that stale guidance, retained the existing implementation source pin, and linked the core investigation at immutable4bf8bbce. All catalog contracts pass. Independent Chinese/Russian review clarified Synapse not installed, post-reboot behavior and actual audio output without claiming success.

## Watch out

Keep modern source implementation, physical validation and legacy binding status separate in every locale. RZ09-0482/0483/0484 still have no admitted complete endpoint FX binding/install recipe; RZ09-0328 uses Dolby Atmos. A common native DLL or shared INF dependency does not make full driver stacks universal. The core coverage fixture compares every supported model and every artifact review; new models require vendor review and a refreshed ledger, not blanket applicability. Documentation-only corrections do not change package metadata, hashes or runtime pins.

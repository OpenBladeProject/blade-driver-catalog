---
title: bound base audio installation to every actual root INF match
author: Jack
date: 2026-10-19
branch: feat/thx-audio-stacks
touches:
  - docs/thx-base-audio-prerequisites.md
  - evidence/thx-base-audio/prerequisites.json
  - schemas/thx-base-audio-prerequisites.schema.json
  - tests/ThxBaseAudioPrerequisites.Tests.ps1
---

## Decided
The full root INF match lists are wider than the three models selected for THX provisioning. The signed Intel root lists six PCI matches across E328, E428 and 4D28; the Realtek root lists eleven HDAUDIO subsystem matches. Keep complete rootHardwareIds in prerequisite metadata so an installer can refuse an incidental matching target before PnPUtil /install. Root match scope and admitted model scope are separate contracts.

## Tried and ruled out
Checking only the selected model's hardware ID does not prove that a root /install cannot affect another present matching device. Conversely, rejecting every Realtek codec or Intel controller is excessive: refuse only another match from the exact reviewed root INF, while requiring the selected model's exact target and ancestry. The earlier inference that the Realtek root contained only two IDs was wrong; both modern IDs are included among eleven.

## Watch out
An SDCA HID sibling was observed but is not an extra audio requirement. Check class/MFD/aggregator inbox roles and their Windows trust; keep observed Windows versions as provenance rather than inventing a version floor. The base prerequisite source evidence remains installation-unvalidated. Future package revisions must re-extract the full INF match set, not just change a CAB hash.

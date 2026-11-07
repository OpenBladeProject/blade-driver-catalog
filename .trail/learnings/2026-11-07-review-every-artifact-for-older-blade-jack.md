---
title: Review every artifact for older Blade model additions
author: Jack
date: 2026-11-07
branch: docs/source-reviewed-model-applicability
touches:
  - catalog/applicability.json
  - tests/RepositoryContracts.Tests.ps1
---

## Decided
The 2019 Base RZ09-0300/0246, 2020 Advanced RZ09-0330/0253 and Late 2020 Base RZ09-0351/0268 require separate reviews against every discovered driver and component entry. The catalog now has 18 models and seven artifacts, with 126 explicit decisions. Pin the immutable core model catalog before refreshing its offline fixture.

## Tried and ruled out
Exact vendor manifests declare different PID-specific driver carriers and shared BladeNative files. Neither shared dependencies nor the presence of generic THX warning UI establishes applicability of an entire existing driver or audio stack. No new Applicable decision or runtime/setup authority follows from the model expansion.

## Watch out
Keep exact artifact versions and hashes as artifact provenance; do not turn them into installed-driver build allowlists. Windows PowerShell treats variable names case-insensitively: use usbProductId, never pid, because PID is a read-only system variable. Preserve existing per-model and per-variant package boundaries.

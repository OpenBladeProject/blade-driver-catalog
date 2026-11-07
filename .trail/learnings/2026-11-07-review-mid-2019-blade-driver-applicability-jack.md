---
title: Review Mid 2019 Blade driver applicability without inheriting stacks
author: Jack
date: 2026-11-07
branch: docs/rz0301-driver-applicability
touches:
  - catalog/applicability.json
  - docs/ru-RU/upstream-components.md
  - docs/upstream-components.md
  - docs/zh-CN/upstream-components.md
  - tests/RepositoryContracts.Tests.ps1
  - tests/fixtures/core-model-catalog.json
  - evidence/source-reviews/rz09-0301.json
---

## Decided
Review RZ09-0301 / PID 0245 against all seven catalog artifacts using Synapse product 581 middleware manifest build 2609301519, revision 3b9a4c059c4b6c9770715f0df2eef07d472cc53c, SHA-256 7F400EF690A7169B0F56A07D6E0EBD016616070096036C9E7EE653F994189203. It declares a separate PID0245Drv 0.1.0.0 carrier and shared BladeNative 1.0.10.1 only. All seven applicability decisions remain NotEstablished. Pin the immutable core model metadata and refresh both offline coverage fixtures; the catalog now has 19 models and 133 decisions.

## Tried and ruled out
A shared native DLL or driver dependency does not establish a complete model-specific driver stack, THX client, APO/service, codec tuning, endpoint binding or installation recipe. No driver download or installation was performed. Do not infer another model from product 581's stale copied support/guide navigation.

## Watch out
Artifact hashes and exact versions are provenance for acquisitions and reviewed recipes, not runtime installed-driver allowlists. The added catalog profile grants no native API, hardware write, installation or physical-validation authority. Trail check may match generic driver/support words from old learnings; the actual review expands coverage with NotEstablished decisions and preserves existing applicability boundaries.

---
title: Bind applicability coverage to an independent offline core snapshot
author: Jack
date: 2026-11-07
branch: docs/source-reviewed-model-applicability
touches:
  - tests/Applicability.Tests.ps1
  - tests/fixtures/core-model-catalog.json
---

## Decided
Catalog coverage must equal the complete model set derived from the independently captured immutable core metadata source, not merely the models the ledger lists. Store exact source bytes and source commit/path, SHA256 and Git blob identity in a data-only JSON fixture; compare both fixture and ledger identities against the decoded source. Keep Run-All offline.

## Tried and ruled out
Internal per-artifact completeness alone accepted deleting a model and all matching review rows, or adding a foreign model with complete rows. The separate core coverage test remains valuable but cannot alone protect a catalog-only change. Do not compile or execute captured source metadata, fetch dependencies during tests, or weaken decoding when upstream source shape changes.

## Watch out
Capture Git blob bytes rather than a CRLF-normalized working file. Refresh the immutable source pin and fixture during every new-model review, review all artifacts, and refresh the separate core coverage fixture. This snapshot protects the reviewed revision; it does not discover later upstream models automatically.

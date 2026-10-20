---
title: Separate catalog artifact hashes from installed driver API compatibility
author: Jack
date: 2026-10-20
branch: feat/thx-audio-stacks
touches:
  - AGENTS.md
  - docs/ru-RU/thx-audio-stacks.md
  - docs/thx-audio-stacks.md
  - docs/upstream-components.md
  - docs/zh-CN/thx-audio-stacks.md
---

## Decided
The maintainer requires compatible installed drivers reached through stable APIs to work without per-build hash allowlists or a new OpenBlade release. Catalog AGENTS.md now distinguishes exact artifact identities from runtime API admission. Core verifies exact model/device/package/service binding, Windows catalog trust and publisher, membership and the typed interface.

## Tried and ruled out
Do not remove catalog SHA-256 values, exact package versions or source/signer evidence: these identify the downloadable/exported installation recipe. Do not make packages universal or widen model applicability. Do not add catalog entries only to whitelist each independently installed driver update.

## Watch out
Observed runtime content fingerprints may invalidate stale reads and registrations; they are not a release-maintained whitelist. Actual API/ABI contract changes still need review. Installation candidates and their original physical-validation gaps remain unchanged, including the missing legacy endpoint effects binding.

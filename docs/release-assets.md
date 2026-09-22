# Release assets and repository boundaries

## What belongs in Git

Git contains metadata and tooling only. INF, CAT, SYS, PNF, ZIP, and other
proprietary package files are ignored and must not be committed. Full device
identities and local inventory also stay outside the repository.

The private evidence archive created during collection must never become a
release asset. It contains full device identities, local inventory, and other
machine-specific evidence. See [the export guide](exporting.md) for the private
collection workflow and the fields allowed in a sanitized manifest.

## Publishing a package archive

Read [THIRD-PARTY-NOTICES.md](../THIRD-PARTY-NOTICES.md) before publishing an
archive. Written authorization must cover the exact files, versions, audience,
and delivery method.

A package-only archive may be attached to a release only after review of its
model-specific exporter and catalog manifest. The exporter must copy only the
admitted files, verify their fixed hashes and signer identities, remove private
inventory and machine-local aliases, and include the required third-party
notice.

The project owner reports written permission from Razer US Ltd for the files,
audience, and delivery method in the current prerelease. The catalog does not
claim an independent review of that permission document. Apache-2.0 applies
only to original repository content and grants no rights to Razer package bytes
or proprietary release assets.

## Current prerelease record

The [checked release record](../releases/rz09-0581-02e0-1.0.0.78-1.0.0.76.json)
binds the catalog manifest path and SHA-256 to the release asset name and
SHA-256. It also records the exporter by pull request, commit, path, and script
hash.

Any change to the release audience requires a separate distribution decision
within the recorded authorization.

The checked record still labels the exporter `UnmergedPullRequest`, but
[OpenBlade core PR #163](https://github.com/OpenBladeProject/openblade-core/pull/163)
merged on August 15, 2026. The record needs a separate data update to point to a
commit reachable from `main`.

## OpenBlade repository responsibilities

- [`openblade-core`](https://github.com/OSSBlade/openblade-core) owns runtime
  admission, exact-device checks, fallback behavior, and validated installation
  policy.
- [`openblade-captures`](https://github.com/OSSBlade/openblade-captures) owns
  protocol captures and hardware behavior evidence.
- This repository owns driver package inventory, read-only export instructions,
  sanitized manifests, and release assets covered by recorded permission.

A reviewer must confirm package topology before OpenBlade core accepts a
runtime or installation claim. Physical validation, driver-host recycle,
reboot, sleep, clean installation, rollback, and production admission remain
separate checks.

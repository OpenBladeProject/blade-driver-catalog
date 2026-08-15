# Blade driver catalog agent guide

This repository contains metadata and read-only collection instructions for
original signed Razer driver packages. It does not contain production device
control code.

- Never commit INF, CAT, SYS, PNF, ZIP, serials, usernames, local paths, full
  device-instance IDs, interface paths, or machine-local `oem###.inf` names.
- Keep every catalog entry scoped to the exact model, hardware IDs, package
  versions, files, hashes, and signer evidence that were reviewed.
- Do not copy a package identity, dependency, installation order, service,
  binary name, or runtime behavior from one Razer device to another.
- Collection workflows are read-only. Do not install, update, bind, disable,
  restart, remove, or delete a driver or device.
- A package export proves only what was installed on the source machine. It
  does not prove compatibility, safe installation, runtime semantics, or
  redistribution rights.
- Proprietary archives may be published only as separate release assets after
  written authorization covers the exact files and delivery method.
- Use Conventional Commits with lowercase imperative summaries.
- Run `tests/Run-All.ps1` after changing documentation, templates, manifests,
  or repository policy.

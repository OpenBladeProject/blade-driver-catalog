# Offline core model coverage

`core-model-catalog.json` captures the complete public metadata source from the
exact `coreSource` revision recorded in `catalog/applicability.json`. Its source
content is inert data; the catalog tests never compile it, execute it or contact
the upstream repository. This fixture grants no runtime or installation authority.

The fixture records the upstream repository, commit, path, Git blob SHA-1 and
SHA-256 of the exact UTF-8 source bytes. `profiles` contains the model numbers,
display names and USB identities decoded from that source. The test verifies
both content hashes, decodes the source initializer independently of the ledger,
and requires the fixture and ledger to contain exactly those identities. Removing
a model and all its reviews, or adding a foreign model with complete reviews,
therefore fails the offline catalog suite.

When reviewing a new core model:

1. Obtain the immutable core source with `git cat-file blob <commit>:<path>`.
   Preserve its exact bytes, including the final newline; do not copy a working
   file with different line endings.
2. Record those bytes as the JSON `source.content` string, the source revision
   and path, `git rev-parse <commit>:<path>` as `source.gitBlobSha1`, and the
   source-byte SHA-256. Refresh the decoded `profiles` from that source.
3. Review every catalog artifact against the new model's vendor definitions.
   Update the applicability ledger and its matching core source pin, then run
   `tests/Run-All.ps1`. If the upstream initializer changes shape, review and
   update the deliberately narrow fixture decoder; do not weaken the identity
   comparison to make the fixture pass.
4. Refresh core's separate catalog coverage fixture and run its coverage tests.
   This catalog fixture supplements that check and does not replace it.

This snapshot covers only the pinned revision. It does not claim to discover
future upstream models without an explicit source and applicability review.

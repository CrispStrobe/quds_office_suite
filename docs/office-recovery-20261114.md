# Office preservation continuation — 14 November 2026

## Recovery baseline

The starting suite commit is `b0335829428d50968258219c4fdced15d546f7c9`.
CrispCloud starts at `15a389f57e3a8fe9837f786407ce787fe198386f` and pins that
suite commit. Both repositories use `codex/office-recovery-20261114` for this
continuation. Each completed increment is committed and pushed before work
continues. The default branches are not the checkpoint destination.

The supplied interrupted-session transcript describes local implementation and
test results, but those changes were absent from the inspected remote trees.
This continuation reconstructs the missing behavior against the latest remote
baseline. Transcript totals are not current validation evidence.

## Scoped work and acceptance

| ID | Owner | Scope | Acceptance | Status |
| --- | --- | --- | --- | --- |
| REC-01 | Engine | Preserve imported formula caches when unsupported calculations affect dependent cells. | Typed caches survive direct, transitive, cross-sheet and runtime references; real errors and cycles remain distinguishable; focused tests pass. | Implemented; full engine gate passed |
| REC-02 | Engine/editor | Preserve SpreadsheetML namespaces and native style properties when editing formatting. | Default/prefixed namespace and foreign-extension regressions pass; horizontal alignment does not introduce vertical centering; explicit color intent survives history. | Implemented; tests, schema and four-file independent render passed |
| REC-03 | Engine/editor | Preserve native Word restriction modes and make tracking/protection controller changes undoable. | Dirty/revision state, undo/redo, imported restriction modes and hash metadata survive save/reopen; read-only history does not enable ordinary edits. | Implemented; full engine/editor suites passed |
| REC-04 | Engine | Conservatively refuse editable opens of signed spreadsheets and presentations. | Signature markers and relationships are detected, unsigned packages remain editable, and original bytes remain available to the host. | Implemented; synthetic marker and unsigned controls passed |
| REC-05 | CrispCloud | Protect unsaved navigation and offer independent recovery copies. | Back/Close Cancel, Discard and Save, pending upload, disconnection, export failure/retry, and original dirty-state regressions pass. | Implemented; host execution in progress |
| REC-06 | CrispCloud | Derive tracking/protection controls from the current controller. | Imported state, replacement controllers, undo/redo and async confirmation races are covered. Depends on REC-03. | Implemented; host execution in progress |
| REC-07 | Both | Synchronize canonical suite changes through the exact source manifest and run acceptance gates. | Manifest verification, focused engine/editor/host tests and source-bound receipts are recorded. Depends on REC-01–06. | Source gates passed; app manifest verified; fresh host gate pending |
| REC-08 | Both | Extend independent first-save Office workflow evidence. | Authored expected documents, exact saved-byte inventory, schema validation and source/render comparisons must pass before claiming closure. | Six fixtures schema-valid; actual host schema/render pending |

## Evidence rules

Implementation, executed tests, external schema/render validation, browser
execution and physical-device behavior are separate claims. A local widget
test does not prove device behavior. A synthetic signature marker does not
verify an Office cryptographic signature. Coverage totals require a fresh
receipt for the exact source under test. Remaining limitations stay explicit.

## Checkpoints

- Recovery plans were remotely saved before implementation in both repositories.
- Canonical implementation checkpoint:
  `36e652014d0e1aade20011309cd84a7f9c1f90a6`.
- App fixture/evidence checkpoint:
  `f7122f7a3c745b09354c76261977e45ca9e8c3eb`.
- Later documentation commits do not change the tested implementation identity.

## Executed canonical validation

The [source receipt](evidence/office-recovery-20261114/suite-validation.json)
binds the following results to the canonical implementation checkpoint. Logs,
output inventories, schema results and dependency hashes are stored beside it.

| Gate | Executed result |
| --- | --- |
| Full engine fidelity gate | 1,256 Dart tests and 440 Python controls passed; 350/350 expected outputs verified |
| Engine analyzer | No issues |
| Full editor suite, including reviewed visual goldens | 539 passed; one existing optional local-PDF comparison skipped |
| Editor semantic oracles and inventory | Corpus, bookmarks, content controls and bookmark-copy checks passed; 29/29 declared files verified |
| Official OpenXML SDK 3.3.0 | All 350 exact engine inventory files validated with zero errors |
| Independently authored app fixtures | Six DOCX/XLSX/PPTX source/reference files validated with zero errors; regeneration is byte-for-byte reproducible |
| Renderer regression controls | 79 passed, including missing first-save reference and identical repeated-loss rejection |
| Formula negative controls | All five selected regressions fail against baseline `b0335829`; the current full engine gate passes |

Local execution used Flutter 3.47.8 / Dart 3.13.7. The existing source CI still
uses its pinned Flutter 3.44.0. Historical line-coverage percentages have not
been relabeled as fresh measurements.

## Behavior and limits

Unsupported spreadsheet calculations preserve imported typed results throughout
the dependent calculation chain. Supported errors remain errors; runtime
`INDIRECT`/`OFFSET` cycles remain detectable. This does not add implementations
for unsupported formula families.

Spreadsheet edits preserve native namespaces, foreign extensions and unrelated
style properties. Explicit font-color commands replace native theme references
even when their current RGB matches; unrelated formatting keeps the theme.

Word settings retain native restriction modes, hash metadata and formatting
restrictions. Protection transitions participate in dirty/revision history.
Comments/forms/tracked-only restrictions conservatively restrict editing, and
password metadata prevents unsupported unprotection. Cryptographic password
verification is outside this change.

Signed XLSX/PPTX editing is refused on recognized package signature markers,
including relationship and content-type declarations. These are preservation
guards, not cryptographic authenticity checks. Real signed-file acceptance,
physical-device journeys and browser execution remain separate open gates.

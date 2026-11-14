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
| REC-01 | Engine | Preserve imported formula caches when unsupported calculations affect dependent cells. | Typed caches survive direct, transitive, cross-sheet and runtime references; real errors and cycles remain distinguishable; focused tests pass. | Planned |
| REC-02 | Engine | Preserve SpreadsheetML namespaces and native style properties when editing formatting. | Default/prefixed namespace and foreign-extension regressions pass; horizontal alignment does not introduce vertical centering. | Planned |
| REC-03 | Engine/editor | Preserve native Word restriction modes and make tracking/protection controller changes undoable. | Dirty/revision state, undo/redo, imported restriction modes and hash metadata survive save/reopen; read-only history does not enable ordinary edits. | Planned |
| REC-04 | Engine | Conservatively refuse editable opens of signed spreadsheets and presentations. | Signature markers and relationships are detected, unsigned packages remain editable, and original bytes remain available to the host. | Planned |
| REC-05 | CrispCloud | Protect unsaved navigation and offer independent recovery copies. | Back/Close Cancel, Discard and Save, pending upload, disconnection, export failure/retry, and original dirty-state regressions pass. | Planned |
| REC-06 | CrispCloud | Derive tracking/protection controls from the current controller. | Imported state, replacement controllers, undo/redo and async confirmation races are covered. Depends on REC-03. | Planned |
| REC-07 | Both | Synchronize canonical suite changes through the exact source manifest and run acceptance gates. | Manifest verification, focused engine/editor/host tests and source-bound receipts are recorded. Depends on REC-01–06. | Planned |
| REC-08 | Both | Extend independent first-save Office workflow evidence. | Authored expected documents, exact saved-byte inventory, schema validation and source/render comparisons must pass before claiming closure. | Open |

## Evidence rules

Implementation, executed tests, external schema/render validation, browser
execution and physical-device behavior are separate claims. A local widget
test does not prove device behavior. A synthetic signature marker does not
verify an Office cryptographic signature. Coverage totals require a fresh
receipt for the exact source under test. Remaining limitations stay explicit.

## Checkpoints

- Recovery plan: repository baselines and bounded acceptance tasks recorded.
- Implementation and fresh results will be appended as increments complete.

## Integration validation on macOS

The integrator merged checkpoint `67139a78207393f6eb2e8c35569e6a3d644403fd`
onto the previous main `b0335829428d50968258219c4fdced15d546f7c9`, using
Flutter 3.47.8 / Dart 3.13.7. REC-01–04 now have implementation and executed
regression coverage; REC-05–07 are coordinated with the CrispCloud host.
REC-08 remains open. These checkpoints do not establish native Office signature
verification or new independent schema/render certification.

- Complete engine suite: **1,728 passed, three conditional skips**.
- Complete editor suite: **520 passed, one conditional skip, 17 existing golden
  failures** on this Mac. The same 17 tests fail at the previous main; all
  **27 retained actual golden-render PNGs are byte-identical** between baseline
  and integration. Goldens were not regenerated or accepted as new references.
- Protection/history cohort after removing an unnecessary accessor override:
  **11 passed**. Both library analyzers are checked separately during integration.

The macOS golden mismatch remains a separate baseline issue; the full editor
suite is not reported as green. Host save/recovery tests and exact vendored
source verification are recorded in CrispCloud's matching continuation record.

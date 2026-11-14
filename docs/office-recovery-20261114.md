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
| REC-05 | CrispCloud | Protect unsaved navigation and offer independent recovery copies. | Back/Close Cancel, Discard and Save, pending upload, disconnection, export failure/retry, and original dirty-state regressions pass. | Complete: 19 lifecycle and three native export tests passed within the full host gate |
| REC-06 | CrispCloud | Derive tracking/protection controls from the current controller. | Imported state, replacement controllers, undo/redo and async confirmation races are covered. Depends on REC-03. | Complete: nine ribbon state/race tests passed within the full host gate |
| REC-07 | Both | Synchronize canonical suite changes through the exact source manifest and run acceptance gates. | Manifest verification, focused engine/editor/host tests and source-bound receipts are recorded. Depends on REC-01–06. | Complete: 2,168 managed files verified; all source gates and 241-test host gate passed |
| REC-08 | Both | Extend independent first-save Office workflow evidence. | Authored expected documents, exact saved-byte inventory, schema validation and source/render comparisons must pass before claiming closure. | Complete: 149 host/reference files schema-valid; 16 render inputs and four independent baselines passed |

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

## Later colour and independent-reference checkpoint

Checkpoint `36e652014d0e1aade20011309cd84a7f9c1f90a6` adds explicit spreadsheet
font-colour intent, including clone/history preservation, and independently
authored save references. The integrated engine rerun passes **1,731 tests**
with three conditional skips. Two CLI tests had exceeded the default 30-second
limit during concurrent compilation; the clean rerun used a two-minute limit
and passed every test. Both library analyzers are clean.

The full editor rerun has **522 passes, one conditional skip and the same 17
baseline macOS golden failures**. All 27 actual golden-render PNGs still match
the original main byte for byte. The focused colour/protection cohort passes
13 tests; the native-render comparison guard passes 72 Python tests.

CrispCloud's coordinated host run passes 55 tests with two platform skips.
Its nine Word/XLSX/PPTX saves and three independently authored references were
rendered by LibreOffice 26.8.2.2: **12 files, 12 pages, three save-cycle groups
and three baseline comparisons, zero failures**. This is scoped first-save
evidence for those workflows, not completion of every REC-08 scenario or
physical-platform acceptance.

## Additional canonical checkpoint receipts

- Recovery plans were remotely saved before implementation in both repositories.
- Canonical implementation checkpoint:
  `36e652014d0e1aade20011309cd84a7f9c1f90a6`.
- Visible namespace fixture and repeated engine acceptance checkpoint:
  `c85c9f0a81a75a4afb5103d397c1816f0140eb00`. Production libraries and editor
  tests are unchanged; only the adversarial fixture's native theme/geometry
  and theme-preservation assertion changed.
- App fixture/evidence checkpoint:
  `f7122f7a3c745b09354c76261977e45ca9e8c3eb`.
- Final measured app checkpoint:
  `05905b86ca3a7fc8db3df131620842da3e134061`, pinning source `c85c9f0a`.
- Later documentation commits do not change the tested implementation identity.

## Executed canonical validation

The [source receipt](evidence/office-recovery-20261114/suite-validation.json)
binds each result to its exact source checkpoint, including the repeated engine
gate after the visible-fixture refinement. Logs, output inventories, schema
results and dependency hashes are stored beside it.

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

## Completed host and independent acceptance

The final [external receipt](evidence/office-recovery-20261114/external/external-validation.json)
records 149 app/reference packages validated by OpenXML SDK with zero errors.
That is 146 actual host outputs and three independently authored references.
It separately revalidates four namespace XLSX files already included in the
350-file engine schema scope; those are not additional unique engine cases.

LibreOffice 24.2.7.2 rendered exactly 16 inputs: nine native app uploads across
Word/Sheet/Slide, their three authored references, and three namespace saves
plus their authored reference. All four three-save groups and four independent
first-save baselines matched page count, text and RGB pixels. The namespace
pages also pass the visible-blue-text safeguard; both real previously clipped
versions are rejected by that control. The main archive preserves exact Office
bytes, PDFs, PNGs, tool receipts and 235 independently hashed entries.

The final app gate passed 241 tests across 34 files, with fresh LCOV bound to
4,732 inputs. Native host line execution is 2,872/4,391 (65.4%); all 16 required
native source files appear in instrumentation. One browser-only adapter and one
verified declaration-only file are reported separately. The gate also passed
41 coverage controls, 16 host-evidence controls, all source synchronization
checks, the exact 149-file inventory and the controller corpus oracle.

These results close REC-01–08 at their declared scope. Browser runtime,
physical-device/live-provider journeys and authentic signed Office fixtures
remain separate open acceptance gates. The app's
[current recovery report](https://github.com/CrispStrobe/CrispCloud/blob/codex/office-recovery-20261114/docs/office-recovery-20261114.md)
states their concrete acceptance conditions.

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

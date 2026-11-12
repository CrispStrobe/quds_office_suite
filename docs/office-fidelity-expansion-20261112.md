# Office fidelity expansion — 12 November 2026

This continuation recovers both interrupted development lines and extends the
shared Quds implementation. CrispCloud consumes committed shared sources through
its guarded manifest sync. Work is saved incrementally on
`feature/office-fidelity-expansion-20261112` in both repositories.

## Recovered work

The source recovery joins follow-up checkpoint `08b0948` and workflow checkpoint
`b1bb296` without discarding either history. Remote merge `2774707` preserves
native table-cell widths, the XML namespace collision fix, Unicode-aware narrow
text wrapping, four reviewed table goldens, the named feature runner, and
successful-run coverage receipts. It retains the later merged-cell topology,
partial-merge guards, spreadsheet font metrics, explicit cell styles, typed
formula caches, history fixes and shared custom-tab controls.

Two independently authored table corpora previously used the same
`fidelity-table-grid/source.docx` output name. The recovered width corpus now uses
`fidelity-table-widths`; both source documents and their separate expectations are
required. The inventory rejects duplicate paths instead of silently accepting one
producer's bytes in place of the other.

The host recovery applies the font-dialog, proportional-picture and coverage
changes from `309a553` to the later host checkpoint `788e1f0`. Remote checkpoint
`36a3634` preserves fractional font values, explicit mixed-selection choices,
cancel/no-op behavior, stale-dialog protection, image proportions and orientation,
and the current custom-tab/upload workflows. The host inventory expands from 62
to 122 actual captures. The previous source pin is not replaced by an older
workflow snapshot; the final host sync takes the combined Quds implementation.

## New supported behavior

### Scoped spreadsheet names

Import retains each definition's worksheet-index scope, independently of its
worksheet's native `sheetId`. Unqualified names prefer a local definition over a
global one. `Sheet!Name` selects that sheet's local definition, whose target cells
may belong to a different sheet. Quoted names, apostrophes, case differences,
absolute ranges and scalar numeric/Boolean/string/error definitions are covered.

Evaluation and dependency collection share the same scope resolver. Referenced
uncached formulas evaluate in their owning sheet with separate LET bindings. All
cycle participants are marked before their old numeric caches can be reused.
Real errors remain native error caches, while strings that look like errors remain
text and unsupported expressions retain their authored typed caches.

Independent review reproduced false cycles for `_xlfn.LET` and
`_xlfn._xlws.LET`, and coercion of real named errors by numeric consumers. The
follow-up normalizes function prefixes consistently and uses an explicit error
propagation policy. Counting, inspection, criteria and lookup functions retain
their individual semantics; IF/IFERROR/IFNA retain selected-branch evaluation.
Only literal conditions can select dependencies. Dynamic conditionals containing
opaque dependencies preserve caches instead of trusting a stale condition.

The existing rename corpus's D10 qualified formula now recalculates to **2**.
Current oracles require that result and reject the previous stale cache of 42.
Historical receipts remain unchanged. New independently authored references are
mandatory for the existing renamed exports and the new qualified-name corpus.

Limits remain for relative/computed definitions, external and three-dimensional
references, whole rows/columns, scoped OFFSET, qualification without a matching
local definition, and other unmodeled syntax. Bare `LOG10(...)` retains its
existing cell-token ambiguity and stays cache-preserving. This is bounded formula
support, not a claim of complete Excel evaluation.

### Complete native bookmark copies

`WordBookmarks.copyForInsertion` validates a copied fragment before mutation,
deep-clones it and remaps colliding native IDs and names. It reserves identities
from the destination, including retained opaque parts. Both endpoints and their
identity attributes change together; original payloads, ordinary clone helpers
and history snapshots keep their identities.

The editor uses this explicit copy path for complete native ranges, including
empty, overlapping and cross-paragraph ranges. Repeated paste, undo/redo after
switching stories, and three direct/isolate/editor saves are covered. An
independently authored expected document must match all six copied exports in
native text, page count and pixels.

Partial ranges and copied bookmark-bearing opaque XML remain rejected. Copied
REF/hyperlink targets keep their original meaning; automatic retargeting is not
implemented. Generated paragraph bookmarks are supported when their whole
paragraph is inserted. Rich-paste merges that would discard that paragraph
property reject before deleting a selection or creating history. Native inline
endpoints remain supported in those merges. FID-025 therefore remains partial.

### Slide arrangement and grouping

Distribution rounds cumulative spacing, keeping both outer endpoints exact on
either axis even when gaps are negative. All six alignment directions are
covered. Group allocation considers the full slide, and native group identities
are allocated separately from model keys without collisions or uint32 overflow.

Alignment, distribution, grouping and ungrouping now use commands owned by the
edited slide. Undo and redo work after changing slides. True no-ops preserve redo
and do not change the document revision. Foreign or duplicate selections,
noncontiguous grouping and partial group splits reject before mutation.

The independent Python oracle verifies five literal card geometries/text values,
two ordered flat groups, one ungrouped card, unique legal root/group/shape IDs,
identity group transforms, and stable identities through six direct/isolate
exports. The native renderer requires each grouped first save to match the
independently authored ungrouped source. Arbitrary nested/scaled native groups
remain outside this bounded representation.

## Recurring acceptance

The committed manifests require exactly the following files. These are authored
memberships, not inventories generated from whichever outputs happen to exist.

| Producer | Required files | Relevant additions |
| --- | ---: | --- |
| Quds engine | 346 | Both table corpora, scoped names and their references, bookmark copies and reference, flat-group exports |
| Quds editor | 29 | Bookmark copies and an independent reference alongside existing stories, tabs and goldens |
| CrispCloud host | 122 | Recovered font and picture captures plus the previous 62 uploads/dialog captures |

Source acceptance requires all **375** engine/editor files to pass the SDK gate.
The native gate accounts for every file; the existing seven comment-control
documents retain their narrowly scoped schema/native-XML qualification. The new
expansion corpora have independent appearance baselines and no new exemptions.

Host acceptance requires **468** engine/actual-host files for schema validation
and native rendering of **all 122 actual-host captures**. Renderer discovery now
includes DOCM, DOTX and DOTM, closing a silent omission in the combined workflow.
Picture-only slide inputs still require the specific authored black-rectangle
geometry and pixel oracle; arbitrary empty output is not accepted.

The engine gate runs the full suite with a source-bound coverage collector, all
15 feature workflows, the curated fidelity producers and package oracles, and the
coverage reporter. The editor gate runs the complete suite and reviewed goldens
without regenerating them. New independent mutation controls cover bookmark
copies, scoped-name caches and slide group identity/geometry. Line coverage
remains separate from branch correctness and Office fidelity.

The host runner uses an immutable LCOV directory and checks its successful
collection receipt. It records the exact documented temporary system-SQLite
pubspec hook, verifies every other collection input, and requires the committed
pubspec to be restored byte-for-byte after the gate.

## Evidence and remaining gaps

Final source acceptance passed at implementation
`2d6529e52f389e8c491ce75331d9efe6bd59a821`: 1,610 full engine tests, 1,147 mandatory
engine tests, 436 Python controls, all 15 feature workflows and 521 editor tests.
The full suites retain their two individually documented existing skips; the
mandatory cohort has none. All 375 packages pass schema validation. Native
acceptance covers 368 files and 687 pages, with 109 save-cycle groups, 47
independent baseline comparisons and 10 page-order comparisons. The seven
existing comment-control qualifications remain explicit. Fresh engine line
coverage is 45,186/54,575 (82.80%). See the
[final source receipt chain](evidence/office-fidelity-expansion-20261112/final-source/README.md).

Focused red/green logs, authored references, source/input hashes and independent
native receipts are under
[`docs/evidence/office-fidelity-expansion-20261112`](evidence/office-fidelity-expansion-20261112/).
The final aggregate receipts bind acceptance to fixed implementation commit
hashes; they do not retroactively change earlier reports. The reproducible source
and host runners are stored with those receipts.

The [gap ledger](office-fidelity-gaps.json) retains open/partial areas, including
Microsoft Office visual equivalence, unexecuted lines and branches, advanced
content controls and fields, partial bookmarks, unknown font metrics, complex
wrapping, nested/scaled slide groups, unsupported formulas and additional host
authoring controls. The expansion closes the named reproduced defects without
claiming exhaustive Office format support.

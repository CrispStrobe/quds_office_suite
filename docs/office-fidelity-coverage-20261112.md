# Office fidelity coverage — 12 November 2026

This continuation is on `feature/office-fidelity-coverage-20261112` in both
[quds_office_suite](https://github.com/CrispStrobe/quds_office_suite/tree/feature/office-fidelity-coverage-20261112)
and [CrispCloud](https://github.com/CrispStrobe/CrispCloud/tree/feature/office-fidelity-coverage-20261112).
Changes are saved as successive remote commits. The default branches are not
changed by this work.

The requested suite `crispcloud` branch was at `c9655003`; the existing fidelity
work had already reached suite `main` at `54fa48ef`. This feature includes that
existing descendant before adding the changes described here. CrispCloud started
from `8c8d5c6c` and uses vendored engine/editor path dependencies. Updating the
suite alone does not update the app.

## Execute import, edit and export workflows

Use the suite's pinned Flutter 3.44.0 toolchain. From
`packages/quds_office_engine`:

```sh
dart run tool/fidelity/office_steps.dart operations
dart run tool/fidelity/office_steps.dart inspect input.docx
dart run tool/fidelity/office_steps.dart export input.docx unchanged.docx
dart run tool/fidelity/office_steps.dart modify input.docx steps.json edited.docx
dart run tool/fidelity/office_steps.dart roundtrip edited.docx build/reopened 3
```

These commands also support XLSX and PPTX in their own native formats. They do
not perform format conversion. The public catalog contains **67 operations:
49 DOCX, 10 XLSX and 8 PPTX**. Every operation has a committed scenario that the
normal gate executes. This is operation-name coverage; it does not establish
complete parameter, branch or OOXML coverage.

The [operation guide](../packages/quds_office_engine/tool/fidelity/README.md)
describes fields, selectors, units, input validation and limitations. The three
new Word structure recipes are:

- `test/fixtures/fidelity/scripts/word-structure-create.json`
- `test/fixtures/fidelity/scripts/word-structure-edit.json`
- `test/fixtures/fidelity/scripts/word-structure-remove.json`

They create, modify and remove native structures in an independently authored
document, checking each intermediate result and three reopen/save cycles.
The source XML and expected semantic JSON are committed separately. Expected
values are not generated from the serializer being tested.

The CLI writes only after every step succeeds, using a temporary output and
rename. A failed late step leaves an existing output intact. Direct operation
entry points also validate arguments before mutation, including late invalid
run formatting, image dimensions, cell text, story text and section geometry.
Offsets cannot bisect UTF-16 surrogate pairs, note references or atomic cached
fields. Relative picture paths are resolved against the script directory.

## Acceptance coverage by feature

| Feature | Operations and edit paths | Independent or regression evidence | Scope still requiring care |
| --- | --- | --- | --- |
| Headings and styles | Heading1–9, custom paragraph/character/table styles, sparse style definitions, selected paragraph edits | Style cascade, referenced styles, style introduction and host gallery tests | All style combinations and fonts are not enumerated |
| Paragraphs | Insert/delete/split, rich replacement, indents, spacing rules, tabs/leaders, shading, borders, direction, breaks | Scripted transitions, atomicity tests, exact host property dialogs, repeated history | Layout equivalence across arbitrary scripts and fonts remains separate |
| Footnotes/endnotes | Caret insertion, rich story editing, deletion, owned links/images/tables, pagination | Exact marker-position/absence oracle, real ribbon tests, note continuation goldens | The whole-note text setter intentionally replaces rich content; paragraph/run edits preserve it |
| Tables | Create, row/column insertion/deletion, merge/unmerge, cell/row/table properties, table styles and RTL | Structural XML golden, negative controls, rich merge and structural history tests | Grid surgery requires unmerged cells; merge uses logical columns, other cell selectors use physical cells |
| TOCs | Create/update/remove, heading ranges, cached page numbers, full/partial page suppression, unique bookmark targets | Structural oracle, native TOC integrity and empty-reference tests | Selectors traverse modeled body containers in depth-first order |
| Pictures | Add/remove/replace/resize, wrapping metadata, distances, rotation, title/description and owning relationships | Byte hashes, native drawing XML, story-media tests and visible-pixel guards | Arbitrary picture contour wrapping is not certified |
| Positioned drawings | Text frames with coordinates, dimensions, page/margin anchors, fill/stroke and native wrap metadata | Native frame oracle, variable-width/bidi geometry and page/column/note-reservation regressions | One available line interval; earlier paragraphs and floating tables are not retroactively reflowed |
| References | Exact native bookmark ranges, partial/cross-paragraph/empty/overlapping ranges, REF caches, inline citation/index fields | Fourteen native packages, independent endpoint/UTF-16 oracle, edits and repeated history | Mixed drawing-anchor endpoints and arbitrary rich complex-field refresh remain partial |
| Content controls | Live nested block containers and paired inline controls, exact metadata, real-parent text/structural edits | Six native direct/isolate exports, unchanged loss probe, corruption controls and controller history | Unsupported topologies and boundary-crossing/colliding copies are guarded; UI lock/data binding semantics remain open |
| Comments | Exact text anchors, replies, edit, resolve and delete; comment-story formatting | Native thread oracle, relational corruption controls, host comment dialog and history tests | Full modern-comment metadata beyond the modeled fields is not claimed |
| Revisions | Body and auxiliary-story ownership, exact native insertion/deletion spans, accept/reject and history | Authored ten-story corpus, direct/isolate export cycles and editor reopen/resolve tests | Disjoint edits rebase; ambiguous intersections are explicit conflicts requiring undo before resolve/export |
| Bibliography | Owned native source parts, add/edit/rename/delete, structured imported authors and source metadata | Relocated native source fixture, independent relationship/source oracle and mutation controls | Citation style rendering and automatic field retargeting after direct tag changes remain separate |
| Headers/footers | All six variants, exact property edits, owned links/media and story-aware history | Authored story fixture, three page goldens and host header controls | Cross-story structural operations are tested only where specified |
| XLSX/PPTX | Existing formula/style/merge/dimension/sheet and shape/text/geometry/note/transition recipes | Independent openpyxl/python-pptx fixtures, semantic oracles and native schema/render gates | Formula-aware sheet renaming and section-aware slide reordering remain explicit guards |

## Failures found and fixed in this continuation

Rich editing and history had failures that a successful save/reopen alone did
not detect. Coalescing discarded metadata; table merges lost non-paragraph
blocks; redo created replacement objects while later commands still referenced
the originals. Rich snapshots now preserve formatting, fields, notes, links,
comments and structural identities through repeated undo/redo.

Revision indices could point into the body when edits actually belonged to a
header, footer or comment. Imported revisions could also receive a stale body
index. Revision targets now bind to actual paragraphs. Export splits coalesced
runs at the native change boundaries, preserving unchanged prefix/suffix text.
Rejecting a reopened insertion no longer removes pre-existing adjacent text.
Disjoint edits and paragraph split/join update pending ranges; resolving earlier
changes shifts later spans. Conflicting overlaps are guarded before destructive
resolution or export, and history restores conflict state and original identities.

The two original source-loss probes now pass without changing their expected
structures. Native bookmarks preserve exact endpoints instead of being expanded
to whole paragraphs. Content controls keep their wrappers and metadata around
live editable children. Shared tree traversal finds the actual parent inside
controls, tables and frames, so structural history operates on the original
container. Unsupported topology is rejected explicitly before package mutation.

Replace-all previously could change an early paragraph before discovering that a
later match crossed an unsupported field/control boundary. A prepared operation
now validates every affected paragraph first. One controller history command
restores rich tokens and pending revision ranges across repeated undo/redo.

Frame layout now uses the available width on each affected line while retaining
the paragraph's bidi shaping and logical character offsets. Square frames allow
text beside them; top-and-bottom frames clear the full intersected column. Tests
cover multiple frames, columns, page transitions, long unbreakable words, TOCs
and changing footnote reservations. Native top-and-bottom wrap is also retained
instead of being read back as square wrap.

CrispCloud's paragraph and margin dialogs rounded fractional values and wrote
unchanged fields back into imported documents. They now apply only edited
fields, retain exact tabs/alignment/leaders, preserve explicit zero and leave a
no-op Apply clean. Selected paragraphs, header/comment stories, custom style
names, links, TOCs and tables are exercised through real host controls.

An independent review deliberately corrupted exports and found oracle blind
spots. The strengthened checks reject dangling comment references, missing field
boundaries, broken TOC anchors, invalid image relationship types, disabled
`cantSplit`, duplicate metadata and duplicate ZIP entries. The operation audit
also rejects unused scenario files as evidence of execution.

New page goldens exposed first-save spacing drift when a heading or TOC added a
style catalog to an imported styleless document. Imported missing paragraph
spacing now keeps native zero-after/single-line defaults; declared defaults and
explicit overrides still cascade. Newly generated TOC link styling also remains
stable across its first export.

Open XML SDK rejected numeric `bidiVisual` values from the new RTL table recipes.
The writer now emits the native `on`/`off` enumeration, with an independent
numeric-value corruption control. See the authoritative
[OnOffOnlyValues definition](https://learn.microsoft.com/en-us/dotnet/api/documentformat.openxml.wordprocessing.onoffonlyvalues).

## Run the acceptance gates

From the repository root, resolve dependencies with the pinned Flutter SDK.
Then run:

```sh
cd packages/quds_office_engine
dart analyze
dart test --coverage=coverage/fresh-vm
bash tool/fidelity/check.sh
python3 tool/fidelity/coverage_report.py coverage/fresh-vm
cd ../quds_office_editor
flutter test --no-pub
```

Use a new, empty directory for each coverage collection. The report records
the source commit, source hashes, unhit instrumented lines and uninstrumented
files. It measures executed lines, not branch coverage or correctness.

`check.sh` cleans only the declared output groups, runs their producers, verifies
the exact authored inventory, checks independent XML/pixel expectations and
runs positive-baseline corruption controls. Normal checks never update PNGs or
semantic expectations. A missing whole group cannot silently pass.

The [suite workflow](../.github/workflows/office-fidelity.yml) adds full editor
goldens, external Open XML SDK validation and LibreOffice/Poppler render
comparisons. Complete three-cycle groups are compared against their source or
edited baseline where available. PDFs, page PNGs, diagnostics, schema reports
and fresh coverage remain workflow artifacts.

## Integrate and validate CrispCloud

The app's `tool/sync_office_fidelity.py` defaults to a dry run. It reads committed
source bytes, verifies every existing vendor pin before writing, refuses local
host customizations or unsafe paths, and records the exact source commit plus
SHA-256 hashes. To apply a reviewed source checkpoint from the app repository:

```sh
python3 tool/sync_office_fidelity.py --source ../quds_office_suite --ref SOURCE_COMMIT --branch feature/office-fidelity-coverage-20261112
python3 tool/sync_office_fidelity.py --source ../quds_office_suite --ref SOURCE_COMMIT --branch feature/office-fidelity-coverage-20261112 --apply
python3 tool/verify_office_fidelity.py
bash tool/check_office_fidelity.sh
```

Use the app's pinned Flutter 3.47.8 and its native test dependencies. The actual
host gate captures **41 required DOCX exports**, validates the inventory, runs
the full declared Office host test set with LCOV, and checks the captured
uploads with Open XML SDK. Every declared host source must appear in coverage;
missing instrumentation fails the gate.

## Remaining gaps and interpretation

The [gap ledger](office-fidelity-gaps.json) distinguishes closed regressions,
partial support, explicit guards and open work. A closed ID establishes the
named bounded behavior. It does not certify every use of that feature or native
Microsoft Word rendering.

The original source-preservation probes are now part of the normal acceptance
gate and can also be run directly:

```sh
cd packages/quds_office_engine
python3 tool/fidelity/unsupported_word_audit.py
```

The diagnostic still exits nonzero on lost source structures. Both committed
probes pass their original expectations through an adjacent edit and three
save/reopen cycles. This closes those reproduced losses while the broader SDT,
bookmark and frame features retain explicit boundaries in the ledger.

Remaining work includes unsupported content-control topology and binding/lock
semantics, mixed text/drawing bookmark anchors, arbitrary nested complex fields,
floating table/picture contour layout, platform/font breadth and uncovered
branch combinations. Formula-aware sheet renaming and section-aware slide
reordering remain deliberate pre-mutation guards.

Earlier numeric coverage and validation reports in this repository are historical
checkpoints. Use the current source-hashed report and the workflow run for the
exact feature-branch commit when assessing a change.

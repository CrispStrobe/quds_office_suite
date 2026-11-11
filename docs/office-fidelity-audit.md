# Office fidelity audit — 2026-11-11

Work is checkpointed on `feature/office-fidelity-completion-20261111` in
[CrispStrobe/quds_office_suite](https://github.com/CrispStrobe/quds_office_suite/tree/feature/office-fidelity-completion-20261111)
and [CrispStrobe/CrispCloud](https://github.com/CrispStrobe/CrispCloud/tree/feature/office-fidelity-completion-20261111).
The base branches have not been changed by this work.

The source continuation includes the earlier fidelity work at
`3146e635`, ahead of the requested `crispcloud` baseline `c9655003`. The app
continuation carried its prior fidelity feature into `main` baseline
`5ec939e8`, then merged current `main` at `e70f24ce` after the same earlier
feature landed there. The later merge preserved the updated fork documentation
without changing the tested application code.

CrispCloud uses vendored engine/editor path dependencies. Shared files are
copied from an exact source commit after checking the app's existing bytes
against the previous pin. `tool/office_fidelity_manifest.json` records that
commit and SHA-256 hashes. An engine-only fix is not considered integrated until
the host copies and actual host tests are checked too.

## Runnable scenarios and expectations

The [runnable guide](../packages/quds_office_engine/tool/fidelity/README.md)
documents import/inspection, export, JSON modification and repeated-save
commands. The public catalog has **43 operations: 25 Word, 10 spreadsheet and
8 presentation operations**. Every operation appears in a committed executable
scenario. The combined scripts cover headings, paragraph/character/table styles,
explicit false/default formatting, footnotes and endnotes, text ranges, paragraph
split/insert/delete, lists/restarts, tables, images, all header/footer variants,
sections, cells/formulas/styles, dimensions, sheet order, slide text/geometry,
speaker notes, transitions and picture replacement.

Unknown fields, invalid types/ranges, broken text offsets, unsupported image
bytes and unsupported operations fail before an output is replaced. Image paths
are relative to the JSON script. Word and slide sizes are points; spreadsheet
row/column dimensions are pixels. Sheet renames involving references and slide
reorders involving sections are explicitly rejected until those rewrites have
complete semantics.

The expectations are authored independently of the exporter. Python reads
ZIP/XML and decoded image pixels directly; the Quds reader is not used to judge
its own serializer. Mutation controls first verify a valid positive control,
then require damaged content, formatting, relationships, note identities,
formulas, media or output inventories to fail. Normal checks never regenerate
fixtures or accept changed PNGs.

## Gaps reproduced and fixed

The [machine-readable gap ledger](office-fidelity-gaps.json) gives stable IDs,
status, evidence paths and explicit limits. A closed item refers to its bounded
regression, not every possible use of that Office feature.

| Area | Failure and resulting behavior | Main evidence |
| --- | --- | --- |
| Notes and history | Note IDs/kinds, atomic references, rich bodies, caret placement, split, formatting and undo/redo survive. Dense/long notes reserve space and continue. | Rich-note and controller regressions; semantic and page goldens |
| Styles | Sparse defaults, inheritance, theme values and character/table properties remain editable; explicit false/black/default-size/zero-spacing values stay direct. Missing referenced built-ins include known parent styles. | Style cascade fixture, sparse XML oracle, scripted Word golden |
| Lists | Imported numbering IDs do not collide with new lists. Restarts affect the intended sequence. Clearing a style-driven list writes an explicit suppression override, so it stays cleared after reopening and history operations. | Collision/restart fixtures, intermediate edit regressions and three-cycle oracle |
| Word media | Body, note and all six header/footer stories retain their own picture/chart links. Replacing or reordering media does not overwrite other payloads. Zero, small and omitted wrap distances remain distinct. | Authored colored pictures, ownership/distance oracles and decoded pixels |
| Native comments | Reply and resolved metadata join through native paragraph anchors independently of numeric comment IDs, including reverse source order. | Native comment fixture, source comparison and corruption controls |
| Embedded content | `altChunk` source blocks and owning-part relationships survive edits and cross-story moves, with target MIME and payload identity checked. | Body/table/note fixture and independent payload oracle |
| Imported defaults | Documents without styles retain sparse properties. Imported leading note markers retain their run properties and exact separator whitespace. Borderless tables stay borderless; inherited borders can be explicitly disabled. | Styleless, note-spacing/XML-space and table-border regressions; external source render comparisons |
| Package routing | Nonstandard document/styles/notes/settings paths are resolved and written through owning-part relationships. | Relocated-package fixture and external schema validation |
| Native bookmarks | Exact endpoint objects retain multiple, overlapping and cross-paragraph ranges through edits, split, history and saves; generated heading bookmarks avoid native collisions. | Independently authored ranges, engine/editor oracles and corruption controls |
| Content controls | Native wrappers retain aliases, tags, IDs, end properties, nesting and empty content around editable blocks/runs. Unsupported container operations reject before mutation. | Authored nested/block/inline controls, actual editor split/history and preflight controls |
| Imported note markers | Exact marker placement, absence, kind and run properties survive exported edits; new notes retain conventional defaults. | Nine authored source cases, independent XML and three-save source comparisons |
| Word compatibility | Import chooses one supported `mc:Choice` or its `Fallback`, including nested branches and namespace aliases. | Authored body/run/table/header/note cases and mutation controls |
| Sections | Page numbering, grids, borders, paper source, gutter, custom columns, line numbers and historical section metadata survive unrelated edits and cloning. Deliberate geometry edits update modeled fields. | Two-section fixture, source-fragment oracle and host section commands |
| Breaks | Line feeds use actual Word break tokens; tabs and typed page/column breaks survive save/reopen. | Structural XML assertions, multiline scripted notes and host text commands |
| Spreadsheet structure | Duplicate drawing links, invalid chart transforms/pivot attributes and font-property ordering are repaired. | Focused regressions plus independent Open XML SDK |
| Spreadsheet dimensions | Edited pixel widths use the maximum-digit-width formula; untouched precision and hidden/grouped/widthless column metadata are retained. | Authored width/property cases and three export cycles |
| Presentation text | Imported mixed rich text, whitespace, hard breaks and body properties survive; explicit font/color/geometry edits and multiline paragraph replacement export correctly. | Native deck, rich-text fixture and independent script oracle |
| Presentation structure | Chart-frame transforms, transition durations and axis identifiers validate; templates, notes, owned media and live chart formulas remain linked. | Native package checks and external schema gate |
| Editor painting | A replaced viewport receives layout before painting, avoiding blank later pages. | Reviewed first/even/default header/footer page PNGs before/after save |
| Canvas image lifetime | Closing Word, Sheet or Slide disposes decoded pictures; pending decodes release pixels without repainting the closed canvas. | Deterministic pending/ready cache tests and actual host reopen regression |
| CrispCloud note commands | Footnote/Endnote commands are exposed in the Word Insert tab/menu and open the editable notes pane, with localization, whitespace preservation, read-only and undo/redo checks. A real ribbon editing workflow verifies three uploaded saves and reopens. | Actual host heading/paragraph/note/picture ZIP/XML/media assertions |
| CrispCloud save state | Edits made while an asynchronous upload is pending remain dirty. A successful earlier upload cannot close a newer edit; selection-only changes and retry behavior are distinguished. | Four real editor-dialog widget cases and captured upload bytes |
| CrispCloud search | Search follows relocated parts, referenced notes, sheet/slide order, used shared strings and speaker notes, including Strict namespaces. Both input bytes and emitted UTF-8 text are bounded. | Authored DOCX/XLSX/PPTX/ODF inputs, shared-string expansion control and recursive-search callers |
| CrispCloud preview | Explicit false formatting, tabs/breaks, note references/bodies and workbook order/names are respected, including relocated and package-root parts. | Independently authored ZIP/XML preview tests and localization tests |
| Test completeness | Missing whole scenarios, wrong filenames, stale unexpected outputs, empty ZIPs and incomplete cycle groups cannot silently pass. | Authored exact manifest, negative controls, SHA receipts and renderer controls |

The source's original footnote/full-page golden is retained. Three additional
reviewed page PNGs cover first-page, even-page and default header/footer images,
columns and explicit page breaks. Tests require real image-colored pixels before
capturing or comparing a golden and use the same expected image before and after
an asynchronous save. Flutter is pinned to 3.44.0 on Linux for these comparisons.

The first story-page golden was deliberately reviewed again after the styleless
import fix: its authored source has neither a styles part nor paragraph spacing.
The old image included added spacing. The new image changes only the resulting
body-picture and note-text positions; all source content remains visible. The
other three page PNGs are unchanged. The story test now explicitly requires the
source paragraph to have zero after-spacing and single line spacing before and
after save.

## Evidence gates

The source workflow runs full engine and editor tests, the portable scripted
corpus, all semantic oracles and fresh VM coverage. Its external jobs use the
Open XML SDK and LibreOffice/Poppler. The renderer retains PDF files and every
page PNG; comparisons use decoded RGB bytes and normalized extracted text,
with numeric page ordering and complete cycle groups. Where a separate source
or edited baseline exists, it participates in the comparison.

The app workflow uses Flutter 3.47.8 and its native test dependencies. It checks
the vendor manifest, runs the same portable corpus and the actual host tests,
collects Office-host LCOV, and retains cloud-upload bytes. The host section and
multiline-text cases add three save/reopen exports each. The schema gate checks
the exact actual-host inventory before validating the downloaded evidence.

### Verified 692 checkpoint

Production engine code is checkpointed at `a7e1a207`; the reviewed story-page
image, its explicit spacing assertions and coverage report are in `692a326`.
The latter commit does not change production engine/editor code.

| Gate | Verified result |
| --- | --- |
| Full engine suite with a fresh VM coverage directory | **623 passed**, one existing optional local-fixture skip |
| Full editor suite on pinned Linux Flutter | **233 passed**, one existing optional local-fixture skip |
| Portable import/edit/export gate | **163 focused Dart tests**, all **43 public operations**, **113 Python oracle/inventory/coverage controls** |
| Authored output inventory | **117/117 engine packages**, 37 complete three-save series and six standalone/baseline inputs |
| Editor package oracle | Saved controller DOCX passes independent XML/media checks; three-page story DOCX is also retained for external validation |
| Engine analysis | No errors or warnings; three pre-existing informational lints in reports/PDF/test code |
| CrispCloud host suite | **97 passed**, including real editor-dialog asynchronous save cases and the search callers |
| Host helper controls | **Eight** inventory controls and **four** coverage-report controls passed |
| Actual host outputs | **14/14 DOCX**: seven captured editor-dialog uploads, three section cycles, three text cycles and the unchanged controller export |
| External Open XML SDK, source snapshot | **119 packages, zero errors**: 117 engine outputs plus two editor documents |
| External Open XML SDK, host snapshot | **131 packages, zero errors**: 117 vendored engine outputs plus all 14 actual-host documents |

The SDK positive and negative self-test also passes. The app's latest complete
gate used immutable `a7e1a207` production code; its final pin advances to
`692a326` with only the reviewed PNG, test assertions and a helper docstring
changed. The vendor guard records **154 shared files**. Source and app export
snapshots retain their exact membership, byte sizes and SHA-256 hashes.

The [external evidence summary](office-validation-692a326.json) records a complete
strict render pass: **119/119 files, 187 pages, 37/37 three-save groups and all
five source/edited baseline comparisons passed**. All 187 retained PNGs were
decoded again and checked against their RGB fingerprints. The three remaining
standalone packages are explicitly labeled as render-only. No conversion failed
or required a retry. Exact snapshot membership and every file hash were checked
again after rendering. This check is independent of the Flutter page goldens and
of schema validity.

### Fresh execution coverage

[The full engine gap inventory](office-coverage-gaps.json) records the clean
production source hash and every unhit instrumented line. It was collected after
removing the old VM coverage directory and running all 623 engine tests against
unchanged production code at `a7e1a207`.

| Scope | Covered / instrumented lines | Coverage |
| --- | ---: | ---: |
| Entire engine | 40,172 / 49,903 | 80.5% |
| Word | 6,955 / 8,757 | 79.4% |
| Spreadsheet | 3,136 / 3,956 | 79.3% |
| Presentation | 1,802 / 2,275 | 79.2% |
| PDF | 11,833 / 15,287 | 77.4% |
| Reports | 9,588 / 11,295 | 84.9% |
| CrispCloud Office host | 1,952 / 3,557 | 54.9% |

The host report is `CrispCloud/docs/office-host-coverage-gaps.json`. All nine
scoped Office service/widget files are instrumented. The engine report lists ten
files absent from VM instrumentation separately; most are export-only library
entry points, with isolate helpers and a PDF template index also listed.
Neither percentage is branch coverage or a claim of correctness. The helpers
reject malformed records, missing paths and out-of-range line numbers; their
source hashes describe the files present when the report was made. Fresh
collection remains required because old hit counts after a same-length source
edit cannot be recognized from coverage data alone.

Most remaining host lines are ribbon/dialog commands outside this test cohort.
The largest engine execution gaps include formula functions, the PDF interpreter,
Word layout and report generation. Their exact line numbers remain in the reports.

## Remaining acceptance boundaries

The original independently authored SDT and bookmark loss probes are now passing
regressions in the modification gate. The [historical diagnostic result](office-unsupported-word-probes.json)
retains the failing `692a326` evidence and its source/fixture hashes; it is not a
claim about current behavior. Run `python3 tool/fidelity/unsupported_word_audit.py`
in the engine package to require preservation through the original adjacent edit
and three-save sequences.

Native Word preservation has explicit model boundaries. Block controls in
paragraph-only header/comment models, row/cell wrappers, invalid nesting and a
paragraph split through an inline control reject explicitly. Paragraph-external
bookmark endpoints, unpaired/cross-story ranges and duplicate native identities
are also guarded. A deliberate whole-note text replacement replaces its rich
body and keeps only its first automatic marker at the start; range edits preserve
rich structure. Exported unconventional note-marker positions are preserved,
while the canvas continues to use conventional note-label layout. Retaining an
embedded external-content payload does not imply rendering or conversion of it.

Column conversion currently defaults to a maximum-digit-width of 7; automatic
measurement of arbitrary imported normal-style fonts is not implemented. The
script refuses referenced sheet renames and slide reorders requiring section
rewrites. Additional OS/font/SDK goldens and arbitrary RTL/layout combinations
remain outside the reviewed visual corpus. The table-border model has one
border/color/width tuple: a deliberate edit writes six uniform edges, while
untouched per-edge source XML is retained.

LibreOffice save-cycle stability and Open XML SDK validity are separate from
Microsoft Office visual equivalence and native application certification. The
exact execution-gap inventory remains a work list, not a claim that executed
lines are correct or that every unhit line is defective.

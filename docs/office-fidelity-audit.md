# Office fidelity audit — 2026-11-11

Work is checkpointed on `feature/office-fidelity-completion-20261111` in
[CrispStrobe/quds_office_suite](https://github.com/CrispStrobe/quds_office_suite/tree/feature/office-fidelity-completion-20261111)
and [CrispStrobe/CrispCloud](https://github.com/CrispStrobe/CrispCloud/tree/feature/office-fidelity-completion-20261111).
The fork merged this continuation into `main` together with the earlier
`feature/office-fidelity-oracles` work.

The source continuation includes the existing, unmerged fidelity work at
`3146e635`, ahead of the requested `crispcloud` baseline `c9655003`. The app
continuation carries its prior fidelity feature into current `main` baseline
`5ec939e8`. Keeping this history avoids dropping earlier fixes while adding
new coverage.

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
| App-only OOXML fixes absent from fork | Both copies emit ordered properties, required note marks and normalized highlights | Package oracle; host formatting tests |
| Note identity lost while copying/editing runs | Formatting, extract/insert, split and undo retain IDs and note kind; multi-digit references stay atomic | Engine and controller regressions |
| Deleting notes altered unrelated `[1]` prose | Delete actual reference runs only | Engine and script tests |
| Repeated exports added note whitespace | Note text stays stable across saves | Three-cycle regression |
| Note/header hyperlinks used document relationships | Resolve and emit relationships in the owning part | Independently authored links; package oracle |
| Direct black/11pt/zero spacing/left alignment treated as absent | Explicit direct defaults override styles | Authored import and scripted formatting tests |
| Styles regenerated with source data loss | Retain untouched paragraph/character/table style XML and defaults; regenerate edited paragraph styles | Style corpus and list assertions |
| Imported styles leaked into a global catalog | Apply styles from the current document | Custom-style/undo test |
| Imported numbering definitions overwritten | Retain existing definitions and merge missing built-ins | Numbering XML, visible-label test and PNG |
| Table style/border width/color changed on save | Retain table style and border properties | Table regression and PNG |
| Paragraph split flattened rich runs | Split/undo preserves formatting, links and notes | Controller workflow |
| Footnote insertion ignored caret; redo snapshot errors | Insert at caret and survive repeated undo/redo | Footnote/endnote history tests |
| Paragraph formatting mutated history snapshots | Restore independent paragraph properties per history operation | Repeated formatting/undo test |
| Multiple/mixed notes in one paragraph hid footnotes | Layout finds individual run references | Mixed-note and multiple-note tests |
| Multiline note bodies truncated; long endnotes overflowed | Render explicit lines and continue endnotes on additional pages | Layout regression and PNG |
| PNG captured before image decode and cut off page bottom | Require visible picture pixels and capture notes/footer | Full-page import/reopen golden |
| Fork changes could silently miss app | Hash guard plus root host integration tests | Vendored manifest and async-save artifact |
| FID-005: narrow independent spreadsheet/presentation corpus | Committed openpyxl/python-pptx inputs; retain source style records, pivots, templates, owned media and chart formulas | Fifteen native/pivot exports, ZIP/XML/pixel oracle, cell/chart/style/pivot edits, slide notes/transitions/animations and reorder cases |
| FID-003: missing effective style cascade | Resolve sparse defaults, basedOn chains, theme fonts/colors, character and table-region formatting; keep inherited values editable; script style definitions | Authored combination fixture, direct false/zero cases, cycle protection, three async cycles, six sparse-XML oracles |
| FID-004: list commands collided with imported IDs 1/2 | Allocate and reuse document-local definitions; changing levels keeps identity; list commands support undo/redo | Collision fixture, three async cycles, host history test |
| Imported numbering start and Roman/alphabetic formats ignored | Honor zero/non-one starts and Roman, alphabetic and padded decimal labels | Independently authored numbering cases |
| FID-001: dense pages overlapped footnotes; long notes disappeared | Reserve the note band during body layout, move references when needed and allocate continuation pages | Dense text with 180 unique note tokens; columns, table-cell reference and following-picture overlap assertions |
| PPTX exported packages lacked masters and required notes size | Preserve imported templates; add missing master/layout/theme and notes relationships; emit standard sections | Open XML SDK gate; native deck and reorder/delete-notes regression |
| Slide images/charts overwrote media on other slides | Give visuals an owning-part namespace and retain source slide URIs through reorder | Independent two-slide deck, distinct pictures and chart values over three async cycles |
| FID-002: notes flattened styled runs, tables, drawings and links | Ordered note blocks round-trip; notes use shaped rich lines and their own media relationships | Rich-note source fixture, three async cycles, glyph/style/link/table/image assertions and reviewed PNG |
| Tall cell paragraphs overflowed pages and placed late notes early | Split oversized rows at complete line boundaries; reserve notes on the reference's actual page | 120 unique tokens, bounded frames, correct note page, four reviewed page PNGs |
| Inherited run toggles acted as replacement values | Compose paragraph/character bold/italic toggles; direct true/false remains absolute | Authored opposing styles and direct overrides across repeated async saves |
| Nonstandard style-part targets could create a second style file | Follow the existing styles relationship when saving | Custom part location and edited character style survive three saves |
| FID-007: only one visual fixture | Twelve reviewed PNGs cover RTL/Arabic, columns, section/page breaks, note continuation and tall tables | Explicit page counts; same golden before and after export |
| FID-008 concrete script/body cases | Image replacement preserves expected pixels and dimensions; failed scripts retain output; opaque body XML stays ordered | Independent decoded-pixel/altChunk oracle, invalid-step control and repeated async saves |
| Notes and history | Note IDs/kinds, atomic references, rich bodies, caret placement, split, formatting and undo/redo survive. Dense/long notes reserve space and continue. | Rich-note and controller regressions; semantic and page goldens |
| Styles | Sparse defaults, inheritance, theme values and character/table properties remain editable; explicit false/black/default-size/zero-spacing values stay direct. Missing referenced built-ins include known parent styles. | Style cascade fixture, sparse XML oracle, scripted Word golden |
| Lists | Imported numbering IDs do not collide with new lists. Restart overrides apply to the intended level and following segment without changing unrelated lists or growing definitions on every save. | Collision/restart fixtures, XML labels and three-cycle oracle |
| Word media | Body, note and all six header/footer stories retain their own picture/chart links. Replacing or reordering media does not overwrite payloads used elsewhere. | Independently authored colored pictures, ownership checks and decoded pixels |
| Package routing | Nonstandard document/styles/notes/settings paths are resolved and written through owning-part relationships. | Relocated-package fixture and external schema validation |
| Word compatibility | Import chooses one supported `mc:Choice` or its `Fallback`, including nested branches and namespace aliases. | Authored body/run/table/header/note cases and mutation controls |
| Sections | Page numbering, grids, borders, paper source, gutter, custom columns, line numbers and historical section metadata survive unrelated edits and cloning. Deliberate geometry edits update modeled fields. | Two-section fixture, source-fragment oracle and host section commands |
| Breaks | Line feeds use actual Word break tokens; tabs and typed page/column breaks survive save/reopen. | Structural XML assertions, multiline scripted notes and host text commands |
| Spreadsheet structure | Duplicate drawing links, invalid chart transforms/pivot attributes and font-property ordering are repaired. | Focused regressions plus independent Open XML SDK |
| Spreadsheet dimensions | Edited pixel widths use the maximum-digit-width formula; untouched precision and hidden/grouped/widthless column metadata are retained. | Authored width/property cases and three export cycles |
| Presentation text | Imported mixed rich text, whitespace, hard breaks and body properties survive; explicit font/color/geometry edits and multiline paragraph replacement export correctly. | Native deck, rich-text fixture and independent script oracle |
| Presentation structure | Chart-frame transforms, transition durations and axis identifiers validate; templates, notes, owned media and live chart formulas remain linked. | Native package checks and external schema gate |
| Editor painting | A replaced viewport receives layout before painting, avoiding blank later pages. | Reviewed first/even/default header/footer page PNGs before/after save |
| CrispCloud save state | Edits made while an asynchronous upload is pending remain dirty. A successful earlier upload cannot close a newer edit; selection-only changes and retry behavior are distinguished. | Four real editor-dialog widget cases and captured upload bytes |
| CrispCloud preview | Explicit false formatting, tabs/breaks, note references/bodies and workbook order/names are respected, including relocated and package-root parts. | Independently authored ZIP/XML preview tests and localization tests |
| Test completeness | Missing whole scenarios, wrong filenames, stale unexpected outputs, empty ZIPs and incomplete cycle groups cannot silently pass. | Authored exact manifest, negative controls, SHA receipts and renderer controls |

The source's original footnote/full-page golden is retained. Three additional
reviewed page PNGs cover first-page, even-page and default header/footer images,
columns and explicit page breaks. Tests require real image-colored pixels before
capturing or comparing a golden and use the same expected image before and after
an asynchronous save. Flutter is pinned to 3.44.0 on Linux for these comparisons.

## Evidence gates

The source workflow runs full engine and editor tests, the portable scripted
corpus, all semantic oracles and fresh VM coverage. Its external steps use the
Open XML SDK and LibreOffice/Poppler. The renderer retains PDF files and every
page PNG; comparisons use decoded RGB bytes and normalized extracted text,
with numeric page ordering and complete cycle groups. Where a separate source
or edited baseline exists, it participates in the comparison.

The app workflow uses Flutter 3.47.8 and its native test dependencies. It checks
the vendor manifest, runs the same portable corpus and the actual host tests,
collects Office-host LCOV, and retains cloud-upload bytes. The host section and
multiline-text cases add three save/reopen exports each. The schema gate checks
the exact actual-host inventory before validating the downloaded evidence.

Feature matrix from the oracle branch (`feature/office-fidelity-oracles`):

| Feature | Import / unchanged export | Modification / history | Independent evidence |
| --- | --- | --- | --- |
| Headings/styles | Heading1 and custom styles | Heading level, custom style, undo | XML snapshot and PNG |
| Paragraph/run formatting | Defaults, highlight and spacing | Alignment, spacing, font, size, bold | Direct-value assertions; host ordering checks |
| Footnotes/endnotes | IDs, bodies, owned links, mixed notes | Add/edit/delete, caret, formatting, split, undo/redo | ZIP/XML oracle and visible notes |
| Pictures | Bytes, relationship and dimensions | Resize and replace; failed-script protection | Independent decoded-pixel hash, dimensions and PNG |
| Lists | Imported definition and label | Imported IDs, new lists, levels, undo/redo | Numbering snapshot, visible labels and collision fixture |
| Tables | Cell text and appearance | Style ID and border properties | XML text, assertions and PNG |
| Header/footer | Owned links and footer text | Existing host header-edit test | Relationship-aware snapshot and PNG |
| Opaque package/body content | Custom XML and altChunk wrapper/HTML retention | Clone and unrelated edits | Byte hash, XML order and owning relationship |
| XLSX | Cells, formulas, styles, links, pivots, charts, freeze/merge | Cell/style edits, live chart updates, new pivots and reorder | Authored JSON plus openpyxl fixture and relationship oracle |
| PPTX | Text, geometry, templates, images/charts, notes | Text, geometry, charts, notes, transitions/animations and reorder | Authored XML plus python-pptx fixture, decoded pixels and template hashes |
| Async host save | Reopen controller output | Existing host minimal-edit/format tests | Python checks the actual saved DOCX |

The core matrix produces 18 exports (three unchanged and three edited cycles
per format). The expanded run produces **65 Office files**, including rich notes,
styles/toggles, native spreadsheets/decks, new pivots, image replacement, opaque
body XML, a script example, layout cases and the async editor save. Independent
semantic/package oracles check 52 files; page goldens and external checks cover
the additional rendering and integration cases.

### Verified checkpoints

- Source `2bd870f4`: full engine **562 passed**, one existing optional-fixture
  skip; full editor **230 passed**, one existing optional-fixture skip.
- Its portable suite: **102 focused Dart tests**, **57 Python controls**, all
  **43 operations** exercised, exact **95-file engine inventory** complete.
- Its external schema snapshot: **97 packages validated, zero errors**,
  including the 95 engine outputs and two actual editor documents.
- Preview regressions: **24 passed** with the package-root routing followup.
- Engine analysis: no errors or warnings; three pre-existing informational
  lints remain in reports/PDF/test code.

### Oracle-branch checkpoint (`a79b7d8`, before merging this continuation)

- Full engine suite: **509 passed, 1 existing optional-fixture skip**.
- Full editor suite: **233 passed, 1 existing optional-fixture skip**, with twelve
  reviewed PNGs tested before and after export and explicit page counts.
- Independent Python oracle self-tests: **9 passed**, including deliberate
  corruption and image/dimension negative controls.
- CrispCloud root host integration: **16 passed locally against the latest pin**,
  using GCC and system SQLite with temporary compiler discovery restored after
  the run. The independent oracle also verified the actual controller export.
  GitHub CI passed at `98fa6b6`; latest-pin CI remains queued. CI installs
  clang/SQLite and uses Flutter 3.47.8; the fork pins 3.44.0.
- Analysis: no errors or warnings; three pre-existing informational lints remain
  in reports/PDF code and an Arabic PDF test.
- Engine execution coverage: **39,247 / 49,130 instrumented lines (79.9%)**.
  [The JSON inventory](office-coverage-gaps.json) lists every unhit line in 216
  instrumented files and 10 files absent from instrumentation. The denominator
  excludes those 10 files and does not measure branch coverage.

Coverage was collected from a fresh directory after the final engine source
change. Schema and render reports include SHA-256 hashes of each checked input.
The source revision for this evidence is `a79b7d8`.

### External checks and remaining boundaries (oracle branch)

The Open XML SDK 3.3.0 validator ran Office 2019 schema/semantic checks over
**all 65 exported files with zero errors**. Positive and deliberately invalid
controls also passed. [The schema report](office-schema-evidence.json) records
each validated file; no errors were suppressed. A separate check of 57 exports
produced by CrispCloud’s toolchain, including its actual host save, also returned
zero errors; [the app report](https://github.com/CrispStrobe/CrispCloud/blob/feature/office-fidelity-oracles/docs/office-schema-evidence.json) pins those inputs.

External validation exposed and closed missing PPTX masters/notes size, wrong
transition/transform namespaces, axis-ID range/collision problems, duplicate
worksheet drawing relationships, invalid pivot metadata, and Excel font/Word
style child-order errors. It also corrected missing required attributes in the
authored style fixture. FID-006's schema/rendering gate is now exercised locally;
GitHub repeats it automatically on the same runner as the full tests.

LibreOffice Writer/Calc/Impress opens the corpus, exports PDFs, and compares text
and rendered page pixels across repeated save cycles. The final run passed
**all 65 files and 22 cycle groups**, including tall-table and inherited toggle
cases.
[The committed render report](office-render-evidence.json) records text, page
counts and pixel hashes. The workflow publishes PDFs and
machine-readable reports alongside all source-engine evidence.

The original FID-001 through FID-007 concrete cases are covered by
the regression matrix above. FID-008's named image/script/opaque-body cases are
covered; its broader coverage inventory remains a test backlog, not evidence
that every unhit line is defective. In particular:

- Opaque Word body elements are preserved for external consumers; the editor
  does not render/edit every unknown element or nested extension.
- The style matrix covers defaults, basedOn, themes, character styles and tested
  table regions. It does not certify every conditional table-style region.
- Native chart/pivot tests cover the declared single-series scenarios; they do
  not certify every chart type, multi-series edit, pivot layout or cache feature.
- PDF/report/formula modules retain unhit lines listed in the coverage inventory.
- Goldens use one pinned Linux/Flutter/font environment. Word/Excel/PowerPoint
  desktop automation and cross-platform pixel equivalence have not been run.

An unhit line is not proof of a bug; an executed line is not proof of correctness.
Keep semantic expectations and these limits visible as the corpus grows.

Coverage is collected from a fresh directory, and the report records source
hashes as well as uncovered lines. Instrumented-line percentages exclude
unloaded/uninstrumented files and do not measure branch correctness.

## Remaining acceptance boundaries

The ledger distinguishes unsupported behavior from tested preservation. In
particular, SDT/content-control wrappers and multiple/cross-paragraph bookmark
ranges need richer editable models. The final audit includes reproducible probes
for these gaps. A retained embedded external-content payload also does not mean
the editor renders or converts that payload.

Column conversion currently defaults to a maximum-digit-width of 7; automatic
measurement of arbitrary imported normal-style fonts is not implemented. The
script refuses referenced sheet renames and slide reorders requiring section
rewrites. Additional OS/font/SDK goldens and arbitrary RTL/layout combinations
remain outside the reviewed visual corpus.

LibreOffice save-cycle stability and Open XML SDK validity are separate from
Microsoft Office visual equivalence and native application certification. The
exact execution-gap inventory remains a work list, not a claim that executed
lines are correct or that every unhit line is defective.

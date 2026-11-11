# Office fidelity audit — 2026-11-11

Baseline: `crispcloud` at `c965500`. CrispCloud integration baseline: `main` at
`05de9cf`. Work is checkpointed on `feature/office-fidelity-oracles` in both
repositories; base branches are unchanged.

CrispCloud uses local path overrides for vendored engine/editor packages, so a
fork-only fix would not update the app. Shared fixes, fixtures, scripts and tests
are also copied into CrispCloud. Its `tool/office_fidelity_manifest.json` pins
the source revision and hashes shared files; unrelated vendor changes remain.

## Gaps found and closed

| Gap | Resulting behavior | Regression evidence |
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

## Corpus and feature matrix

Expected values come from authored XML/JSON, not from blessing serializer output.
Python reads exported ZIP/XML directly. Negative tests prove that the oracle
rejects deliberately damaged fixtures. Normal checks never regenerate goldens.

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

See [the runnable guide](../packages/quds_office_engine/tool/fidelity/README.md)
for command syntax, operation fields, golden maintenance and output locations.

## Verification

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

## External checks and remaining boundaries

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

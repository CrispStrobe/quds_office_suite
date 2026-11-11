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

## Corpus and feature matrix

Expected values come from authored XML/JSON, not from blessing serializer output.
Python reads exported ZIP/XML directly. Negative tests prove that the oracle
rejects deliberately damaged fixtures. Normal checks never regenerate goldens.

| Feature | Import / unchanged export | Modification / history | Independent evidence |
| --- | --- | --- | --- |
| Headings/styles | Heading1 and custom styles | Heading level, custom style, undo | XML snapshot and PNG |
| Paragraph/run formatting | Defaults, highlight and spacing | Alignment, spacing, font, size, bold | Direct-value assertions; host ordering checks |
| Footnotes/endnotes | IDs, bodies, owned links, mixed notes | Add/edit/delete, caret, formatting, split, undo/redo | ZIP/XML oracle and visible notes |
| Pictures | Bytes, relationship and dimensions | Resize; replacement CLI provided | Hash/dimensions and visible pixels |
| Lists | Imported definition and label | Apply imported list style | Numbering snapshot and PNG |
| Tables | Cell text and appearance | Style ID and border properties | XML text, assertions and PNG |
| Header/footer | Owned links and footer text | Existing host header-edit test | Relationship-aware snapshot and PNG |
| Opaque package parts | Custom XML retention | Unrelated edits | Byte hash |
| XLSX | Numbers, string, boolean, formula/cache, merge, frozen row | Cell edit and formula recalculation | Authored JSON vs exported XML |
| PPTX | Shape text and geometry | Text, position and size | Authored JSON vs exported XML |
| Async host save | Reopen controller output | Existing host minimal-edit/format tests | Python checks the actual saved DOCX |

Each format produces three unchanged and three edited save/reopen exports:
**18 exports** total. The CLI adds a separate multi-feature DOCX edit example.
Editor and app tests add an actual asynchronous-save DOCX.

See [the runnable guide](../packages/quds_office_engine/tool/fidelity/README.md)
for command syntax, operation fields, golden maintenance and output locations.

## Verification

- Full engine suite: **478 passed, 1 existing optional-fixture skip**.
- Full editor suite: **228 passed, 1 existing optional-fixture skip**, including
  the reviewed full-page before/after PNG.
- Independent Python oracle tests: **8 passed**. Scenario exports match all
  semantic goldens and package checks.
- CrispCloud root host integration: **15 passed** in GitHub CI, plus the shared
  corpus and vendor hash guard. CI installs its native compiler/SQLite
  dependencies and uses Flutter 3.47.8. The fork pins Flutter 3.44.0 for the PNG.
- Engine analysis: no errors/warnings; three pre-existing informational lints
  remain in reports/PDF code and an Arabic PDF test.
- Engine execution coverage: **37,937 / 47,807 instrumented lines (79.4%)**.
  [The JSON inventory](office-coverage-gaps.json) lists every unhit line in 211
  instrumented files, and 10 files absent from instrumentation. The denominator
  excludes those 10 files and is not branch coverage.

Coverage was collected from a fresh directory after the final source change.
GitHub workflow artifacts retain exports, oracle reports, coverage and image
failure diffs. An earlier CI invocation failed on an unsupported analyzer flag;
the workflow now uses the supported `dart analyze` command.

## Open gaps

The regressions above are fixed. This is not exhaustive Office-format support
or interoperability certification. Remaining gaps are explicit:

| ID | Gap | Next acceptance check |
| --- | --- | --- |
| FID-001 | Footnote placement does not reflow dense body text or continue an oversized footnote | `_attachNotes` runs after body pagination; add dense multi-page fixtures and assert no body/note overlap |
| FID-002 | Note overlays lack complete rich-run styling, wrapping, drawings and tables | Shape and paginate rich note content; add long/rich-note visual fixtures |
| FID-003 | Source style preservation is broader than implemented character/table style editing and cascade | Effective-style fixtures for basedOn/theme/character/table combinations |
| FID-004 | List-type commands use built-in IDs that can collide with imported numId 1/2 | Collision fixtures and document-local definition allocation |
| FID-005 | Independent sheet/slide corpus is smaller than DOCX | External fixtures for sheet styles/charts/pivots and slide masters/themes/notes/animations |
| FID-006 | No external Word/LibreOffice rendering or full XSD validation performed | Open/export corpus in external engines and compare rendered output/schema results |
| FID-007 | One visual fixture on one platform/SDK | Expand RTL/Arabic, columns, sections, long documents and page breaks |
| FID-008 | Untested branches/features beyond this corpus | Use exact coverage inventory; imageReplace, arbitrary unsupported body XML and many PDF/report/formula branches need stronger oracles |

An unhit line is not proof of a bug; an executed line is not proof of correct
behavior. Keep both semantic expectations and this gap list as the suite grows.

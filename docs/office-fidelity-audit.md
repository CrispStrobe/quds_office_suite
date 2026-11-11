# Office fidelity audit — 2026-11-11

Work is checkpointed on `feature/office-fidelity-completion-20261111` in
[CrispStrobe/quds_office_suite](https://github.com/CrispStrobe/quds_office_suite/tree/feature/office-fidelity-completion-20261111)
and [CrispStrobe/CrispCloud](https://github.com/CrispStrobe/CrispCloud/tree/feature/office-fidelity-completion-20261111).
The base branches have not been changed by this work.

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

Final followup results, source hashes, coverage totals and renderer counts are
recorded below when the new preservation cases and host integration complete.
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

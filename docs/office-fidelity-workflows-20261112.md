# Office workflow and evidence follow-up

Recovered from workflow branch commit `b1bb296` during the expansion integration.
The counts and source pins below describe that historical run; the merged
expansion requires its own current inventories and acceptance receipts.

## Source relationship

The requested `crispcloud` branch is at `c9655003f14c87ec0c11d481341126ebb08a1419`.
It is an ancestor of the suite's `main` revision
`54f0f8de01416640560519aa9d732f668f603709`, which already contains the
import/edit/export scripting harness, independent package oracles, mutation
controls, output inventories, reviewed Linux Flutter goldens and external
schema/render gates. This follow-up preserves that work on
`feature/office-fidelity-workflows-20261112`.

CrispCloud initially pins suite revision
`84b11839126a9577b6688b6acf80edd3cc2601ee` through 237 selected files. Its
corresponding feature branch now pins
`3e4502152d4b6c99d164f621b5271ba4b0a7ec71` and verifies all 378 selected
shared files. The app's path dependencies need this explicit synchronization;
changes to the suite branch alone cannot update it. Later evidence-only suite
commits do not require a new implementation pin.

## Reproduced gaps in this follow-up

| Area | Finding | Work and acceptance |
| --- | --- | --- |
| Coverage provenance | A same-length source edit could be assigned stale VM hits because source hashing happened only when reporting | The collector records inputs before execution, seals only successful runs, and verifies exact source/output hashes when reporting |
| Merged-table scripts | Physical cell indexes and logical grid columns were ambiguous for horizontally/vertically merged cells | `gridColumn` resolves spans and vertical continuations to the content owner; invalid topology rejects before edits |
| Native table widths | Cell preferred widths disappeared, and namespace capture could overwrite the native width attribute | Retain `dxa`/`pct`/`auto`/`nil` metadata; update widths for explicit edits and merge/unmerge; match namespace declarations by qualified name |
| Actual host font dialog | Opening and applying the dialog could round imported sizes, flatten mixed formatting and replace complex-script fonts | Preserve unchanged values and apply only explicitly requested properties; 17 real-dialog tests and 30 required exports |
| Picture insertion and history | Fixed dimensions stretched images, stale pickers changed new targets, and drawing undo used the currently selected slide | Proportional bounded insertion, original-target checks and original-slide history; 20 host tests and 30 required exports |
| Coverage and workflow selection | Stale artifacts could obscure missing producers, and feature commands needed manual assembly | Source-bound collection and a strict 15-area producer/oracle matrix with selected-output cleanup and receipts |
| Narrow-cell rendering | Visual review found long words clipped in new nested-table scenes | Emergency wrapping in fixed containers preserves whole graphemes and grows rows; 41 focused regressions and four reviewed PNGs |
| Unicode boundaries | Existing hand-written grapheme tables split Indic conjuncts and other extended clusters | Use the pure-Dart Unicode 16 `characters` implementation, with 17 additional script/spacing regressions and unchanged reviewed goldens |

The full format-support ledger remains
[`office-fidelity-gaps.json`](office-fidelity-gaps.json); these bounded fixes do
not imply complete OOXML, branch, platform or Microsoft Office visual coverage.

## Source-bound coverage collection

Resolve dependencies before collection. In `packages/quds_office_engine`:

```sh
python3 tool/fidelity/collect_coverage.py coverage/vm
python3 tool/fidelity/coverage_report.py coverage/vm --require-receipt
```

Choose a fresh directory for every run. The collector never deletes or reuses an
existing directory. It hashes engine sources, tests and fixtures, scenario
tools, imported Dart examples, sibling font assets and available dependency
resolution files before starting the test process. It records the Dart version,
executable hash, exact arguments and exit status. A failed or interrupted run,
changed input, missing coverage, or replaced/extra output cannot produce a
verified report. Concurrent implementation edits intentionally invalidate a
collection.

## Feature-driven scripts

The existing strict CLI supports `operations`, `inspect`, `export`, `modify`
and `roundtrip` for DOCX/XLSX/PPTX. Its operation catalog contains 67 named
operations, each linked to an executable scenario. A stronger catalog audit
rejects empty, malformed, incomplete or duplicated catalogs. This is operation
presence coverage, not exhaustive parameter or format coverage.

From `packages/quds_office_engine`:

```sh
dart run tool/fidelity/office_steps.dart inspect input.docx
dart run tool/fidelity/office_steps.dart modify input.docx steps.json edited.docx
dart run tool/fidelity/office_steps.dart roundtrip edited.docx build/my-document 3
python3 tool/fidelity/feature_matrix.py list
python3 tool/fidelity/feature_matrix.py plan footnotes headings tables
python3 tool/fidelity/feature_matrix.py run styles references
```

The matrix exposes footnotes, endnotes, headings, styles, paragraphs, images,
tables, TOCs, textflow, placement, drawings, references, comments, spreadsheets
and slides. It connects those 15 areas to 19 producer/oracle bundles and lists
the pinned editor golden commands separately. The complete matrix run from a
clean inventory passed 565 Dart tests, three additional Dart producers,
19 independent package oracles and 205 Python mutation controls. All 214
selected Office packages were freshly regenerated and verified across 38
successful commands. Full acceptance separately requires all 305 engine and
22 editor packages.

## Independent table acceptance

`table-grid-{format,replace,unmerge}.json` exercises logical merged-cell
selection, formatting, replacement and unmerge against native source XML.
Independent authored XML specifies each expected phase. The 28-package corpus
contains source and edited baselines plus eight three-save direct/isolate
series. The XML oracle checks text, exact native width units/values, rich run
formatting, logical grids, merge ownership, nested tables and bookmarks.
Controls deliberately corrupt 18 properties and remove each required file.

The focused Open XML SDK run accepted all 28 packages with zero errors. The
independent LibreOffice/Poppler run rendered all 28 packages, matched all eight
first-save series to their authored baselines and accepted all eight repeated
save groups without failures. Four additional Quds PNGs were reviewed; their initial review exposed and led
to the narrow-cell rendering correction above. The new images retain all
characters and expand the row. With no supplied font the existing fallback
metrics wrap conservatively; these snapshots do not establish native line-break
equivalence. Native acceptance
does not certify Quds canvas layout or Microsoft Word rendering equivalence.

Native percentage/automatic/nil preferred widths are preserved metadata. The
canvas uses the logical table grid; it does not resolve all auto-fit policies.
Full table-property revision history and arbitrary incomplete-grid geometry
remain outside this correction.

Historical coverage can still be inspected with `--allow-unverified`; those
reports explicitly mark collection provenance as unverified. Runtime dependency
contents and the operating system are not hermetically sealed. A verified
collection proves the identity of the measured source and outputs, not that
every executed line is correct or that every branch was tested.

The collector and reporter controls include same-length source edits, fixture
and lockfile changes, failed child processes, stale/missing/replaced coverage,
unsafe destinations and malformed VM records. CI now requires the receipt.


## Picture-only native evidence

The twelve actual-host slide picture exports contain no text. Native acceptance
requires an independently prescribed page size and black rectangle, its position,
size, area, solid interior, grayscale color and white exterior. It also checks
raw native transforms, because a picture extending past the page edge could
otherwise look correct after clipping. All twelve real exports pass, as do all
four repeated-save groups and 49 renderer control tests. Other text-free files
are not accepted through this precise corpus rule. The app workflow now renders
its exact downloaded host inventory after schema validation, retaining PDFs,
PNGs and measured pixel receipts.

## Measured acceptance and remaining gaps

The [retained execution evidence](evidence/office-fidelity-workflows-20261112/README.md)
identifies exact source revisions, runtime versions, successful collection
receipts, package hashes and original logs. The final engine collection passed
1,425 tests with one existing font-fallback skip. The editor passed 452 tests
with one existing author-local PDF skip, including all 27 committed PNG
goldens. The full portable gate passed 963 Dart tests and 389 Python controls,
verified all 67 operation scenarios and required all 305 engine exports.
The separate feature run is a selected subset; these test counts must not be
added together as unique tests.

Engine line execution is 44,326 of 53,898 instrumented lines (82.2%), leaving
9,572 unhit lines and ten files absent from instrumentation. The app's actual
host gate passed 154 Flutter tests across 21 files, plus 31 provenance,
12 artifact and seven synchronization controls. Its scoped Office line
execution is 2,540 of 3,782 lines (67.2%): all ten scoped files were
instrumented, with 1,242 unhit lines. The app independently ran the vendored
portable corpus and required 104 host exports.

Open XML SDK accepted all 327 suite packages and all 409 app packages with
zero validation errors. These are separate generated package instances,
including each repository's 305 engine outputs. Native rendering has its own
reports and qualifications; schema acceptance alone is not a visual result.

The ledger contains 94 tracked findings: 80 closed within their stated scope,
seven partial, six open and one explicitly guarded operation. Remaining work
includes broader platform/font rendering, branch and unhit-line coverage,
arbitrary content-control bindings, mixed bookmark/range topology, general
spreadsheet formulas and font metrics, complex field refresh, overlapping
tracked changes, full floating/wrapping geometry, and additional actual-host
authoring controls. Seven qualified native auxiliary-comment documents have
schema-only acceptance, without visual certification. Microsoft Office native
rendering equivalence remains unverified.

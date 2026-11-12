# Worksheet-qualified defined names (FID-027 expansion)

The independent native fixture reproduces three defects in the previous
implementation: imported worksheet scope was discarded, explicit worksheet
qualification was rejected, and scalar defined names were not imported. The
red checkpoint records three expected failing tests and one passing cache
preservation control. Implementation checkpoint `ecdbab2` passes the 152-test
formula/cache/rename cohort and the sheet analyzer.

## Supported semantics

The workbook retains `localSheetId` as a zero-based worksheet index. It is not
the OOXML `sheetId`: the fixture deliberately uses worksheet IDs 41, 7 and 99.
Unqualified names select a local definition on the formula's own worksheet
before the workbook definition. Explicit `Sheet!Name` selects that worksheet's
local definition, even when the definition targets a different worksheet.
Names and worksheet names compare case-insensitively. Quoted worksheet names,
escaped apostrophes, underscores, periods and Unicode name characters are
covered by the fixture.

Supported definitions are absolute in-workbook cell/range references and
numeric, Boolean, quoted-string or native-error scalar literals. An ordinary
string such as `"#REF!"` remains text; an actual `#REF!` definition remains an
error. Unsupported evaluation has separate provenance from a real `#NAME?`
error, so the former retains an authored cache and the latter recalculates as
an actual error.

The dependency graph uses the same scope resolver as evaluation. Named range
endpoints and subsequent edits trigger dependency-order calculation. Every
member of a cycle is marked before consulting old numeric caches. Formula
cells evaluated lazily use their own worksheet scope and separate LET
bindings. Local LET bindings are also excluded from name dependencies.

The model retains scalar and opaque definitions separately from editable
absolute ranges. Native name metadata, local scope, unsupported definitions,
and external owner text survive save and range-list rebuild. Sheet rename
updates modeled definitions and native owners together; undo/redo and three
direct/isolate saves exercise this boundary.

## Explicit limits

Explicit worksheet qualification without a matching worksheet-local name
remains unsupported. The primary guidance establishes local qualification,
but does not establish a global fallback for that syntax; the engine therefore
keeps the authored typed cache instead of guessing. Computed/alias definitions,
relative references, external workbooks, 3D references, whole-row/column
references and dynamic OFFSET from scoped names also retain authored caches.
An unsupported local definition still shadows a global definition. It cannot
fall through to the global value or be silently ignored by SUM as zero.

Primary semantic sources:

- [Microsoft: Names in formulas](https://support.microsoft.com/en-us/excel/names-in-formulas)
- [MS-OE376: definedName and localSheetId](https://learn.microsoft.com/en-us/openspecs/office_standards/ms-oe376/ddfb7406-8921-4540-a4ed-8516b3d7d583)
- [MS-XLSX: formula grammar](https://learn.microsoft.com/en-us/openspecs/office_standards/ms-xlsx/3d025add-118d-4413-9856-ab65712ec1b0)

## Independent evidence

The new Python oracle checks 120 typed cache outcomes across six exported
workbooks, together with formulas, name definitions, scope and metadata. Its
14 tests include an independently authored valid package and mutation controls
for stale caches, wrong scope, lost metadata, error/text/Boolean confusion,
unsupported results coerced to zero, external cache changes and stale rename
qualifiers. The current sheet-rename oracle has 19 tests; the added mutation
control rejects stale D10=42 now that its qualified name correctly evaluates
to 2. Other historical cell classifications remain unchanged. Historical
fixtures and 42-cell receipts were not edited.

The external receipt binds ten exact inputs to Open XML SDK validation and
LibreOffice 24.2.7.2 rendering: the original seven-file cohort and three
independently authored reference files. All ten pass schema validation and
render into 29 pages. All six new exports match their corresponding authored
references in page count, extracted text and decoded pixels, without masking,
normalization or tolerance. Both three-save groups are stable. Original and
snapshot hashes were checked before and after comparison. `native-proof.tar.gz`
contains those frozen inputs, reports, PDFs and page images; its digest is in
`native-proof.json`.

After this focused acceptance, the same independent reference bytes were
promoted to permanent engine fixtures and added to the producers so aggregate
CI can require the comparisons on every run. The final new cohort has nine
files and the existing rename cohort has five. A 69-test producer rerun and
both current Python oracles pass after those additions. The aggregate source
gate is responsible for binding its own final commit and fresh produced bytes.

## Mandatory producer/oracle inputs

All commands below run from `packages/quds_office_engine`.

```sh
dart test test/sheet_qualified_names_test.dart test/sheet_rename_fidelity_test.dart
python3 tool/fidelity/sheet_qualified_names_oracle.py
python3 tool/fidelity/sheet_rename_oracle.py
python3 -m unittest discover -s tool/fidelity -p test_sheet_qualified_names_oracle.py -v
python3 -m unittest discover -s tool/fidelity -p test_sheet_rename_oracle.py -v
```

Independent expected fixtures can be reproduced without Quds evaluation:

```sh
python3 tool/fidelity/sheet_qualified_names_oracle.py --write-expected test/fixtures/fidelity
```

| Producer output | Independent baseline copied by producer |
| --- | --- |
| `fidelity-sheet-qualified-names/recalculated-{1,2,3}.xlsx` | `fidelity-sheet-qualified-names/expected-recalculated.xlsx` |
| `fidelity-sheet-qualified-names/renamed-{1,2,3}.xlsx` | `fidelity-sheet-qualified-names/expected-renamed.xlsx` |
| `fidelity-sheet-rename/renamed-{1,2,3}.xlsx` | `fidelity-sheet-rename/qualified-expected.xlsx` |

The new cohort also contains `source.xlsx`. The legacy rename cohort retains
its own unchanged `source.xlsx`. Producer source files are
`sheet_qualified_names_test.dart` and `sheet_rename_fidelity_test.dart`.

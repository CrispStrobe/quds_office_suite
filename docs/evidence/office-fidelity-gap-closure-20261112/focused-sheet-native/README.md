# Focused native Sheet rename receipt

This checkpoint validates the four FID-027 packages whose exact byte hashes
appear in `input-manifest.json`. All four pass the Open XML SDK and render as
two pages each. Each of the three saved packages matches an independently
authored expected native package on page count, complete extracted text, and
every RGB page fingerprint. The original source's first page also matches
exactly, and all three save cycles are identical.

The reference was constructed from the **original committed source fixture**;
production exports were not inputs to its construction. The generator changes
only the declared sheet name/reference owners and the five cache results below.
`property-change-proof.json` records exactly **34 scalar XML changes across four
parts**, unchanged XML structure, and byte-identical contents for every other
ZIP member. `expectation-spec.json` states the complete reference contract.

| Cell | Expected cached result | Reason |
| --- | --- | --- |
| D1 | Numeric `2` | Supported local reference recalculation |
| D2 | Numeric `5` | Supported local reference recalculation |
| D8 | String `Data!A1 "quoted"`, type `str` | Correct string result, including escaped quotes |
| D13 | Error `#REF!`, type `e` | `INDIRECT("Data!B2")` intentionally retains its string literal |
| D14 | Numeric `4` | Supported `2 + 2` recalculation |

The other nine D1:D14 caches remain numeric `42`, including unsupported
external, three-dimensional, structured, name, whole-row, and whole-column
references. The classified receipt checks all 14 cells in each of three saves:
**42 exact formula/cache/type checks**. Numerically equivalent spellings such as
`42` and `42.0` compare exactly with `Decimal`; no rounding tolerance is used.

This is an **expected-result comparison**, not a claim that the renamed workbook
is visually identical to the original. No pixel masks, image thresholds, or text
normalization are used. A control run against the earlier defective exports
rejects their incorrect caches/types and all three complete native renders.
FID-027 remains partial for unsupported evaluation and opaque formula forms.

## Reproduction and evidence

The exact scripts are `reproduce/author_expected_native.py` and
`reproduce/compare_native.py`. The first takes the original fixture path and an
output `.xlsx` path. The second takes a fresh four-file proof directory, the
independent reference directory, and `tool/office-validation/render.py`.
Generate fresh SDK path/SHA receipts and native render records before comparing;
`command-results.json` records the actual validation commands. The reference's
`render/render-record.json` contains the direct `render.render_document` result
and input SHA, while the four-file corpus uses the renderer's normal CLI report.

The renderer provenance identifies official LibreOffice **24.2.7.2**, its
unchanged task-local LibreOfficeKit adapter, and the exact tool hashes. Raw
receipts retain their original paths; `archive-manifest.json` verifies the
archived copies without rewriting those receipts. Full XLSX/PDF/PNG artifacts
remain outside Git in the recorded validation directories.

This focused checkpoint predates later source refinements and does not replace
the final integrated source gate. Its claim applies to the exact recorded inputs
and producer file hashes.

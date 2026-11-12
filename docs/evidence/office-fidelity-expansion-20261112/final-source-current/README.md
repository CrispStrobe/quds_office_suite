# Current final source acceptance

All required local source gates passed at implementation commit
`1d19150ff35e95374fa3c11e0b6a43d187d24024`, tree
`086bb6960d04c406fc486f57699a3822c1d9117e`. This fresh run includes the shared renderer correction
for the schema-valid authored host picture-bounds slide: 100 by 72 points with
picture rectangle (10, 7.2, 90, 45). The detached validation checkout and all
947 tracked source-file fingerprints remained unchanged.

The [earlier full acceptance](../final-source/README.md) at `2d6529e` remains
unchanged. Current receipts identify the corrected pin explicitly; later
documentation and receipt commits preserve the accepted implementation.

| Gate | Result |
| --- | --- |
| Engine analyzer | Passed |
| Full engine suite | 1,610 passed; 1 existing font-availability skip |
| Mandatory fidelity cohort | 1,147 passed; no skips |
| Python fidelity controls | 436 passed |
| Named feature workflows | All 15 passed; 22 bundles, 44 commands, 236 fresh selected files |
| Editor analyzer | Passed |
| Full editor suite and reviewed goldens | 521 passed; 1 existing developer-local PDF skip |
| Engine/editor output inventories | Exactly 346 + 29 files |
| Open XML SDK | All 375 packages passed with matching byte receipts |
| Renderer controls | 56 passed |
| Native rendering | 368 files, 687 pages; 7 existing explicit qualifications |
| Native repeated-save comparisons | 109 groups passed |
| Independent native baseline comparisons | 47 passed |
| Native page-order comparisons | 10 passed |

The page-order comparisons are also included in the baseline comparison count.
Fresh engine coverage is **45,186 / 54,575
instrumented lines (82.80%)**. The verified collector bound
123 VM coverage files to 599
source/configuration inputs and the pinned runtime. Word coverage is
9,681/11,364;
sheet 4,251/5,023;
slide 2,182/2,541.
These line measurements have a narrower scope than branch coverage or universal
Office fidelity.

The font skip reports that the available Latin face already covers Arabic, so a
distinct third PDF font resource cannot be forced. The editor skip is an existing
comparison tool requiring a developer-local PDF. Both diagnostics are retained
in the aggregate summary and complete suite logs.

The seven `fidelity-aux-controls` documents retain the existing qualification:
LibreOffice rejects a native block content control in a comment. Their native XML
oracles and exact SDK receipts pass; they have no native visual certification.
Every new expansion corpus is covered by the native gate. All six new
qualified-name exports, all six engine/editor bookmark-copy exports, the three
existing renamed-sheet exports, and all six grouped slides must match their
explicit independent references.

## Receipt chain

- [Aggregate summary](summary.json) contains exact counts, skip diagnostics,
  qualifications and hashes of producer and external receipts.
- [Engine acceptance](engine/acceptance.json), [collection receipt](engine/collection-receipt.json),
  [coverage report](engine/coverage-gaps.json) and [feature workflows](engine/feature-workflows.json)
  bind the successful run to its input bytes.
- [Editor acceptance](editor/acceptance.json) requires the matching passed engine
  receipt before running the editor oracles.
- [External summary](external/acceptance-summary.json), [schema report](external/schema-report.json)
  and [native report](external/render/render-report.json) account for every exact
  input, including the seven qualified files.
- [Renderer provenance](external/renderer-provenance.json) and
  [validator provenance](external/schema-validator-provenance.json) record the
  frozen native adapter and independently compiled validator.
- [Raw coverage provenance](engine/raw-coverage-provenance.json) preserves the
  generated VM archive fingerprint. Its original payload remains a reproducible
  external build artifact alongside exported packages, PDFs and PNGs.
- [Remote CI observation](remote-ci-observation.json) and its
  [compressed API/config evidence](remote-ci-raw.json.gz) preserve the separate
  timestamped GitHub observations. Source jobs were cancelled before steps ran,
  with an unknown cancellation reason; host jobs were queued at that observation.
  No completed remote green result is established by those observations.
- [Artifact hashes](artifact-hashes.json) identify the committed evidence. Logs
  are compressed without changing their contents; original validation paths
  remain in receipts.

Reproduction uses the committed runners in [../runtime](../runtime), Flutter
3.44.0 / Dart 3.12.0, the explicit clean implementation pin, a fresh coverage
directory, and the pinned external runtime. Run engine acceptance before editor
acceptance, then external acceptance with `--expected-count 375`.
The runners reject changed source, stale receipts, missing outputs, mismatched
byte hashes and incomplete native comparisons. They retain reviewed visual
goldens unchanged.

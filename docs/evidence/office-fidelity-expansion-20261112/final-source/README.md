# Final source acceptance

All source gates passed at implementation commit
`2d6529e52f389e8c491ce75331d9efe6bd59a821`, tree
`f8032c89074ecb3ccc5d4bfa36fac359b573b272`. Later receipt/documentation commits do
not change that accepted implementation. The detached validation checkout and
947 tracked source-file fingerprints remained unchanged.

| Gate | Result |
| --- | --- |
| Engine analyzer | Passed |
| Full engine suite | 1,610 passed; one existing font-availability skip |
| Mandatory fidelity cohort | 1,147 passed; no skips |
| Python fidelity controls | 436 passed |
| Named feature workflows | All 15 passed; 22 bundles, 44 commands, 236 fresh selected files |
| Editor analyzer | Passed |
| Full editor suite and reviewed goldens | 521 passed; one existing developer-local PDF skip |
| Engine/editor output inventories | Exactly 346 + 29 files |
| Open XML SDK | All 375 packages passed with matching byte receipts |
| Renderer controls | 54 passed |
| Native rendering | 368 files, 687 pages; seven existing explicit qualifications |
| Native repeated-save comparisons | 109 groups passed |
| Independent native baseline comparisons | 47 passed |
| Native page-order comparisons | 10 passed |

Fresh engine coverage is **45,186 / 54,575 instrumented lines (82.80%)**. The
verified collector bound 123 VM coverage files to 599 source/configuration inputs
and the pinned runtime. Word coverage is 9,681/11,364; sheet 4,251/5,023; slide
2,182/2,541. These are line measurements, not branch coverage or universal Office
fidelity claims.

The font skip reports that the available Latin face already covers Arabic, so a
distinct third PDF font resource cannot be forced. The editor skip is an existing
comparison tool requiring a developer-local PDF. Neither was introduced or
silently suppressed by this expansion.

The seven `fidelity-aux-controls` documents retain the existing qualification:
LibreOffice rejects a native block content control in a comment. Their native XML
oracles and exact SDK receipts pass; they have no native visual certification.
No new expansion corpus is exempted. All six new qualified-name exports, all six
engine/editor bookmark-copy exports, the three existing renamed-sheet exports,
and all six grouped slides must match their explicit independent references.

## Receipt chain

- [Aggregate summary](summary.json) contains exact counts, skip diagnostics,
  qualifications and hashes of the producer and external receipts.
- [Engine acceptance](engine/acceptance.json), [collection receipt](engine/collection-receipt.json),
  [coverage report](engine/coverage-gaps.json) and [feature workflows](engine/feature-workflows.json)
  bind the complete successful run to its input bytes.
- [Editor acceptance](editor/acceptance.json) requires the matching passed engine
  receipt before running the editor oracles.
- [External summary](external/acceptance-summary.json), [schema report](external/schema-report.json)
  and [native report](external/render/render-report.json) account for every exact
  input, including the seven qualified files.
- [Renderer provenance](external/renderer-provenance.json) and
  [validator provenance](external/schema-validator-provenance.json) record the
  frozen native adapter and independently compiled validator.
- [Artifact hashes](artifact-hashes.json) identify the committed evidence. Raw
  logs are compressed without altering their contents. Original validation paths
  remain in the reports; VM payloads, exported packages, PDFs and PNGs are
  reproducible build artifacts.

Reproduction uses the committed runners in [../runtime](../runtime), Flutter
3.44.0 / Dart 3.12.0, the explicit clean implementation pin, a fresh coverage
directory, and the pinned external runtime. Run engine acceptance before editor
acceptance, then external acceptance with `--expected-count 375`. The runners
reject changed source, stale receipts, missing outputs, mismatched byte hashes
and incomplete native comparisons. They do not update visual goldens.

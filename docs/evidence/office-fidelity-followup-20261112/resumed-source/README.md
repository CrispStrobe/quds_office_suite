# Resumed source validation — 12 November 2026

This fresh validation binds to unchanged implementation commit
`7641d9cfa167987216134ebfc4772918cc945d97`. During publication, the interrupted
session's own final report arrived remotely at `83ec9de6c6627eb99ab82a7e6b0cd3d6b3ec9c5f`.
Its `final-source/` receipts and conclusions are preserved. The current run's
receipts are stored separately here and corroborate the same implementation.
This checkpoint changes no production, test, authored expectation or managed
source file.

## Completed source and native gates

| Gate | Current result |
| --- | --- |
| Pinned runtime | Flutter 3.44.0 / Dart 3.12.0 |
| Source analyzers | Complete engine and editor library analyzers pass |
| Full engine suite | 1,384 passed, one existing conditional font skip |
| Mandatory fidelity | 921 passed, no skips; 344 Python controls passed |
| Full editor suite | 478 passed, one existing local-PDF comparison skip |
| Exact inventories | 296 engine exports + 25 editor exports = 321 |
| Independent Open XML SDK | All 321 pass; original, snapshot and validator hashes agree |
| Native LibreOffice 24.2.7.2 | 314 files, 614 pages; 95 save-cycle groups, 32 baselines, 10 page-order checks passed |
| Existing native limitation | Seven comment-content-control files retain schema/native-XML evidence only |
| Renderer control suite | All 41 passed |
| Instrumented engine line coverage | 44,568 / 54,173 (82.27%), from 116 fresh VM coverage files |

The 921 mandatory cases overlap the full engine suite. Line coverage is not
branch completeness. All producer source and tracked-golden fingerprints remain
unchanged. Native comparisons use full text and decoded RGB fingerprints;
no masking, normalization, new exemption or tolerance was added.

`producer-summary.json`, `engine-acceptance.json`, `editor-acceptance.json`,
`external-acceptance.json` and their inventories retain exact hashes and commands.
Receipt paths identify the execution workspace. `schema-acceptance.json` is the
intermediate SDK checkpoint, whose native-pending status is superseded by the
passed final `external-acceptance.json`.

## Focused formula, font, table and tab checks

`focused-followup-summary.json` derives the bounded feature checks from the full
native report. The authored Normal-font source matches all three unchanged saves
and three blank-column-width-edited saves in page count, text and decoded pixels.
The table cases retain separate unchanged and intentionally edited native
baselines. The three actual shared custom-tab editor exports pass repeated-save
comparison; intentionally edited files are not claimed identical to source.

`focused-sheet/classified-native-comparison.json` verifies 42 cell results over
three renamed saves: nine supported numeric recalculations, 27 retained
unsupported formula caches, three exact string results and three intentional
INDIRECT reference errors. All three exports match an independently authored
native expected workbook. The reproducible expected workbook and XML property
change receipt are under `sheet-expected-native/`; its authoring and comparison
sources are the unchanged tracked helpers in the earlier gap-closure evidence.
This distinguishes preserved cached values from evaluated formula errors and
does not expand the supported formula engine.

## Preserved orchestration attempt and skips

`editor-initial-attempt.json` records a missing-engine-corpus failure after the
full editor suite had passed. The historical runner allowed concurrent producers,
but editor bookmark/control oracles also inspect engine exports. After engine
completion, only outstanding editor oracles and inventory checks were resumed,
with the same frozen source fingerprint. `editor-acceptance.json` is the final
passed receipt. The initial failure is retained rather than overwritten.

The engine skip is `wave4_platform_test.dart`'s multi-face PDF resource check:
the available Latin face already covers Arabic. The editor skip requires the
unavailable developer-local `/home/mohammed/Desktop/al_tahreer_profile.pdf`.
Neither is a new Office fidelity regression.

## Logs, limits and reproduction

`logs/` contains lossless gzip copies. `log-manifest.json` records compressed and
original SHA-256 hashes and sizes. The runtime helpers preserve the validation
implementation and runtime provenance; environment files record this session's
installed SDK/cache paths. Adapt those paths when recreating the runtime.
The source library workspace was resolved offline from the preserved cache.

Future runs must complete engine export generation before editor shared-output
oracles. The existing archived follow-up runner already implements that ordering;
historical reports are not replaced by this run's receipts.

Unknown/unloaded spreadsheet fonts keep explicit fallbacks. Logical-grid table
addressing preserves existing physical selectors and guards unsupported topology.
Custom tabs do not add the outstanding style-management UI. Native evidence is
bounded to the authored fixtures and this LibreOffice runtime; it does not claim
arbitrary Microsoft Office equivalence.

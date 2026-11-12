# Legacy DOC parser integration — 2026-11-12

Quds consumes the standalone parser through the pinned workspace package in
`packages/legacy_doc_parser`. The source commit and tree are recorded in that
package's `UPSTREAM.json`. Parser source, tests, fixtures, format references,
licenses, and historical validation evidence are mirrored without local edits.

The only upstream file difference remains `pubspec.yaml`: Quds retains
`resolution: workspace`, `lints: ^6.0.0`, and `xml: ^7.0.1`. Its complete bytes
retain SHA-256
`150af8d89562635bf5a876c0a539c20ae48b58ea3666db071b5e4ebd3addf153`.
The portable parser SDK requirement is unchanged. The integrated branch also
retains Quds main commit `74960237cea7c560f3db7ee96ca37641c4438567` in its ancestry,
including the editor/reports dependency paths, the editor URL-launcher
dependency, and the strict native Word-picture package and raster checks.

## Checkpoint: parser 77b6b1d

Source commit:
[`77b6b1d6b3edc52e314b64043fc2e6d7585fe4d7`](https://github.com/CrispStrobe/legacy-doc-parser/commit/77b6b1d6b3edc52e314b64043fc2e6d7585fe4d7).
The [upstream file receipt](evidence/legacy-doc-parser-integration-20261112/77b6b1d/upstream-files.json)
records the Git blob and SHA-256 of every upstream file. All 288 files other
than the preserved workspace pubspec match the pinned tree byte-for-byte.

The [integration receipt](evidence/legacy-doc-parser-integration-20261112/77b6b1d/summary.json)
records commands, exit codes, log hashes, and these results:

| Check in the Quds workspace | Result |
| --- | --- |
| Complete mirrored parser Dart suite | 571 passed |
| Parser Python oracle/runner tests | 98 passed |
| Complete engine Dart suite | 1,627 passed; one font-dependent skip |
| Engine analysis with `--fatal-infos` | Clean |
| Parser analysis | Exit 0; 214 infos, no warnings or errors |

The skipped engine test reports that the installed Latin font already covers
Arabic, so it cannot force a third font face. The parser infos arise under the
workspace's XML 7 and lints 6 versions; they are retained in the analysis log.
No source suppression or dependency downgrade was added to hide them.

Quds root CI now analyzes and tests the mirrored parser in its existing engine
job. The nested upstream workflow is retained as source material; the root
workflow is the active integration gate.

These checks establish mirror identity and Quds integration behavior. The
parser's native-rendering, round-trip, and SDK evidence retains the source
identity recorded in each upstream receipt. This integration does not promote
historical evidence to a claim of complete Office layout, geometry, table,
comment, or revision fidelity.

## Report-studio CI regressions

The first integration CI run exposed two existing studio test failures. The
[retained CI excerpts](evidence/legacy-doc-parser-integration-20261112/studio-regressions/ci-before.json)
confirm the same assertions failed on the prior `9fb8bf1` checkpoint; the test
and application sources were unchanged by the parser mirror update.

The tests assumed that a bundled template had no variables and printed
without a parameter prompt. The current feature-showcase template contains
three variables and asks for values before printing. The corrected save/open
test checks every pre-existing variable name/value plus the explicitly added
value. The print test now checks cancellation, acceptance of an edited
parameter, saved defaults staying unchanged, remembered runtime answers, and
the PDF's name and page size. It waits for observed print completion through
the existing bounded I/O helper.

No application behavior changed. The [repair receipt](evidence/legacy-doc-parser-integration-20261112/studio-regressions/summary.json)
retains the failing local reproduction and passing follow-up logs: both
focused tests pass, the complete studio suite passes 16 tests with its two
existing opt-in screenshot producers skipped, and studio analysis is clean.

## Checkpoint: parser 53a7f0d

The next mirror pins
[`53a7f0df113f0b88967f7fecd492652ad5c730d5`](https://github.com/CrispStrobe/legacy-doc-parser/commit/53a7f0df113f0b88967f7fecd492652ad5c730d5).
All 340 upstream files other than the unchanged workspace pubspec match the
recorded source bytes and modes. This carries the bounded row-revision and
image-appearance work, the raw review-data audit, and the retained native
round-trip report with its original source identity.

The [production integration receipt](evidence/legacy-doc-parser-integration-20261112/34e1484/summary.json)
records 616 parser Dart tests, 104 Python tests, and 1,627 engine tests passing
(with the same single font-dependent skip). Engine analysis is clean. The
[follow-up receipt](evidence/legacy-doc-parser-integration-20261112/53a7f0d/summary.json)
proves that the parser library, tests, example, pubspec, and analysis options
have identical Git object IDs between that tested production checkpoint and
this evidence/CI checkpoint. The added audit tooling was freshly analyzed:
271 informational diagnostics, no warnings or errors. The 104 Python tests
were rerun successfully.

The root engine CI job now sets up Python 3.12, installs the parser's exact
`tool/fidelity/requirements-test.txt` declaration (`Pillow==13.0.0`), and runs
the parser's Python test discovery. This avoids depending on an image library
that happens to be preinstalled in a developer environment. The existing
workspace Dart dependency settings remain unchanged.

## Continuation checkpoint: parser 713973f

The prior integration PR was merged into Quds main
`9a0a0268aa57f0d61b4112e101968e29a3a5f077`. The continuation starts from that
complete main tree, preserving its Word-package guards, native image oracles,
editor URL-launcher declaration and plugin registrants. Its intermediate parser
pin, `f689b4c7cc4f9fd4d28d855c8572664bd8c6dd27`, was verified against all
340 unpatched upstream files; it introduced no Quds-specific parser adaptation.

The next mirrored source is
[`713973fb27330d190281cbe66193f6b22ec722f8`](https://github.com/CrispStrobe/legacy-doc-parser/commit/713973fb27330d190281cbe66193f6b22ec722f8).
The [file receipt](evidence/legacy-doc-parser-integration-20261112/713973f/upstream-files.json)
verifies all 355 unpatched upstream files against tree
`a16bf1c9d3ddab00009c58dfcf8eaf706f1178d4`. The workspace pubspec remains
byte-identical. This checkpoint carries bounded OfficeArt background-color and
layout-in-cell context, textbox range-separator handling, authored regression
fixtures, and the lossless archive of the earlier native DOC/DOCX stage files.
The canonical upstream CI file removes a duplicate Python/Pillow setup; the
active Quds root workflow retains its Python 3.12 dependency-install and test
steps.

The [integration receipt](evidence/legacy-doc-parser-integration-20261112/713973f/summary.json)
records these fresh checks in the Quds dependency workspace:

| Check | Result |
| --- | --- |
| Complete mirrored parser Dart suite | 647 passed |
| Parser Python oracle/runner tests | 109 passed |
| Complete engine Dart suite | 1,627 passed; one existing font-dependent skip |
| Engine analysis with `--fatal-infos` | Clean |
| Parser analysis | Exit 0; 287 infos, no warnings or errors |

The first engine attempt encountered a full development filesystem. Its five
temporary-directory creation failures and original log are retained in a
[separate failed-run receipt](evidence/legacy-doc-parser-integration-20261112/713973f/engine-tests-enospc.json).
After space was reclaimed from reproducible caches, the complete engine suite
was rerun successfully with unchanged parser and engine source. The failed run
is not counted as a successful gate. Historical native-rendering receipts keep
their recorded source and renderer identities; this is an integration
checkpoint, not a claim that the remaining fidelity gaps are closed.

## Main reconciliation: parser f56dff2

Quds main advanced to `74960237cea7c560f3db7ee96ca37641c4438567` while the
continuation was being validated. Its parser pin is
[`f56dff2842e0cb7f57e021b335618247ed8474bf`](https://github.com/CrispStrobe/legacy-doc-parser/commit/f56dff2842e0cb7f57e021b335618247ed8474bf),
a descendant of the preceding `713973f` source. The merge preserves both the
current main ancestry and the earlier integration receipts. The only merge
conflict was the upstream pin metadata; no parser implementation was replaced
with a Quds-specific adaptation.

The [file receipt](evidence/legacy-doc-parser-integration-20261112/f56dff2/upstream-files.json)
verifies all 374 unpatched parser files against tree
`d1a8d5eac5d605fbaa5e405fad47314f5e649e26`. The existing workspace pubspec is
unchanged. This retains main's bounded metafile-arc rendering, media-revision
semantics, their authored controls, and the archived native evidence.

The [fresh integration receipt](evidence/legacy-doc-parser-integration-20261112/f56dff2/summary.json)
records 697 parser Dart tests, 115 Python tests and 21 focused engine tests
across legacy document parsing, conversion and note-marker suites, all passing.
Engine analysis with `--fatal-infos` is clean. Parser analysis exits zero with
298 informational diagnostics and no warnings or errors under the workspace
dependencies. The complete 1,627-test engine result above remains attributed
to its original `713973f` checkpoint; this merge's local engine test scope is
explicitly limited to those three integration suites.

## Note and header boundary checkpoint: parser d28be0a

The next source roll pins
[`d28be0a173415ebb392a8309aacdbe2bb1a50da7`](https://github.com/CrispStrobe/legacy-doc-parser/commit/d28be0a173415ebb392a8309aacdbe2bb1a50da7),
tree `9cf883d7829627051a2f1068235dfe20d2e37383`. The
[file receipt](evidence/legacy-doc-parser-integration-20261112/d28be0a/upstream-files.json)
verifies all 421 unpatched upstream files and the unchanged workspace pubspec.
Quds main remains `74960237cea7c560f3db7ee96ca37641c4438567`, already in this
branch's ancestry.

This roll preserves every source paragraph in note and separator stories while
avoiding an extra generated paragraph after a final table. Corroborated normal/
first-header textbox aliases retain their source shapes and one-frame identity;
shared review/event identities and independent media revision metadata exclude
alias recovery. The earlier main arc and media revision work is retained.

The [integration receipt](evidence/legacy-doc-parser-integration-20261112/d28be0a/summary.json)
records 761 parser Dart tests, 129 Python tests and 21 focused engine tests,
all passing. Engine analysis with `--fatal-infos` is clean. Parser analysis exits
zero with 315 informational diagnostics and no warnings or errors under the
preserved workspace dependency versions. The fresh engine scope is the three
legacy document, conversion and note-marker suites. The full engine gate and
the final native corpus receipt will follow after the native run is sealed.

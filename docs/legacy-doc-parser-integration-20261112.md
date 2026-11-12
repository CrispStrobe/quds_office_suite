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
retains Quds main commit `e2b00bae0600e7e384ca633a7364e8dcd2e95c58` in its ancestry,
including main's editor/reports dependency paths.

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

## Continuation: arcs and object revision provenance

The development branch now pins parser `ba5f5b0cdd540bd0c03f62aabc88faadd8660e0b`.
All 360 upstream files were checked before and after synchronization; only the
existing workspace pubspec adaptation remains. The [continuation receipt](evidence/legacy-doc-parser-continuation-20261112/README.md)
records 666 parser tests and 21 focused legacy bridge tests passing.

This is the same runtime accepted by the standalone 153-case Open XML SDK gate.
That gate caught and corrected paragraph-mark revision ordering and OLE shape
identifiers; it does not establish visual identity or native object activation.

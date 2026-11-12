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

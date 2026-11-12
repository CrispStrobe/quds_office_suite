# Consolidated Office acceptance evidence — 12 November 2026

These receipts describe the combined engine/editor code at
`7bd56f609d5ec63e44e0393560b3ec1055c3bf7e`, after both remote Office histories,
recovered changes, and pending-draft fixes were joined. The later independent
validator supports DOCX/DOCM/DOTX/DOTM with native package-type checks; its exact
source hash is recorded separately. The source documents and native visual
results are unchanged by that validator-only extension.

## Measured results

- Engine: 1,061 tests pass, one existing font-capability skip; analysis clean.
- Required fidelity gate: 598 tests, 308 Python controls, 67 public operations.
- Engine output inventory: 241 exact files, comprising 73 three-save series and
  22 standalone files.
- Editor: 410 tests pass, one existing developer-local PDF fixture skip;
  production analysis and all 23 reviewed page goldens pass.
- Editor output inventory: 22 exact files, comprising seven three-save series
  and one standalone file.
- Independent SDK validation: all 263 packages pass with exact SHA-256 receipts.
- Stable external rendering: 256 files and 392 pages render; all 78 save-cycle
  comparisons and 19 mapped native-baseline comparisons pass.
- Seven native comment-control packages are explicitly schema-only after their
  original source reproduces the narrowly qualified native import refusal.
  They are not included in the visual success count.
- Engine line coverage: 42,488/52,127 instrumented lines (81.51%); ten library
  files are absent from instrumentation. This is not branch or all-source coverage.

## Files and provenance

`engine-acceptance.json` and `editor-acceptance.json` record test/code identities.
The two inventory files enumerate expected and observed outputs. `engine-coverage.json`
contains each measured unhit line and absent source file. `source-inputs.json`
records the exact 241 + 22 exported bytes. `source-schema.json` and
`source-render.json` are the complete external receipts; `external-acceptance.json`
links their hashes and separates native schema-only cases.

`renderer-provenance.json` records the official LibreOffice 24.2.7.2 release,
archive/header hashes, adapter source, native import/export calls, strict
refusal mapping, successful positive/negative probes, and preserved failures
from the unaccepted alpha renderer. The adapter uses LibreOfficeKit because the
standalone executable requires unavailable IPC paths in this runtime. Only the
specific synchronous native empty-component refusal can map to the existing
CLI refusal diagnostic. Signals, timeouts, export failures and missing PDFs
retain distinct failure paths.

`schema-validator-provenance.json` and the validator build receipt identify the
unchanged Microsoft Open XML SDK 3.3.0 packages and .NET 8 runtime. The extended
self-test checks eight valid Word packages, four invalid-XML cases, twelve
mislabeled native package types, and exact discovery of all 24 files. Revalidating
the 263 source files produces the identical schema report. SDK package archives,
LibreOffice binaries, generated PDFs and page bitmaps are not duplicated here.
The small runtime adapters are archived byte-for-byte for review and reproduction.

Paths embedded in raw receipts identify the execution workspace and are retained
for provenance. On a normal development host, run the repository's
`.github/workflows/office-fidelity.yml` steps with its pinned Flutter toolchain,
.NET/Open XML SDK and a supported LibreOffice executable. The archived adapter
sources and recorded official download hashes document the constrained runtime
alternative; their directory layout follows the `runtime` paths in provenance.

`artifact-hashes.json` binds every archived data/runtime file to its SHA-256.
The [consolidation report](../../office-fidelity-consolidation-20261112.md) explains
merge decisions and bounded support claims. Existing top-level evidence JSONs
from the earlier coverage branch remain historical and are not substitutes for
this combined-code acceptance.

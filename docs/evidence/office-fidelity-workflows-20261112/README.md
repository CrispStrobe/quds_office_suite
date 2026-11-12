# Source-bound Office acceptance evidence

This directory retains the execution evidence for the workflow follow-up.
The engine was measured at `12799e2a6b371226012163a092fab866c133f967`;
subsequent native picture-oracle and conversion-retry changes do not change its
measured inputs. All 572 engine input hashes were rechecked after those changes.
The matching engine coverage and feature-run input digest is
`f60e6be31ae2cf6a594b49b4e1c1db425ebb38c6b732d1a8ca2c5c105291f99d`.

## Completed checks

| Check | Measured result |
| --- | --- |
| Full engine collection | 1,425 passed; one existing font-fallback skip |
| Named feature workflows | 565 Dart tests, 19 independent oracles, 205 Python controls; 214 outputs |
| Full portable fidelity gate | 963 Dart tests, 389 Python controls; 305 outputs and all 67 operation scenarios |
| Engine line execution | 44,326 / 53,898 instrumented lines, 82.2% |
| Source-bound collection | 116 VM files, 572 hashed inputs; successful and unchanged |
| Complete editor suite | 452 passed; one existing local-PDF skip |
| Editor evidence | 22 exports; all 27 reviewed PNGs pass unchanged after the Unicode correction |
| Open XML SDK, suite exports | 327 files, zero validation errors |
| LibreOffice/Poppler, suite exports | 320 rendered; seven explicitly qualified schema-only cases; zero gate failures |
| Native comparisons | 97 three-save groups, 37 authored-baseline comparisons, ten page-order comparisons |
| Retained native artifacts | 320 PDFs and 575 page PNGs; all decoded PNG fingerprints verified |

`engine-summary.json` contains runtime and count details. The coverage report
lists all 9,572 unhit instrumented lines and ten files absent from
instrumentation. This measures line execution; it does not certify branches or
complete format support. The independent package oracles establish their
separate declared behavioral properties.

## Retained files

- `engine-collection-receipt.json`: exact successful run, input hashes, runtime
  identity and all VM-output hashes.
- `engine-vm-coverage.tar.xz`: all 116 original VM files plus their receipt,
  losslessly compressed. Every uncompressed coverage file was checked against
  its receipt hash after archiving.
- `engine-coverage-gaps.json`: detailed source and per-line execution inventory.
- `engine-feature-run.json`: the all-15-feature plan, commands, results and
  hashes of all 214 selected regenerated packages.
- `engine-inventory.json` and `editor-inventory.json`: exact managed inventories.
- `suite-input-receipt.json` and `suite-schema-report.json`: the frozen native
  input identities and complete SDK results.
- `suite-inputs.tar.xz`: all 327 exact validated packages, losslessly compressed
  and checked against the staged input receipt after archiving.
- `suite-native-report.json`, `suite-native.log.gz`: complete successful native
  results and every conversion attempt, at renderer commit
  `c8d5ba3cfddf8c6fd3fa736deab992be1e0cc3aa`.
- `suite-native-artifacts.tar.xz`, `suite-native-artifact-hashes.json`: all 895
  retained PDF/PNG files. PNG dimensions and decoded RGB fingerprints match
  their renderer records. PDF hashes identify the archived bytes; they are not
  a separate conversion-time PDF fingerprint.
- `acceptance-summary.json`: machine-readable counts, identities and limits.
- Compressed `.log.gz` files: original successful execution output, including
  the full engine and editor runs, and reproduced pre-fix layout/Unicode failures.
- `native-retry-controls.log.gz`: all 60 native Python controls, including
  isolated negative tests for each bounded retry and evidence-preservation rule.
- `initial-native-failed-report.json`: the first native run, which retained six
  killed conversion processes as failures. It is diagnostic evidence, not a
  successful native acceptance report.
- `focused-native-retry-report.json`: all six exact initially killed inputs
  converted successfully in a separate serial diagnostic retry. This does not
  substitute for the complete native gate.
- `serial-native-interruption-report.json`: the subsequent complete run
  rendered 319 files, retained seven qualified schema-only cases and failed on
  one different killed spreadsheet conversion plus its missing cycle result.
  The killed-process cause has not been established.

The complete native suite gate passed at the recorded renderer commit. One
spreadsheet conversion was killed, then succeeded on its second attempt with
unchanged input bytes; both attempts remain in the report. All 327 frozen
package hashes were unchanged after rendering. The seven precisely scoped
auxiliary-comment documents receive schema-only status only after the authored
XML checks and exact SDK receipts pass and the renderer actually refuses their
source. Such cases have no visual certification. Host native results are
recorded separately in CrispCloud's evidence.

The renderer now permits at most three attempts only when the SOFFICE
conversion process itself is killed by SIGKILL. Every attempt uses a fresh
profile/output and verifies the original input hash. Its complete diagnostics
remain in the report. Ordinary conversion errors, timeouts, Poppler failures,
input changes and schema/text/pixel mismatches cannot use this retry. All 60
native Python controls passed at this checkpoint. The native corpus result
above also exercised and retained one real interrupted-then-successful retry.

## Reproduction and provenance

The later exact-six Word image-only oracle is retained separately as
`word-image-only-acceptance-summary.json`, its SDK/native reports, input
receipt, compressed logs and `word-image-only-artifacts.tar.xz`. All six
focused packages and both three-save groups passed; the combined native
control suite passed 69 tests. This extends the separate host corpus without
changing the engine inputs or transferring the earlier full-suite renderer
identity to a different code revision.

Use Flutter 3.44.0 for this repository and the normal commands in
`packages/quds_office_engine/tool/fidelity/README.md`. Run the collectors into
new directories after resolving dependencies. Normal checks never update source
expectations or PNG goldens.

To reproduce the retained native inputs, extract `suite-inputs.tar.xz` into a
new directory, regenerate the Open XML SDK receipt for that location, then run
the native validator against that new receipt. Preserve the archive's relative
corpus paths. The archived schema report identifies its original input paths.

These receipts identify the original run. A different checkout, runtime
resolution or changed source must produce a new collection; an archived
verified state cannot be transferred to different inputs. Dependency contents
and the operating system are not claimed to be hermetic. Keep historical
failure reports separate from successful receipts.

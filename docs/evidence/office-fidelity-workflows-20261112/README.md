# Source-bound Office acceptance evidence

This directory retains the execution evidence for the workflow follow-up.
The engine was measured at `12799e2a6b371226012163a092fab866c133f967`;
subsequent native picture-oracle changes do not change its measured inputs.
The matching engine coverage and feature-run input digest is
`f60e6be31ae2cf6a594b49b4e1c1db425ebb38c6b732d1a8ca2c5c105291f99d`.

## Completed engine and editor checks

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
- Compressed `.log.gz` files: original successful execution output, including
  the full engine and editor runs, and reproduced pre-fix layout/Unicode failures.
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

Full native acceptance is recorded separately when the final serial render
completes. The seven precisely scoped auxiliary-comment documents can receive
schema-only status only after the authored XML checks and exact SDK receipts
pass and the renderer actually refuses their source. Such cases have no visual
certification. Picture-only host cases instead require actual measured pixels.

The renderer now permits at most three attempts only when the SOFFICE
conversion process itself is killed by SIGKILL. Every attempt uses a fresh
profile/output and verifies the original input hash. Its complete diagnostics
remain in the report. Ordinary conversion errors, timeouts, Poppler failures,
input changes and schema/text/pixel mismatches cannot use this retry. All 60
native Python controls pass; final corpus acceptance still requires the
separate complete native run.

## Reproduction and provenance

Use Flutter 3.44.0 for this repository and the normal commands in
`packages/quds_office_engine/tool/fidelity/README.md`. Run the collectors into
new directories after resolving dependencies. Normal checks never update source
expectations or PNG goldens.

These receipts identify the original run. A different checkout, runtime
resolution or changed source must produce a new collection; an archived
verified state cannot be transferred to different inputs. Dependency contents
and the operating system are not claimed to be hermetic. Keep historical
failure reports separate from successful receipts.

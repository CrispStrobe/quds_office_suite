# Quds integration of parser d14f03f

This receipt binds the complete workspace validation to canonical parser
`d14f03f198a9735c660d0f8ae18ba6fc316fcf25` and tree `78dc7f4ec68e45e82a62bedf95da3b98ce62393e`. All
475 unpatched files match upstream byte for byte;
all 476 entry modes match. The sole content adaptation
is the existing workspace pubspec (workspace resolution, lints 6 and xml 7),
whose SHA256 remains `150af8d89562635bf5a876c0a539c20ae48b58ea3666db071b5e4ebd3addf153`.

The measured clean Quds commit was `2a35557fd436b9bb2f8ae15225771c249e1e51de`.
The GitHub source checkpoint `aa1d3c88ede1f772a7f76e35348ff4e1b831976a` has exactly
the same tree `e024041254fbae2c07d38586eb69325cdf058093` and preserves current-main parent
`e3b81f56e95e9ebc9f1802fb31fc8d8aa756bb08`. The later receipt commit adds only evidence.

## Complete workspace checks

| Gate | Result |
| --- | --- |
| Parser Dart tests | 810 passed, zero failures or skips; all 66 suite files in 9 batches |
| Engine Dart tests | 1,627 passed, zero failures; all 123 suite files in 16 batches |
| Existing engine runtime skip | One: the selected Latin font already covers Arabic, so the multi-face font test cannot force a third font resource |
| Parser Python tests | 162 passed |
| Engine analyzer | Clean with `--fatal-infos` |
| Parser analyzer | Zero errors/warnings; 325 info diagnostics under the retained lints 6 / xml 7 workspace versions |
| Source stability | Exact before/after snapshots match for both complete test runs |

The portable parser's own dependency versions and SDK constraints are unchanged.
The parser analyzer's informational compatibility diagnostics are reported here;
no lint rules or CI gates were suppressed.

## Bounded test execution

The installed workspace resolves `test_core 0.6.18`, which retains compiled
suite kernels until a test process exits. Each batch therefore executes at most
eight sorted `*_test.dart` files with `dart test --concurrency=1 --reporter expanded`
and a JSON file reporter. VM/kernel compilation, timeouts, test selection inside
each suite and skip logic retain their defaults. All 123 engine paths and all
66 parser paths occur exactly once; the inventory includes each source SHA256.
There are no retries, name filters, omitted suites or fail-fast settings.

Every batch exited successfully and left no scratch files. Disk space was
checked at process boundaries; the reports retain those measurements, not an
unmeasured claim about the minimum space within each test process. The source
snapshots also bind the workspace dependency lock and package configuration.

`engine-report.json` and `parser-report.json` retain commands, environments,
counts and per-batch results. The corresponding inventories retain all suite
paths and hashes. `validation-artifacts.tar.xz` losslessly retains 95
members: every expanded log, JSON event stream, batch record, before/after source
snapshot, the exact batch runners, analysis/Python logs and publication receipt.
Every decompressed member was checked against
`validation-artifacts.manifest.json`; archive SHA256 is `190aa2713415130f6f35b911d81abd3e1c0e5305060acafa28cae9d7bb262205`.

## Fidelity scope

This is an integration receipt, not a claim that all Office fidelity gaps are
closed. The mirrored parser retains its current supported/remaining matrix and
the original native receipts, including genuine parser losses, DOC bridge losses
and renderer differences. No goldens, runtime behavior or existing test skip
conditions were changed for this validation.

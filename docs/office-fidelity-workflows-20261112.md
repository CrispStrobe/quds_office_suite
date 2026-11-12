# Office workflow and evidence follow-up

## Source relationship

The requested `crispcloud` branch is at `c9655003f14c87ec0c11d481341126ebb08a1419`.
It is an ancestor of the suite's `main` revision
`54f0f8de01416640560519aa9d732f668f603709`, which already contains the
import/edit/export scripting harness, independent package oracles, mutation
controls, output inventories, reviewed Linux Flutter goldens and external
schema/render gates. This follow-up preserves that work on
`feature/office-fidelity-workflows-20261112`.

CrispCloud initially pins suite revision
`84b11839126a9577b6688b6acf80edd3cc2601ee` through 237 selected files. Its
corresponding feature branch first synchronizes the newer source revision and
verifies all 352 selected shared files. The app's path dependencies need this
explicit synchronization; changes to the suite branch alone cannot update it.

## Reproduced gaps in this follow-up

| Area | Finding | Work and acceptance |
| --- | --- | --- |
| Coverage provenance | A same-length source edit could be assigned stale VM hits because source hashing happened only when reporting | The collector records inputs before execution, seals only successful runs, and verifies exact source/output hashes when reporting |
| Merged-table scripts | Physical cell indexes and logical grid columns were ambiguous for horizontally/vertically merged cells | Add an explicit logical selector with backwards-compatible physical indexes and independent exported-XML checks |
| Actual host font dialog | Opening and applying the dialog could round imported sizes, flatten mixed formatting and replace complex-script fonts | Preserve unchanged values and apply only requested properties; exercise the real dialog and three save/reopen cycles |

The latter two rows are implementation goals until their test evidence is
recorded below. The full format-support ledger remains
[`office-fidelity-gaps.json`](office-fidelity-gaps.json); these bounded fixes do
not imply complete OOXML, branch, platform or Microsoft Office visual coverage.

## Source-bound coverage collection

Resolve dependencies before collection. In `packages/quds_office_engine`:

```sh
python3 tool/fidelity/collect_coverage.py coverage/vm
python3 tool/fidelity/coverage_report.py coverage/vm --require-receipt
```

Choose a fresh directory for every run. The collector never deletes or reuses an
existing directory. It hashes engine sources, tests and fixtures, scenario
tools, imported Dart examples, sibling font assets and available dependency
resolution files before starting the test process. It records the Dart version,
executable hash, exact arguments and exit status. A failed or interrupted run,
changed input, missing coverage, or replaced/extra output cannot produce a
verified report. Concurrent implementation edits intentionally invalidate a
collection.

Historical coverage can still be inspected with `--allow-unverified`; those
reports explicitly mark collection provenance as unverified. Runtime dependency
contents and the operating system are not hermetically sealed. A verified
collection proves the identity of the measured source and outputs, not that
every executed line is correct or that every branch was tested.

The collector and reporter controls include same-length source edits, fixture
and lockfile changes, failed child processes, stale/missing/replaced coverage,
unsafe destinations and malformed VM records. CI now requires the receipt.

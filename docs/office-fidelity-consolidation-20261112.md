# Office fidelity consolidation — 12 November 2026

The continuation branch is `feature/office-fidelity-consolidation-20261112` in
both `CrispStrobe/quds_office_suite` and `CrispStrobe/CrispCloud`.

## Recovered work and remote ancestry

The interrupted session left nine source files outside a commit. They are
preserved remotely in source commit `6d3adec9f8c09d19c78aec1c1c027ff3ed46733f`.
That checkpoint retains native note separator definitions and their absence,
corrects the authored footer PAGE paragraph property order, checks every reopened
layout export, and preserves renderer diagnostics and exact schema receipts.

The consolidated source combines these remote heads:

| Branch | Commit | Contribution |
| --- | --- | --- |
| `main` | `84b11839126a9577b6688b6acf80edd3cc2601ee` | Earlier completion work, content revisions, image-cache disposal, and independent bookmark/control/note regressions |
| `feature/office-fidelity-coverage-20261112` | `adcccb405b0e11ac407fabaaaf7d0ebbb1a48f10` | Newer native structures, safe editing/history, bibliography, frame wrapping, nested layout, and 23 reviewed page images |

The app combines `main` at
`f8dd29db4a00607513b7f687b21e4dc16e075735` with the newer Office coverage head
`86338bdab58f46eeb68bb24d0916690874dfdca5`. Its vendored engine/editor files are
synchronized from an exact committed source checkpoint and verified by hashes.

The earlier completion and oracle work is represented by those histories. The
source `crispcloud`, CI, and cursor branches have no additional commits outside
the consolidated source ancestry. No open pull requests were found during the
initial audit. CrispCloud's ebook feature is a separate new subsystem; its
unfinished Rust cloud-engine branch is also outside this Office consolidation.

## Merge decisions

The two source branches independently implemented native Word structures. The
newer live `WmlContentControlBlock` model is retained with typed bookmark and
note-marker inlines. Missing safeguards from the earlier implementation are
ported into that model. Maintaining two competing representations would make
editing and traversal ambiguous.

Both branches' independently authored fixtures and semantic checks are retained.
The older bookmark, content-control, and note-marker corpora now use separate
`fidelity-*-legacy` output directories. The old marker test, expected JSON, and
oracle use explicit `legacy` filenames. Their expected contents are retained;
the directory separation prevents one producer or exact inventory check from
overwriting the other corpus.

The merged engine manifest requires **241 Office exports**. The editor manifest
requires **20 actual exports**, including all three cycles of the four layout
fixtures and the earlier controller bookmark/control workflows. These are
authored inventory requirements, not claims that a run has passed.

The gap ledger keeps the newer conservative scope for content controls,
bookmarks, field refresh, and revisions. The earlier note-ribbon and image-cache
entries are retained as `FID-069` and `FID-070`, because their old IDs collided
with different entries on the newer branch.

## Acceptance status

Fresh validation is in progress. Historical reports from source `adcccb4` must
not be presented as green: that run had 14 schema failures and 15 render-gate
failures. Current receipts and rendered comparisons must be regenerated from
the consolidated code and exact output bytes.

The required checks are source analysis, the full engine and editor suites,
scripted operation coverage, both independent corpus families, corruption
controls, exact export inventories, Open XML SDK validation, and source/repeated
save render comparisons. CrispCloud also requires real host upload/reopen tests,
fresh host coverage, and schema validation of captured saves.

The renderer limitation for a block content control inside a native comment
remains narrowly qualified. Only exact clean SDK receipts and the reproduced
source-import refusal can permit `native_schema_only`; those packages are
reported separately and do not receive visual certification.

## Remaining scope

See [the gap ledger](office-fidelity-gaps.json) and
[the operation guide](../packages/quds_office_engine/tool/fidelity/README.md).
Complete operation-name coverage does not establish all OOXML combinations,
branch coverage, platform/font equivalence, arbitrary complex-field refresh,
content-control binding/lock semantics, or floating contour layout. Unsupported
operations retain their explicit pre-mutation guards.

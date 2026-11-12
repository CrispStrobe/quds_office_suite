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

## Additional remote refresh

A second remote audit found source coverage advanced to
`31add77938bb1242d510ab544dbe886d87ebdf75`. Both additional commits are merged:
`c19e90d` adds the native separator-presence model/layout guard and independent
note controls, while `31add77` reserves native separator/continuation IDs before
inserting a note and checks the reviewed story through three saves. The latter
follows actual package relationships, including relocated main/note parts, and
rejects external targets before mutation. The previous allocator could choose
13 for a new note when a retained continuation notice already owned that ID.

The incoming reviewed story-page image removes only the synthetic separator:
1,248 pixels at x160–783/y916–917 in the 900×1120 page. All other pixels and the
other 22 reviewed page images are unchanged. The incoming image is retained
byte-for-byte; no local golden regeneration was used.

CrispCloud main also advanced to `d32191c3af8d74c9ec59be20d3183e323dea532f` with
Rust-SMB starting-offset/progress fixes. Its coverage branch reached
`389a2fd2b9acb6d6213b9bbf2b5b6808534195f0`, including the two source syncs and a
historical evidence update. These are included in the app consolidation.
The refreshed audit found two independent draft PRs, [#53 for ebooks](https://github.com/CrispStrobe/CrispCloud/pull/53)
and [#54 for file-manager capabilities](https://github.com/CrispStrobe/CrispCloud/pull/54).
They remain separate from this Office work. No source PR is open.

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
requires **22 actual exports**, including all three cycles of the four layout
fixtures, the reviewed three-page story, and the earlier controller
bookmark/control workflows. These are authored inventory requirements; fresh
execution results are recorded separately below.

The gap ledger keeps the newer conservative scope for content controls,
bookmarks, field refresh, and revisions. The earlier note-ribbon and image-cache
entries are retained as `FID-069` and `FID-070`, because their old IDs collided
with different entries on the newer branch.

## Save integrity and recovered fidelity fixes

The shared controller now exposes `commitPendingEdits()`. Both synchronous and
asynchronous saves commit active Word note, Sheet cell, and Slide shape/table
text drafts. Actual text changes advance a monotonic content revision before
an undo command exists. Pending text contributes to dirty state without
replacing the state of unrelated committed commands. Cancelling a draft cannot
clear those commands; focusing, moving the caret, and committing unchanged text
remain clean. A rejected spreadsheet validation draft stays visible and dirty
when saving fails.

The app commits pending edits before recording the upload revision, then marks
clean or closes only if that revision still matches after upload. Its Close
prompt reads current dirty state without committing, so invalid drafts can
still be cancelled or discarded. The source regressions cover both save APIs,
clipboard changes, exact edited cell/shape ownership, Slide table-cell cancel,
undo/redo, validation errors, and newer drafts during an outstanding save.

The recovered note serializer preserves native separator, continuation
separator, and continuation-notice definitions, including an intentionally
absent definition. Inherited namespace and XML compatibility context stays local
to copied fragments. Twenty direct/isolate repeated-save regressions cover both
footnotes and endnotes, aliased/default namespaces, relocated native parts,
ordinary note edits, and new documents' standard separator pair.

Duplicate bookmark IDs and names are rejected across all modeled owners that
share one physical XML part, including separate notes or textboxes. Separate
header, footer, footnote, and endnote parts may reuse identities. Both the newer
corpus and main's independent legacy corpus remain mandatory.

## Acceptance checkpoints

The completed checkpoint results below precede the additional native separator/ID
merge. The engine ran from clean `6a9d858312dffe4a408df6844aed1639348a37f7`
with library fingerprint
`182d0d3dba65d60b5d02e74739096d688539d6241ab568f386fc50bdaf419496`; the editor
draft-save suite ran at `256402fc7d15029e78981a59dfd94a32565d00c4`. Fresh full
engine/editor gates and exact 263-file schema/render evidence are now required
for the merged native changes. The merged focused gate has already passed 72
Dart tests, 32 note-oracle controls, and 21 inventory controls.

| Check | Result |
| --- | --- |
| Engine analysis | No issues |
| Complete engine suite | 1,046 passed; one existing font-capability skip |
| Mandatory fidelity gate | 583 Dart tests and 306 Python controls passed |
| Scripted operation catalog | 67/67 exercised: 49 DOCX, 10 XLSX, 8 PPTX |
| Exact engine export inventory | 241/241: 73 three-cycle series and 22 standalone files |
| Complete editor suite after draft fix | 410 passed; one existing local-PDF-fixture skip |
| Focused controller draft/revision regressions | 38/38 passed, including 33 new tests |
| Reviewed Flutter page goldens | All 23 retained unchanged |
| Exact editor export inventory | 20/20: six three-cycle series and two standalone files |
| Source Open XML SDK | The initial 261-file pass has zero errors; final editor-byte receipts are being refreshed |
| External rendering | Stable LibreOffice 24.2.7.2 acceptance is in progress |

The full editor analyzer reports two existing brace-style informational findings
in `office_nested_table_golden_test.dart`; analysis of the changed production
and test files is clean. The engine skip requires a third fallback font that
this runtime does not force. The editor skip references the developer-local
`/home/mohammed/Desktop/al_tahreer_profile.pdf`, which is not a repository fixture.
Neither skip hides an authored Office fidelity fixture.

Fresh VM coverage records **42,465 of 52,102 instrumented engine lines
(81.50%)**, with ten library files absent from instrumentation. This measures
executed lines, not branch coverage or all source lines. Word, Sheet, and Slide
have no absent files in their measured component scopes.

| Component | Covered / instrumented lines |
| --- | ---: |
| Word | 9,101 / 10,813 |
| Sheet | 3,139 / 3,959 |
| Slide | 1,806 / 2,278 |
| PDF | 11,834 / 15,289 |
| Reports | 9,588 / 11,295 |

Historical reports from source `adcccb4` were not green: they had 14 schema
failures and 15 render-gate failures. The recovered fixes correct the authored
PAGE paragraph property order, preserve note separator absence, and require all
three editor layout exports. Current evidence is regenerated from the combined
code and exact output bytes.

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

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
`31add77938bb1242d510ab544dbe886d87ebdf75`. Both additional code commits are merged:
`c19e90d` adds the native separator-presence model/layout guard and independent
note controls, while `31add77` reserves native separator/continuation IDs before
inserting a note and checks the reviewed story through three saves. The latter
follows actual package relationships, including relocated main/note parts, and
rejects external targets before mutation. The previous allocator could choose
13 for a new note when a retained continuation notice already owned that ID.
The subsequent docs-only coverage commit
`f29eb9c1c9a85224ef71595eba9163ce442c392b` is also merged; its earlier receipts
remain explicitly historical.

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

## Fresh acceptance

Engine and editor acceptance ran against clean source code commit
`7bd56f609d5ec63e44e0393560b3ec1055c3bf7e`. The complete engine library
fingerprint stayed
`2891da0e0eb8336310cfc80ae98c0be7b0d1988037bc099463870a3c8e1f31b8`
throughout the run. Later documentation and external-validator updates do not
change those engine/editor bytes.

| Check | Result |
| --- | --- |
| Engine and editor production analysis | No issues |
| Complete engine suite | 1,061 passed; one existing font-capability skip |
| Mandatory fidelity gate | 598 Dart tests and 308 Python controls passed |
| Scripted operation catalog | 67/67 exercised: 49 DOCX, 10 XLSX, 8 PPTX |
| Exact engine export inventory | 241/241: 73 three-cycle series and 22 standalone files |
| Complete editor suite | 410 passed; one existing local-PDF-fixture skip |
| Controller draft/revision regressions | 38/38 passed, including 33 new tests |
| Native note/marker/bookmark merge gate | 72 Dart tests, 32 note controls, and 21 inventory controls passed |
| Reviewed Flutter page goldens | All 23 pass, including the exact incoming separator correction |
| Exact editor export inventory | 22/22: seven three-cycle series and one standalone file |
| Open XML SDK, exact final inputs | 263/263 packages; zero errors |
| Stable native rendering | 256/256 renderable files, 392 pages; zero failures |
| Repeated native visual comparisons | All 78 three-save series pass; 19 native baseline comparisons |
| Explicit native importer limitation | Seven exact-schema-qualified packages; no visual certification |

The editor production analyzer is clean. The package-wide analyzer separately
reports two existing brace-style informational findings in
`office_nested_table_golden_test.dart`. The engine skip requires a third fallback
font that this runtime does not force. The editor skip references the
developer-local `/home/mohammed/Desktop/al_tahreer_profile.pdf`, which is not a
repository fixture. Neither skip hides an authored Office fidelity fixture.

Fresh VM coverage records **42,488 of 52,127 instrumented engine lines
(81.51%)**, with ten library files absent from instrumentation. This measures
executed lines, not branch coverage or all source lines. Word, Sheet, and Slide
have no absent files in their measured component scopes.

| Component | Covered / instrumented lines |
| --- | ---: |
| Word | 9,124 / 10,838 |
| Sheet | 3,139 / 3,959 |
| Slide | 1,806 / 2,278 |
| PDF | 11,834 / 15,289 |
| Reports | 9,588 / 11,295 |

The largest remaining instrumented Office gaps include spreadsheet formula
functions (470 unhit lines), slide motion (215), Word layout (210), and several
OMML math import/edit/layout paths. Unhit code is an evidence gap, not proof of
a defect. The committed coverage inventory records every measured unhit line
and every absent file.

### External validation and rendering provenance

The schema validator uses the independent Microsoft Open XML SDK 3.3.0 against
Office 2019 rules. Receipts bind each validation result to its exact package
SHA-256. Discovery includes DOCX/DOCM/DOTX/DOTM, including uppercase suffixes,
and checks the expected native Word package type. Its self-test verifies eight
valid packages, four invalid-XML controls, twelve mismatched-type controls, and
exact discovery of all 24 cases. The original 263-package schema report remains
byte-identical after this stricter extension-aware validation. The final source aggregate contains 241 engine and 22 actual editor
exports. All input hashes remained unchanged through rendering.

Rendering used the official LibreOffice 24.2.7.2 engine through its documented
LibreOfficeKit API. The sandbox's standalone CLI could not create its required
IPC socket. The task-local adapter uses synchronous batch import and PDF export;
it retains native failures and uses the same strict repository comparison gate.
The bundled 26.8 alpha renderer had crashed on an XLSX that the stable engine
converted successfully. The accepted result uses the stable engine only.

The visual gate compares page count, extracted text, and SHA-256 fingerprints of
page dimensions plus RGB pixels across required save cycles and mapped native
baselines. The seven native block-content-control-in-comment packages are
separate: the original independently authored source produces a native import
refusal, and only matching clean SDK receipts plus semantic qualification allow
`native_schema_only`. Timeouts, crashes, missing files, and export errors cannot
use that exception. These seven packages receive no visual certification.

Historical source `adcccb4` had 14 schema failures and 15 render-gate failures.
Current outputs and receipts were regenerated after the combined fixes; those
historical failures are not presented as passed. The stable renderer adapter,
its probes, validator provenance, exact input hashes, full schema/render
receipts, coverage, and test summaries are preserved in
[the acceptance evidence](evidence/office-fidelity-consolidation-20261112/README.md).

## Remaining scope

See [the gap ledger](office-fidelity-gaps.json) and
[the operation guide](../packages/quds_office_engine/tool/fidelity/README.md).
Complete operation-name coverage does not establish all OOXML combinations,
branch coverage, platform/font equivalence, arbitrary complex-field refresh,
content-control binding/lock semantics, or floating contour layout. Unsupported
operations retain their explicit pre-mutation guards.

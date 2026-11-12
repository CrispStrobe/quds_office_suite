# Office fidelity follow-up — 12 November 2026

This continuation starts from Quds `54f0f8de01416640560519aa9d732f668f603709`
and CrispCloud `9cd18e7c704937897d037b1051d38341d4928bf5` on
`feature/office-fidelity-followup-20261112` in both repositories. The source
checkpoint is already on Quds main; the companion host work remains in draft
[CrispCloud PR 68](https://github.com/CrispStrobe/CrispCloud/pull/68).

The interrupted conversation's last visible status predates its actual saved
work. Typed formula caches, reversible worksheet renames, legacy conversion,
the complete source/host acceptance receipts and both PRs survived remotely.
The earlier [gap-closure report](office-fidelity-gap-closure-20261112.md) retains
its exact historical scope; its counts are not measurements of this continuation.

## Recovered remote validation

At recovery, the previous source [Office fidelity workflow](https://github.com/CrispStrobe/quds_office_suite/actions/runs/43209321086)
and host [Office integration workflow](https://github.com/CrispStrobe/CrispCloud/actions/runs/43209357326)
had both completed successfully. This supersedes their earlier queued status.

The broader source CI was unsuccessful. Its engine job reported three export
ordering diagnostics; the editor also reported two missing-brace diagnostics.
Those narrow issues are corrected in the first continuation checkpoint without
changing runtime behavior. The moving stable Flutter SDK additionally reports
Material API deprecations across the existing editor/example/studio. That SDK
migration remains distinct from the pinned Flutter 3.44 Office acceptance;
diagnostics and gates are not suppressed. Broader CrispCloud CLI, source-review
and formatting failures are not represented as Office test failures or successes.

## Completed implementation scope

The reusable changes are owned by Quds at frozen source commit
`7641d9cfa167987216134ebfc4772918cc945d97`. CrispCloud checkpoint
`b7edb919def85ef78d6d34ba6eb7c74d61e0bd4d` pins that revision through its
[366-file hash manifest](https://github.com/CrispStrobe/CrispCloud/blob/b7edb919def85ef78d6d34ba6eb7c74d61e0bd4d/tool/office_fidelity_manifest.json).
The continuation is saved on the feature branches and tracked in
[Quds PR 2](https://github.com/CrispStrobe/quds_office_suite/pull/2) and
[CrispCloud PR 79](https://github.com/CrispStrobe/CrispCloud/pull/79).
Host code supplies localized dialogs, I/O and existing history integration;
font measurement, native serialization and reusable controls remain in Quds.

### FID-029 — partial: native Normal-font metrics and dimension history

The engine resolves the native built-in Normal style through its style-XF/font
links and theme family. The editor measures digits 0–9 at the requested size
only for a known loaded face and records the actual resolved family. Imported
native widths retain their original precision; newly edited widths use the
resolved maximum digit width. Metric refresh preserves explicit pixel edits,
dirty state and history. Column and row resize commands remain attached to the
worksheet where preview began; a read-only transition restores an unfinished
preview without creating a dirty command.

An independent review caught stale width provenance: an imported width 8.72 at
MDW7, overwritten directly with 166px, accidentally matched its former native
projection at MDW19 and then shrank to 105px at MDW12. Observed mismatches now
invalidate that association, and column/grid snapshots retain only current
native associations. Regression cases cover the collision and restoration.
See the [metrics regression](../packages/quds_office_engine/test/sheet_normal_font_metrics_test.dart)
and [controller regression](../packages/quds_office_editor/test/sheet_normal_font_metrics_test.dart).

Native rendering also exposed an independent style-zero defect: omitting the
source cell's explicit `s="0"` changed a one-page sheet to two pages although
`styles.xml` was unchanged. Restoring that attribute alone reproduced the
source's exact text and decoded RGB. Per-cell presence now survives sorting,
structural history and direct/isolate saves, while originally absent styles
remain absent. The [causal evidence](evidence/office-fidelity-followup-20261112/style-zero/summary.json)
records the probe and authored fixture provenance.

FID-029 remains partial. Missing or ambiguous Normal metadata and unavailable
fonts remain unresolved; the engine retains its MDW7 fallback until supplied a
resolver. Sheets omitting both native default/base column widths still use the
historical 64px default. Substituted families are identified explicitly; these
fixtures do not establish arbitrary-font or Microsoft Office equivalence.

### FID-057 — closed within the supported logical-grid contract

Opt-in `gridColumn` addressing resolves horizontal spans and vertical
continuations to their owning master cell. Legacy physical `column` selectors
retain their meaning; supplying both forms is rejected. Logical-grid mutations and merge/unmerge preflight unsupported topology.
Whole-cell replacement additionally protects bookmark/revision owners before
mutation. Ragged rows, nonpositive spans, orphaned or mismatched
continuations and partial merge boundaries are guarded.

Native `gridBefore`/`gridAfter` omissions survive import, cloning, history and
serialization. Logical-grid edits, row/column mutations and table sizing on
omitted-row topology remain guarded. Existing physical whole-story replacement remains supported.
This is a bounded addressing closure, not certification of arbitrary merged or
omitted-row layout.

The first omitted-row native comparison correctly failed because the supposedly
unchanged series actually edited its cell story. The corrected corpus has a
true no-op three-cycle series against its literal native source, plus an edited
series against independently authored native expected XML using the prescribed
paragraph defaults. The expected package never reads engine output. Negative
controls enforce the proper baseline; the separate regular merged-table edited
series establishes repeat-cycle stability only. See the
[corrected native baseline evidence](evidence/office-fidelity-followup-20261112/table-grid/native-corrected/summary.json).

### FID-068 — partial: shared custom tab controls

Quds `WordTabStopsEditor` supports custom positions; left, center, right and
decimal alignment; and none, dot, hyphen and underscore leaders. CrispCloud
integrates the shared widget into its localized paragraph dialog and existing
history. Tests exercise actual controls and preserve native values through
three captured uploads; see the
[host focused receipt](https://github.com/CrispStrobe/CrispCloud/blob/feature/office-fidelity-followup-20261112/docs/evidence/office-fidelity-followup-20261112/custom-tabs/host-focused-summary.json).
Character-style editing, custom style creation and table-style selection remain
open, as do native bar/clear tabs, heavy/middleDot leaders and inherited
style-tab semantics.

## Final acceptance for this continuation

Acceptance binds to the two clean implementation commits above. The following
receipts are from this continuation; later documentation commits preserve all
production, test, gate and managed-source bytes.

| Gate | Final receipt and result |
| --- | --- |
| Source engine, mandatory fidelity, fresh coverage | [1,384 passed, one conditional skip; 921 mandatory cases, no skips; 344 Python controls](evidence/office-fidelity-followup-20261112/final-source/engine-acceptance.json). Fresh coverage: 44,568/54,173 instrumented lines (82.3%). |
| Source editor and all oracles | [478 passed, one local-file skip; all three oracles and 25-file inventory passed](evidence/office-fidelity-followup-20261112/final-source/editor-acceptance.json). Analyzer clean. |
| Host source-pin verification and integration gate | [921 vendored-engine and 143 host tests passed; 366 source hashes verified; 296 engine + 62 host exports](https://github.com/CrispStrobe/CrispCloud/blob/feature/office-fidelity-followup-20261112/docs/evidence/office-fidelity-followup-20261112/final-host/summary.json). Host coverage: 2,216/3,549 lines (62.4%), all ten scoped files instrumented. |
| Source exact-byte SDK/native acceptance | [321 SDK-valid packages; 314 rendered files/614 pages; 95 cycle groups, 32 source/expected baselines and 10 page-order comparisons passed](evidence/office-fidelity-followup-20261112/final-source/external-acceptance.json). Seven existing comment-content-control files remain schema/native-XML only; no new exemption. |
| Host exact-byte SDK/native acceptance | [358 SDK-valid packages; eleven selected native uploads/23 pages plus six tab/ribbon files in two complete save cycles passed](https://github.com/CrispStrobe/CrispCloud/blob/feature/office-fidelity-followup-20261112/docs/evidence/office-fidelity-followup-20261112/final-host/summary.json). This is selected host native coverage. |
| Remote feature-head and workflow check | Both implementation pins were verified on the feature branches. [Remote workflow audit](evidence/office-fidelity-followup-20261112/final-source/remote-implementation-audit.json) records the new PR workflows as queued; these complete local receipts do not claim a remote CI pass. |

The original parallel editor attempt is retained: its bookmark oracle also
reads engine exports and ran while engine generation was incomplete. The
scratch runner now requires a passed engine receipt with the same clean frozen
commit and source fingerprints before editor acceptance. The serial editor
rerun uses a fresh output directory. This sequencing failure is not hidden or
presented as a production regression. Only FID-057 receives bounded closure;
FID-029 and FID-068 remain partial, and the remaining ledger gaps retain their
stated limits.

The engine skip is the existing multi-face PDF case when its Latin face already
covers Arabic; the editor skip is a local comparison tool requiring an absent
personal PDF. Neither mandatory fidelity nor host integration skipped a case.
Line coverage measures executed instrumented lines, not branch completeness.
Exact raw logs, the initial sequencing failure and every final byte receipt are
preserved under [final-source](evidence/office-fidelity-followup-20261112/final-source/summary.json).

## Verification after the interrupted connection

A fresh run against the same `7641d9c` implementation independently reproduced
the full source counts and native results above. While saving that run, remote
commit `83ec9de` supplied the interrupted session's final report. That report and
its original evidence remain intact; the
[resumed source receipts](evidence/office-fidelity-followup-20261112/resumed-source/README.md)
record the additional run separately. No source or golden changed.

The resumed formula check explicitly classified 42 results across three renamed
saves: nine supported numeric recalculations, 27 retained unsupported caches,
three exact string results and three intentional INDIRECT reference errors.
All three saved workbooks matched the independently authored native expected
result. The [classified comparison](evidence/office-fidelity-followup-20261112/resumed-source/focused-sheet/classified-native-comparison.json)
and [focused font/table/tab summary](evidence/office-fidelity-followup-20261112/resumed-source/focused-followup-summary.json)
retain the exact output hashes and bounded comparison claims. Formula support,
unknown-font fallbacks, unsupported table topology and remaining style UI limits
are unchanged.

# Office fidelity gap closure — 12 November 2026

Both repositories use `feature/office-fidelity-gap-closure-20261112`. Quds is the
source of truth for reusable Office parsing, conversion, preservation and editor
behavior. CrispCloud consumes a source-commit-pinned, hash-verified snapshot and
owns cloud I/O, file actions, dialogs, localization and upload coordination.

This report continues `office-fidelity-consolidation-20261112.md`. Its earlier
acceptance receipts remain historical; this branch has its own final receipts.
Closure in the gap ledger means a named, bounded regression is fixed. It does
not mean complete OOXML support or Microsoft Office layout equivalence.

## Incremental remote checkpoints

Source checkpoints retained the implementation as it became reviewable:

| Source commit | Change |
| --- | --- |
| `4407811bad36826c36be440338954ee12d4f7337` | Shared Word package guards, compound-file reader and legacy Word extraction |
| `0b15f8e5418e5baf951f55109f83baa2f8475db1` | Native Word frame outline projection, canvas painting and reviewed golden changes |
| `7a39436211610fff292f50d24417823efec61e98` | Native slide sections and atomic reorder plan |
| `fab46c1c355136b698b2b23e5a57d83a9a1a16fa` | Section-aware editor history |
| `90e49659e86a78a978b65d70000f6db289d42d5e` | Invalid native slide target guards |
| `74642e920f3a06471977146960e84a02d0fac511` | Native worksheet reference rewriting and adversarial controls |
| `dabdbea2ba7cae7a68556e0f09d741df48b68f2b` | Slide placeholder inheritance and independent native page-order acceptance |
| `fe760c25d7435c01c0095089312510414b2050ee` | Shared Office graph navigation and bounded search |
| `50f16f8707cb7a6d8d72378174bb84b0b13bd1cf` | Independent native Sheet rename expectation and rejection controls |
| `72f66e875b30e90de3b36b3cc8df90c22ed0ca51` | Refreshed compound-file guards, relocated Word identity and bounded legacy conversion |

The host was synchronized and saved after the helper, outline, section and
search milestones. Commit `ced4ad7c945cd16049fc3f5dc9c4fef691cb26e0` additionally
merges current main through `977b5037`, including upstream Rust cloud engines and
remote POSIX path fixes. The merge preserved the pinned Office source bytes.

## Additional viewer branch reconciliation

A fresh remote check found eight format-viewers commits beyond the earlier
`9068e31` baseline. Their Office changes are incorporated by component rather
than copying generic implementations back into the host:

| Incoming commit | Incorporation |
| --- | --- |
| `0b46b3a` | Global CFB directory ownership and raw 64-bit stream-size guards in Quds |
| `e84abea` | Relationship-aware compact host preview through the public Quds navigator |
| `c6b179b` | Case-preserving/relocated DOCM and DOTM detection in Quds, with host PDF regressions |
| `43519b0` | Bounded DOC/DOT main-story text conversion in Quds; localized host dialog and captured destination |
| `8b8d80e` | DOC conversion F3/F4 host routing; separate KeePass hunks excluded |
| `90e843b` from PR 62 | Host CI vendored dependency resolution fix |

The pure KeePass commits `209762e` and `c29b81f`, plus KeePass hardening in
`77a63a0`, remain outside the Office scope. Their branch is not claimed as a
fully merged ancestor. Source main already contains the prior consolidation,
and no additional source Office branch commits were missing at the refresh.
The new CFB/identity/conversion source cohort passed 64 tests; 13 new controls
failed against the prior implementation before passing with the fixes.

## Source ownership

| Reusable component | Authoritative location in Quds |
| --- | --- |
| Bounded compound-file traversal | `lib/src/opc/ole/bounded_cfb_reader.dart` |
| Legacy Word text extraction | `lib/src/word/legacy/legacy_word_document.dart` |
| Legacy Word body-text conversion | `lib/src/word/legacy/legacy_word_conversion.dart` |
| Macro/template preservation checks | `lib/src/word/serial/word_package_preservation.dart` |
| Relationship-aware part navigation | `lib/src/opc/office_package_parts.dart` |
| Bounded Office text search | `lib/src/extract/office_search_text.dart` |

Paths above are under `packages/quds_office_engine`. The host's earlier copies
of the five existing helpers were deleted. Their callers use public engine
exports. Pure format tests moved upstream; host tests still exercise actual
search, preview, save and dialog paths. The new conversion implementation also
belongs upstream. No extra parsing dependency was introduced by these moves.

The host retains its F3 presentation parser and Markdown/EPUB presentation,
platform menu bridge, localization, assets and cloud orchestration. This is a
bounded extraction of reusable Office mechanisms, not a claim that every
existing host presentation line has been moved.

## Worksheet renaming and cache fidelity

`SheetRename` prepares an atomic, reversible change. Local references are
rewritten in model and native formulas, names, print names, validation and
conditional rules, internal links, consolidation sources, chart title/category/
value formulas and pivot sources. Quoted names, apostrophes, case differences,
three-dimensional endpoints and repeated whole-row/column qualifiers are
covered. Strings inside formulas, structured references and external workbook
qualifiers stay unchanged.

`SheetEditorController.renameSheet` commits pending drafts, applies one history
command and respects read-only/no-op/rejected paths. Apply and undo preflight
stale state. Undo changes only owned reference slots, so a later edit or a
cached result produced during save is not replaced by an old XML snapshot.

Native comparisons exposed evaluator/serializer defects that XML reference
checks alone did not catch: unsupported formulas lost imported caches, escaped
quotes were truncated, missing-sheet lookup could use the active sheet, and
string results lacked native cache types. Whole-expression parsing now separates
supported recalculation from unsupported syntax whose imported cache is kept.
Worksheet lookup is case-insensitive and a missing sheet remains missing.

Actual evaluator errors now retain internal type provenance until the scalar
cache is written; the public evaluator still returns plain scalar values.
Literal, IF-returned and referenced strings such as `"#REF!"` and `"#N/A"`
remain strings, while real errors retain native `t="e"`. Imported explicit
string/error cache types survive save without recalculation. An ambiguous
manually supplied error-looking cache without recalculation rejects before
package mutation. Fourteen regressions failed before this fix and passed after.
The affected final cohort passed 200 engine cases, 51 editor cases and 18 Python
controls; the complete suites below provide the combined acceptance.

The focused native proof compares three renamed exports to a separately authored
expected workbook. The expected package starts from the original fixture and
changes exactly 34 scalar values across four XML parts, including five approved
recomputed caches; XML structure and every other package member remain unchanged.
It is not constructed from an engine export. All renamed pages match its full
page text and decoded RGB fingerprints, and all 42 per-cell formula/cache/type
checks pass. Historical broken exports fail the same comparison. No masks or
numerical rendering tolerance are used.

The three supported numeric recomputations are 42→2, 42→5 and 42→4. The escaped
string result remains `Data!A1 "quoted"`. The unchanged
`INDIRECT("Data!B2")` intentionally becomes an actual `#REF!` after Data is
renamed. Unsupported external, three-dimensional, whole-row/column and
qualified-name formulas retain their authored caches. This preservation is not
a claim of formula evaluation support.

FID-027 is **partial**. Opaque executable/data-model owners, unknown reference
slots, lossy modified native projections, incomplete shared formulas and
array/data-table formulas reject before mutation. Arbitrary Excel formulas and
all extension vocabularies remain outside this acceptance.

## Slide sections and placeholder inheritance

The shared plan retains section GUIDs, order, empty sections, per-slide opaque
metadata and namespace bindings. A moved slide adopts the original destination
slide's section; all other memberships stay unchanged. The editor keeps active
slide identity and reversible history. Duplicate, orphaned, nonconsecutive,
ambiguous or stale membership and invalid relationship targets reject before
mutation.

An independently authored six-slide/six-section source includes leading,
interior and trailing empty sections. Unchanged, within-section, forward,
backward and emptied-section scenarios are exercised through three direct and
isolate saves. The native comparison uses the prescribed original page order,
not the first output as the only expectation.

This comparison exposed a missing `p:ph` placeholder binding in exported
`p:nvPr`. Restoring only that property in a scratch probe recovered source title
alignment and bullets. The serializer now preserves modeled placeholder
presence, type and index, including omitted defaults. The source and all 31
exports pass external schema validation; 32 files/192 rendered pages pass all
10 cycle groups and all 10 exact source-order comparisons, with no exemptions.

FID-028 is **closed** for the bounded section operation. FID-076 records the
placeholder fix. Arbitrary PowerPoint extension metadata and master/theme
behavior are not certified beyond the stated properties and authored layouts.

## Word frame outlines

The engine projects explicit native DrawingML width, preset/custom dash spacing,
caps, joins, miter and inset alignment into a read-only line style. The real Word
canvas paints those properties and keeps selection chrome separate. New frames
preview the same one-point outline that they serialize; imported omitted widths
retain the earlier approximation. Original native XML survives clone, color
edits and repeated direct/isolate saves.

The focused checks cover 34 engine cases, six real-canvas pixel cases and seven
painter defensive controls. Replaying the new width assertion against the old
renderer failed, establishing that the regression detects the prior bug.

Three existing page images changed only within a four-pixel rectangle perimeter:
1,076 pixels in `nested_table_content`, and 1,273 each in `structure_create_1`
and `structure_edit_2`. Their interiors and the other 20 reviewed images did not
change. The detailed review and hashes are in `office-golden-review-20261112.md`.
There was no blanket golden update. Theme inheritance, compound/non-solid
outlines and extreme subpixel dash patterns remain uncertified; FID-056 stays
partial and FID-061 retains its bounded closure.

## Final combined acceptance

Final source, host, schema, renderer, inventory and coverage receipts are
recorded alongside this report under
`evidence/office-fidelity-gap-closure-20261112/`. Results in this section will be
filled from the clean, combined branch execution before the final checkpoint.

## Remaining scope

The gap ledger remains the authoritative list of open, partial and guarded work.
The broad outstanding items include full Microsoft Office/platform equivalence,
branch coverage, nondefault spreadsheet Normal-font metrics, complex content
control bindings/locking/repeating structures, mixed bookmark drawing remapping,
rich complex fields, revision rebasing, broader frame wrapping, merged table
index semantics, note-pane partial-range deletion, the native comment/control
importer limitation and host style/custom-tab UI.

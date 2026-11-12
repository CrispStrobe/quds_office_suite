# Slide arrangement and flat groups

The resumed coverage audit found three concrete faults: repeated rounding of
one distribution gap moved the final endpoint; creating a second independent
group reused an existing group identity; and arrangement commands changed the
document outside undo/redo and dirty-state tracking. Checking native exports
also exposed collisions between compact imported group keys and native shape
IDs, plus silent splitting of nonconsecutive group membership.

## Resulting behavior

Horizontal and vertical distribution round each cumulative gap once to an
integer EMU. Positive gaps and negative overlap keep both original endpoints.
All six alignment axes retain dimensions, rotation and the orthogonal position.
These operations use the model's rectangular bounds, without computing rotated
visual outlines.

Grouping a selection allocates its identity within the complete slide. The
engine accepts that scope through `allShapes`, and the controller always supplies
it. Group keys remain separate from the unique native IDs allocated when writing
`p:grpSp`. Two independently created groups keep separate membership across
direct and isolate saves.

The flat model requires each group to occupy one consecutive run in drawing
order. Grouping or ungrouping that would split a group rejects before changing
membership. The serializer validates every slide before changing package
parts, so a nonconsecutive model cannot silently become multiple native groups.
This bounded support does not add nested groups or transformed group coordinate
systems, preserve native group names/IDs, or implicitly change drawing order.

Alignment, distribution, grouping and ungrouping now use one undo command each
when they change state. Commands retain their original shape identities when
the active slide changes. Insufficient selections, unchanged arranged geometry
ungrouping already ungrouped shapes and regrouping an entire existing group do
not consume history or discard redo. Native group IDs use available unsigned
identities even when an existing shape occupies the maximum unsigned ID.
Viewing and selecting modes remain read-only.

## Focused evidence

`slide_arrange_fidelity_test.dart` checks literal geometry expectations for all
six axes, positive and negative spacing on both axes, retained drawing order,
small selections, group membership, native ID uniqueness and save preflight.
`slide_arrange_history_test.dart` checks independent groups, movement isolation,
one-step history, dirty state, content revisions, slide switching, no-op behavior,
read-only modes and rejection without selection changes.

The first runs against the original implementation reproduced seven engine
and twelve editor failures. Two later engine assertions and one editor
assertion also reproduced maximal-ID overflow and unnecessary regroup history.
After the fixes, the focused cohorts pass 95 engine tests and 122 editor tests,
including existing slide import, section reorder,
feature and embedding regressions. Targeted analysis of the six changed Dart
code/test files reports no issues. Original failure logs and the focused command
outputs are retained in
`docs/evidence/office-fidelity-expansion-20261112/slide-arrange`, together with
the final source hashes, input manifest and independent schema/native receipts.

The ungrouped reference `test/fixtures/fidelity/slide-arrange.pptx` is authored
independently with python-pptx 1.0.2 by the explicit maintenance script
`tool/fidelity/generate_slide_arrange_fixture.py`. Normal tests consume its
committed bytes. Five named rectangles have fixed positions, sizes, text,
fonts, fills and borders. The tested edit only groups the first pair and the
second pair. The test writes that original source plus three actual direct
save/reopen files and three actual isolate save/reopen files under
`build/fidelity-slide-arrange`.

All seven packages pass the independent Open XML SDK validator. All six edited
exports match the independently authored source's page count, extracted text
and rendered pixel fingerprints exactly, and both three-save series remain
stable. These checks cover this authored flat-group corpus; the final combined
source and host gates provide separate fixed-commit evidence.

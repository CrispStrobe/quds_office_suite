# Reviewed Office renderer baselines — 12 November 2026

The pinned Flutter 3.44.0 renderer was checked against suite code checkpoint
`0ce6e983a2e11e6c3adc36a33a63fb8fc5754750`. After visual review, the full editor
suite passed 355 tests with one documented skip in ordinary comparison mode,
including 12 golden cases covering 22 page images. Updating baselines is a
separate review step; the normal gate never updates them.

## Existing images changed for verified source corrections

- `office_fidelity_word.png`: the authored imported document has run defaults,
  but no paragraph spacing defaults. It now keeps native zero after-spacing and
  single line spacing when adding referenced styles. Imported note markers are
  painted at their source position with their source run properties.
- `office_stories_page_1.png`: the source marker is adjacent to its source text.
  Layout no longer invents a period or separator absent from the source XML.
- `continued_notes_1.png` and `tall_table_4.png`: newly created notes paint the
  same superscript marker and separator as their native export, without an
  artificial period. Later continuation pages are unchanged.

The native-default regression and exact-marker oracle independently establish
these changes; a renderer snapshot alone is not their specification.

## New structure images

`office_structure_goldens_test.dart` runs all three committed Word structure
recipes against authored source XML. It checks create (one page), edit (two
pages) and remove (one page), before save and after three native save/reopen
cycles. The four page images show headings, reference text, comments, picture
rotation, RTL table order, merge structure, TOC links, paragraph geometry and
positioned frames. The image-containing scene waits for at least 100 pixels of
the authored green PNG, so an asynchronous loading placeholder cannot pass.

The test reuses the canvas render object between selected pages and replacement
layouts. This exercises the viewport extent/layout invalidation correction.
Exact page counts prevent missing continuation pages from going unnoticed.
These snapshots establish Quds rendering stability, not full native Word visual
equivalence or all wrapping/anchor combinations. Remaining layout limits are
recorded in `office-fidelity-gaps.json`.

## Native frame wrapping images

`office_frame_wrap_golden_test.dart` adds three reviewed images from authored
native XML: `none`, `square` and `topBottom`. The no-wrap view intentionally
allows body/frame overlap; square flow starts beside the frame and returns to
full width below it; top-and-bottom flow starts below the frame. Exact mode,
geometry, colors and logical character ownership have independent XML/layout
checks. Each scene must match before saving and after all three native cycles.

## Reproduce normal validation

From `packages/quds_office_editor`, with the pinned SDK and dependencies:

```sh
flutter test --no-pub test/office_fidelity_golden_test.dart \
  test/office_story_golden_test.dart test/office_layout_goldens_test.dart \
  test/office_structure_goldens_test.dart \
  test/office_frame_wrap_golden_test.dart
```

Do not use `--update-goldens` in an acceptance run. Each cycle must match the
reviewed baseline; accepting an image on every cycle could conceal drift.

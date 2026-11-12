# Reviewed Office renderer baselines — 12 November 2026

At suite code checkpoint `adcccb405b0e11ac407fabaaaf7d0ebbb1a48f10`, the full
editor suite passed **365 tests with one documented skip** under pinned Flutter
3.44.0 in ordinary comparison mode. This includes **13 golden cases covering 23
reviewed page images**. Updating baselines is a separate review step; the normal
gate never updates them.

The subsequent layout-cycle correction extends `office_layout_goldens_test.dart`
to check the original document and all three sequential native save/reopen
states for `columns_sections`, `continued_notes`, `rtl` and `tall_table`. Each
reopened document is rendered against the same reviewed PNGs, with exact page
counts checked. The four series produce 12 actual DOCX exports and 44 page
comparisons. Exports 2 and 3 are serialized from the preceding reopened document.
The baselines are unchanged. **The final full run after this correction is
pending**; the verified counts above belong to `adcccb4`.

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

The subsequent native-presentation correction moves only the textbox's own
text to its source-default insets: 7.2 points horizontally and 3.6 vertically
when `bodyPr` omits those attributes. Frame geometry and body wrapping remain
unchanged. The three changed images were inspected again; source XML tests and
the independent frame oracle establish the defaults. The normal four-state
comparison checks the source model and each save cycle against the same image.

## Rich nested table image

`office_nested_table_golden_test.dart` adds one image with a filled parent cell,
a visible authored green picture, a two-cell nested table, a TOC and an absolute
text frame. This brings the reviewed set to 23 page images in 13 golden cases.
The test checks the live model and three native save/reopen cycles. Layout
checks require four cell boxes, one picture, one frame and one TOC entry.
Independent pixel guards require visible picture pixels, frame-text ink outside
the parent cell, and a dark TOC page number inside the cell. Their regions exclude
borders and leader dots. The reviewed image has 4,465 green picture pixels,
268 frame-text pixels and 14 page-number pixels, above thresholds of 100, 40 and
5 respectively.

## Reproduce normal validation

From `packages/quds_office_editor`, with the pinned SDK and dependencies:

```sh
flutter test --no-pub test/office_fidelity_golden_test.dart \
  test/office_story_golden_test.dart test/office_layout_goldens_test.dart \
  test/office_structure_goldens_test.dart \
  test/office_frame_wrap_golden_test.dart \
  test/office_nested_table_golden_test.dart
```

Do not use `--update-goldens` in an acceptance run. Each cycle must match the
reviewed baseline; accepting an image on every cycle could conceal drift.

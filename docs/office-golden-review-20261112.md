# Reviewed Office renderer baselines — 12 November 2026

The latest workflow follow-up passes **452 editor tests with one existing
local-PDF skip** under Flutter 3.44.0, with **27 reviewed PNGs**. The four new
merged-table images and the clipping correction are documented in the final
section. The earlier checkpoint counts below retain their original scope.

At suite code checkpoint `31add77938bb1242d510ab544dbe886d87ebdf75`, the full
editor suite passed **365 tests with one documented skip** under pinned Flutter
3.44.0 in ordinary comparison mode. This includes **13 golden cases covering 23
reviewed page images**. Updating baselines is a separate review step; the normal
gate never updates them.

The layout-cycle correction extends `office_layout_goldens_test.dart`
to check the original document and all three sequential native save/reopen
states for `columns_sections`, `continued_notes`, `rtl` and `tall_table`. Each
reopened document is rendered against the same reviewed PNGs, with exact page
counts checked. The four series produce 12 actual DOCX exports and 44 page
comparisons. Exports 2 and 3 are serialized from the preceding reopened document.
The layout baselines are unchanged. The intermediate run at `c19e90d` passed
364 tests with one documented skip and reported one outdated story-page image,
reviewed below. After that specific correction, the complete editor suite at
`31add77` passed 365 tests with one documented skip in ordinary comparison mode.
The separate 13-case golden cohort also passed without updates.

## Existing images changed for verified source corrections

- `office_fidelity_word.png`: the authored imported document has run defaults,
  but no paragraph spacing defaults. It now keeps native zero after-spacing and
  single line spacing when adding referenced styles. Imported note markers are
  painted at their source position with their source run properties.
- `office_stories_page_1.png`: the source marker is adjacent to its source text.
  Layout no longer invents punctuation or spacing around that marker.
- `continued_notes_1.png` and `tall_table_4.png`: newly created notes paint the
  same superscript marker and separator as their native export, without an
  artificial period. Later continuation pages are unchanged.

The native-default regression and exact-marker oracle independently establish
these changes; a renderer snapshot alone is not their specification.

## Imported note separator absence

The authored `story-media.docx` footnotes part contains only normal footnote 3;
it has no separator, continuation-separator or continuation-notice definition.
The native separator-preservation correction at `c19e90d` therefore also stops
the Quds preview from inventing a horizontal separator rule for this source.
Newly created notes retain their conventional rule.

The previous and actual page-1 images were inspected side by side. Exactly
1,248 pixels changed, confined to the two-pixel rule at x=160..783,
y=916..917 in the 900×1120 image. Every other pixel is identical, including the
intersecting vertical column separator, note text and picture, body text, and
header/footer pictures. Only `office_stories_page_1.png` was updated through
the pinned Flutter 3.44.0 golden-review command. SHA-256 checks confirmed that
the other 22 committed PNGs, including story pages 2 and 3, are unchanged.

`office_story_golden_test.dart` now checks the original source-derived document
and three sequential asynchronous native save/reopen states. Each state must
retain three pages, both owning-part story pictures, the source spacing and
the absence of native footnote separators. All 12 page comparisons passed in
ordinary mode after the single-image review. The exact export inventory is
`three-pages-1.docx`, `three-pages-2.docx` and `three-pages-3.docx`; each later
export is written from the previous reopened document. The former standalone
`three-pages.docx` output is removed explicitly, and unexpected DOCX files fail
the producer's inventory check. This adds two real exports while keeping the
reviewed set at **23 PNGs in 13 golden cases**. The independent local
LibreOfficeDev 26.8 run rendered all three exports as three pages and accepted
the complete cycle group with identical extracted text and page-pixel
fingerprints, with no failures or exemptions.

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
  test/office_nested_table_golden_test.dart \
  test/office_table_grid_golden_test.dart
```

Do not use `--update-goldens` in an acceptance run. Each cycle must match the
reviewed baseline; accepting an image on every cycle could conceal drift.

## Gap-closure follow-up: explicit native frame outlines

The native outline preview correction reads the preserved DrawingML width,
dash pattern, cap, join and alignment. Newly authored frames export a one-point
line and now preview that same width, replacing the previous fixed 0.8-point
canvas stroke. Imported omitted widths keep the existing 0.8-point
approximation, so all three frame-wrap baselines remain unchanged.

Three existing images contain newly authored one-point outlines. Their actual
images, masked differences and exact changed-pixel bounds were reviewed before
copying only these three results to the golden directory. Every changed pixel
is within the four-pixel perimeter of the existing frame rectangle. No text,
fill, picture, table, pagination or other geometry changes. The remaining
20 reviewed images were not updated. Bounds below use exclusive right/bottom.

| Image | Changed pixels | Changed-pixel bounds | Accepted SHA-256 |
| --- | ---: | --- | --- |
| `nested_table_content.png` | 1,076 | `(436, 503, 638, 574)` | `83078c839ace1acdfb98e15afc7379a090cc63c5be59229a34bf0b8f3b580f54` |
| `structure_create_1.png` | 1,273 | `(192, 186, 434, 268)` | `a70893909dbfd920e6c95dee22b71e61b0fd03ee236358dd38b31a6469084014` |
| `structure_edit_2.png` | 1,273 | `(103, 76, 318, 185)` | `4bc0c8855e5fa4c0ecdfa5f02f194d5ec4b78be0e7c68a177eaf6babdbe8ed9c` |

`office_frame_outline_test.dart` independently samples native six-point dash
widths and gaps, custom dash percentages, round dot caps, miter/round/bevel
corners, inset bounds and selection behavior. Width/dash checks run before
saving and through three direct/isolate save cycles, including a stroke-color
edit. The first six-point assertion fails against the archived renderer at
`4407811`, and passes with the correction. Engine tests independently check
source XML preservation; malformed and extreme patterns have bounded fallback
controls. These tests do not certify theme inheritance, compound outlines,
gradient/pattern strokes or complete native Word visual equivalence.


## Logical merged-table editing and complete contained text

The workflow follow-up adds `office_table_grid_golden_test.dart` and four
640 by 900 PNGs for unchanged, format, replace and unmerge phases. The reference
models come only from independently authored raw XML. Actual scripted models,
then three direct and three isolate saves/reopens, compare exact RGBA pixels
against the authored model. Those 32 comparisons remain mandatory even when
an explicit maintenance run uses `--update-goldens`.

Visual review of the first images found clipped words in narrow nested cells.
The native source PDF displayed all letters on continuation lines. New semantic
checks reproduced the right-edge overflow and required every contained line
to fit the innermost cell and its growing row. The corrected line breaker
emergency-wraps oversized tokens in fixed containers at whole grapheme
boundaries; default body behavior is unchanged. Unicode controls protect
regional-indicator pairs, emoji modifiers, ZWJ sequences, combining marks,
UTF-16 ranges and RTL shaped-glyph ownership.

All four corrected images were inspected. Nested labels are complete, blank
cells remain blank, the selected merged origin retains the intended fill and
formatting, replacement changes the intended text, and unmerge creates the
expected grid. The row grows to contain every line, including the final nested
tail, and the following body paragraph remains visible. No authored fixture
width was enlarged to hide the defect. Only the four new PNGs changed; the
earlier 23 baselines retain their bytes.

These scenes intentionally use `WordLayoutEngine(font: null)` like the existing
fallback-layout tests. Its conservative 0.72-em metric and the scaled nested
grid produce very narrow content boxes, including one-grapheme lines. The
images certify complete constrained text and stable edits/saves under that
policy, not font-metric equality with LibreOffice or Microsoft Word. They bring
the reviewed image set to 27 PNGs. Full editor acceptance is recorded separately
for the exact implementation checkpoint.


A final Unicode audit reproduced eleven failures for omitted Indic conjuncts,
spacing marks and related cluster classes. `GraphemeClusters.segment` now uses
Dart's `characters` 1.4.1 (Unicode 16.0) and retains its public UTF-16 API.
Seventeen additional regressions cover the concrete gaps and saved cell
scenarios. The contained-wrap cohort now has 41 passing tests; the full editor
again passes 452 tests with its existing skip, and all 27 PNGs remain unchanged.
This establishes boundary and ownership behavior, not arbitrary Indic font
shaping or native font-metric equivalence.

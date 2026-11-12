# Generated paragraph bookmarks during rich paste

The insertion-copy review found a distinct boundary from native bookmark
endpoints. A generated paragraph bookmark lives in paragraph properties. The
copy engine correctly allocates its new name, but rich paste can merge only
the incoming inlines into an existing paragraph. That merge discarded the
generated bookmark property. Header, footer and comment paste used the same
inline-only path for every incoming paragraph.

The editor now rejects that unsupported merge before deleting selected text
or opening a history batch. The guard covers the first incoming paragraph
when merging into nonempty body text or a body selection, and every incoming paragraph in header,
footer and comment stories. Existing selection, content, paragraph objects,
undo/redo, dirty state and content revision remain unchanged on rejection.

Complete generated paragraphs still paste into a blank document or an empty
body paragraph, and later complete paragraphs remain separate blocks during
body insertion. Their allocated names survive undo/redo and actual repeated
save/reopen checks. Native endpoint bookmarks continue to merge with inline
text, including in a header; the existing complete native-copy corpus remains
supported. This guard does not introduce conversion of generated paragraph
bookmarks into arbitrary inline ranges, or broaden paragraph-property merging.

Twelve new regressions exercise these boundaries. Seven initial rejection cases fail
against the earlier implementation because the paste returns successfully;
the four supported controls pass. A further regression catches a selection
ending in an empty paragraph while leaving a nonempty prefix in its first
paragraph; this now rejects before deleting or joining either paragraph.
With the preflight guard, all 52
tests in the generated/native bookmark and content-control history cohort
pass. Analysis of the controller and new test file reports no issues.

The focused logs and exact source hashes are retained in
`docs/evidence/office-fidelity-expansion-20261112/generated-bookmark-paste`.
No new persistent export inventory is introduced: supported generated cases
perform save/reopen checks in memory, while the existing native-copy tests
continue producing the established independent corpus for the combined gate.

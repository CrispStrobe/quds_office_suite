# Complete bookmark insertion copies

This increment extends FID025 with an explicit `WordBookmarks.copyForInsertion`
operation and uses it for Word rich clipboard paste. A fragment must contain
complete editable bookmark pairs. When an incoming identity collides, the copy
receives a deterministic free decimal ID and a name with a bounded `_copy`
suffix. Original endpoints, the reusable clipboard payload, and ordinary
`WmlClone` history snapshots retain their identities.

Allocation reserves the whole destination, including body and textbox stories,
headers, footers, notes, comments, generated paragraph bookmarks, and preserved
opaque XML. It also reserves distinct later incoming identities before allocating
earlier collisions. Newly allocated names contain only ASCII letters, digits and
underscores, start with a letter or underscore, and fit within 40 characters.
Name collisions are compared without regard to case. Noncolliding native IDs
retain their original decimal spelling.

Both endpoints and their paragraph compatibility aliases are updated together.
The copy retains overlap order, cross-paragraph selection, zero-width empty
ranges, UTF-16 text positions, formatting, and extra native marker attributes.
The insertion preflight completes before a history batch or destination edit.

Copied `REF` fields and hyperlink anchors continue to target the original
bookmark name. They are not redirected to the new copy. Partial ranges,
bookmark-bearing opaque XML, and preserved native TOC caches still require an
explicit supported editing operation. Existing content-control identity guards
remain unchanged. Mixed text/drawing endpoint ordering is outside this work, so
FID025 remains partially covered overall.

## Evidence

The first regression checkpoint records three expected failures at the original
duplicate-copy guard. Partial selection rejection and empty paste already passed.
The final focused engine cohort passes **73 tests**, and the editor cohort passes
**40 tests**, without skips. Both analyzers pass. After adding the required native
reference, the **20 engine copy tests**, **5 editor copy tests**, and **16 Python
oracle controls** pass again. These are overlapping checks, not additional
distinct test totals.

The authored XML and JSON specify the text ranges and new identities independently
of the Dart implementation. The Python oracle checks the original and copied
endpoints, native attributes, bold runs, field results, and unchanged link
targets. Its negative controls detect duplicate identities, missing endpoints,
range expansion, lost metadata, retargeted references, and missing or extra
evidence. Engine and editor oracle modes have separate inventories.

The tracked `bookmark_copy_expected.docx` was authored from the native fixture and
the explicit copy mapping, without the Dart serializer. Both producers copy its
exact bytes into their respective output inventories. The same reference is
appropriate for both because all six engine/editor copied exports were verified
against it in the independent native renderer.

The final inventory contains **five engine files and four editor files**, including
one independent reference in each package. All **nine files pass Open XML SDK
validation and render as nine pages in LibreOffice 24.2.7.2**. Every copied export
matches the authored reference exactly in page count, extracted text and rendered
pixels across three saves. No native-schema-only qualification was used.

See `green-summary.json` for exact commands, source fingerprints, scope and counts;
`native/acceptance-summary.json` for the native comparisons; and `native/` for
input, SDK and renderer receipts. `logs.tar.gz` retains the successful runs and
earlier development diagnostics. The initial engine test invocation used the
Flutter test executable for a Dart CLI subprocess test; the corrected `dart test`
cohort passed. No test was skipped or weakened to resolve that invocation error.

The reusable `runtime/bookmark_native_acceptance.py` takes `--repo`, `--runtime`
and a fresh `--output` directory. It snapshots both producer inventories, checks
their semantic oracles, validates all nine packages, renders them, compares every
copied output against the native reference, and rechecks source/snapshot hashes.
It requires the pinned external runtime described by the recorded provenance.

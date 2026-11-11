# Office fidelity audit

Baseline: `crispcloud` at c965500. Integration: CrispStrobe/CrispCloud `main`
at 05de9cf, using local path overrides for the engine and editor.

## Verification design

- Independently authored OOXML input fixtures, with expected semantic snapshots.
- Import, unedited export, mutation, and repeated export/reopen scenarios.
- Package-level XML/relationship/media oracles independent of the reader.
- Editor/controller scenarios including undo/redo and asynchronous save.
- Run the same portable engine corpus against CrispCloud's vendored package.
- Commit and push checkpoints to feature branches; never modify base branches.

## Initial findings

| Area | Evidence | Status |
| --- | --- | --- |
| Fork/vendor drift | Word serializer, reader, properties and layout differ | Audit in progress |
| Footnote/endnote bodies | Reference markers present in app serializer only | Port and cover |
| OOXML ordering | App has pPr/rPr/sectPr order fixes absent from fork | Port and cover |
| Highlights | App converts enum names/RGB; fork does not | Port and cover |
| Styles/headings | Existing tests omit direct-default overrides and style mutations | Add oracles |
| Images/relationships | Need repeated-save, modification and binary preservation checks | Add oracles |
| Host save path | OfficeEditorDialog calls saveBytesAsync | Cover async/controller path |
| Goldens | No shared reviewed semantic corpus across both repositories | Add corpus |

This is a tracked audit, not a claim of complete OOXML support. Final results,
commands and any remaining limitations belong here as evidence is collected.

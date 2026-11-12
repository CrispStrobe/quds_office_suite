# Native proof for the six image-only Word captures

The complete host native run at app `561f486b` / source `1d19150` rejected the three GIF and three JPEG captures because the generic guard required extractable text. These fixtures intentionally have no text. They retain the original opaque black 80 × 40 pixel media and display it at 60 × 30 points. The failed full report remains preserved here and in the host failure checkpoint.

The shared renderer now selects only those six exact DOCX filenames under `fidelity-host`. It independently verifies the main part, paragraph/drawing structure, native format and content type, internal media relationship, intrinsic dimensions, A4 page dimensions, 72-point margins, Arial 11-point defaults, first paragraph leading/spacing, zero inline transform offset, exact extents and absence of extra visible content. The harmless dropped empty run and matching title metadata on reopen are the only supported structural normalization. Optional foot/endnotes may contain only the authored separator definitions.

Full raster evidence is mandatory even though extracted text is empty. It must show a single native page with the complete expected black rectangle, no extra ink or interior holes, and only the existing one-pixel edge band. Exact package checks reject even one-EMU extent/offset changes that rasterization could conceal. Missing pictures, wrong media formats/dimensions, crops, anchors, extra parts/text/pages, changed font or paragraph metrics, blank/colored/clipped/shifted images and forged evidence are negative controls. Other empty documents remain rejected; no schema-only or native-render exemption was added.

## Independent placement reference

`author_reference.py` does not read an exported package. It manually authors native DOCX inputs from the fixture's literal intentions and model defaults and independently encodes opaque black images using Pillow. The references use A4 (11,906 × 16,838 twips), 72-point margins, an empty Arial 11-point paragraph with 1.15 line spacing and 8 points after, followed by the 60 × 30 point inline picture. Both references pass the independent SDK validator.

Their native PDF places the image at `(72, 94.4507446, 132, 124.4507446)` points. The oracle fixes the rounded rectangle `(72, 94.45, 60, 30)`; it does not infer placement from a tested export. The literal native placement is tied to this font/layout and the recorded LibreOffice runtime. A different environment that changes it must fail for review, rather than redefine the target from its own output. Two independent read-only reviews checked reference provenance/layout and package/raster rejection boundaries.

## Final focused result

All **66 renderer controls** pass, including **10 new Word controls** with multiple corruptions. All six unchanged captured inputs pass SDK validation and native rendering, one page each, with two successful three-save comparisons. Each complete decoded RGB page also matches its separately authored native reference exactly; repeated-save identity is not the only appearance proof. Input and renderer/test source hashes remained unchanged during the final checks.

`summary.json` binds commands, exact source/input hashes and six independent-reference comparisons. `native-proof.tar.gz` preserves all six inputs, the two independent references, their reference PDFs/PNGs and all six native outputs. `archive-manifest.json` binds every member. Raw red/green logs, both SDK reports, runtime provenance and the earlier full native failure are retained. This is focused acceptance of the new shared oracle. The full source and host gates must still run against their newly published pins.

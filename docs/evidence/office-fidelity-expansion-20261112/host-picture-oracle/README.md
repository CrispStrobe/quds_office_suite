# Shared host picture bounds oracle correction

The host's corrected bounds fixture uses a 100 × 72 point slide and a black
picture at `(10, 7.2, 90, 45)` points. The previous shared native oracle still
expected a 100 × 60 point slide and a vertical picture offset of 6 points. It
therefore rejected all three corrected real exports before native rendering.
The old slide height was below the native schema's 914400 EMU minimum.

The source oracle now uses the corrected independently authored literal values.
The exact package transform check, complete pixel measurement, one-pixel edge
band, accepted corpus names, and repeated-save comparison are unchanged. No
expected geometry is inferred from an exported file.

## Focused verification

- The unchanged old oracle rejected all three corrected real PPTX files.
  Updated rendering controls produced 13 errors across 49 tests against that
  old expectation; the expected failing result is retained in the red receipt.
- All **56 controls pass** after the correction: the existing 54 controls plus
  two regressions. The new controls reject the old canvas or vertical offset
  independently, and reject a one-EMU width overflow even when clipping makes
  its raster identical to the correct picture.
- LibreOffice 24.2.7.2 rendered all **three corrected exports**, one page each.
  Each passed the literal geometry and full pixel checks. Their repeated-save
  pixel hashes are identical, with no unexpected ink, interior holes, or
  colored pixels.
- Existing independent SDK receipts validate the exact original paths and
  bytes of all three inputs with zero errors. Original and copied snapshot
  hashes were checked before and after rendering and remain unchanged.

The native renderer reports a 100.006 × 72 point page, rasterized at 72 dpi to
101 × 72 pixels. Its measured black rectangle spans `[10, 7, 100, 53]` pixels;
the existing one-pixel edge band permits that subpixel rounding while the
package geometry remains exact at page `[1270000, 914400]` and rectangle
`[127000, 91440, 1143000, 571500]` EMU.

## Reproduction and evidence

From the repository root, run all renderer controls with:

```sh
python3 -m unittest discover -s tool/office-validation -p 'test_*.py' -v
```

`native-proof.tar.gz` contains the three immutable input snapshots under
`inputs/fidelity-host/`, their PDFs and page PNGs, and the native report. With
LibreOffice and Poppler installed, run the shared renderer against the extracted
`inputs` directory and a fresh output directory:

```sh
python3 tool/office-validation/render.py INPUTS_DIRECTORY NEW_OUTPUT_DIRECTORY
```

`summary.json` records the source base, corrected host fixture commit, source
hashes, command, counts, and measurements. `input-manifest.json` binds snapshots
to the original SDK-validated inputs. The schema report and supplied producer
receipts are preserved without changing their original paths. Compressed red,
green, and native logs retain the observed results, and `artifact-hashes.json`
binds the evidence files.

This is focused verification of the shared renderer correction. Full source
and host acceptance must run again after publishing and consuming the new
shared source pin; the earlier acceptance history is preserved separately.

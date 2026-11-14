# Independent Office validation

`external-validation.json` is the final receipt. It identifies app commit
`05905b86ca3a7fc8db3df131620842da3e134061`, suite/pin
`c85c9f0a81a75a4afb5103d397c1816f0140eb00`, the successful host collection,
all source/tool hashes, commands, exact input counts and archive hashes.

## Validated scope

- OpenXML SDK: 149 host/reference files, zero errors. Four namespace XLSX files
  are revalidated separately; they are a subset of the source's 350-file scope.
- LibreOffice: 16 files comprising nine native host uploads, three independently
  authored native references, three namespace saves and their authored reference.
- All four three-save groups and all four first-save baselines match page count,
  extracted text and RGB pixels exactly.
- The namespace pages additionally contain visible blue text. The guard rejects
  both genuine earlier clipped versions, whose exact input/render bytes remain
  in `namespace-visibility-controls.zip`.

`external-artifacts.zip` preserves the exact Office inputs, rendered PDFs/PNGs,
raw reports, inventories, source snapshot and runtime receipts. Its SHA-256 is
`ec6911d1ee449e1927d2c1045dd5ff6a81a2b6db181129ce8d0560ac616908cc`.
All 235 recorded per-file hashes and the archive integrity were checked.

The collector uses the official LibreOffice 24.2.7.2 engine through the existing
LibreOfficeKit adapter because the normal CLI cannot create its IPC pipe here.
It verifies the official archive/runtime/adapter hashes and font inputs. The
OpenXML 3.3.0 validator uses the unchanged source and exact official dependencies
recorded in the build receipt. No renderer or validator was stubbed.

This is scoped visual evidence. It does not establish whole-format equivalence,
all-host rendering, browser execution, physical-device behavior or authentic
signature verification. Runtime and source provenance remain in the receipts;
`collect.py` and the recorded replay commands describe reproduction.

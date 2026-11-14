# Office recovery validation — 14 November 2026

`suite-validation.json` is the index for the current canonical-source results.
It records the tested implementation commit, runtime versions, gate results,
commands, bounds and SHA-256 hashes of the supporting files.

The full engine gate and editor suite ran against the code at
`36e652014d0e1aade20011309cd84a7f9c1f90a6`. Documentation added afterward does
not change that tested implementation. The engine and editor inventories retain
the exact saved-file hashes. `engine-schema-report.json` validates the 350 engine
files staged only after verifying those inventory hashes.

The .NET CLI cannot initialize its named NuGet migration mutex in this workspace.
The unchanged validator source was compiled with the official .NET 8.0.428
Roslyn compiler, official .NET 8.0.34 reference assemblies and the project's
exact OpenXML 3.3.0 / System.IO.Packaging 8.0.1 assemblies. The build receipt
retains source, assembly and package hashes. Validator negative self-tests ran
successfully before the positive packages were accepted.

The editor suite includes the reviewed visual goldens. Its one existing skip is
the optional `pdf_pixel_compare_render_test.dart` local-PDF comparison; no
new regression was skipped. No fresh engine line-coverage collection is claimed.

All Flutter/Dart runs used `CI=true`, `BOT=true`, suppressed analytics, a
workspace `TMPDIR`, and the workspace Pub cache. These supported CI settings
avoid cloud-machine metadata detection during Flutter startup.

Actual app-host outputs and independent LibreOffice comparisons are separate
evidence. Their final receipts must identify the app inputs, canonical pin,
exact exported bytes, independent expected documents and external runtime.

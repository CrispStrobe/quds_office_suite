# Office recovery validation — 14 November 2026

`suite-validation.json` is the index for the current canonical-source results.
It records the tested implementation commit, runtime versions, gate results,
commands, bounds and SHA-256 hashes of the supporting files.

The implementation was validated at
`36e652014d0e1aade20011309cd84a7f9c1f90a6`. The full engine gate and all 350
engine schema checks were repeated at
`c85c9f0a81a75a4afb5103d397c1816f0140eb00`, after improving the namespace
fixture's native theme and column width so its rotated text is visibly rendered.
Production libraries and editor tests are unchanged between those commits;
the 539-test editor result retains its original source identity. The inventories
retain the exact saved-file hashes, checked before staging for validation.

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
evidence under `external/`. Its collector binds the app inputs, canonical pin,
exact exported bytes, independent expected documents and external runtime.
The namespace fixture also has a narrowly scoped blue-text visibility guard;
the two previously clipped rendered examples are rejecting controls. Matching
empty-looking pages cannot satisfy this witness.

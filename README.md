# Quds Office Suite

<p align="center">
  <strong>A production-grade Office stack for Dart and Flutter.</strong><br/>
  Pure Dart engine. Custom RenderBox editors. Word · Excel · PowerPoint · PDF · Band reports.
</p>

<p align="center">
  <a href="https://pub.dev/packages/quds_office_engine"><img alt="engine" src="https://img.shields.io/pub/v/quds_office_engine.svg?label=quds_office_engine&color=2B579A"/></a>
  <a href="https://pub.dev/packages/quds_reports"><img alt="reports" src="https://img.shields.io/pub/v/quds_reports.svg?label=quds_reports&color=C9A227"/></a>
  <a href="https://pub.dev/packages/quds_office_editor"><img alt="editor" src="https://img.shields.io/pub/v/quds_office_editor.svg?label=quds_office_editor&color=217346"/></a>
  <a href="LICENSE"><img alt="license" src="https://img.shields.io/badge/license-MIT-0B1F3A"/></a>
  <img alt="sdk" src="https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white"/>
  <img alt="i18n" src="https://img.shields.io/badge/languages%20%26%20directions-LTR%20·%20RTL%20·%20BiDi-C9A227"/>
</p>

---

Three packages and one desktop app. Depend on each package **on its own**.

> **1.0 is out.** Both packages are stable and follow semantic versioning.
> See *What 1.0 brings* in the [engine](packages/quds_office_engine#what-10-brings)
> and [editor](packages/quds_office_editor#what-10-brings) READMEs.

| Package | Runtime | What it is | pub.dev |
| --- | --- | --- | --- |
| **[`quds_office_engine`](packages/quds_office_engine)** | Pure Dart | OOXML + OPC/ZIP + formulas + PDF 1.7 | [pub.dev/packages/quds_office_engine](https://pub.dev/packages/quds_office_engine) |
| **[`quds_reports`](packages/quds_reports)** | Pure Dart | `.qrep` band reports: templates, expressions, PDF / XLSX / DOCX | [pub.dev/packages/quds_reports](https://pub.dev/packages/quds_reports) |
| **[`quds_office_editor`](packages/quds_office_editor)** | Flutter | Interactive Word / Sheet / Slide / PDF surfaces and the report designer | [pub.dev/packages/quds_office_editor](https://pub.dev/packages/quds_office_editor) |
| **[`quds_report_studio`](apps/quds_report_studio)** | Flutter desktop app | Standalone report editor: open, design, preview, export `.qrep` | [Windows and Linux installers](https://github.com/MohammedAsaadAsaad/quds_office_suite/releases/tag/studio-v1.5.0) |

```text
┌─────────────────────────────────────────────────────────────┐
│                     your Flutter / Dart app                 │
├──────────────────────────────┬──────────────────────────────┤
│     quds_office_editor       │     quds_office_engine       │
│  QudsWordEditor              │  Docx / Xlsx / Pptx builders │
│  QudsSheetEditor             │  Wml / Sml / Pml models      │
│  QudsSlideEditor             │  Formula engine              │
│  QudsPdfViewer / Editor      │  PdfFile + OfficePdfExport   │
│  QudsReportDesigner          │  quds_reports (.qrep → PDF,  │
│  custom RenderBox canvases   │    XLSX, DOCX)               │
│         │                    │  OfficeIsolateOpen / Save    │
│         └────────────────────┤  OPC · ZIP · OLE · XML       │
│                              │  BiDi · shaping · fonts      │
└──────────────────────────────┴──────────────────────────────┘
```

The engine **never** imports `dart:ui` or Flutter. The editor **never** uses
`TextField`, `ListView`, or `InteractiveViewer` for the document surface.

![Quds Report Studio: designer, chart element, and inspector](apps/quds_report_studio/screenshots/studio_chart.png)

<table>
  <tr>
    <td width="50%"><img src="packages/quds_office_editor/example/screenshots/word.png" alt="Word"/><br/><b>Word</b>: paginated canvas, BiDi caret, outline, comments</td>
    <td width="50%"><img src="packages/quds_office_editor/example/screenshots/excel.png" alt="Excel"/><br/><b>Excel</b>: virtualized grid, formula engine, charts</td>
  </tr>
  <tr>
    <td><img src="packages/quds_office_editor/example/screenshots/powerpoint.png" alt="PowerPoint"/><br/><b>PowerPoint</b>: stage, animations, Morph, reverse playback</td>
    <td><img src="packages/quds_office_editor/example/screenshots/pdf.png" alt="PDF"/><br/><b>PDF</b>: open real files, find, annotate, forms</td>
  </tr>
  <tr>
    <td><img src="apps/quds_report_studio/screenshots/studio_preview.png" alt="Report preview"/><br/><b>Report preview</b>: engine pagination, vector charts</td>
    <td><img src="apps/quds_report_studio/screenshots/studio_rtl_invoice.png" alt="Arabic report"/><br/><b>RTL reports</b>: Arabic invoice with tafqeet and QR</td>
  </tr>
</table>

<table>
  <tr>
    <td width="33%"><img src="packages/quds_office_engine/example/screenshots/report_chart_gallery.png" alt="Chart gallery"/></td>
    <td width="33%"><img src="packages/quds_office_engine/example/screenshots/report_chart_extruded.png" alt="Extruded charts"/></td>
    <td width="33%"><img src="packages/quds_office_engine/example/screenshots/report_shape_map.png" alt="Country shape map"/></td>
  </tr>
</table>

Chart gallery and a country shape map, rendered by the engine.

### Report output (rendered by the engine, no Flutter)

<table>
  <tr>
    <td width="33%"><img src="packages/quds_office_engine/example/screenshots/report_sales_performance.png" alt="Sales dashboard"/></td>
    <td width="33%"><img src="packages/quds_office_engine/example/screenshots/report_sales_invoice_ar.png" alt="Arabic invoice"/></td>
    <td width="33%"><img src="packages/quds_office_engine/example/screenshots/report_inventory_ar.png" alt="Inventory"/></td>
  </tr>
</table>

### Files from other suites

A DOCX written in LibreOffice Writer. On the left is LibreOffice's own PDF.
On the right is the engine's, made in pure Dart.

![LibreOffice's PDF next to quds_office_engine's for the same DOCX](packages/quds_office_engine/example/screenshots/office_fidelity_word.png)

---

## About this fork (CrispStrobe)

This is the CrispStrobe fork of
[MohammedAsaadAsaad/quds_office_suite](https://github.com/MohammedAsaadAsaad/quds_office_suite).

### Why it exists

[CrispCloud](https://github.com/CrispStrobe/CrispCloud) opens, edits and saves
Word, Excel and PowerPoint files that live in users' cloud accounts. It uses
`quds_office_engine` and `quds_office_editor` from this repository through
local path overrides (`packages/` in CrispCloud, pinned to a commit of this
fork by a file-hash manifest). Two consequences drove the work here:

- **One fix, two places.** A fix made only in CrispCloud would never come back
  here, and a fix made only here would never reach the app. Every change lands
  in this fork first; CrispCloud then syncs the exact files and its hash guard
  fails if the copies drift.
- **Saving must not damage a user's file.** A cloud file manager that silently
  rewrites styles, drops notes or breaks a deck on save destroys data the user
  did not ask it to touch. So the goal was not "more features" but "what goes
  in comes out", proven by checks that do not trust our own serializer.

### What we changed

- **Word round-trip fidelity.** Footnote/endnote identity, source styles,
  numbering definitions, table styles and borders, hyperlinks in notes and
  headers, and explicit direct formatting (black / 11pt / zero spacing / left)
  are preserved instead of regenerated or flattened on save.
- **Notes layout.** Mixed and multiple notes per paragraph, multiline bodies
  and notes with styled runs, tables, drawings and links render. The note band
  is reserved during body layout, and long or rich notes paginate onto extra
  pages in source order instead of disappearing or overlapping the body.
- **Lists.** List commands allocate document-local definitions, so they no
  longer collide with imported list IDs; imported start values and Roman,
  alphabetic and padded-decimal formats are honored; list edits undo/redo.
- **Editing and history.** Footnote insertion follows the caret, paragraph
  splits keep rich runs, and repeated undo/redo no longer mutates history
  snapshots.
- **PowerPoint templates and media.** Exported decks keep the imported slide
  masters, layouts and theme, and gain any missing master/layout/theme and
  notes-size parts PowerPoint requires. Pictures and charts are namespaced to
  the slide that owns them, so editing or reordering one slide can no longer
  overwrite another slide's media.
- **Word style cascade.** Sparse style definitions resolve through document
  defaults, `basedOn` chains, theme fonts and colours, and character and
  table-region styles, without freezing the inherited values into direct
  formatting, so they stay editable and the saved file keeps its styles.
- **Spreadsheet fidelity.** Source cell style records, pivot tables and live
  chart formulas are kept on save instead of being regenerated or flattened
  to values.
- **Fixes merged back from CrispCloud.** Imported footnote references render
  as superscript, visible Word selection and header/footer relayout, rotated
  PDF watermarks, and report-designer font and template-band fixes.
- **Lint clean.** Engine and reports analysis passes with `--fatal-infos`.

### How it is verified

Expected values are authored by hand (XML/JSON) or produced by other tools,
never by blessing our own output:

- A Python oracle reads exported ZIP/XML directly and compares it with the
  authored expectations; negative tests confirm it rejects damaged files.
- Import fixtures `native.pptx` and `native.xlsx` are produced by independent
  libraries (python-pptx, openpyxl; versions in `native-producers.json`), so
  import is tested against files our code did not write.
- A .NET tool (`tool/office-validation`) validates every exported package with
  the Open XML SDK.
- Save/reopen exports across DOCX, XLSX and PPTX, scripted edits, and a
  reviewed full-page visual golden.
- The `office-fidelity` CI workflow runs all of it; the engine's own suite has
  about 490 tests.

Run it locally from `packages/quds_office_engine`: `dart test`, then
`tool/fidelity/check.sh`. The full gap list, feature matrix and coverage
inventory are in [`docs/office-fidelity-audit.md`](docs/office-fidelity-audit.md)
and [`docs/office-coverage-gaps.json`](docs/office-coverage-gaps.json); the
runnable guide is
[`packages/quds_office_engine/tool/fidelity/README.md`](packages/quds_office_engine/tool/fidelity/README.md).

### Known limits

- The page golden is reviewed on Linux with Flutter 3.44.0 (what CI uses). On
  macOS or another Flutter version it differs by about 0.6% of pixels from
  font rasterization. That is not a regression; do not regenerate the golden
  from a different platform.
- Engine line coverage is 79.4% (line, not branch, coverage).
- Fidelity is proven for the features in the audit matrix; anything listed
  there as a gap may still be simplified on save.

---

## Why this suite

Most Dart “Office” libraries stop at writing a simple DOCX. Quds goes further:

- **Round-trip real files** — open Microsoft Office / LibreOffice packages, mutate the model, write them back.
- **Own the stack** — ZIP, Deflate, CFBF/OLE, XML, fonts, BiDi, and PDF are implemented here. Fewer mystery dependencies.
- **Many languages, many directions** — UAX #9 BiDi, Arabic shaping, mixed LTR/RTL, and logical caret movement live in the engine; the editor paints them.
- **Editors that look like Office** — paginated Word, virtualized Excel, a slide stage with Morph, wipe, push, and **reverse** slideshow playback.
- **Band reports** — `.qrep` templates with bands, groups, expressions, typed variables, charts, barcodes, and Arabic amount-in-words (`TAFQEET`), exported to PDF, XLSX, and DOCX. A detail band can print one page per table row, the report form of a mail merge (class certificates). A visual designer and a desktop app come with it.
- **100+ PDF report templates** — classified by domain, direction-aware, with distinct `SheetSkin` layouts (not text-only clones).
- **Server or UI** — generate reports on a CLI/server with the engine; embed the same models in Flutter with the editor.

---

## Install

### Engine only (CLI, server, isolates, Flutter)

```yaml
dependencies:
  quds_office_engine: ^1.5.0
```

### Reports only (CLI, server, isolates, Flutter)

```yaml
dependencies:
  quds_reports: ^1.5.0
```

```dart
import 'package:quds_reports/quds_reports.dart';
```

`QudsReportEngine` from that import is the engine's report engine. PDF, XLSX,
DOCX, expressions, `.qrep` packages, charts, and shape maps are all on it.
The designer is `package:quds_office_editor/quds_reports.dart`.

### Editor (pulls the engine and quds_reports)

```yaml
dependencies:
  quds_office_editor: ^1.5.0
```

This repository is a [Dart workspace](https://dart.dev/tools/pub/workspaces). From the root:

```bash
dart pub get
```

---

## 60-second engine tour

```dart
import 'dart:io';
import 'package:quds_office_engine/quds_office_engine.dart';

void main() {
  final theme = OfficeDocumentTheme.custom(
    palette: const OfficePalette(primary: '2B579A', accent: '217346'),
    rtl: true,
  );

  final docx = (DocxDocumentBuilder(theme: theme)
        ..heading('Quarterly report')
        ..paragraph('A pure Dart Office engine for many languages and directions.')
        ..table([
          ['Item', 'Value'],
          ['Files', '3'],
        ]))
      .build();

  final xlsx = (XlsxWorkbookBuilder(theme: theme)
        ..addSheet('Summary')
            .addRow(['Quarter', 'Revenue']))
      .build();

  final pptx = (PptxDeckBuilder(theme: theme)
        ..addCoverSlide(title: 'Quds Office', subtitle: 'Engine + Editor'))
      .build();

  File('report.docx').writeAsBytesSync(docx);
  File('book.xlsx').writeAsBytesSync(xlsx);
  File('deck.pptx').writeAsBytesSync(pptx);

  File('report.pdf').writeAsBytesSync(
    OfficePdfExport.fromBytes(docx, title: 'Quarterly report'),
  );
}
```

Full walkthrough: [`packages/quds_office_engine/README.md`](packages/quds_office_engine/README.md).

---

## 60-second editor tour

```dart
import 'package:flutter/widgets.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordHost extends StatefulWidget {
  const WordHost({super.key});
  @override
  State<WordHost> createState() => _WordHostState();
}

class _WordHostState extends State<WordHost> {
  late final WordEditorController controller = WordEditorController(
    config: const OfficeSurfaceConfig(
      textDirection: TextDirection.rtl,
      strings: OfficeStrings.english,
    ),
  );

  @override
  void initState() {
    super.initState();
    controller.insertHeading(text: 'New document');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QudsWordEditor(controller: controller);
  }
}
```

Same pattern for `SheetEditorController` + `QudsSheetEditor`,
`SlideEditorController` + `QudsSlideEditor`, `PdfViewerController` +
`QudsPdfViewer`, and `ReportDesignerController` + `QudsReportDesigner`.

---

## 60-second report tour

```dart
import 'dart:io';
import 'package:quds_office_engine/quds_reports.dart';

Future<void> main() async {
  // A ready-made template file from packages/quds_office_editor/templates/.
  final ReportTemplateInfo info = ReportTemplateInfo.decode(
    File('sales_performance.qrep').readAsBytesSync(),
  );
  // Pass `fonts:` (a ReportFontRegistry) to embed faces; Arabic needs one.
  final QudsReportEngine engine = QudsReportEngine.fromXml(info.xml);
  final Map<String, Object?> data = info.sampleData(); // or your own Map

  File('sales.pdf').writeAsBytesSync(await engine.exportToPdf(data));
  File('sales.xlsx').writeAsBytesSync(await engine.exportToExcel(data));
  File('sales.docx').writeAsBytesSync(await engine.exportToWord(data));
}
```

Design the same template visually with `QudsReportDesigner` (Flutter) or
in **Quds Report Studio**:

<table>
  <tr>
    <td width="50%"><img src="apps/quds_report_studio/screenshots/studio_text_inspector.png" alt="Inspector"/><br/>Inspector: steppers, segmented icons, switches, B/I/U</td>
    <td width="50%"><img src="apps/quds_report_studio/screenshots/studio_autocomplete.png" alt="Autocomplete"/><br/><code>{{ }}</code> autocomplete from data, functions, and formats</td>
  </tr>
</table>

Format, expressions, charts, templates: [engine README → Band reports](packages/quds_office_engine/README.md#band-reports-quds_reportsdart).
Designer and inspector: [editor README → Report designer](packages/quds_office_editor/README.md#report-designer).

Full walkthrough: [`packages/quds_office_editor/README.md`](packages/quds_office_editor/README.md).

---

## Run the apps

**Quds Report Studio**: the standalone report editor (open, design, preview, export).
Download it:

| Platform | Installer | Portable |
| --- | --- | --- |
| Windows 10/11 (x64) | [setup.exe](https://github.com/MohammedAsaadAsaad/quds_office_suite/releases/download/studio-v1.5.0/QudsReportStudio-1.5.0-windows-x64-setup.exe) | [zip](https://github.com/MohammedAsaadAsaad/quds_office_suite/releases/download/studio-v1.5.0/QudsReportStudio-1.5.0-windows-x64-portable.zip) |
| Debian / Ubuntu (x64) | [.deb](https://github.com/MohammedAsaadAsaad/quds_office_suite/releases/download/studio-v1.5.0/quds-report-studio_1.5.0_amd64.deb) | [tar.gz](https://github.com/MohammedAsaadAsaad/quds_office_suite/releases/download/studio-v1.5.0/QudsReportStudio-1.5.0-linux-x64.tar.gz) |

It becomes the app for `.qrep` files on its first run. Install and
uninstall steps are in the
[studio README](apps/quds_report_studio/README.md#download). Or run it from
source:

```bash
cd apps/quds_report_studio
flutter run -d linux     # or windows, macos
```

**Quds Office Studio**: the editor example, a desktop workspace with ribbons, samples, and OS window chrome:

```bash
cd packages/quds_office_editor/example
flutter run
```

The engine example writes a gallery of Word / Excel / PowerPoint files **and** their PDFs:

```bash
cd packages/quds_office_engine
dart run example/rich_export_gallery.dart
```

---

## Architecture

```mermaid
flowchart LR
  subgraph Host["Your app"]
    UI[Material / Cupertino chrome]
  end
  subgraph Editor["quds_office_editor"]
    W[QudsWordEditor]
    X[QudsSheetEditor]
    P[QudsSlideEditor]
    D[QudsReportDesigner]
    C[Controllers + IME + undo]
  end
  subgraph Engine["quds_office_engine"]
    M[WmlDocument / SmlWorkbook / PmlPresentation]
    F[Formula + layout + BiDi]
    IO[OPC ZIP OLE XML]
    PDF[OfficePdfExport]
    R[quds_reports .qrep]
  end
  UI --> W & X & P & D
  W & X & P --> C --> M
  M --> F --> IO
  M --> PDF
  D --> R --> PDF
```

| Layer | Lives in | Rule |
| --- | --- | --- |
| Models, IO, layout, formulas, PDF | `quds_office_engine` | No Flutter |
| Painting, hit-testing, IME, gestures | `quds_office_editor` | `RenderBox` / `LeafRenderObjectWidget` only |
| Ribbons, file dialogs, window buttons | **your** host (or the studio example) | Material is allowed here |

---

## Repository map

```text
quds_office_suite/
├── packages/
│   ├── quds_office_engine/     ← publish this to pub.dev
│   ├── quds_reports/           ← publish this to pub.dev
│   └── quds_office_editor/     ← publish this to pub.dev
│       └── example/            Quds Office Studio (not published)
├── apps/
│   └── quds_report_studio/     standalone report editor (not published)
├── docs/                       MISSION, STANDARDS (limits), PDF, PUBLISHING,
│                               office-fidelity-audit, coverage gaps
├── tool/office-validation/     Open XML SDK validator used by CI
└── LICENSE                     MIT
```

---

## Publishing

Packages are published **separately**, engine first, then reports, then the editor:

```bash
cd packages/quds_office_engine && dart pub publish
cd packages/quds_reports && dart pub publish
cd packages/quds_office_editor && flutter pub publish
```

Step-by-step, dry-run, and versioning: [`docs/PUBLISHING.md`](docs/PUBLISHING.md).

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Issues and pull requests are welcome.

## License

[MIT](LICENSE) © Mohammed Asaad Asaad. Fork changes © CrispStrobe, same license.

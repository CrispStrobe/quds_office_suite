import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quds_office_editor/quds_office_editor.dart';
import 'package:quds_office_studio/credentials/biometric_secret_store.dart';
import 'package:quds_office_studio/studio_chrome.dart';
import 'package:quds_office_studio/studio_credential_storage.dart';
import 'package:quds_office_studio/studio_mail.dart';
import 'package:quds_office_studio/studio_downloads_manager.dart';
import 'package:quds_office_studio/studio_ribbon_preferences.dart';
import 'package:quds_office_studio/suite_workspace.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/studio_document_mode.dart';
import 'support/studio_test_settings.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Finder _command(String label) => find.byWidgetPredicate(
  (widget) => widget is StudioCmd && widget.label == label,
);

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

Future<WordEditorController> _studio(
  WidgetTester tester, {
  Size size = const Size(1440, 1000),
  double textScale = 1,
}) async {
  final preferences = StudioRibbonPreferences(persist: false);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    preferences.dispose();
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'Liberation Sans'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: SuiteWorkspace(ribbonPreferences: preferences),
    ),
  );
  await _frames(tester);
  final word = tester
      .widget<QudsWordEditor>(find.byType(QudsWordEditor))
      .controller;
  word.proofing.enabled = false;
  word.proofing.configure(OfficeProofingService(providers: []));
  word.document = WmlDocument.empty(text: 'Keep this paragraph.');
  word.commands.clear();
  word.markClean();
  word.refresh();
  await _frames(tester);
  return word;
}

Future<void> _tab(WidgetTester tester, String tab) async {
  final finder = _key('ribbon-tab-$tab');
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _frames(tester);
}

Future<void> _exposeRibbon(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scrollable = find.descendant(
      of: find.byType(StudioRibbonStrip),
      matching: find.byType(Scrollable),
    );
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pump();
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 200, scrollable: scrollable);
    }
  }
  await tester.ensureVisible(finder);
  await tester.pump();
}

Future<void> _openMenu(WidgetTester tester, String id) async {
  final finder = _key('ribbon-menu-word-layout-$id');
  await _exposeRibbon(tester, finder);
  await tester.tap(finder);
  await _frames(tester);
}

Future<void> _menu(WidgetTester tester, String id, String label) async {
  await _openMenu(tester, id);
  final choice = find.widgetWithText(MenuItemButton, label);
  expect(choice, findsOneWidget);
  await tester.ensureVisible(choice);
  await tester.tap(choice);
  await _frames(tester);
}

Future<void> _pageLayout(
  WidgetTester tester, {
  String label = 'Page Layout…',
}) async {
  final finder = _command(label);
  await _exposeRibbon(tester, finder);
  await tester.tap(finder);
  await _frames(tester);
  expect(_key('studio-page-layout-dialog'), findsOneWidget);
}

Future<void> _undo(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Undo'));
  await _frames(tester);
}

Future<void> _closeSettings(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Close'));
  await _frames(tester);
}

void _expectDark(WidgetTester tester, Finder finder) {
  final theme = Theme.of(tester.element(finder));
  expect(theme.brightness, Brightness.dark);
  expect(theme.colorScheme.surface.computeLuminance(), lessThan(0.15));
  expect(theme.colorScheme.onSurface.computeLuminance(), greaterThan(0.6));
}

void main() {
  testWidgets('Layout dropdown commands apply and Undo restores each setting', (
    tester,
  ) async {
    final word = await _studio(tester);
    final originalWidth = word.pageSize.width;
    final originalHeight = word.pageSize.height;
    await _tab(tester, 'layout');
    expect(find.widgetWithText(MenuItemButton, 'Narrow'), findsNothing);

    await _menu(tester, 'margins', 'Narrow');
    expect(word.pageMargins.matches(WmlPageMargins.narrow), isTrue);
    expect(
      tester
          .widget<StudioCommandMenu>(_key('ribbon-menu-word-layout-margins'))
          .currentValue,
      'Narrow',
    );
    await _undo(tester);
    expect(word.pageMargins.matches(WmlPageMargins.normal), isTrue);

    await _menu(tester, 'orientation', 'Landscape');
    expect(word.pageSize.isLandscape, isTrue);
    await _undo(tester);
    expect(word.pageSize.width, originalWidth);
    expect(word.pageSize.height, originalHeight);

    await _menu(tester, 'size', 'Legal');
    expect(word.pageSize.portrait.matches(WmlPageSize.legal()), isTrue);
    await _undo(tester);
    expect(word.pageSize.width, originalWidth);
    expect(word.pageSize.height, originalHeight);

    await _menu(tester, 'columns', 'Four');
    expect(word.sectionAtCaret.columnCount, 4);
    await _undo(tester);
    expect(word.sectionAtCaret.columnCount, 1);
    expect(word.document.paragraphs.single.text, 'Keep this paragraph.');
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets(
    'Paragraph presets switch exact spacing back to multiples without truncating custom spacing',
    (tester) async {
      final word = await _studio(tester);
      final props = word.document.paragraphs.single.properties;
      props.lineSpacing = 24;
      props.lineSpacingRule = WmlLineSpacingRule.exact;
      props.spacingAfter = 96;
      word.refresh();
      await _tab(tester, 'layout');
      await _menu(tester, 'paragraph', '1.5');
      expect(word.document.paragraphs.single.properties.lineSpacing, 1.5);
      expect(
        word.document.paragraphs.single.properties.lineSpacingRule,
        WmlLineSpacingRule.auto,
      );
      await _undo(tester);
      expect(word.document.paragraphs.single.properties.lineSpacing, 24);
      expect(
        word.document.paragraphs.single.properties.lineSpacingRule,
        WmlLineSpacingRule.exact,
      );
      await _menu(tester, 'paragraph', 'After+');
      expect(word.document.paragraphs.single.properties.spacingAfter, 102);
      await _undo(tester);
      expect(word.document.paragraphs.single.properties.spacingAfter, 96);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'Paragraph menu reflects the active first-page header and preserves body formatting',
    (tester) async {
      final word = await _studio(tester);
      final section = word.document.sections.first;
      section.differentFirstPage = true;
      section.header.add(
        WmlParagraph(
          properties: WmlParagraphProps(lineSpacing: 1.5),
          inlines: [WmlRun(text: 'Standard header')],
        ),
      );
      section.firstHeader.add(
        WmlParagraph(
          properties: WmlParagraphProps(lineSpacing: 2),
          inlines: [WmlRun(text: 'First header')],
        ),
      );
      word.document.paragraphs.single.properties.lineSpacing = 1;
      word.relayout();
      word.beginHeaderFooterEdit(0, footer: false);
      await _frames(tester);
      expect(
        word.editingHeaderFooterVariant,
        WordHeaderFooterVariant.firstPage,
      );
      await _tab(tester, 'layout');
      await _openMenu(tester, 'paragraph');
      final selected = find.widgetWithText(MenuItemButton, '2.0');
      expect(tester.widget<MenuItemButton>(selected).trailingIcon, isA<Icon>());
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _frames(tester);
      await _menu(tester, 'paragraph', '1.15');
      expect(section.firstHeader.single.properties.lineSpacing, 1.15);
      expect(section.header.single.properties.lineSpacing, 1.5);
      expect(word.document.paragraphs.single.properties.lineSpacing, 1);
      await _undo(tester);
      expect(section.firstHeader.single.properties.lineSpacing, 2);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'Page Layout and Paragraph dialogs are reachable from the ribbon',
    (tester) async {
      final word = await _studio(tester);
      await _tab(tester, 'layout');
      await _pageLayout(tester);
      expect(_key('page-layout-left'), findsOneWidget);
      await tester.tap(_key('page-layout-cancel'));
      await _frames(tester);

      await _tab(tester, 'home');
      final paragraph = find.byTooltip('Paragraph…');
      await _exposeRibbon(tester, paragraph);
      await tester.tap(paragraph);
      await _frames(tester);
      expect(_key('studio-paragraph-dialog'), findsOneWidget);
      await tester.tap(_key('paragraph-cancel'));
      await _frames(tester);

      await _tab(tester, 'layout');
      await _menu(tester, 'paragraph', 'Paragraph…');
      expect(_key('studio-paragraph-dialog'), findsOneWidget);
      await tester.tap(_key('paragraph-cancel'));
      await _frames(tester);
      expect(word.canUndo, isFalse);
      expect(word.document.paragraphs.single.text, 'Keep this paragraph.');
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'Document mode explains restrictions and disables layout editing',
    (tester) async {
      final word = await _studio(tester);
      for (final mode in <OfficeInteractionMode>[
        OfficeInteractionMode.selecting,
        OfficeInteractionMode.viewing,
      ]) {
        await selectStudioDocumentMode(tester, mode);
        expect(word.config.mode, mode);
        expect(word.config.allowsMutation, isFalse);
        expect(
          word.config.allowsSelection,
          mode == OfficeInteractionMode.selecting,
        );
        await _tab(tester, 'layout');
        final margins = _key('ribbon-menu-word-layout-margins');
        await _exposeRibbon(tester, margins);
        expect(
          tester
              .widget<StudioCommandMenu>(margins)
              .commands
              .every((command) => command.onPressed == null),
          isTrue,
        );
        expect(
          tester.widget<StudioCmd>(_command('Page Layout…')).onPressed,
          isNull,
        );
        await tester.tap(margins);
        await _frames(tester);
        expect(find.widgetWithText(MenuItemButton, 'Narrow'), findsNothing);
        expect(_key('studio-page-layout-dialog'), findsNothing);
      }
      await selectStudioDocumentMode(tester, OfficeInteractionMode.editing);
      expect(word.config.allowsMutation, isTrue);
      await _tab(tester, 'layout');
      expect(
        tester.widget<StudioCmd>(_command('Page Layout…')).onPressed,
        isNotNull,
      );
      await tester.tap(find.byTooltip('Settings'));
      await _frames(tester);
      expect(
        find.byType(DropdownButtonFormField<OfficeInteractionMode>),
        findsNothing,
      );
      expect(find.byType(DropdownButtonFormField<SuiteLook>), findsOneWidget);
      await _closeSettings(tester);
      expect(word.canUndo, isFalse);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'Dark appearance updates the open Settings dialog and later routes',
    (tester) async {
      final word = await _studio(tester);
      await tester.tap(find.byTooltip('Settings'));
      await _frames(tester);
      final appearance = find.byType(DropdownButtonFormField<SuiteLook>);
      await tester.ensureVisible(appearance);
      await tester.tap(appearance);
      await _frames(tester);
      await tester.tap(find.text('Dark').last);
      await _frames(tester);
      _expectDark(tester, find.byType(AlertDialog));
      expect(word.config.theme.adaptDocumentColors, isTrue);
      await _closeSettings(tester);
      final inactiveTab = tester.widget<Text>(
        find.descendant(
          of: _key('ribbon-tab-file'),
          matching: find.byType(Text),
        ),
      );
      expect(inactiveTab.style!.color!.computeLuminance(), greaterThan(0.4));

      await _tab(tester, 'layout');
      await _pageLayout(tester);
      _expectDark(tester, _key('studio-page-layout-dialog'));
      final editable = tester.widget<EditableText>(
        find.descendant(
          of: _key('page-layout-left'),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.style.color!.computeLuminance(), greaterThan(0.6));
      await tester.tap(_key('page-layout-cancel'));
      await _frames(tester);

      await _openMenu(tester, 'margins');
      final normal = find.widgetWithText(MenuItemButton, 'Normal');
      _expectDark(tester, normal);
      final label = find.descendant(of: normal, matching: find.text('Normal'));
      final rich = tester.widget<RichText>(
        find.descendant(of: label, matching: find.byType(RichText)),
      );
      expect(rich.text.style!.color!.computeLuminance(), greaterThan(0.6));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _frames(tester);
      expect(find.widgetWithText(MenuItemButton, 'Normal'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets('Downloads inherits dark Studio appearance from Settings', (
    tester,
  ) async {
    final word = await _studio(tester);
    expect(
      Theme.of(tester.element(find.byType(SuiteWorkspace))).brightness,
      Brightness.light,
    );
    await tester.tap(find.byTooltip('Settings'));
    await _frames(tester);
    final appearance = find.byType(DropdownButtonFormField<SuiteLook>);
    await tester.ensureVisible(appearance);
    await tester.tap(appearance);
    await _frames(tester);
    await tester.tap(find.text('Dark').last);
    await _frames(tester);
    _expectDark(tester, find.byType(AlertDialog));
    expect(word.config.theme.adaptDocumentColors, isTrue);

    final downloads = find.widgetWithText(ListTile, 'Downloads');
    expect(downloads, findsOneWidget);
    await tester.ensureVisible(downloads);
    await tester.tap(downloads);
    await _frames(tester);
    expect(find.byType(StudioDownloadsManager), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<SuiteLook>), findsNothing);
    _expectDark(tester, find.byType(StudioDownloadsManager));
    _expectDark(tester, find.byType(AlertDialog));

    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await _frames(tester);
    expect(find.byType(StudioDownloadsManager), findsNothing);
    expect(word.document.paragraphs.single.text, 'Keep this paragraph.');
    expect(word.canUndo, isFalse);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets(
    'narrow Arabic Layout menus and dialog stay reachable at 160 percent',
    (tester) async {
      final word = await _studio(
        tester,
        size: const Size(520, 900),
        textScale: 1.6,
      );
      await tester.tap(find.byTooltip('Settings'));
      await _frames(tester);
      final language = find.byType(DropdownButtonFormField<StudioLanguage>);
      await tester.ensureVisible(language);
      await tester.tap(language);
      await _frames(tester);
      await tester.tap(find.text('العربية').last);
      await _frames(tester);
      expect(
        Directionality.of(tester.element(find.byType(AlertDialog))),
        TextDirection.rtl,
      );
      await tester.tap(find.widgetWithText(TextButton, 'إغلاق'));
      await _frames(tester);
      await tester.tap(find.byTooltip('الإعدادات'));
      await _frames(tester);
      expect(
        Directionality.of(tester.element(find.byType(AlertDialog))),
        TextDirection.rtl,
      );
      await tester.tap(find.widgetWithText(TextButton, 'إغلاق'));
      await _frames(tester);
      await _tab(tester, 'layout');
      await _menu(tester, 'margins', 'ضيق');
      final tabText = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: _key('ribbon-tab-layout'),
          matching: find.byType(RichText),
        ),
      );
      final label = tabText.text.toPlainText();
      final boxes = tabText.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: label.length),
      );
      expect(boxes, isNotEmpty);
      for (final box in boxes) {
        expect(
          box.bottom,
          lessThanOrEqualTo(tabText.size.height + 0.1),
          reason: 'Arabic tab glyphs and descenders must fit without clipping.',
        );
      }
      expect(word.pageMargins.matches(WmlPageMargins.narrow), isTrue);
      await _pageLayout(tester, label: 'تخطيط الصفحة…');
      expect(
        Directionality.of(tester.element(_key('studio-page-layout-dialog'))),
        TextDirection.rtl,
      );
      await tester.tap(_key('page-layout-cancel'));
      await _frames(tester);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
  testWidgets(
    'Mail uses shared chrome without duplicate keys or traffic-light overlap',
    (tester) async {
      // SuiteWorkspace owns the dialog, so isolate its default catalog through
      // the public session backend without opening platform preferences.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      // Since 38b0dae0 changing the selection on macOS also clears any stale
      // Touch ID vault key over a platform channel. Answer it here: an
      // unanswered engine channel never completes inside a widget test.
      final biometricVault = MethodChannelBiometricSecretStore.defaultChannel;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        biometricVault,
        (call) async => null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          biometricVault,
          null,
        ),
      );
      final credentialSelection = StudioCredentialStorage.instance;
      final previousMode = credentialSelection.mode;
      final previousPath = credentialSelection.customPath;
      await credentialSelection.select(StudioCredentialMode.session);
      addTearDown(
        () => credentialSelection.select(previousMode, path: previousPath),
      );
      await _studio(tester);
      final mail = find.byWidgetPredicate(
        (w) => w is StudioAppSwitcher && w.label == 'Mail',
      );
      await tester.tap(mail);
      await _frames(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      final selected = tester.widget<StudioAppSwitcher>(
        find.byWidgetPredicate(
          (w) => w is StudioAppSwitcher && w.label == 'Mail' && w.selected,
        ),
      );
      expect(selected.selected, isTrue);
      final mailDialog = find.byType(StudioMailDialog);
      final trafficLightSpace = find.descendant(
        of: mailDialog,
        matching: find.byKey(const ValueKey('native-traffic-light-space')),
      );
      expect(trafficLightSpace, findsOneWidget);
      expect(find.text('Credential storage'), findsNothing);
      final ribbon = find.descendant(
        of: mailDialog,
        matching: find.byType(StudioRibbonStrip),
      );
      expect(ribbon, findsOneWidget);
      expect(
        find.descendant(
          of: mailDialog,
          matching: find.widgetWithText(StudioTabChip, 'Home'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(ribbon).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(trafficLightSpace).dy),
      );
      final close = find.descendant(
        of: ribbon,
        matching: find.byTooltip('Close'),
      );
      expect(close, findsOneWidget);
      await tester.tap(close);
      await _frames(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(QudsWordEditor), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}

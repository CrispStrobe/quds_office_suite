import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quds_office_studio/credentials/secure_storage_service.dart';
import 'package:quds_office_studio/studio_credential_settings.dart';
import 'package:quds_office_studio/studio_credential_storage.dart';
import 'package:quds_office_studio/studio_mail_credentials.dart';
import 'package:quds_office_studio/studio_mail_native.dart';
import 'package:quds_office_studio/studio_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _DelayedSelection extends StudioCredentialStorage {
  final entered = Completer<void>();
  final release = Completer<void>();
  bool fail = false;
  int selections = 0;

  @override
  Future<void> loadSelection() async {}

  @override
  Future<bool> vaultExists() async => false;

  @override
  Future<void> select(StudioCredentialMode next, {String? path}) async {
    selections++;
    entered.complete();
    await release.future;
    if (fail) throw StateError('Synthetic selected-store failure');
    mode = next;
  }
}

Future<void> _open(
  WidgetTester tester,
  StudioCredentialStorage manager,
  void Function(bool) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => onResult(
              await showStudioCredentialSettings(context, manager: manager),
            ),
            child: const Text('Open storage'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open storage'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'a delayed system-store probe cannot cache under a newly selected mode',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      final entered = Completer<void>();
      final release = Completer<void>();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      // Since 3307415d the system-store probe writes, reads back and deletes
      // a nonce key; hold the first probe call until the selection changed.
      final probed = <String, String>{};
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (!entered.isCompleted) {
          entered.complete();
          await release.future;
        }
        final arguments = (call.arguments as Map).cast<String, Object?>();
        final key = arguments['key'] as String?;
        switch (call.method) {
          case 'write':
            probed[key!] = arguments['value']! as String;
            return null;
          case 'read':
            return probed[key];
          case 'delete':
            probed.remove(key);
            return null;
          case 'containsKey':
            return probed.containsKey(key);
        }
        fail('Unexpected secure-storage call ${call.method}');
      });
      addTearDown(() {
        if (!release.isCompleted) release.complete();
        messenger.setMockMethodCallHandler(channel, null);
      });
      final manager = StudioCredentialStorage();
      addTearDown(manager.dispose);
      await manager.loadSelection();
      final pendingSystem = manager.storage;
      await entered.future;
      await manager.select(StudioCredentialMode.session);
      release.complete();
      final original = await pendingSystem;
      final selected = await manager.storage;
      expect(original, isA<PlatformSecureStorage>());
      expect(selected, isA<InMemorySecureStorage>());
      expect(selected, isNot(same(original)));
      expect(selected.isPersistent, isFalse);
      expect(manager.mode, StudioCredentialMode.session);
    },
  );

  test('only committed choices advance the selection revision', () async {
    final manager = StudioCredentialStorage();
    addTearDown(manager.dispose);
    await manager.loadSelection();
    expect(manager.revision, 0);
    await manager.select(StudioCredentialMode.session);
    expect(manager.revision, 1);
    await expectLater(
      manager.select(StudioCredentialMode.encryptedVault),
      throwsStateError,
    );
    expect(manager.revision, 1);
    expect(manager.mode, StudioCredentialMode.session);
    await manager.select(StudioCredentialMode.system);
    expect(manager.revision, 2);
  });

  testWidgets('selection stays open across barrier and back until committed', (
    tester,
  ) async {
    final manager = _DelayedSelection();
    addTearDown(manager.dispose);
    bool? result;
    await _open(tester, manager, (value) => result = value);
    await tester.tap(find.text('Use this store'));
    await tester.pump();
    await manager.entered.future;
    final dialogContext = tester.element(find.byType(AlertDialog));
    expect(ModalRoute.of(dialogContext)!.barrierDismissible, isFalse);
    expect(
      tester.widget<PopScope<bool>>(find.byType(PopScope<bool>)).canPop,
      isFalse,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
          .onPressed,
      isNull,
    );
    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    await Navigator.of(dialogContext).maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(result, isNull);
    expect(manager.selections, 1);
    manager.release.complete();
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'Cancel before selection returns false without changing a store',
    (tester) async {
      final manager = _DelayedSelection();
      addTearDown(manager.dispose);
      bool? result;
      await _open(tester, manager, (value) => result = value);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(manager.selections, 0);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('failed selection re-enables Cancel and leaves the dialog open', (
    tester,
  ) async {
    final manager = _DelayedSelection()..fail = true;
    addTearDown(manager.dispose);
    bool? result;
    await _open(tester, manager, (value) => result = value);
    await tester.tap(find.text('Use this store'));
    await tester.pump();
    await manager.entered.future;
    manager.release.complete();
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      tester.widget<PopScope<bool>>(find.byType(PopScope<bool>)).canPop,
      isTrue,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
  testWidgets(
    'an open Mail dialog reloads an externally selected empty store',
    (tester) async {
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final systemReads = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        // No native credential service is touched by this test. This callback
        // also runs while pumpAndSettle owns the test's asynchronous guard.
        expectSync(call.method, 'read');
        systemReads.add((call.arguments as Map)['key'] as String);
        return null;
      });
      final manager = StudioCredentialStorage.instance;
      await manager.select(StudioCredentialMode.session);
      final session = await manager.storage;
      expect(session, isA<InMemorySecureStorage>());
      await session.deleteAll();
      await tester.binding.setSurfaceSize(const Size(1280, 1500));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await manager.select(StudioCredentialMode.session);
        await session.deleteAll();
        messenger.setMockMethodCallHandler(channel, null);
        await tester.binding.setSurfaceSize(null);
      });
      const saved = StudioMailCredentials(
        email: 'session-only@example.test',
        password: 'synthetic-session-password',
        imapHost: 'imap.example.test',
        smtpHost: 'smtp.example.test',
        manual: true,
        startTls: false,
      );
      expect(await StudioMailAccountsStore().save(saved), isTrue);
      await tester.pumpWidget(
        const MaterialApp(
          home: StudioMailDialog(strings: StudioStrings(StudioLanguage.en)),
        ),
      );
      await tester.pumpAndSettle();
      Finder field(String hint) => find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.autofillHints?.contains(hint) == true,
      );
      String text(String hint) =>
          tester.widget<TextField>(field(hint)).controller!.text;
      final savedAccount = find.descendant(
        of: find.byKey(const ValueKey('studio-mail-saved-account')),
        matching: find.byType(DropdownButtonFormField<String>),
      );
      expect(text(AutofillHints.email), saved.email);
      expect(text(AutofillHints.password), saved.password);
      expect(
        tester.state<FormFieldState<String>>(savedAccount).value,
        saved.accountId,
      );

      // Model another window committing its app-wide storage choice.
      await manager.select(StudioCredentialMode.system);
      await tester.pumpAndSettle();
      expect(systemReads, [
        'crispoffice.mail.accounts.v2',
        'crispoffice.mail.account.v1',
      ]);
      expect(text(AutofillHints.email), isEmpty);
      expect(text(AutofillHints.password), isEmpty);
      expect(tester.state<FormFieldState<String>>(savedAccount).value, isNull);
      final original = await StudioMailAccountsStore(
        storage: () async => session,
      ).loadAccounts();
      expect(original.catalog!.selectedAccountId, saved.accountId);
      expect(tester.takeException(), isNull);
    },
  );
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quds_mail_core/quds_mail_core.dart';
import 'package:quds_mail_transport/quds_mail_transport.dart';
import 'package:quds_mail_ui/quds_mail_ui.dart';
import 'package:quds_office_studio/studio_mail_bulk_status.dart';
import 'package:quds_office_studio/studio_mail_ews.dart';
import 'package:quds_office_studio/studio_strings.dart';
import 'package:quds_office_studio/studio_mail_workspace_strings.dart';

import 'support/mail_draft_store.dart';

const _strings = StudioStrings(StudioLanguage.en);
const _success = MailSuccess<MailUnit>(MailUnit.value);
const _definiteFailure = MailFailure<MailUnit>(
  MailProblem(MailProblemCode.permissionDenied, mutationMayHaveOccurred: false),
);
const _uncertain = MailFailure<MailUnit>(
  MailProblem(MailProblemCode.unavailable),
);

class _Provider extends Fake implements MailProvider {
  _Provider(this.account, this.kind);

  @override
  final MailAccountId account;
  final MailProviderKind kind;
  final commands = <MailOperation>[];
  final leases = <MailOperationLease>[];
  FutureOr<MailResult<MailUnit>> Function(MailOperation, int)? respond;
  int headerReads = 0;
  int bodyReads = 0;
  int disposals = 0;

  MailMailboxId box(String name) => MailMailboxId(name, account: account);
  MailRemoteIdentity remote(String id) =>
      MailOpaqueIdentity(account: account, provider: kind, value: 'remote-$id');

  List<MailHeaderRecord> get headers => [
    for (final id in ['one', 'two', 'three'])
      MailHeaderRecord(
        id: MailMessageId(id),
        remote: remote(id),
        envelope: MailEnvelope(
          subject: 'Frozen subject $id',
          from: [const MailAddress('writer@example.test')],
        ),
        flags: id == 'two' ? const MailMessageFlags(isFlagged: true) : null,
      ),
  ];

  @override
  Future<MailResult<MailCapabilities>> capabilities(
    MailOperationLease lease,
  ) async => MailSuccess(
    MailCapabilities(const [MailCapability.mail, MailCapability.folders]),
  );

  @override
  Future<MailResult<List<MailMailbox>>> listMailboxes(
    MailOperationLease lease,
  ) async => MailSuccess([
    MailMailbox(id: box('inbox'), displayName: 'Inbox'),
    MailMailbox(id: box('archive'), displayName: 'Archive'),
  ]);

  @override
  Future<MailResult<MailHeaderPage>> fetchHeaders(
    MailMailboxId mailbox, {
    MailCursor? cursor,
    required int limit,
    required MailOperationLease lease,
  }) async {
    headerReads++;
    return MailSuccess(MailHeaderPage(messages: headers));
  }

  @override
  Future<MailResult<MailMessage>> fetchMessage(
    MailRemoteIdentity identity, {
    required MailReadBudget budget,
    required MailOperationLease lease,
  }) async {
    bodyReads++;
    final header = headers.firstWhere((header) => header.remote == identity);
    return MailSuccess(
      MailMessage(
        raw: MailBytes(
          Uint8List.fromList('Subject: Frozen\r\n\r\nbody'.codeUnits),
        ),
        envelope: header.envelope,
        body: const MailBody(plainText: 'Opened message body'),
        localId: header.id,
        remoteIdentity: identity,
      ),
    );
  }

  @override
  Future<MailResult<MailUnit>> apply(
    MailOperation operation,
    MailOperationLease lease,
  ) async {
    commands.add(operation);
    leases.add(lease);
    return respond == null
        ? _success
        : await respond!(operation, commands.length);
  }
}

final class _EwsProvider extends _Provider implements MailEwsProvider {
  _EwsProvider(this.configuration)
    : super(configuration.account, MailProviderKind.ews);

  final MailEwsConfiguration configuration;
}

final class _CloudProvider extends _Provider implements MailCloudProvider {
  _CloudProvider(this.configuration)
    : super(
        configuration.account,
        configuration.service == MailCloudService.gmail
            ? MailProviderKind.gmail
            : MailProviderKind.graph,
      );

  final MailCloudConfiguration configuration;

  @override
  void dispose() => disposals++;
}

final class _Tokens extends Fake implements MailCloudTokenSource {
  @override
  void dispose() {}
}

final class _Harness {
  _Harness(this.kind);
  final MailProviderKind kind;
  final drafts = MemoryStudioMailDrafts();
  final providers = <_Provider>[];
  void Function(_Provider)? configure;
  _Provider get provider => providers.last;

  Widget dialog() {
    if (kind == MailProviderKind.ews) {
      return StudioMailEwsDialog(
        strings: _strings,
        draftStoreFactory: drafts.open,
        providerFactory: (configuration, credentials) {
          final provider = _EwsProvider(configuration);
          configure?.call(provider);
          providers.add(provider);
          return provider;
        },
      );
    }
    return StudioMailEwsDialog.cloud(
      strings: _strings,
      service: kind == MailProviderKind.gmail
          ? MailCloudService.gmail
          : MailCloudService.microsoft365,
      initialClientId: 'test-desktop-client',
      draftStoreFactory: drafts.open,
      cloudAuthorizer:
          ({
            required configuration,
            required account,
            required openBrowser,
            required lease,
            log,
          }) async => MailSuccess(_Tokens()),
      cloudProviderFactory:
          ({required configuration, required tokenSource, log}) {
            final provider = _CloudProvider(configuration);
            configure?.call(provider);
            providers.add(provider);
            return provider;
          },
    );
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

Future<void> _show(WidgetTester tester, _Harness harness) async {
  tester.view
    ..physicalSize = const Size(1280, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => harness.dialog(),
            ),
            child: const Text('Open mail'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open mail'));
  await _pump(tester);
  await _connect(tester, harness.kind);
}

Future<void> _connect(WidgetTester tester, MailProviderKind kind) async {
  if (kind == MailProviderKind.ews) {
    await tester.enterText(
      _key('ews-endpoint'),
      'https://mail.example.test/EWS/Exchange.asmx',
    );
    await tester.enterText(_key('ews-mailbox'), 'reader@example.test');
    await tester.enterText(_key('ews-login'), 'reader');
    await tester.enterText(_key('ews-password'), 'test-password');
  } else {
    await tester.enterText(_key('cloud-mailbox'), 'reader@example.test');
  }
  final connect = _key(
    kind == MailProviderKind.ews ? 'ews-connect' : 'cloud-connect',
  );
  await tester.ensureVisible(connect);
  await tester.tap(connect);
  await _pump(tester);
  expect(find.byType(MailMessageList), findsOneWidget);
}

MailMessageList _list(WidgetTester tester) =>
    tester.widget(find.byType(MailMessageList));
StudioMailBulkStatus _status(WidgetTester tester) =>
    tester.widget(find.byType(StudioMailBulkStatus));
List<String> _ids(WidgetTester tester) =>
    _list(tester).items.map((item) => item.id).toList();

Future<void> _start(WidgetTester tester, MailBulkFlagAction action) async {
  final list = _list(tester);
  list.onBulkAction!(action, _ids(tester));
  await _pump(tester);
}

void _counts(
  WidgetTester tester,
  int confirmed,
  int failed,
  int uncertain,
  int unattempted,
) {
  final report = _status(tester).report;
  expect(report.confirmedCount, confirmed);
  expect(report.failedCount, failed);
  expect(report.uncertainCount, uncertain);
  expect(report.unattemptedCount, unattempted);
}

void main() {
  for (final kind in [
    MailProviderKind.ews,
    MailProviderKind.gmail,
    MailProviderKind.graph,
  ]) {
    testWidgets(
      '${kind.name}: reversed subset freezes caller IDs and preserves the reader',
      (tester) async {
        final harness = _Harness(kind);
        await _show(tester, harness);
        _list(tester).onOpen('ews-message-one');
        await _pump(tester);
        final reader = tester
            .widget<MailMessageView>(find.byType(MailMessageView))
            .controller;
        expect(harness.provider.bodyReads, 1);
        for (final action in MailBulkFlagAction.values) {
          final gate = Completer<MailResult<MailUnit>>();
          harness.provider.respond = (_, _) => gate.future;
          final before = harness.provider.commands.length;
          final ids = ['ews-message-three', 'ews-message-two'];
          _list(tester).onBulkAction!(action, ids);
          ids
            ..clear()
            ..add('ews-message-one');
          await tester.pump();
          expect(harness.provider.commands, hasLength(before + 1));
          gate.complete(_success);
          await _pump(tester);
          final commands = harness.provider.commands.skip(before).toList();
          expect(commands.map((command) => command.message), [
            harness.provider.remote('three'),
            harness.provider.remote('two'),
          ]);
          final readAction =
              action == MailBulkFlagAction.markRead ||
              action == MailBulkFlagAction.markUnread;
          final desired =
              action == MailBulkFlagAction.markRead ||
              action == MailBulkFlagAction.flag;
          for (final command in commands) {
            if (readAction) {
              expect(command, isA<MailSetRead>());
              expect((command as MailSetRead).read, desired);
            } else {
              expect(command, isA<MailSetFlagged>());
              expect((command as MailSetFlagged).flagged, desired);
            }
          }
          expect(
            tester
                .widget<MailMessageView>(find.byType(MailMessageView))
                .controller,
            same(reader),
          );
          expect(_list(tester).selectedId, 'ews-message-one');
          expect(_list(tester).items.first.isRead, isNull);
          expect(_list(tester).items.first.isFlagged, isNull);
          _counts(tester, 2, 0, 0, 0);
        }
        expect(harness.provider.bodyReads, 1);
        expect(harness.provider.headerReads, 1);
      },
    );

    testWidgets(
      '${kind.name}: folder A B A rejects callbacks from the earlier observation',
      (tester) async {
        final harness = _Harness(kind);
        await _show(tester, harness);
        final callback = _list(tester).onBulkAction!;
        final ids = _ids(tester);
        await tester.tap(find.text('Archive'));
        await _pump(tester);
        await tester.tap(find.text('Inbox'));
        await _pump(tester);
        callback(MailBulkFlagAction.markRead, ids);
        await _pump(tester);
        expect(harness.provider.commands, isEmpty);
        expect(harness.provider.headerReads, 3);
        await _start(tester, MailBulkFlagAction.flag);
        _counts(tester, 3, 0, 0, 0);
        expect(harness.provider.bodyReads, 0);
      },
    );

    testWidgets(
      '${kind.name}: generic failure codes never certify an unchanged server',
      (tester) async {
        final harness = _Harness(kind);
        await _show(tester, harness);
        for (final code in [
          MailProblemCode.cancelled,
          MailProblemCode.staleOperation,
          MailProblemCode.permissionDenied,
        ]) {
          final before = harness.provider.commands.length;
          harness.provider.respond = (_, _) => MailFailure(MailProblem(code));
          await _start(tester, MailBulkFlagAction.flag);
          _counts(tester, 0, 0, 1, 2);
          expect(harness.provider.commands, hasLength(before + 1));
          expect(_list(tester).bulkActionsEnabled, isFalse);
          await tester.tap(find.byTooltip(_strings.refresh));
          await _pump(tester);
        }
        expect(harness.provider.bodyReads, 0);
      },
    );

    testWidgets(
      '${kind.name}: selected bulk actions update only confirmed target flags without body fetches',
      (tester) async {
        final harness = _Harness(kind);
        await _show(tester, harness);
        for (final action in MailBulkFlagAction.values) {
          await tester.ensureVisible(_key('mail-list-select-shown'));
          await tester.tap(_key('mail-list-select-shown'));
          await _pump(tester);
          await tester.tap(_key('mail-list-bulk-actions'));
          await _pump(tester);
          await tester.tap(_key('mail-list-bulk-${action.name}'));
          await _pump(tester);
          final items = _list(tester).items;
          final readAction =
              action == MailBulkFlagAction.markRead ||
              action == MailBulkFlagAction.markUnread;
          final desired =
              action == MailBulkFlagAction.markRead ||
              action == MailBulkFlagAction.flag;
          expect(
            items.map((item) => readAction ? item.isRead : item.isFlagged),
            everyElement(desired),
          );
          if (action == MailBulkFlagAction.markRead) {
            expect(items.first.isFlagged, isNull);
            expect(items[1].isFlagged, isTrue);
          }
          _counts(tester, 3, 0, 0, 0);
          expect(_status(tester).running, isFalse);
        }
        expect(harness.provider.commands, hasLength(12));
        expect(
          harness.provider.commands.map((command) => command.id).toSet(),
          hasLength(12),
        );
        expect(harness.provider.bodyReads, 0);
        expect(harness.provider.headerReads, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${kind.name}: request limit stops the tail and preserves retry guidance without refresh',
      (tester) async {
        final harness = _Harness(kind)
          ..configure = (provider) {
            provider.respond = (_, _) => const MailFailure(
              MailProblem(
                MailProblemCode.quotaExceeded,
                retryAfter: Duration(seconds: 12),
                mutationMayHaveOccurred: false,
              ),
            );
          };
        await _show(tester, harness);
        await _start(tester, MailBulkFlagAction.flag);
        _counts(tester, 0, 1, 0, 2);
        expect(harness.provider.commands, hasLength(1));
        expect(
          _status(tester).report.stopReason,
          MailBulkFlagStopReason.rateLimited,
        );
        expect(_status(tester).report.requiresRefresh, isFalse);
        expect(_list(tester).bulkActionsEnabled, isTrue);
        expect(find.textContaining('Request limit reached.'), findsOneWidget);
        expect(
          find.text('Wait at least 12 seconds before trying again.'),
          findsOneWidget,
        );
        expect(harness.provider.bodyReads, 0);
        expect(harness.provider.headerReads, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${kind.name}: certified stale scope requires refresh before a new batch',
      (tester) async {
        final harness = _Harness(kind);
        await _show(tester, harness);
        harness.provider.respond = (_, _) => const MailFailure(
          MailProblem(
            MailProblemCode.staleOperation,
            mutationMayHaveOccurred: false,
          ),
        );
        await _start(tester, MailBulkFlagAction.flag);
        _counts(tester, 0, 1, 0, 2);
        expect(harness.provider.commands, hasLength(1));
        expect(_list(tester).bulkEnabled, isFalse);
        expect(
          find.textContaining('verify the current message state'),
          findsOneWidget,
        );
        expect(_key('studio-mail-bulk-dismiss'), findsNothing);
        expect(
          find.text(_strings.mailWorkspaceRefreshRequired),
          findsOneWidget,
        );
        _list(tester).onBulkAction!(MailBulkFlagAction.markRead, _ids(tester));
        await _pump(tester);
        expect(harness.provider.commands, hasLength(1));
        harness.provider.respond = (_, _) => _success;
        await tester.tap(find.byTooltip(_strings.refresh));
        await _pump(tester);
        expect(_list(tester).bulkEnabled, isTrue);
        await _start(tester, MailBulkFlagAction.markRead);
        _counts(tester, 3, 0, 0, 0);
        expect(harness.provider.headerReads, 2);
        expect(harness.provider.bodyReads, 0);
      },
    );

    testWidgets(
      '${kind.name}: definite failure remains failed while independent later messages continue',
      (tester) async {
        final harness = _Harness(kind)
          ..configure = (provider) {
            provider.respond = (_, index) =>
                index == 1 ? _definiteFailure : _success;
          };
        await _show(tester, harness);
        await _start(tester, MailBulkFlagAction.markRead);
        _counts(tester, 2, 1, 0, 0);
        expect(harness.provider.commands, hasLength(3));
        expect(_list(tester).items.first.isRead, isNull);
        expect(
          _list(tester).items.skip(1).map((item) => item.isRead),
          everyElement(isTrue),
        );
        expect(_list(tester).bulkActionsEnabled, isTrue);
        expect(harness.provider.bodyReads, 0);
      },
    );

    testWidgets(
      '${kind.name}: uncertainty stops dispatch, requires refresh and rejects stale refresh callbacks',
      (tester) async {
        final harness = _Harness(kind)
          ..configure = (provider) {
            provider.respond = (_, index) => index == 2 ? _uncertain : _success;
          };
        await _show(tester, harness);
        final oldCallback = _list(tester).onBulkAction!;
        final selected = _ids(tester);
        oldCallback(MailBulkFlagAction.markRead, selected);
        await _pump(tester);
        _counts(tester, 1, 0, 1, 1);
        expect(harness.provider.commands, hasLength(2));
        expect(_list(tester).items.first.isRead, isTrue);
        expect(_list(tester).items[1].isRead, isFalse);
        expect(_list(tester).items.last.isRead, isNull);
        expect(_list(tester).bulkActionsEnabled, isFalse);
        oldCallback(MailBulkFlagAction.flag, selected);
        await _pump(tester);
        expect(harness.provider.commands, hasLength(2));
        await tester.tap(find.byTooltip(_strings.refresh));
        await _pump(tester);
        expect(_list(tester).bulkActionsEnabled, isTrue);
        oldCallback(MailBulkFlagAction.flag, selected);
        await _pump(tester);
        expect(harness.provider.commands, hasLength(2));
        await _start(tester, MailBulkFlagAction.flag);
        expect(harness.provider.commands, hasLength(5));
        expect(harness.provider.bodyReads, 0);
        expect(harness.provider.headerReads, 2);
      },
    );

    testWidgets(
      '${kind.name}: thrown provider errors remain uncertain without exposing private text',
      (tester) async {
        final harness = _Harness(kind)
          ..configure = (provider) {
            provider.respond = (_, _) =>
                throw StateError('private-provider-password');
          };
        await _show(tester, harness);
        await _start(tester, MailBulkFlagAction.flag);
        _counts(tester, 0, 0, 1, 2);
        expect(harness.provider.commands, hasLength(1));
        expect(_list(tester).items.first.isFlagged, isNull);
        expect(find.textContaining('private-provider-password'), findsNothing);
        expect(harness.provider.bodyReads, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${kind.name}: Stop retains in-flight confirmation and leaves the remaining selection unattempted',
      (tester) async {
        final gate = Completer<MailResult<MailUnit>>();
        final harness = _Harness(kind)
          ..configure = (provider) {
            provider.respond = (_, _) => gate.future;
          };
        await _show(tester, harness);
        await _start(tester, MailBulkFlagAction.markRead);
        expect(harness.provider.commands, hasLength(1));
        expect(_status(tester).running, isTrue);
        await tester.ensureVisible(_key('mail-list-stop-bulk'));
        await tester.tap(_key('mail-list-stop-bulk'));
        await _pump(tester);
        expect(harness.provider.leases.single.isCurrent, isTrue);
        gate.complete(_success);
        await _pump(tester);
        _counts(tester, 1, 0, 0, 2);
        expect(
          _status(tester).report.stopReason,
          MailBulkFlagStopReason.cancelled,
        );
        expect(_status(tester).running, isFalse);
        expect(_list(tester).items.first.isRead, isTrue);
        expect(_list(tester).bulkActionsEnabled, isTrue);
        expect(harness.provider.commands, hasLength(1));
        expect(harness.provider.bodyReads, 0);
      },
    );

    testWidgets(
      '${kind.name}: disconnect and reconnect cannot project late results into overlapping row IDs',
      (tester) async {
        final gate = Completer<MailResult<MailUnit>>();
        final harness = _Harness(kind)
          ..configure = (provider) {
            provider.respond = (_, _) => gate.future;
          };
        await _show(tester, harness);
        final oldProvider = harness.provider;
        final oldCallback = _list(tester).onBulkAction!;
        final ids = _ids(tester);
        oldCallback(MailBulkFlagAction.markRead, ids);
        await _pump(tester);
        await tester.tap(find.byTooltip(_strings.disconnect));
        await _pump(tester);
        harness.configure = null;
        await _connect(tester, kind);
        final currentProvider = harness.provider;
        // Since 45f0e503 the account id is derived from the stable account
        // settings, so a reconnect to the same mailbox reuses it. Isolation
        // now rests on the per-connection provider and session lease.
        expect(currentProvider, isNot(same(oldProvider)));
        expect(oldProvider.leases.single.isCurrent, isFalse);
        gate.complete(_success);
        await _pump(tester);
        oldCallback(MailBulkFlagAction.flag, ids);
        await _pump(tester);
        expect(oldProvider.commands, hasLength(1));
        expect(currentProvider.commands, isEmpty);
        expect(_list(tester).items.first.isRead, isNull);
        expect(find.byType(StudioMailBulkStatus), findsNothing);
        expect(oldProvider.bodyReads + currentProvider.bodyReads, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${kind.name}: invalid selections are refused atomically and closed dialogs stop further dispatch',
      (tester) async {
        final gate = Completer<MailResult<MailUnit>>();
        final harness = _Harness(kind)
          ..configure = (provider) {
            provider.respond = (_, _) => gate.future;
          };
        await _show(tester, harness);
        final callback = _list(tester).onBulkAction!;
        final ids = _ids(tester);
        callback(MailBulkFlagAction.flag, [ids.first, 'not-in-folder']);
        callback(MailBulkFlagAction.flag, [ids.first, ids.first]);
        await _pump(tester);
        expect(harness.provider.commands, isEmpty);
        callback(MailBulkFlagAction.flag, ids);
        await _pump(tester);
        expect(harness.provider.commands, hasLength(1));
        await tester.tap(find.byTooltip(_strings.close));
        await _pump(tester);
        gate.complete(_success);
        await _pump(tester);
        callback(MailBulkFlagAction.flag, ids);
        await _pump(tester);
        expect(harness.provider.commands, hasLength(1));
        expect(harness.provider.bodyReads, 0);
        expect(find.byType(StudioMailEwsDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final language in StudioLanguage.values) {
    testWidgets(
      '${language.name}: bulk receipts keep all outcomes and compact localized details accessible',
      (tester) async {
        tester.view
          ..physicalSize = const Size(320, 260)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final account = MailAccountId(
          'receipt',
          profile: MailProfileId('receipt', hostId: 'test'),
        );
        final session = MailAccountSession(account);
        addTearDown(session.dispose);
        final identities = [
          for (var i = 0; i < 4; i++)
            MailOpaqueIdentity(
              account: account,
              provider: MailProviderKind.ews,
              value: 'id-$i',
            ),
        ];
        var calls = 0;
        final report = await MailBulkFlagCoordinator().run(
          plan: MailBulkFlagPlan(
            id: 'receipt',
            mailbox: MailMailboxId('inbox', account: account),
            provider: MailProviderKind.ews,
            action: MailBulkFlagAction.markUnread,
            messages: identities,
          ),
          lease: session.begin(),
          apply: (_, _) async =>
              MailBulkFlagAttempt.fromResult(switch (++calls) {
                1 => _success,
                2 => _definiteFailure,
                _ => _uncertain,
              }),
          isScopeCurrent: () => true,
        );
        final direction = language == StudioLanguage.ar
            ? TextDirection.rtl
            : TextDirection.ltr;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 260),
                textScaler: TextScaler.linear(1.5),
              ),
              child: Directionality(
                textDirection: direction,
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: StudioMailBulkStatus(
                      strings: StudioStrings(language),
                      report: report,
                      running: false,
                      subjects: {
                        for (var i = 0; i < 4; i++)
                          identities[i]: 'Frozen subject $i',
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await _pump(tester);
        _counts(tester, 1, 1, 1, 1);
        await tester.ensureVisible(_key('studio-mail-bulk-details'));
        await tester.tap(_key('studio-mail-bulk-details'));
        await _pump(tester);
        expect(_key('studio-mail-bulk-details-dialog'), findsOneWidget);
        expect(
          Directionality.of(tester.element(_key('studio-mail-bulk-result-0'))),
          direction,
        );
        expect(find.text('Frozen subject 0'), findsOneWidget);
        final list = find.descendant(
          of: _key('studio-mail-bulk-details-dialog'),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          _key('studio-mail-bulk-result-3'),
          80,
          scrollable: list,
        );
        expect(find.text('Frozen subject 3'), findsOneWidget);
        await tester.tap(_key('studio-mail-bulk-details-close'));
        await _pump(tester);
        expect(_key('studio-mail-bulk-details-dialog'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

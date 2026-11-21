import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:quds_mail_core/quds_mail_core.dart';
import 'package:quds_mail_mime/quds_mail_mime.dart';
import 'package:quds_mail_transport/quds_mail_transport.dart';
import 'package:quds_mail_ui/quds_mail_ui.dart';
import 'package:quds_mail_store/quds_mail_store.dart';
import 'package:quds_office_editor/quds_office_editor.dart';
import 'package:quds_office_studio/studio_mail_compose.dart';
import 'package:quds_office_studio/studio_mail_bulk_status.dart';
import 'package:quds_office_studio/studio_mail_ews.dart';
import 'package:quds_office_studio/studio_mail_native.dart';
import 'package:quds_office_studio/studio_mail_strings.dart';
import 'package:quds_office_studio/studio_mail_workspace_strings.dart';
import 'package:quds_office_studio/studio_strings.dart';
import 'package:quds_office_studio/studio_mail_archive_action.dart';
import 'package:quds_office_studio/studio_mail_archive_folder_action.dart';
import 'package:quds_office_studio/studio_mail_archive_strings.dart';

import 'support/mail_attachment_picker.dart';
import 'support/mail_draft_store.dart';

const _strings = StudioStrings(StudioLanguage.en);

final class _Provider extends Fake implements MailEwsProvider {
  _Provider(this.configuration, this.credentials);
  final MailEwsConfiguration configuration;
  final MailCredentialStore credentials;
  Completer<MailResult<MailCapabilities>>? connectGate;
  Completer<MailResult<MailMessage>>? messageGate;
  Completer<MailResult<MailHeaderPage>>? headerGate;
  MailHeaderPage Function(MailMailboxId, MailCursor?)? headerPage;
  Completer<MailSubmissionResult>? sendGate;
  MailSubmissionOutcome outcome = MailSubmissionOutcome.accepted;
  MailCapabilities supported = MailCapabilities(const [
    MailCapability.mail,
    MailCapability.folders,
    MailCapability.send,
    MailCapability.move,
  ]);
  MailProblem? mutationProblem;
  Future<MailResult<MailUnit>> Function(MailOperation, MailOperationLease)?
  mutationHandler;
  bool failConnection = false;
  int connects = 0;
  int lists = 0;
  int reads = 0;
  String firstMessageId = 'one';
  bool replyParticipants = false;
  MailEnvelope? envelopeOverride;
  void Function()? onSubmit;
  final List<MailCursor?> cursors = [];
  final List<int> headerLimits = [];
  final List<MailOperation> commands = [];
  final List<MailPreparedMessage> submissions = [];
  final List<String> attempts = [];
  MailOperationLease? lastLease;

  @override
  MailAccountId get account => configuration.account;
  MailMailboxId box(String name) => MailMailboxId(name, account: account);
  MailOpaqueIdentity identity(String id) => MailOpaqueIdentity(
    account: account,
    provider: MailProviderKind.ews,
    value: id,
  );

  MailHeaderRecord header(
    String id,
    String subject, {
    MailMessageFlags? flags = const MailMessageFlags(),
    MailEnvelope? envelope,
  }) => MailHeaderRecord(
    id: MailMessageId(id),
    remote: identity(id),
    envelope:
        envelope ??
        MailEnvelope(
          subject: subject,
          from: [const MailAddress('writer@example.test')],
        ),
    flags: flags,
  );

  MailMessage message() {
    final bytes = utf8.encode(
      'From: Writer <writer@example.test>\r\n'
      'To: Reader <reader@example.test>${replyParticipants ? ', teammate@example.test' : ''}\r\n'
      '${replyParticipants ? 'Reply-To: author@example.test\r\nCc: copied@example.test\r\nMessage-ID: <parent@example.test>\r\nReferences: <root@example.test>\r\n' : ''}'
      'Subject: First Exchange message\r\n'
      'Bcc: hidden@example.test\r\nX-Preserved:  original\r\n\tfolding\r\n'
      'MIME-Version: 1.0\r\nContent-Type: multipart/mixed; boundary=fixture\r\n'
      '\r\n--fixture\r\nContent-Type: text/plain; charset=utf-8\r\n'
      '\r\nA message from Exchange.\r\n'
      '--fixture\r\nContent-Type: application/octet-stream\r\n'
      'Content-Disposition: attachment; filename=example.txt\r\n'
      'Content-Transfer-Encoding: base64\r\n\r\nZXhhbXBsZQ==\r\n'
      '--fixture--\r\n',
    );
    final parsed = const QudsMimeCodec().parse(bytes).message!;
    return MailMessage(
      raw: parsed.raw,
      envelope: envelopeOverride ?? parsed.envelope,
      body: parsed.body,
      attachments: parsed.attachments,
      remoteIdentity: identity(firstMessageId),
      localId: MailMessageId(firstMessageId),
    );
  }

  @override
  Future<MailResult<MailCapabilities>> capabilities(
    MailOperationLease lease,
  ) async {
    connects++;
    lastLease = lease;
    if (failConnection) throw StateError('private-password-and-server-text');
    return connectGate == null
        ? MailSuccess(supported)
        : await connectGate!.future;
  }

  @override
  Future<MailResult<List<MailMailbox>>> listMailboxes(
    MailOperationLease lease,
  ) async {
    lists++;
    lastLease = lease;
    return MailSuccess([
      MailMailbox(id: box('inbox'), displayName: 'Inbox'),
      MailMailbox(id: box('archive'), displayName: 'Archive'),
    ]);
  }

  @override
  Future<MailResult<MailHeaderPage>> fetchHeaders(
    MailMailboxId mailbox, {
    MailCursor? cursor,
    required int limit,
    required MailOperationLease lease,
  }) async {
    cursors.add(cursor);
    headerLimits.add(limit);
    lastLease = lease;
    expect(limit, inInclusiveRange(1, 50));
    if (headerGate case final gate?) return gate.future;
    if (headerPage case final page?) return MailSuccess(page(mailbox, cursor));
    if (mailbox.value == 'archive') {
      return MailSuccess(
        MailHeaderPage(
          messages: [header('archive-message', 'Archived message')],
        ),
      );
    }
    return MailSuccess(
      MailHeaderPage(
        messages: [
          cursor == null
              ? header(firstMessageId, 'First Exchange message')
              : header('two', 'Second Exchange message'),
        ],
        next: cursor == null
            ? MailCursor(mailbox: mailbox, value: 'next-page')
            : null,
      ),
    );
  }

  @override
  Future<MailResult<MailMessage>> fetchMessage(
    MailRemoteIdentity identity, {
    required MailReadBudget budget,
    required MailOperationLease lease,
  }) async {
    reads++;
    lastLease = lease;
    return messageGate == null
        ? MailSuccess(message())
        : await messageGate!.future;
  }

  @override
  Future<MailResult<MailUnit>> apply(
    MailOperation operation,
    MailOperationLease lease,
  ) async {
    commands.add(operation);
    lastLease = lease;
    if (mutationHandler case final handler?) return handler(operation, lease);
    return mutationProblem == null
        ? const MailSuccess(MailUnit.value)
        : MailFailure(mutationProblem!);
  }

  @override
  Future<MailSubmissionResult> submit(
    MailPreparedMessage message, {
    required String attemptId,
    required MailOperationLease lease,
  }) async {
    onSubmit?.call();
    submissions.add(message);
    attempts.add(attemptId);
    lastLease = lease;
    return sendGate == null
        ? MailSubmissionResult(attemptId: attemptId, outcome: outcome)
        : await sendGate!.future;
  }
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

Finder _field(String key) => find.byKey(ValueKey(key));
Finder _iconButton(String tooltip) => find.byWidgetPredicate(
  (widget) => widget is IconButton && widget.tooltip == tooltip,
);

Future<void> _show(
  WidgetTester tester,
  StudioEwsProviderFactory factory, {
  Size size = const Size(1280, 900),
  StudioMailArchiveWriter? archiveWriter,
  StudioMailArchiveFolderWriter? archiveFolderWriter,
  MemoryStudioMailDrafts? drafts,
}) async {
  final draftStorage = drafts ?? MemoryStudioMailDrafts();
  tester.view
    ..physicalSize = size
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
              builder: (_) => StudioMailEwsDialog(
                draftStoreFactory: draftStorage.open,
                strings: _strings,
                providerFactory: factory,
                archiveWriter: archiveWriter,
                archiveFolderWriter: archiveFolderWriter,
              ),
            ),
            child: const Text('Open Exchange'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Exchange'));
  await _pump(tester);
}

Future<void> _settings(
  WidgetTester tester, {
  String endpoint = 'https://mail.example.test/EWS/Exchange.asmx',
}) async {
  await tester.enterText(_field('ews-endpoint'), endpoint);
  await tester.enterText(_field('ews-mailbox'), 'reader@example.test');
  await tester.enterText(_field('ews-login'), r'EXAMPLE\reader');
  await tester.enterText(_field('ews-password'), 'ephemeral-test-password');
  await tester.ensureVisible(_field('ews-connect'));
  await _pump(tester);
}

Future<void> _connect(WidgetTester tester) async {
  await _settings(tester);
  await tester.tap(_field('ews-connect'));
  await _pump(tester);
}

Finder _composerField(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _compose(
  WidgetTester tester, {
  String to = 'recipient@example.test',
  String cc = '',
  String bcc = '',
  Future<void> Function()? beforeSend,
}) async {
  await tester.tap(find.byTooltip(_strings.compose));
  await _pump(tester);
  await tester.enterText(_composerField(_strings.to), to);
  if (cc.isNotEmpty || bcc.isNotEmpty) {
    await tester.tap(find.text(_strings.mailCopyRecipients));
    await _pump(tester);
    await tester.enterText(_composerField(_strings.mailCc), cc);
    await tester.enterText(_composerField(_strings.mailBcc), bcc);
  }
  await tester.enterText(_composerField(_strings.subject), 'EWS send');
  tester
      .widget<QudsWordEditor>(find.byType(QudsWordEditor))
      .controller
      .insertText('Composed in the existing Word editor.');
  await tester.pump();
  await beforeSend?.call();
  await tester.ensureVisible(find.widgetWithText(FilledButton, _strings.send));
  await tester.tap(find.widgetWithText(FilledButton, _strings.send));
  await _pump(tester);
}

MailResult<MailArchiveImportResult> _archiveSuccess(MailMessage message) =>
    MailSuccess(
      MailArchiveImportResult(
        entry: MailArchiveEntry(
          id: message.raw.sha256,
          envelope: message.envelope,
          archivedAt: DateTime.utc(2026, 11, 19),
          byteLength: message.raw.length,
          attachmentCount: message.attachments.length,
          indexTruncated: false,
          attachmentTextIndexed: 0,
          attachmentTextSkipped: 0,
        ),
        duplicate: false,
        originAdded: true,
      ),
    );

MailArchiveRunReport _folderReport() => MailArchiveRunReport(
  status: MailArchiveRunStatus.completed,
  pages: 2,
  processed: 4,
  saved: 3,
  duplicates: 1,
  failed: 0,
  bytes: 300,
  elapsedMicroseconds: 1000,
  observerErrors: 0,
  failures: const [],
  droppedFailures: 0,
);

MailMessageList _bulkList(WidgetTester tester) =>
    tester.widget<MailMessageList>(find.byType(MailMessageList));

StudioMailBulkStatus _bulkStatus(WidgetTester tester) =>
    tester.widget<StudioMailBulkStatus>(find.byType(StudioMailBulkStatus));

void _expectBulkCounts(
  WidgetTester tester,
  int confirmed,
  int failed,
  int uncertain,
  int unattempted,
) {
  final report = _bulkStatus(tester).report;
  expect(report.confirmedCount, confirmed);
  expect(report.failedCount, failed);
  expect(report.uncertainCount, uncertain);
  expect(report.unattemptedCount, unattempted);
  expect(
    find.textContaining(
      '$confirmed confirmed · $failed failed · $uncertain uncertain · '
      '$unattempted not attempted',
    ),
    findsOneWidget,
  );
  expect(find.text('Confirmed: $confirmed'), findsOneWidget);
  expect(find.text('Failed: $failed'), findsOneWidget);
  expect(find.text('Uncertain: $uncertain'), findsOneWidget);
  expect(find.text('Not attempted: $unattempted'), findsOneWidget);
}

List<MailHeaderRecord> _bulkHeaders(_Provider provider) => [
  provider.header('one', 'First Exchange message'),
  provider.header('two', 'Second Exchange message'),
  provider.header('three', 'Third Exchange message'),
];

void main() {
  testWidgets(
    'EWS bulk assigns each explicit value to checked targets without opening mail',
    (tester) async {
      late _Provider provider;
      await _show(tester, (configuration, credentials) {
        provider = _Provider(configuration, credentials);
        provider.headerPage = (mailbox, cursor) =>
            MailHeaderPage(messages: _bulkHeaders(provider));
        return provider;
      });
      await _connect(tester);
      for (final action in MailBulkFlagAction.values) {
        _bulkList(tester).onBulkAction!(action, [
          'ews-message-three',
          'ews-message-two',
        ]);
        await _pump(tester);
      }
      expect(
        provider.commands.map(
          (command) => (command.message as MailOpaqueIdentity).value,
        ),
        ['three', 'two', 'three', 'two', 'three', 'two', 'three', 'two'],
      );
      expect(
        provider.commands.whereType<MailSetRead>().map(
          (command) => command.read,
        ),
        [true, true, false, false],
      );
      expect(
        provider.commands.whereType<MailSetFlagged>().map(
          (command) => command.flagged,
        ),
        [true, true, false, false],
      );
      expect(
        provider.commands.map((command) => command.id).toSet(),
        hasLength(8),
      );
      expect(provider.reads, 0);
      expect(provider.cursors, hasLength(1));
      expect(_bulkList(tester).selectedId, isNull);
      _expectBulkCounts(tester, 2, 0, 0, 0);
    },
  );

  testWidgets(
    'EWS bulk leaves the independently open message and reader unchanged',
    (tester) async {
      late _Provider provider;
      await _show(tester, (configuration, credentials) {
        provider = _Provider(configuration, credentials);
        provider.headerPage = (mailbox, cursor) =>
            MailHeaderPage(messages: _bulkHeaders(provider));
        return provider;
      });
      await _connect(tester);
      _bulkList(tester).onOpen('ews-message-one');
      await _pump(tester);
      final reader = tester
          .widget<MailMessageView>(find.byType(MailMessageView))
          .controller;
      final ids = ['ews-message-two', 'ews-message-three'];
      _bulkList(tester).onBulkAction!(MailBulkFlagAction.flag, ids);
      ids.clear();
      await _pump(tester);
      expect(_bulkList(tester).selectedId, 'ews-message-one');
      expect(
        tester.widget<MailMessageView>(find.byType(MailMessageView)).controller,
        same(reader),
      );
      expect(_bulkList(tester).items.map((item) => item.isFlagged), [
        false,
        true,
        true,
      ]);
      expect(provider.reads, 1);
      expect(provider.cursors, hasLength(1));
    },
  );

  testWidgets('EWS bulk observes only the confirmed target flag', (
    tester,
  ) async {
    late _Provider provider;
    await _show(tester, (configuration, credentials) {
      provider = _Provider(configuration, credentials);
      provider.headerPage = (mailbox, cursor) => MailHeaderPage(
        messages: [
          provider.header('one', 'Unknown', flags: null),
          provider.header(
            'two',
            'Known',
            flags: const MailMessageFlags(
              isRead: true,
              isFlagged: true,
              isAnswered: true,
              isDraft: true,
              isDeleted: true,
            ),
          ),
        ],
      );
      return provider;
    });
    await _connect(tester);
    _bulkList(tester).onBulkAction!(MailBulkFlagAction.markRead, [
      'ews-message-one',
      'ews-message-two',
    ]);
    await _pump(tester);
    expect(_bulkList(tester).items.map((item) => item.isRead), [true, true]);
    expect(_bulkList(tester).items.map((item) => item.isFlagged), [null, true]);
    _bulkList(tester).onBulkAction!(MailBulkFlagAction.unflag, [
      'ews-message-two',
    ]);
    await _pump(tester);
    expect(_bulkList(tester).items.map((item) => item.isRead), [true, true]);
    expect(_bulkList(tester).items.map((item) => item.isFlagged), [
      null,
      false,
    ]);
    expect(provider.reads, 0);
    expect(provider.cursors, hasLength(1));
  });

  for (final problem in [
    MailProblemCode.cancelled,
    MailProblemCode.staleOperation,
    MailProblemCode.permissionDenied,
  ]) {
    testWidgets(
      'EWS bulk keeps generic $problem uncertain and does not retry',
      (tester) async {
        late _Provider provider;
        await _show(tester, (configuration, credentials) {
          provider = _Provider(configuration, credentials);
          provider.headerPage = (mailbox, cursor) =>
              MailHeaderPage(messages: _bulkHeaders(provider));
          provider.mutationHandler = (operation, lease) async =>
              provider.commands.length == 2
              ? MailFailure(MailProblem(problem))
              : const MailSuccess(MailUnit.value);
          return provider;
        });
        await _connect(tester);
        _bulkList(tester).onBulkAction!(MailBulkFlagAction.markRead, [
          'ews-message-one',
          'ews-message-two',
          'ews-message-three',
        ]);
        await _pump(tester);
        expect(provider.commands, hasLength(2));
        expect(_bulkList(tester).items.map((item) => item.isRead), [
          true,
          false,
          false,
        ]);
        expect(_bulkList(tester).bulkEnabled, isFalse);
        _expectBulkCounts(tester, 1, 0, 1, 1);
        expect(
          find.textContaining(_strings.mailWorkspaceRefreshRequired),
          findsOneWidget,
        );
        _bulkList(tester).onBulkAction!(MailBulkFlagAction.flag, [
          'ews-message-three',
        ]);
        await _pump(tester);
        expect(provider.commands, hasLength(2));
        expect(provider.cursors, hasLength(1));
        expect(provider.reads, 0);
        await tester.tap(find.byTooltip(_strings.refresh));
        await _pump(tester);
        expect(_bulkList(tester).bulkEnabled, isTrue);
        expect(provider.cursors, hasLength(2));
      },
    );
  }

  for (final problem in [
    MailProblemCode.permissionDenied,
    MailProblemCode.cancelled,
    MailProblemCode.staleOperation,
  ]) {
    testWidgets(
      'EWS bulk distinguishes explicit no-mutation $problem evidence',
      (tester) async {
        final stops = problem != MailProblemCode.permissionDenied;
        final refreshRequired = problem == MailProblemCode.staleOperation;
        late _Provider provider;
        await _show(tester, (configuration, credentials) {
          provider = _Provider(configuration, credentials);
          provider.headerPage = (mailbox, cursor) =>
              MailHeaderPage(messages: _bulkHeaders(provider));
          provider.mutationHandler = (operation, lease) async =>
              provider.commands.length == 1
              ? MailFailure(
                  MailProblem(problem, mutationMayHaveOccurred: false),
                )
              : const MailSuccess(MailUnit.value);
          return provider;
        });
        await _connect(tester);
        _bulkList(tester).onBulkAction!(MailBulkFlagAction.markRead, [
          'ews-message-one',
          'ews-message-two',
          'ews-message-three',
        ]);
        await _pump(tester);
        expect(provider.commands, hasLength(stops ? 1 : 3));
        expect(_bulkList(tester).items.map((item) => item.isRead), [
          false,
          !stops,
          !stops,
        ]);
        expect(_bulkList(tester).bulkEnabled, !refreshRequired);
        _expectBulkCounts(tester, stops ? 0 : 2, 1, 0, stops ? 2 : 0);
        expect(
          find.text(_strings.mailWorkspaceRefreshRequired),
          refreshRequired ? findsOneWidget : findsNothing,
        );
        expect(provider.reads, 0);
        expect(provider.cursors, hasLength(1));
        expect(_bulkList(tester).busy, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'EWS bulk cancellation retains current reply without cancelling its lease',
    (tester) async {
      late _Provider provider;
      final gate = Completer<MailResult<MailUnit>>();
      await _show(tester, (configuration, credentials) {
        provider = _Provider(configuration, credentials);
        provider.headerPage = (mailbox, cursor) =>
            MailHeaderPage(messages: _bulkHeaders(provider));
        provider.mutationHandler = (operation, lease) => gate.future;
        return provider;
      });
      await _connect(tester);
      _bulkList(tester).onBulkAction!(MailBulkFlagAction.flag, [
        'ews-message-one',
        'ews-message-two',
        'ews-message-three',
      ]);
      await _pump(tester);
      expect(provider.commands, hasLength(1));
      _bulkStatus(tester).onStop!();
      await _pump(tester);
      expect(_bulkList(tester).busy, isTrue);
      expect(provider.lastLease!.isCurrent, isTrue);
      gate.complete(const MailSuccess(MailUnit.value));
      await _pump(tester);
      expect(provider.commands, hasLength(1));
      expect(_bulkList(tester).items.map((item) => item.isFlagged), [
        true,
        false,
        false,
      ]);
      expect(_bulkList(tester).bulkEnabled, isTrue);
      expect(_bulkStatus(tester).onStop, isNull);
      _expectBulkCounts(tester, 1, 0, 0, 2);
    },
  );

  testWidgets(
    'EWS bulk stale callback cannot reach the same folder after ABA navigation',
    (tester) async {
      late _Provider provider;
      await _show(tester, (configuration, credentials) {
        provider = _Provider(configuration, credentials);
        provider.headerPage = (mailbox, cursor) =>
            MailHeaderPage(messages: _bulkHeaders(provider));
        return provider;
      });
      await _connect(tester);
      final stale = _bulkList(tester).onBulkAction!;
      await tester.tap(find.text('Archive'));
      await _pump(tester);
      await tester.tap(find.text('Inbox'));
      await _pump(tester);
      stale(MailBulkFlagAction.flag, ['ews-message-one']);
      await _pump(tester);
      expect(provider.commands, isEmpty);
      expect(provider.reads, 0);
    },
  );

  testWidgets(
    'EWS refresh retains discovery but rejects the old bulk selection scope',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
      );
      await _connect(tester);
      await tester.enterText(_field('mail-list-search'), 'Exchange');
      await _pump(tester);
      final old = _bulkList(tester);
      await tester.tap(find.byTooltip(_strings.refresh));
      await _pump(tester);
      final refreshed = _bulkList(tester);
      expect(refreshed.scopeId, old.scopeId);
      expect(refreshed.selectionRevision, isNot(old.selectionRevision));
      expect(
        tester.widget<TextField>(_field('mail-list-search')).controller!.text,
        'Exchange',
      );
      old.onBulkAction!(MailBulkFlagAction.flag, ['ews-message-one']);
      await _pump(tester);
      expect(provider.commands, isEmpty);
      expect(provider.reads, 0);
    },
  );

  testWidgets(
    'EWS bulk ignores duplicate or missing row identities before dispatch',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
      );
      await _connect(tester);
      final callback = _bulkList(tester).onBulkAction!;
      callback(MailBulkFlagAction.flag, ['ews-message-one', 'ews-message-one']);
      callback(MailBulkFlagAction.flag, ['ews-message-missing']);
      callback(MailBulkFlagAction.flag, const []);
      await _pump(tester);
      expect(provider.commands, isEmpty);
      expect(_bulkList(tester).busy, isFalse);
    },
  );

  testWidgets('EWS disposed bulk callback never dispatches or changes state', (
    tester,
  ) async {
    late _Provider provider;
    await _show(
      tester,
      (configuration, credentials) =>
          provider = _Provider(configuration, credentials),
    );
    await _connect(tester);
    final stale = _bulkList(tester).onBulkAction!;
    await tester.pumpWidget(const SizedBox.shrink());
    stale(MailBulkFlagAction.flag, ['ews-message-one']);
    await _pump(tester);
    expect(provider.commands, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'EWS bulk confirmation cannot enter a reconnected account or dispatch its tail',
    (tester) async {
      late _Provider provider;
      await _show(tester, (configuration, credentials) {
        provider = _Provider(configuration, credentials);
        provider.headerPage = (mailbox, cursor) =>
            MailHeaderPage(messages: _bulkHeaders(provider));
        return provider;
      });
      await _connect(tester);
      final previous = provider;
      final oldCallback = _bulkList(tester).onBulkAction!;
      final gate = Completer<MailResult<MailUnit>>();
      previous.mutationHandler = (operation, lease) => gate.future;
      oldCallback(MailBulkFlagAction.markRead, [
        'ews-message-one',
        'ews-message-two',
      ]);
      await _pump(tester);
      await tester.tap(find.byTooltip(_strings.disconnect));
      await _pump(tester);
      await _connect(tester);
      gate.complete(const MailSuccess(MailUnit.value));
      await _pump(tester);
      oldCallback(MailBulkFlagAction.flag, ['ews-message-one']);
      await _pump(tester);
      expect(previous.commands, hasLength(1));
      expect(provider.commands, isEmpty);
      expect(
        _bulkList(tester).items.every((item) => item.isRead == false),
        isTrue,
      );
      expect(find.byType(StudioMailBulkStatus), findsNothing);
      expect(_bulkList(tester).busy, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS searches recipients and dates without fetching or mutating',
    (tester) async {
      late _Provider provider;
      final date = DateTime(2026, 11, 20, 12);
      await _show(tester, (configuration, credentials) {
        provider = _Provider(configuration, credentials);
        provider.headerPage = (mailbox, cursor) => MailHeaderPage(
          messages: [
            provider.header(
              'one',
              'Quarterly report',
              flags: const MailMessageFlags(isFlagged: true),
              envelope: MailEnvelope(
                subject: 'Quarterly report',
                from: const [
                  MailAddress('writer@example.test', displayName: 'Writer'),
                ],
                to: const [
                  MailAddress('team@example.test', displayName: 'Project Team'),
                ],
                cc: const [
                  MailAddress('reviewer@example.test', displayName: 'Reviewer'),
                ],
                bcc: const [MailAddress('hidden@example.test')],
                sentAt: date,
              ),
            ),
            provider.header('two', 'Quarterly report', flags: null),
          ],
        );
        return provider;
      });
      await _connect(tester);
      final rows = tester
          .widget<MailMessageList>(find.byType(MailMessageList))
          .items;
      expect(rows.first.date, date);
      expect(rows.first.to, contains('Project Team <team@example.test>'));
      expect(rows.first.cc, contains('reviewer@example.test'));
      await tester.enterText(
        _field('mail-list-search'),
        'from:writer to:"Project Team" cc:reviewer subject:"Quarterly report" '
        'after:2026-11-19 before:2026-11-21 is:unread is:flagged',
      );
      await _pump(tester);
      expect(_field('ews-message-one'), findsOneWidget);
      expect(_field('ews-message-two'), findsNothing);
      await tester.enterText(
        _field('mail-list-search'),
        'to:hidden@example.test',
      );
      await _pump(tester);
      expect(
        find.text(_strings.mailMessageListStrings.noMatches),
        findsOneWidget,
      );
      expect(provider.cursors, hasLength(1));
      expect(provider.reads, 0);
      expect(provider.commands, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS confirms a previously unknown flag without inventing unread',
    (tester) async {
      late _Provider provider;
      await _show(tester, (configuration, credentials) {
        provider = _Provider(configuration, credentials);
        provider.headerPage = (mailbox, cursor) => MailHeaderPage(
          messages: [
            provider.header('one', 'First Exchange message', flags: null),
          ],
        );
        return provider;
      });
      await _connect(tester);
      await tester.tap(_field('ews-message-one'));
      await _pump(tester);
      await tester.tap(find.byTooltip(_strings.ewsFlag));
      await _pump(tester);
      final row = tester
          .widget<MailMessageList>(find.byType(MailMessageList))
          .items
          .single;
      expect(row.isFlagged, isTrue);
      expect(row.isRead, isNull);
      expect(find.byTooltip(_strings.ewsUnflag), findsOneWidget);
      await tester.tap(_field('mail-list-flagged'));
      await _pump(tester);
      expect(_field('ews-message-one'), findsOneWidget);
      await tester.tap(_field('mail-list-unread'));
      await _pump(tester);
      expect(_field('ews-message-one'), findsNothing);
      await tester.tap(find.byTooltip(_strings.ewsUnflag));
      await _pump(tester);
      final updated = tester
          .widget<MailMessageList>(find.byType(MailMessageList))
          .items
          .single;
      expect(updated.isFlagged, isFalse);
      expect(updated.isRead, isNull);
      expect(
        provider.commands.last,
        isA<MailSetFlagged>().having(
          (command) => command.flagged,
          'flagged',
          false,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('EWS confirms unknown read state without inventing flag state', (
    tester,
  ) async {
    late _Provider provider;
    await _show(tester, (configuration, credentials) {
      provider = _Provider(configuration, credentials);
      provider.headerPage = (mailbox, cursor) => MailHeaderPage(
        messages: [
          provider.header('one', 'First Exchange message', flags: null),
        ],
      );
      return provider;
    });
    await _connect(tester);
    await tester.tap(_field('ews-message-one'));
    await _pump(tester);
    await tester.tap(find.byTooltip(_strings.markRead));
    await _pump(tester);
    var row = tester
        .widget<MailMessageList>(find.byType(MailMessageList))
        .items
        .single;
    expect(row.isRead, isTrue);
    expect(row.isFlagged, isNull);
    await tester.tap(_field('mail-list-unread'));
    await _pump(tester);
    expect(_field('ews-message-one'), findsNothing);
    await tester.tap(find.byTooltip(_strings.ewsMarkUnread));
    await _pump(tester);
    row = tester
        .widget<MailMessageList>(find.byType(MailMessageList))
        .items
        .single;
    expect(row.isRead, isFalse);
    expect(row.isFlagged, isNull);
    expect(_field('ews-message-one'), findsOneWidget);
    await tester.tap(_field('mail-list-flagged'));
    await _pump(tester);
    expect(_field('ews-message-one'), findsNothing);
    expect(provider.commands.map((command) => (command as MailSetRead).read), [
      true,
      false,
    ]);
    expect(tester.takeException(), isNull);
  });

  for (final observed in [false, true]) {
    testWidgets(
      'EWS refresh replaces command observations with ${observed ? 'observed' : 'unknown'} flags',
      (tester) async {
        late _Provider provider;
        await _show(tester, (configuration, credentials) {
          provider = _Provider(configuration, credentials);
          provider.headerPage = (mailbox, cursor) => MailHeaderPage(
            messages: [
              provider.header('one', 'First Exchange message', flags: null),
            ],
          );
          return provider;
        });
        await _connect(tester);
        await tester.tap(_field('ews-message-one'));
        await _pump(tester);
        await tester.tap(find.byTooltip(_strings.markRead));
        await _pump(tester);
        await tester.tap(find.byTooltip(_strings.ewsFlag));
        await _pump(tester);
        provider.headerPage = (mailbox, cursor) => MailHeaderPage(
          messages: [
            provider.header(
              'one',
              'First Exchange message',
              flags: observed ? const MailMessageFlags() : null,
            ),
          ],
        );
        await tester.tap(find.byTooltip(_strings.refresh));
        await _pump(tester);
        final row = tester
            .widget<MailMessageList>(find.byType(MailMessageList))
            .items
            .single;
        expect(row.isRead, observed ? isFalse : isNull);
        expect(row.isFlagged, observed ? isFalse : isNull);
        expect(find.byType(MailMessageView), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'EWS appended flag snapshots supersede only observed command state',
    (tester) async {
      late _Provider provider;
      await _show(tester, (configuration, credentials) {
        provider = _Provider(configuration, credentials);
        provider.headerPage = (mailbox, cursor) => MailHeaderPage(
          messages: [
            provider.header('one', 'First Exchange message', flags: null),
          ],
          next: MailCursor(mailbox: mailbox, value: 'next-page'),
        );
        return provider;
      });
      await _connect(tester);
      await tester.tap(_field('ews-message-one'));
      await _pump(tester);
      await tester.tap(find.byTooltip(_strings.ewsFlag));
      await _pump(tester);
      provider.headerPage = (mailbox, cursor) => MailHeaderPage(
        messages: [
          provider.header('one', 'First Exchange message', flags: null),
        ],
        next: MailCursor(mailbox: mailbox, value: 'third-page'),
      );
      await tester.tap(_field('ews-load-more'));
      await _pump(tester);
      var row = tester
          .widget<MailMessageList>(find.byType(MailMessageList))
          .items
          .single;
      expect(row.isFlagged, isTrue);
      expect(row.isRead, isNull);
      expect(find.byTooltip(_strings.ewsUnflag), findsOneWidget);
      provider.headerPage = (mailbox, cursor) => MailHeaderPage(
        messages: [
          provider.header(
            'one',
            'First Exchange message',
            flags: const MailMessageFlags(isRead: true),
          ),
        ],
      );
      await tester.tap(_field('ews-load-more'));
      await _pump(tester);
      row = tester
          .widget<MailMessageList>(find.byType(MailMessageList))
          .items
          .single;
      expect(row.isRead, isTrue);
      expect(row.isFlagged, isFalse);
      expect(find.byTooltip(_strings.ewsMarkUnread), findsOneWidget);
      expect(find.byTooltip(_strings.ewsFlag), findsOneWidget);
      expect(provider.commands, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('EWS folder changes retire confirmations for reused remote ids', (
    tester,
  ) async {
    late _Provider provider;
    await _show(tester, (configuration, credentials) {
      provider = _Provider(configuration, credentials);
      provider.headerPage = (mailbox, cursor) => MailHeaderPage(
        messages: [
          provider.header('one', 'First Exchange message', flags: null),
        ],
      );
      return provider;
    });
    await _connect(tester);
    await tester.tap(_field('ews-message-one'));
    await _pump(tester);
    await tester.tap(find.byTooltip(_strings.ewsFlag));
    await _pump(tester);
    expect(
      tester
          .widget<MailMessageList>(find.byType(MailMessageList))
          .items
          .single
          .isFlagged,
      isTrue,
    );
    await tester.tap(find.text('Archive'));
    await _pump(tester);
    final row = tester
        .widget<MailMessageList>(find.byType(MailMessageList))
        .items
        .single;
    expect(row.isFlagged, isNull);
    expect(row.isRead, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('EWS folder navigation resets loaded search and filter scope', (
    tester,
  ) async {
    late _Provider provider;
    await _show(
      tester,
      (configuration, credentials) =>
          provider = _Provider(configuration, credentials),
    );
    await _connect(tester);
    await tester.enterText(_field('mail-list-search'), 'first');
    await tester.tap(_field('mail-list-unread'));
    await tester.tap(_field('mail-list-flagged'));
    await _pump(tester);
    expect(
      find.text(_strings.mailMessageListStrings.noMatches),
      findsOneWidget,
    );
    await tester.tap(find.text('Archive'));
    await _pump(tester);
    expect(_field('ews-message-archive-message'), findsOneWidget);
    expect(
      tester.widget<TextField>(_field('mail-list-search')).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<FilterChip>(_field('mail-list-unread')).selected,
      isFalse,
    );
    expect(
      tester.widget<FilterChip>(_field('mail-list-flagged')).selected,
      isFalse,
    );
    expect(provider.cursors, hasLength(2));
    expect(provider.reads, 0);
    expect(provider.commands, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'EWS loaded filters retain pagination with zero visible matches',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
      );
      await _connect(tester);
      await tester.enterText(_field('mail-list-search'), 'second');
      await tester.tap(_field('mail-list-unread'));
      await _pump(tester);
      expect(
        find.text(_strings.mailMessageListStrings.noMatches),
        findsOneWidget,
      );
      expect(provider.cursors, hasLength(1));
      expect(provider.reads, 0);
      await tester.tap(_field('ews-load-more'));
      await _pump(tester);
      expect(_field('ews-message-one'), findsNothing);
      expect(_field('ews-message-two'), findsOneWidget);
      // The last page is loaded: only the filter count remains.
      expect(find.text('1 shown · 2 loaded'), findsOneWidget);
      expect(provider.cursors.map((cursor) => cursor?.value), [
        null,
        'next-page',
      ]);
      expect(provider.reads, 0);
      expect(provider.commands, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS compact Back and resize preserve query selection and reader',
    (tester) async {
      late _Provider provider;
      await _show(tester, (configuration, credentials) {
        provider = _Provider(configuration, credentials);
        provider.headerPage = (mailbox, cursor) => MailHeaderPage(
          messages: [
            provider.header(
              'one',
              'First Exchange message',
              flags: const MailMessageFlags(isFlagged: true),
            ),
          ],
        );
        return provider;
      }, size: const Size(400, 850));
      await _connect(tester);
      await tester.enterText(_field('mail-list-search'), 'first');
      await tester.tap(_field('mail-list-unread'));
      await tester.tap(_field('mail-list-flagged'));
      await _pump(tester);
      await tester.tap(_field('ews-message-one'));
      await _pump(tester);
      final reader = tester
          .widget<MailMessageView>(find.byType(MailMessageView))
          .controller;
      expect(
        reader.result.message!.body.plainText,
        contains('A message from Exchange.'),
      );
      await tester.tap(find.byTooltip(_strings.backToMessages));
      await _pump(tester);
      expect(
        tester.widget<TextField>(_field('mail-list-search')).controller!.text,
        'first',
      );
      expect(
        tester.widget<FilterChip>(_field('mail-list-unread')).selected,
        isTrue,
      );
      expect(
        tester.widget<FilterChip>(_field('mail-list-flagged')).selected,
        isTrue,
      );
      expect(
        tester.widget<Semantics>(_field('ews-message-one')).properties.selected,
        isTrue,
      );
      expect(
        tester
            .widget<MailMessageView>(
              find.byType(MailMessageView, skipOffstage: false),
            )
            .controller,
        same(reader),
      );
      tester.view.physicalSize = const Size(1280, 900);
      await _pump(tester);
      expect(
        tester.widget<TextField>(_field('mail-list-search')).controller!.text,
        'first',
      );
      expect(
        tester.widget<MailMessageView>(find.byType(MailMessageView)).controller,
        same(reader),
      );
      tester.view.physicalSize = const Size(400, 850);
      await _pump(tester);
      expect(
        tester.widget<TextField>(_field('mail-list-search')).controller!.text,
        'first',
      );
      expect(provider.reads, 1);
      expect(provider.commands, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('EWS confirmed read and flag changes update active filters', (
    tester,
  ) async {
    late _Provider provider;
    await _show(
      tester,
      (configuration, credentials) =>
          provider = _Provider(configuration, credentials),
    );
    await _connect(tester);
    await tester.tap(_field('mail-list-unread'));
    await _pump(tester);
    await tester.tap(_field('ews-message-one'));
    await _pump(tester);
    await tester.tap(find.byTooltip(_strings.markRead));
    await _pump(tester);
    expect(_field('ews-message-one'), findsNothing);
    expect(find.byType(MailMessageView), findsOneWidget);
    await tester.tap(find.byTooltip(_strings.ewsMarkUnread));
    await _pump(tester);
    expect(_field('ews-message-one'), findsOneWidget);
    await tester.tap(_field('mail-list-flagged'));
    await _pump(tester);
    expect(_field('ews-message-one'), findsNothing);
    await tester.tap(find.byTooltip(_strings.ewsFlag));
    await _pump(tester);
    expect(_field('ews-message-one'), findsOneWidget);
    await tester.tap(find.byTooltip(_strings.ewsUnflag));
    await _pump(tester);
    expect(_field('ews-message-one'), findsNothing);
    expect(provider.commands, hasLength(4));
    expect(
      provider.commands[0],
      isA<MailSetRead>().having((command) => command.read, 'read', true),
    );
    expect(
      provider.commands[1],
      isA<MailSetRead>().having((command) => command.read, 'read', false),
    );
    expect(
      provider.commands[2],
      isA<MailSetFlagged>().having(
        (command) => command.flagged,
        'flagged',
        true,
      ),
    );
    expect(
      provider.commands[3],
      isA<MailSetFlagged>().having(
        (command) => command.flagged,
        'flagged',
        false,
      ),
    );
    expect(provider.reads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('EWS list keyboard navigation requires explicit opening', (
    tester,
  ) async {
    late _Provider provider;
    await _show(
      tester,
      (configuration, credentials) =>
          provider = _Provider(configuration, credentials),
    );
    await _connect(tester);
    await tester.tap(_field('ews-load-more'));
    await _pump(tester);
    tester.widget<Focus>(_field('mail-list-focus')).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await _pump(tester);
    expect(provider.reads, 0);
    expect(provider.commands, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _pump(tester);
    expect(provider.reads, 1);
    expect(provider.commands, isEmpty);
    expect(find.byType(MailMessageView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final invalid in [
    'nonadvancing cursor',
    'wrong mailbox cursor',
    'wrong account cursor',
    'wrong account header',
    'wrong provider header',
    'duplicate remote identity',
    'duplicate local identity',
    'oversized page',
  ]) {
    testWidgets('EWS rejects $invalid without replacing loaded rows', (
      tester,
    ) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
      );
      await _connect(tester);
      provider.headerPage = (mailbox, cursor) {
        final foreignAccount = MailAccountId(
          'foreign',
          profile: provider.account.profile,
        );
        final added = provider.header('rejected', 'Rejected page');
        return switch (invalid) {
          'nonadvancing cursor' => MailHeaderPage(
            messages: [added],
            next: cursor,
          ),
          'wrong mailbox cursor' => MailHeaderPage(
            messages: [added],
            next: MailCursor(
              mailbox: provider.box('archive'),
              value: 'foreign',
            ),
          ),
          'wrong account cursor' => MailHeaderPage(
            messages: [added],
            next: MailCursor(
              mailbox: MailMailboxId('inbox', account: foreignAccount),
              value: 'foreign',
            ),
          ),
          'wrong account header' => MailHeaderPage(
            messages: [
              MailHeaderRecord(
                id: added.id,
                remote: MailOpaqueIdentity(
                  account: foreignAccount,
                  provider: MailProviderKind.ews,
                  value: 'foreign',
                ),
                envelope: added.envelope,
              ),
            ],
          ),
          'wrong provider header' => MailHeaderPage(
            messages: [
              MailHeaderRecord(
                id: added.id,
                remote: MailOpaqueIdentity(
                  account: provider.account,
                  provider: MailProviderKind.graph,
                  value: 'foreign',
                ),
                envelope: added.envelope,
              ),
            ],
          ),
          'duplicate remote identity' => MailHeaderPage(
            messages: [
              added,
              MailHeaderRecord(
                id: MailMessageId('other-id'),
                remote: added.remote,
                envelope: added.envelope,
              ),
            ],
          ),
          'duplicate local identity' => MailHeaderPage(
            messages: [
              added,
              MailHeaderRecord(
                id: added.id,
                remote: provider.identity('other-remote'),
                envelope: added.envelope,
              ),
            ],
          ),
          _ => MailHeaderPage(
            messages: [
              for (var i = 0; i < 51; i++)
                provider.header('rejected-$i', 'Rejected page'),
            ],
          ),
        };
      };
      await tester.tap(_field('ews-load-more'));
      await _pump(tester);
      expect(_field('ews-message-one'), findsOneWidget);
      expect(find.text('Rejected page'), findsNothing);
      expect(
        find.text(
          invalid == 'oversized page'
              ? _strings.ewsBudgetExceeded
              : _strings.mailWorkspaceRefreshRequired,
        ),
        findsOneWidget,
      );
      expect(provider.cursors, hasLength(2));
      expect(
        tester.widget<TextButton>(_field('ews-load-more')).onPressed,
        invalid == 'oversized page' ? isNotNull : isNull,
      );
      expect(provider.reads, 0);
      expect(provider.commands, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'EWS rejects a cursor cycle and retains earlier successful pages',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
      );
      await _connect(tester);
      provider.headerPage = (mailbox, cursor) => MailHeaderPage(
        messages: [provider.header('two', 'Second Exchange message')],
        next: MailCursor(mailbox: mailbox, value: 'third-page'),
      );
      await tester.tap(_field('ews-load-more'));
      await _pump(tester);
      provider.headerPage = (mailbox, cursor) => MailHeaderPage(
        messages: [provider.header('rejected', 'Rejected page')],
        next: MailCursor(mailbox: mailbox, value: 'next-page'),
      );
      await tester.tap(_field('ews-load-more'));
      await _pump(tester);
      expect(_field('ews-message-one'), findsOneWidget);
      expect(_field('ews-message-two'), findsOneWidget);
      expect(find.text('Rejected page'), findsNothing);
      expect(find.text(_strings.mailWorkspaceRefreshRequired), findsOneWidget);
      expect(
        tester.widget<TextButton>(_field('ews-load-more')).onPressed,
        isNull,
      );
      expect(provider.cursors.map((cursor) => cursor?.value), [
        null,
        'next-page',
        'third-page',
      ]);
      provider.headerPage = (mailbox, cursor) => MailHeaderPage(
        messages: [provider.header('fresh', 'Refreshed message')],
        next: MailCursor(mailbox: mailbox, value: 'fresh-next-page'),
      );
      await tester.tap(find.byTooltip(_strings.refresh));
      await _pump(tester);
      expect(_field('ews-message-fresh'), findsOneWidget);
      expect(_field('ews-message-one'), findsNothing);
      expect(provider.cursors.last, isNull);
      expect(
        tester.widget<TextButton>(_field('ews-load-more')).onPressed,
        isNotNull,
      );
      expect(find.text(_strings.mailWorkspaceRefreshRequired), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('EWS late header completion cannot enter a reconnected session', (
    tester,
  ) async {
    late _Provider provider;
    await _show(
      tester,
      (configuration, credentials) =>
          provider = _Provider(configuration, credentials),
    );
    await _connect(tester);
    final previous = provider;
    final gate = Completer<MailResult<MailHeaderPage>>();
    previous.headerGate = gate;
    await tester.tap(_field('ews-load-more'));
    await _pump(tester);
    final lease = previous.lastLease!;
    await tester.tap(find.byTooltip(_strings.disconnect));
    await _pump(tester);
    await _connect(tester);
    expect(identical(provider, previous), isFalse);
    expect(lease.isCurrent, isFalse);
    gate.complete(
      MailSuccess(
        MailHeaderPage(
          messages: [previous.header('late', 'Late private result')],
        ),
      ),
    );
    await _pump(tester);
    expect(_field('ews-message-one'), findsOneWidget);
    expect(find.text('Late private result'), findsNothing);
    expect(provider.cursors, hasLength(1));
    expect(provider.reads, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('EWS requests only remaining capacity and stops at 1000 rows', (
    tester,
  ) async {
    late _Provider provider;
    var produced = 0;
    await _show(tester, (configuration, credentials) {
      provider = _Provider(configuration, credentials);
      provider.headerPage = (mailbox, cursor) {
        final count = cursor == null ? 37 : provider.headerLimits.last;
        final start = produced;
        produced += count;
        return MailHeaderPage(
          messages: [
            for (var i = start; i < produced; i++)
              provider.header('row-$i', 'Message $i'),
          ],
          next: MailCursor(mailbox: mailbox, value: 'next-$produced'),
        );
      };
      return provider;
    });
    await _connect(tester);
    for (var page = 0; page < 20; page++) {
      await tester.tap(_field('ews-load-more'));
      await _pump(tester);
    }
    expect(produced, 1000);
    expect(provider.headerLimits.last, 13);
    expect(provider.cursors, hasLength(21));
    expect(_field('ews-load-more'), findsNothing);
    expect(find.text(_strings.mailWorkspaceLimit), findsWidgets);
    // Since ca5be882 the compact list shows the count and keeps the loaded
    // scope explanation in its tooltip.
    final scope = find.text('1000 shown · 1000 loaded');
    expect(scope, findsOneWidget);
    expect(
      find.ancestor(
        of: scope,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              widget.message == _strings.mailMessageListStrings.loadedScope,
        ),
      ),
      findsOneWidget,
    );
    expect(provider.reads, 0);
    expect(provider.commands, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'EWS restores an unfinished draft after closing and reconnecting',
    (tester) async {
      final drafts = MemoryStudioMailDrafts();
      final providers = <_Provider>[];
      await _show(tester, (configuration, credentials) {
        final provider = _Provider(configuration, credentials);
        providers.add(provider);
        return provider;
      }, drafts: drafts);
      await _connect(tester);
      await tester.tap(find.byTooltip(_strings.compose));
      await _pump(tester);
      await tester.enterText(_composerField(_strings.to), 'Alice <unfinished');
      await tester.enterText(
        _composerField(_strings.subject),
        'Recover EWS work',
      );
      tester
          .widget<QudsWordEditor>(find.byType(QudsWordEditor))
          .controller
          .insertText('Still editing this body');
      await tester.ensureVisible(find.text(_strings.mailDraftSaveClose));
      await tester.tap(find.text(_strings.mailDraftSaveClose));
      await _pump(tester);
      expect(drafts.records.values.single.draft.to, 'Alice <unfinished');
      expect(providers.single.submissions, isEmpty);
      await tester.tap(find.byTooltip(_strings.close));
      await _pump(tester);
      expect(drafts.closes, 1);
      await tester.tap(find.text('Open Exchange'));
      await _pump(tester);
      await _connect(tester);
      expect(
        drafts.identities.map((identity) => identity.account).toSet(),
        hasLength(1),
      );
      expect(find.text(_strings.mailDraftRestored), findsOneWidget);
      expect(providers.last.submissions, isEmpty);
      await tester.tap(find.byTooltip(_strings.compose));
      await _pump(tester);
      expect(
        tester.widget<TextField>(_composerField(_strings.to)).controller!.text,
        'Alice <unfinished',
      );
      expect(
        tester
            .widget<TextField>(_composerField(_strings.subject))
            .controller!
            .text,
        'Recover EWS work',
      );
      expect(
        tester
            .widget<QudsWordEditor>(find.byType(QudsWordEditor))
            .controller
            .document
            .paragraphs
            .single
            .text,
        'Still editing this body',
      );
      await tester.ensureVisible(find.text(_strings.mailDraftSaveClose));
      await tester.tap(find.text(_strings.mailDraftSaveClose));
      await _pump(tester);
      expect(
        providers.every((provider) => provider.submissions.isEmpty),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS waits for the durable uncertainty marker before submission',
    (tester) async {
      final drafts = MemoryStudioMailDrafts();
      final markerGate = Completer<void>();
      final deliveryGate = Completer<MailSubmissionResult>();
      late _Provider provider;
      bool? durableAtSubmission;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials)
              ..sendGate = deliveryGate
              ..onSubmit = () => durableAtSubmission =
                  drafts.records.values.single.submissionUncertain,
        drafts: drafts,
      );
      await _connect(tester);
      await _compose(
        tester,
        beforeSend: () async {
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump();
          expect(drafts.saved.last.submissionUncertain, isFalse);
          drafts.saveGate = markerGate;
        },
      );
      expect(provider.submissions, isEmpty);
      expect(drafts.records.values.single.submissionUncertain, isFalse);
      markerGate.complete();
      await _pump(tester);
      expect(provider.submissions, hasLength(1));
      expect(durableAtSubmission, isTrue);
      expect(drafts.records.values.single.submissionUncertain, isTrue);
      deliveryGate.complete(
        MailSubmissionResult(
          attemptId: provider.attempts.single,
          outcome: MailSubmissionOutcome.accepted,
        ),
      );
      await _pump(tester);
      expect(drafts.clears, 1);
      expect(drafts.records, isEmpty);
      expect(find.text(_strings.ewsSubmissionAccepted), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS accepted cleanup failure remains uncertain after reconnect',
    (tester) async {
      final drafts = MemoryStudioMailDrafts()..failClear = true;
      final providers = <_Provider>[];
      await _show(tester, (configuration, credentials) {
        final provider = _Provider(configuration, credentials);
        providers.add(provider);
        return provider;
      }, drafts: drafts);
      await _connect(tester);
      await _compose(tester);
      expect(providers.single.submissions, hasLength(1));
      expect(
        find.text(_strings.mailDraftAcceptedCleanupFailed),
        findsOneWidget,
      );
      expect(drafts.records.values.single.submissionUncertain, isTrue);
      await tester.pump(const Duration(seconds: 30));
      expect(providers.single.submissions, hasLength(1));
      await tester.tap(find.byTooltip(_strings.close));
      await _pump(tester);
      await tester.tap(find.text('Open Exchange'));
      await _pump(tester);
      await _connect(tester);
      expect(find.text(_strings.mailSubmissionUncertain), findsOneWidget);
      expect(providers.last.submissions, isEmpty);
      await tester.tap(find.byTooltip(_strings.compose));
      await _pump(tester);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, _strings.send),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text(_strings.mailDraftSaveClose));
      await tester.tap(find.text(_strings.mailDraftSaveClose));
      await _pump(tester);
      expect(providers.last.submissions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS can retry draft storage opening and never sends a failed save',
    (tester) async {
      final drafts = MemoryStudioMailDrafts()..failOpen = true;
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
        drafts: drafts,
      );
      await _connect(tester);
      expect(find.text(_strings.mailDraftStorageFailed), findsOneWidget);
      drafts.failOpen = false;
      drafts.failSave = true;
      await _compose(tester);
      expect(provider.submissions, isEmpty);
      expect(find.byType(StudioMailComposeDialog), findsOneWidget);
      expect(find.text(_strings.mailDraftSaveFailed), findsOneWidget);
      drafts.failSave = false;
      await tester.ensureVisible(find.text(_strings.mailDraftRetrySave));
      await tester.tap(find.text(_strings.mailDraftRetrySave));
      await _pump(tester);
      expect(find.text(_strings.mailDraftSaved), findsOneWidget);
      await tester.ensureVisible(find.text(_strings.mailDraftSaveClose));
      await tester.tap(find.text(_strings.mailDraftSaveClose));
      await _pump(tester);
      expect(drafts.records.values.single.draft.subject, 'EWS send');
      expect(provider.submissions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('EWS rejected retry preserves an earlier uncertain submission', (
    tester,
  ) async {
    final drafts = MemoryStudioMailDrafts();
    late _Provider provider;
    await _show(
      tester,
      (configuration, credentials) =>
          provider = _Provider(configuration, credentials)
            ..outcome = MailSubmissionOutcome.uncertain,
      drafts: drafts,
    );
    await _connect(tester);
    await _compose(tester);
    expect(drafts.records.values.single.submissionUncertain, isTrue);
    provider.outcome = MailSubmissionOutcome.rejected;
    await tester.tap(find.byTooltip(_strings.compose));
    await _pump(tester);
    final acknowledge = find.byType(CheckboxListTile);
    await tester.ensureVisible(acknowledge);
    await tester.tap(acknowledge);
    await tester.pump();
    final send = find.widgetWithText(FilledButton, _strings.send);
    await tester.ensureVisible(send);
    await tester.tap(send);
    await _pump(tester);
    expect(provider.submissions, hasLength(2));
    expect(drafts.records.values.single.submissionUncertain, isTrue);
    await tester.tap(find.byTooltip(_strings.compose));
    await _pump(tester);
    expect(find.text(_strings.mailRetryAcknowledgement), findsOneWidget);
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    await tester.ensureVisible(find.text(_strings.mailDraftSaveClose));
    await tester.tap(find.text(_strings.mailDraftSaveClose));
    await _pump(tester);
    expect(provider.submissions, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'EWS failed definite-result persistence retains the retry guard',
    (tester) async {
      final drafts = MemoryStudioMailDrafts();
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials)
              ..outcome = MailSubmissionOutcome.rejected
              ..onSubmit = () => drafts.failSave = true,
        drafts: drafts,
      );
      await _connect(tester);
      await _compose(tester);
      expect(provider.submissions, hasLength(1));
      expect(drafts.records.values.single.submissionUncertain, isTrue);
      expect(find.text(_strings.mailSubmissionUncertain), findsOneWidget);
      drafts.failSave = false;
      await tester.tap(find.byTooltip(_strings.compose));
      await _pump(tester);
      expect(find.text(_strings.mailRetryAcknowledgement), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, _strings.send),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text(_strings.mailDraftSaveClose));
      await tester.tap(find.text(_strings.mailDraftSaveClose));
      await _pump(tester);
      expect(provider.submissions, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('EWS retires a draft store opened after its host was closed', (
    tester,
  ) async {
    final gate = Completer<void>();
    final drafts = MemoryStudioMailDrafts()..openGate = gate;
    late _Provider provider;
    await _show(
      tester,
      (configuration, credentials) =>
          provider = _Provider(configuration, credentials),
      drafts: drafts,
    );
    await _connect(tester);
    expect(drafts.identities, hasLength(1));
    await tester.tap(find.byTooltip(_strings.close));
    await _pump(tester);
    gate.complete();
    await _pump(tester);
    expect(drafts.closes, 1);
    expect(drafts.records, isEmpty);
    expect(provider.submissions, isEmpty);
    expect(find.byType(StudioMailEwsDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('native account setup exposes the Exchange Server entry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: StudioMailDialog(strings: _strings)),
    );
    await tester.tap(find.byKey(const ValueKey('studio-mail-open-ews')));
    await _pump(tester);
    expect(find.byType(StudioMailEwsDialog), findsOneWidget);
    expect(_field('ews-endpoint'), findsOneWidget);
    expect(find.text(_strings.ewsNtlm), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'manual NTLM connection loads bounded headers and clears the password field',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
      );
      await _settings(tester);
      final password = tester
          .widget<TextField>(_field('ews-password'))
          .controller!;
      await tester.tap(_field('ews-connect'));
      await _pump(tester);
      expect(provider.configuration.authentication, MailEwsAuthentication.ntlm);
      expect(provider.configuration.username, r'EXAMPLE\reader');
      expect(provider.configuration.mailboxAddress, 'reader@example.test');
      expect(provider.configuration.endpoint.host, 'mail.example.test');
      expect(password.text, isEmpty);
      expect(provider.connects, 1);
      expect(provider.lists, 1);
      expect(provider.reads, 0);
      expect(provider.commands, isEmpty);
      expect(find.text('First Exchange message'), findsOneWidget);
      await tester.tap(_field('ews-load-more'));
      await _pump(tester);
      expect(provider.cursors.last?.value, 'next-page');
      expect(find.text('Second Exchange message'), findsOneWidget);
      expect(_field('ews-load-more'), findsNothing);
      await tester.tap(find.text('First Exchange message'));
      await _pump(tester);
      final reader = tester
          .widget<MailMessageView>(find.byType(MailMessageView))
          .controller;
      expect(
        reader.result.message!.body.plainText,
        contains('A message from Exchange.'),
      );
      expect(
        reader.result.message!.attachments.single.displayName,
        'example.txt',
      );
      expect(find.textContaining('example.txt'), findsOneWidget);
      expect(
        provider.commands,
        isEmpty,
        reason: 'Opening a message must not mark it read implicitly.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('explicit read, flag and move actions use the EWS provider', (
    tester,
  ) async {
    late _Provider provider;
    await _show(
      tester,
      (configuration, credentials) =>
          provider = _Provider(configuration, credentials),
    );
    await _connect(tester);
    await tester.tap(find.text('First Exchange message'));
    await _pump(tester);
    await tester.tap(find.byTooltip(_strings.markRead));
    await _pump(tester);
    expect(
      provider.commands.single,
      isA<MailSetRead>().having((c) => c.read, 'read', true),
    );
    expect(find.byTooltip(_strings.ewsMarkUnread), findsOneWidget);
    await tester.tap(find.byTooltip(_strings.ewsFlag));
    await _pump(tester);
    expect(
      provider.commands.last,
      isA<MailSetFlagged>().having((c) => c.flagged, 'flagged', true),
    );
    await tester.tap(find.byTooltip(_strings.ewsMove));
    await _pump(tester);
    await tester.tap(
      find.widgetWithText(PopupMenuItem<MailMailbox>, 'Archive'),
    );
    await _pump(tester);
    expect(
      provider.commands.last,
      isA<MailMove>().having(
        (c) => c.destination.value,
        'destination',
        'archive',
      ),
    );
    expect(find.byType(MailMessageView), findsNothing);
    expect(find.text('First Exchange message'), findsNothing);
    expect(_field('ews-load-more'), findsNothing);
    expect(find.text(_strings.ewsFolderChanged), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Basic authentication is available only by explicit selection', (
    tester,
  ) async {
    late _Provider provider;
    await _show(
      tester,
      (configuration, credentials) =>
          provider = _Provider(configuration, credentials),
    );
    await _settings(tester);
    await tester.tap(find.text(_strings.ewsNtlm));
    await _pump(tester);
    await tester.tap(find.text(_strings.ewsBasic).last);
    await _pump(tester);
    await tester.tap(_field('ews-connect'));
    await _pump(tester);
    expect(provider.configuration.authentication, MailEwsAuthentication.basic);
    expect(find.text('First Exchange message'), findsOneWidget);
  });

  testWidgets(
    'read-only capabilities allow local drafts but disable sending and actions',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials)
              ..supported = MailCapabilities(const [
                MailCapability.mail,
                MailCapability.folders,
              ]),
      );
      await _connect(tester);
      expect(
        tester.widget<IconButton>(_iconButton(_strings.compose)).onPressed,
        isNotNull,
      );
      await tester.tap(_iconButton(_strings.compose));
      await _pump(tester);
      final composer = tester.widget<StudioMailComposeDialog>(
        find.byType(StudioMailComposeDialog),
      );
      expect(composer.canSend, isFalse);
      expect(composer.onQueueDraft, isNull);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, _strings.send),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text(_strings.mailDraftSaveClose));
      await tester.tap(find.text(_strings.mailDraftSaveClose));
      await _pump(tester);
      expect(find.byType(StudioMailComposeDialog), findsNothing);
      await tester.tap(find.text('First Exchange message'));
      await _pump(tester);
      expect(
        tester.widget<IconButton>(_iconButton(_strings.reply)).onPressed,
        isNull,
      );
      expect(
        tester.widget<IconButton>(_iconButton(_strings.replyAll)).onPressed,
        isNull,
      );
      expect(
        tester.widget<IconButton>(_iconButton(_strings.forward)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              _iconButton(_strings.mailForwardWithAttachments),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<PopupMenuButton<MailMailbox>>(
              find.byType(PopupMenuButton<MailMailbox>),
            )
            .enabled,
        isFalse,
      );
      expect(provider.submissions, isEmpty);
      expect(provider.commands, isEmpty);
    },
  );

  testWidgets(
    'delete requires explicit confirmation before moving to Deleted Items',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
      );
      await _connect(tester);
      await tester.tap(find.text('First Exchange message'));
      await _pump(tester);
      await tester.tap(find.byTooltip(_strings.ewsDelete));
      await _pump(tester);
      expect(provider.commands, isEmpty);
      await tester.tap(find.widgetWithText(TextButton, _strings.cancel));
      await _pump(tester);
      expect(provider.commands, isEmpty);
      await tester.tap(find.byTooltip(_strings.ewsDelete));
      await _pump(tester);
      await tester.tap(find.widgetWithText(FilledButton, _strings.ewsDelete));
      await _pump(tester);
      expect(provider.commands.single, isA<MailDelete>());
      expect(find.byType(MailMessageView), findsNothing);
      expect(find.text('First Exchange message'), findsNothing);
    },
  );

  testWidgets(
    'failed write confirmation requires refresh before another change',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
      );
      await _connect(tester);
      await tester.tap(find.text('First Exchange message'));
      await _pump(tester);
      provider.mutationProblem = const MailProblem(MailProblemCode.conflict);
      await tester.tap(find.byTooltip(_strings.markRead));
      await _pump(tester);
      expect(find.text(_strings.ewsMutationFailed), findsOneWidget);
      final flag = tester.widget<IconButton>(_iconButton(_strings.ewsFlag));
      expect(flag.onPressed, isNull);
      expect(
        tester.widget<TextButton>(_field('ews-load-more')).onPressed,
        isNull,
      );
      final pagesBefore = provider.cursors.length;
      await tester.tap(_field('ews-load-more'));
      await _pump(tester);
      expect(provider.cursors, hasLength(pagesBefore));
      expect(
        tester.widget<IconButton>(_iconButton(_strings.ewsFlag)).onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip(_strings.refresh));
      await _pump(tester);
      await tester.tap(find.text('First Exchange message'));
      await _pump(tester);
      expect(
        tester.widget<IconButton>(_iconButton(_strings.ewsFlag)).onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('insecure endpoints fail before provider creation', (
    tester,
  ) async {
    var calls = 0;
    await _show(tester, (configuration, credentials) {
      calls++;
      return _Provider(configuration, credentials);
    });
    await _settings(
      tester,
      endpoint: 'http://mail.example.test/EWS/Exchange.asmx',
    );
    await tester.tap(_field('ews-connect'));
    await _pump(tester);
    expect(calls, 0);
    expect(find.text(_strings.ewsInvalidSettings), findsOneWidget);
  });

  testWidgets(
    'closing a pending connection invalidates its lease and clears credentials',
    (tester) async {
      late _Provider provider;
      final gate = Completer<MailResult<MailCapabilities>>();
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials)
              ..connectGate = gate,
      );
      await _connect(tester);
      expect(provider.lastLease!.isCurrent, isTrue);
      await tester.tap(find.byTooltip(_strings.close));
      await _pump(tester);
      expect(provider.lastLease!.isCurrent, isFalse);
      final stored = await provider.credentials.load(
        provider.configuration.credential,
      );
      expect((stored as MailSuccess<MailCredentialRecord?>).value, isNull);
      gate.complete(MailSuccess(MailCapabilities([MailCapability.mail])));
      await _pump(tester);
      expect(provider.lists, 0);
      expect(find.byType(StudioMailEwsDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'disconnect ignores late message bodies and returns to cleared setup',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
      );
      await _connect(tester);
      final gate = Completer<MailResult<MailMessage>>();
      provider.messageGate = gate;
      await tester.tap(find.text('First Exchange message'));
      await _pump(tester);
      await tester.tap(find.byTooltip(_strings.disconnect));
      await _pump(tester);
      expect(provider.lastLease!.isCurrent, isFalse);
      gate.complete(MailSuccess(provider.message()));
      await _pump(tester);
      expect(find.byType(MailMessageView), findsNothing);
      expect(
        tester.widget<TextField>(_field('ews-password')).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'composer supplies every To Cc and Bcc recipient to EWS without leaking Bcc',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
      );
      await _connect(tester);
      await _compose(
        tester,
        to: 'first@example.test; second@example.test',
        cc: 'copied@example.test',
        bcc: 'hidden@example.test',
      );
      expect(provider.submissions, hasLength(1));
      final submitted = provider.submissions.single;
      expect(submitted.envelope.sender, 'reader@example.test');
      expect(submitted.envelope.recipients, [
        'first@example.test',
        'second@example.test',
        'copied@example.test',
        'hidden@example.test',
      ]);
      final decoded = const QudsMimeCodec().parse(submitted.wire.bytes);
      expect(decoded.status, MailParseStatus.complete);
      expect(decoded.message!.envelope.subject, 'EWS send');
      expect(decoded.message!.envelope.to.map((address) => address.address), [
        'first@example.test',
        'second@example.test',
      ]);
      expect(
        decoded.message!.envelope.cc.single.address,
        'copied@example.test',
      );
      expect(decoded.message!.envelope.bcc, isEmpty);
      expect(
        utf8.decode(submitted.wire.bytes),
        isNot(contains('hidden@example.test')),
      );
      expect(
        decoded.message!.body.plainText,
        contains('Composed in the existing Word editor.'),
      );
      expect(find.text(_strings.ewsSubmissionAccepted), findsOneWidget);
      expect(find.byTooltip(_strings.mailDiscardDraft), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS host preserves visible groups and hides Bcc from canonical MIME',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
      );
      await _connect(tester);
      await tester.tap(find.byTooltip(_strings.compose));
      await _pump(tester);
      await tester.enterText(
        _composerField(_strings.to),
        'primary@Example.test; second@example.test',
      );
      await tester.tap(find.text(_strings.mailCopyRecipients));
      await _pump(tester);
      await tester.enterText(
        _composerField(_strings.mailCc),
        'primary@example.test, copy@example.test',
      );
      await tester.enterText(
        _composerField(_strings.mailBcc),
        'copy@example.test; hidden@example.test',
      );
      await tester.enterText(
        _composerField(_strings.subject),
        'Recipient privacy',
      );
      final send = find.widgetWithText(FilledButton, _strings.send);
      await tester.ensureVisible(send);
      await tester.tap(send);
      await _pump(tester);
      final submitted = provider.submissions.single;
      expect(submitted.envelope.recipients, [
        'primary@Example.test',
        'second@example.test',
        'copy@example.test',
        'hidden@example.test',
      ]);
      final decoded = const QudsMimeCodec().parse(submitted.wire.bytes);
      expect(decoded.status, MailParseStatus.complete);
      expect(decoded.message!.envelope.to.map((entry) => entry.address), [
        'primary@Example.test',
        'second@example.test',
      ]);
      expect(decoded.message!.envelope.cc.map((entry) => entry.address), [
        'copy@example.test',
      ]);
      expect(decoded.message!.envelope.bcc, isEmpty);
      expect(
        utf8.decode(submitted.wire.bytes),
        isNot(contains('hidden@example.test')),
      );
      expect(find.text(_strings.ewsSubmissionAccepted), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS keeps exact attachments and private recipients across acknowledged retry',
    (tester) async {
      final source = Uint8List.fromList([0, 255, 128, 13, 10, 42]);
      final expected = Uint8List.fromList(source);
      final picker = MailAttachmentPickerFixture(
        () async => FilePickerResult([
          PlatformFile(
            name: 'Exchange snapshot.docx',
            size: source.length,
            readStream: Stream<List<int>>.value(source),
          ),
        ]),
      );
      FilePicker.platform = picker;
      addTearDown(() => FilePicker.platform = FilePickerIO());
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials)
              ..outcome = MailSubmissionOutcome.uncertain,
      );
      await _connect(tester);
      await _compose(
        tester,
        cc: 'copied@example.test',
        bcc: 'hidden@example.test',
        beforeSend: () async {
          final add = find.byKey(const ValueKey('studio-mail-add-attachments'));
          await tester.ensureVisible(add);
          await tester.tap(add);
          await _pump(tester);
          expect(find.text('Exchange snapshot.docx'), findsOneWidget);
          source.fillRange(0, source.length, 17);
        },
      );
      expect(provider.submissions, hasLength(1));
      expect(find.text(_strings.mailSubmissionUncertain), findsOneWidget);
      await tester.pump(const Duration(minutes: 1));
      expect(provider.submissions, hasLength(1));
      await tester.tap(find.byTooltip(_strings.compose));
      await _pump(tester);
      expect(find.text('Exchange snapshot.docx'), findsOneWidget);
      expect(picker.calls, 1);
      final send = find.widgetWithText(FilledButton, _strings.send);
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      provider.outcome = MailSubmissionOutcome.accepted;
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await _pump(tester);
      await tester.ensureVisible(send);
      await tester.tap(send);
      await _pump(tester);
      expect(provider.submissions, hasLength(2));
      expect(provider.attempts.toSet(), hasLength(2));
      for (final submission in provider.submissions) {
        expect(submission.envelope.recipients, [
          'recipient@example.test',
          'copied@example.test',
          'hidden@example.test',
        ]);
        final wire = ascii.decode(submission.wire.bytes);
        expect(wire, contains('multipart/mixed'));
        expect(wire, contains('multipart/alternative'));
        expect(wire, isNot(contains('hidden@example.test')));
        final decoded = const QudsMimeCodec().parse(submission.wire.bytes);
        expect(decoded.status, MailParseStatus.complete);
        expect(
          decoded.message!.body.plainText,
          'Composed in the existing Word editor.',
        );
        expect(decoded.message!.attachments, hasLength(1));
        expect(
          decoded.message!.attachments.single.displayName,
          'Exchange snapshot.docx',
        );
        expect(decoded.message!.attachments.single.content.bytes, expected);
        expect(decoded.message!.envelope.bcc, isEmpty);
      }
      expect(find.text(_strings.ewsSubmissionAccepted), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'uncertain submissions retain the draft and require acknowledged retry',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials)
              ..outcome = MailSubmissionOutcome.uncertain,
      );
      await _connect(tester);
      await _compose(
        tester,
        to: 'first@example.test, second@example.test',
        cc: 'copied@example.test',
        bcc: 'hidden@example.test',
      );
      expect(find.text(_strings.mailSubmissionUncertain), findsOneWidget);
      expect(provider.submissions, hasLength(1));
      await tester.tap(find.byTooltip(_strings.compose));
      await _pump(tester);
      expect(find.byType(StudioMailComposeDialog), findsOneWidget);
      expect(
        tester
            .widget<TextField>(_composerField(_strings.subject))
            .controller!
            .text,
        'EWS send',
      );
      expect(
        tester.widget<TextField>(_composerField(_strings.to)).controller!.text,
        'first@example.test, second@example.test',
      );
      expect(
        tester
            .widget<TextField>(_composerField(_strings.mailCc))
            .controller!
            .text,
        'copied@example.test',
      );
      expect(
        tester
            .widget<TextField>(_composerField(_strings.mailBcc))
            .controller!
            .text,
        'hidden@example.test',
      );
      final send = find.widgetWithText(FilledButton, _strings.send);
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      expect(provider.submissions, hasLength(1));
      provider.outcome = MailSubmissionOutcome.accepted;
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await _pump(tester);
      await tester.ensureVisible(send);
      await tester.tap(send);
      await _pump(tester);
      expect(provider.submissions, hasLength(2));
      for (final submission in provider.submissions) {
        expect(submission.envelope.recipients, [
          'first@example.test',
          'second@example.test',
          'copied@example.test',
          'hidden@example.test',
        ]);
        expect(
          utf8.decode(submission.wire.bytes),
          isNot(contains('hidden@example.test')),
        );
      }
      expect(provider.attempts.toSet(), hasLength(2));
      expect(find.text(_strings.ewsSubmissionAccepted), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS explicit attachment forward waits for durable save and starts a new thread',
    (tester) async {
      final drafts = MemoryStudioMailDrafts();
      final markerGate = Completer<void>();
      late _Provider provider;
      bool? durableAtSubmission;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials)
              ..replyParticipants = true
              ..onSubmit = () => durableAtSubmission =
                  drafts.records.values.single.submissionUncertain,
        drafts: drafts,
      );
      await _connect(tester);
      final source = const QudsMimeCodec().parse(provider.message().raw.bytes);
      expect(source.status, MailParseStatus.complete);
      expect(source.message!.attachments, hasLength(1));
      await tester.tap(find.text('First Exchange message'));
      await _pump(tester);
      await tester.tap(find.byTooltip(_strings.mailForwardWithAttachments));
      await _pump(tester);
      final initial = tester
          .widget<StudioMailComposeDialog>(find.byType(StudioMailComposeDialog))
          .initialDraft!;
      expect(initial.to, isEmpty);
      expect(initial.cc, isEmpty);
      expect(initial.bcc, isEmpty);
      expect(initial.attachments.items.single.name, 'example.txt');
      expect(
        initial.attachments.items.single.content.bytes,
        utf8.encode('example'),
      );
      expect(initial.thread.inReplyTo, isNull);
      expect(initial.thread.references, isNull);
      expect(initial.body, isNot(contains(_strings.mailTextOnlyForward)));
      expect(provider.submissions, isEmpty);
      await tester.enterText(
        _composerField(_strings.to),
        'forward@example.test',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(
        drafts.records.values.single.draft.attachments.items,
        hasLength(1),
      );
      expect(drafts.records.values.single.submissionUncertain, isFalse);
      drafts.saveGate = markerGate;
      final send = find.widgetWithText(FilledButton, _strings.send);
      await tester.ensureVisible(send);
      await tester.tap(send);
      await _pump(tester);
      expect(provider.submissions, isEmpty);
      expect(drafts.records.values.single.submissionUncertain, isFalse);
      markerGate.complete();
      await _pump(tester);
      expect(durableAtSubmission, isTrue);
      final submission = provider.submissions.single;
      final parsed = const QudsMimeCodec().parse(submission.wire.bytes);
      expect(parsed.status, MailParseStatus.complete);
      final message = parsed.message!;
      expect(message.attachments.single.displayName, 'example.txt');
      expect(message.attachments.single.content.bytes, utf8.encode('example'));
      expect(message.attachments.single.inline, isFalse);
      expect(message.envelope.inReplyTo, isNull);
      expect(message.envelope.references, isEmpty);
      expect(message.envelope.bcc, isEmpty);
      expect(submission.envelope.recipients, ['forward@example.test']);
      expect(
        utf8.decode(submission.wire.bytes),
        isNot(contains('hidden@example.test')),
      );
      expect(drafts.records, isEmpty);
      expect(find.text(_strings.ewsSubmissionAccepted), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final tooltip in [
    _strings.reply,
    _strings.replyAll,
    _strings.forward,
    _strings.mailForwardWithAttachments,
  ]) {
    testWidgets(
      'EWS $tooltip quotes safe HTML body text without active content',
      (tester) async {
        late _Provider provider;
        await _show(
          tester,
          (configuration, credentials) =>
              provider = _Provider(configuration, credentials),
        );
        await _connect(tester);
        final raw = Uint8List.fromList(
          utf8.encode(
            'From: writer@example.test\r\n'
            'To: reader@example.test\r\n'
            'Bcc: hidden@example.test\r\n'
            'Subject: HTML from Exchange\r\n'
            'Content-Type: text/html; charset=utf-8\r\n\r\n'
            '<p>Quoted Exchange HTML.</p>'
            '<script>private-script-content</script>'
            '<style>private-style-content</style>',
          ),
        );
        final parsed = const QudsMimeCodec().parse(raw);
        expect(parsed.status, MailParseStatus.complete);
        expect(parsed.message!.body.plainText, isNull);
        final header = provider.header(
          provider.firstMessageId,
          'First Exchange message',
        );
        final message = parsed.message!;
        provider.messageGate = Completer<MailResult<MailMessage>>()
          ..complete(
            MailSuccess(
              MailMessage(
                raw: message.raw,
                envelope: message.envelope,
                body: message.body,
                attachments: message.attachments,
                localId: header.id,
                remoteIdentity: header.remote,
              ),
            ),
          );
        await tester.tap(find.text('First Exchange message'));
        await _pump(tester);
        await tester.tap(find.byTooltip(tooltip));
        await _pump(tester);
        expect(find.byType(StudioMailComposeDialog), findsOneWidget);
        final body = tester
            .widget<QudsWordEditor>(find.byType(QudsWordEditor))
            .controller
            .document
            .paragraphs
            .map((paragraph) => paragraph.text)
            .join('\n');
        expect(body, contains('Quoted Exchange HTML.'));
        expect(body, isNot(contains('hidden@example.test')));
        expect(body, isNot(contains('private-script-content')));
        expect(body, isNot(contains('private-style-content')));
        expect(provider.submissions, isEmpty);
        await tester.ensureVisible(find.text(_strings.mailDraftSaveClose));
        await tester.tap(find.text(_strings.mailDraftSaveClose));
        await _pump(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final tooltip in [
    _strings.reply,
    _strings.replyAll,
    _strings.forward,
    _strings.mailForwardWithAttachments,
  ]) {
    testWidgets(
      'EWS $tooltip refuses a message with neither body nor attachments',
      (tester) async {
        late _Provider provider;
        await _show(
          tester,
          (configuration, credentials) =>
              provider = _Provider(configuration, credentials),
        );
        await _connect(tester);
        final source = provider.message();
        provider.messageGate = Completer<MailResult<MailMessage>>()
          ..complete(
            MailSuccess(
              MailMessage(
                raw: source.raw,
                envelope: source.envelope,
                body: const MailBody(),
                remoteIdentity: source.remoteIdentity,
                localId: source.localId,
              ),
            ),
          );
        await tester.tap(find.text('First Exchange message'));
        await _pump(tester);
        await tester.tap(find.byTooltip(tooltip));
        await _pump(tester);
        expect(find.byType(StudioMailComposeDialog), findsNothing);
        expect(find.text(_strings.mailPlainTextUnavailable), findsOneWidget);
        expect(provider.submissions, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'EWS retained uncertainty takes priority over invalid forward attachments',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials)
              ..outcome = MailSubmissionOutcome.uncertain,
      );
      await _connect(tester);
      await _compose(tester);
      expect(provider.submissions, hasLength(1));
      final source = provider.message();
      provider.messageGate = Completer<MailResult<MailMessage>>()
        ..complete(
          MailSuccess(
            MailMessage(
              raw: source.raw,
              envelope: source.envelope,
              body: source.body,
              attachments: [
                ...source.attachments,
                MailAttachment(
                  partPath: 'unsupported',
                  mediaType: 'message/rfc822',
                  displayName: 'private-source.eml',
                  content: MailBytes(Uint8List.fromList([1, 2, 3])),
                ),
              ],
              remoteIdentity: source.remoteIdentity,
              localId: source.localId,
            ),
          ),
        );
      await tester.tap(find.text('First Exchange message'));
      await _pump(tester);
      await tester.tap(find.byTooltip(_strings.mailForwardWithAttachments));
      await _pump(tester);
      expect(find.text(_strings.mailRetainedDraft), findsOneWidget);
      expect(
        find.text(_strings.mailForwardAttachmentsUnavailable),
        findsNothing,
      );
      expect(find.byType(StudioMailComposeDialog), findsNothing);
      expect(provider.submissions, hasLength(1));
      await tester.tap(find.byTooltip(_strings.compose));
      await _pump(tester);
      expect(
        tester
            .widget<TextField>(_composerField(_strings.subject))
            .controller!
            .text,
        'EWS send',
      );
      expect(find.text(_strings.mailRetryAcknowledgement), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, _strings.send),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text(_strings.mailDraftSaveClose));
      await tester.tap(find.text(_strings.mailDraftSaveClose));
      await _pump(tester);
      expect(provider.submissions, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS Reply all opens visible participants and preserves threading',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials)
              ..replyParticipants = true,
      );
      await _connect(tester);
      await tester.tap(find.text('First Exchange message'));
      await _pump(tester);
      await tester.tap(find.byTooltip(_strings.replyAll));
      await _pump(tester);
      expect(
        tester.widget<TextField>(_composerField(_strings.to)).controller!.text,
        'author@example.test, teammate@example.test',
      );
      expect(
        tester
            .widget<TextField>(_composerField(_strings.mailCc))
            .controller!
            .text,
        'copied@example.test',
      );
      expect(
        tester
            .widget<TextField>(_composerField(_strings.mailBcc))
            .controller!
            .text,
        isEmpty,
      );
      final send = find.widgetWithText(FilledButton, _strings.send);
      await tester.ensureVisible(send);
      await tester.tap(send);
      await _pump(tester);
      final submission = provider.submissions.single;
      expect(submission.envelope.recipients, [
        'author@example.test',
        'teammate@example.test',
        'copied@example.test',
      ]);
      final message = const QudsMimeCodec()
          .parse(submission.wire.bytes)
          .message!;
      expect(message.envelope.inReplyTo, '<parent@example.test>');
      expect(message.envelope.references, [
        '<root@example.test>',
        '<parent@example.test>',
      ]);
      expect(message.envelope.bcc, isEmpty);
      expect(message.body.plainText, contains('A message from Exchange.'));
      expect(message.attachments, isEmpty);
      expect(
        utf8.decode(submission.wire.bytes),
        isNot(contains('hidden@example.test')),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS reply actions reject ambiguous source recipients before composition',
    (tester) async {
      late _Provider provider;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials)
              ..envelopeOverride = MailEnvelope(
                subject: 'First Exchange message',
                from: const [MailAddress('writer@example.test')],
                replyTo: const [
                  MailAddress('first@example.test,second@example.test'),
                ],
              ),
      );
      await _connect(tester);
      await tester.tap(find.text('First Exchange message'));
      await _pump(tester);
      for (final action in [_strings.reply, _strings.replyAll]) {
        await tester.tap(find.byTooltip(action));
        await _pump(tester);
        expect(find.byType(StudioMailComposeDialog), findsNothing);
        expect(
          find.text(_strings.mailReplyRecipientsUnavailable),
          findsOneWidget,
        );
        expect(provider.submissions, isEmpty);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disposing during send ignores a late acceptance', (
    tester,
  ) async {
    late _Provider provider;
    final gate = Completer<MailSubmissionResult>();
    await _show(
      tester,
      (configuration, credentials) =>
          provider = _Provider(configuration, credentials)..sendGate = gate,
    );
    await _connect(tester);
    await _compose(tester);
    expect(provider.submissions, hasLength(1));
    final attempt = provider.attempts.single;
    await tester.tap(find.byTooltip(_strings.close));
    await _pump(tester);
    expect(provider.lastLease!.isCurrent, isFalse);
    gate.complete(
      MailSubmissionResult(
        attemptId: attempt,
        outcome: MailSubmissionOutcome.accepted,
      ),
    );
    await _pump(tester);
    expect(find.byType(StudioMailEwsDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider exceptions stay redacted in connection feedback', (
    tester,
  ) async {
    await _show(
      tester,
      (configuration, credentials) =>
          _Provider(configuration, credentials)..failConnection = true,
    );
    await _connect(tester);
    expect(find.text(_strings.mailConnectionFailed), findsOneWidget);
    expect(
      find.textContaining('private-password-and-server-text'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'narrow Exchange layout keeps setup, message and actions usable',
    (tester) async {
      await _show(
        tester,
        (configuration, credentials) => _Provider(configuration, credentials),
        size: const Size(390, 720),
      );
      await _connect(tester);
      expect(find.byType(DropdownButton<MailMailboxId>), findsOneWidget);
      await tester.tap(find.text('First Exchange message'));
      await _pump(tester);
      expect(find.byType(MailMessageView), findsOneWidget);
      expect(find.byTooltip(_strings.backToMessages), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS archive action preserves the fetched original and provenance without sending or mutating',
    (tester) async {
      late _Provider provider;
      MailMessage? archived;
      var archiveCalls = 0;
      MailArchiveOrigin? provenance;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
        archiveWriter: (message, {required origin, cancellation}) async {
          archiveCalls++;
          archived = message;
          provenance = origin;
          return _archiveSuccess(message);
        },
      );
      await _connect(tester);
      final original = provider.message();
      provider.messageGate = Completer<MailResult<MailMessage>>();
      await tester.tap(find.text('First Exchange message'));
      await _pump(tester);
      expect(archived, isNull);
      provider.messageGate!.complete(MailSuccess(original));
      await _pump(tester);
      await tester.tap(find.byTooltip(_strings.archiveCurrentMessage));
      await _pump(tester);
      expect(archived, same(original));
      expect(archived!.raw.bytes, orderedEquals(original.raw.bytes));
      expect(archived!.envelope.bcc.single.address, 'hidden@example.test');
      expect(archived!.attachments.single.displayName, 'example.txt');
      expect(
        archived!.attachments.single.content.bytes,
        orderedEquals(utf8.encode('example')),
      );
      expect(provenance!.source, 'Exchange · reader@example.test');
      expect(provenance!.folder, 'Inbox');
      expect(provenance!.sourceMessageId, 'one');
      expect(provider.reads, 1);
      expect(provider.commands, isEmpty);
      expect(provider.submissions, isEmpty);
      expect(archiveCalls, 1);
      expect(find.text(_strings.archiveMessageStored), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS folder archive uses the selected mailbox and a stable profile',
    (tester) async {
      late _Provider provider;
      MailArchiveProfile? profile;
      await _show(
        tester,
        (configuration, credentials) =>
            provider = _Provider(configuration, credentials),
        archiveFolderWriter:
            (
              value, {
              required cancellation,
              onProgress,
              required verboseDiagnostics,
            }) async {
              profile = value;
              return _folderReport();
            },
      );
      await _connect(tester);
      await tester.tap(find.byTooltip(_strings.archiveSelectedFolder));
      await _pump(tester);
      expect(profile, isNull);
      await tester.tap(find.byKey(const ValueKey('archive-folder-start')));
      await _pump(tester);
      expect(profile!.source, 'Exchange · reader@example.test');
      expect(profile!.folder, 'Inbox');
      expect(profile!.kind, MailArchiveProfileKind.mailbox);
      expect(profile!.includeSubfolders, isFalse);
      expect(profile!.id, startsWith('studio-mailbox:'));
      expect(provider.reads, 0);
      expect(provider.commands, isEmpty);
      expect(provider.submissions, isEmpty);
      expect(
        find.text(_strings.archiveFolderCounts(3, 1, 0, 2, 300)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('EWS selected message hashes an overlong opaque source ID', (
    tester,
  ) async {
    final originalId = 'opaque-EWS-value' * 160;
    MailArchiveOrigin? receivedOrigin;
    await _show(
      tester,
      (configuration, credentials) =>
          _Provider(configuration, credentials)..firstMessageId = originalId,
      archiveWriter: (message, {required origin, cancellation}) async {
        receivedOrigin = origin;
        return _archiveSuccess(message);
      },
    );
    await _connect(tester);
    await tester.tap(find.text('First Exchange message'));
    await _pump(tester);
    await tester.tap(find.byTooltip(_strings.archiveCurrentMessage));
    await _pump(tester);
    expect(
      receivedOrigin!.sourceMessageId,
      studioArchiveSourceMessageId(originalId),
    );
    expect(receivedOrigin!.sourceMessageId.length, 71);
    expect(tester.takeException(), isNull);
  });
}

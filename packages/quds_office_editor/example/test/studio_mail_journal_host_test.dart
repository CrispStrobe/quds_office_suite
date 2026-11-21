@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:enough_mail/enough_mail.dart' as mail;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quds_mail_core/quds_mail_core.dart';
import 'package:quds_mail_store/quds_mail_store.dart';
import 'package:quds_mail_transport/quds_mail_transport.dart';
import 'package:quds_mail_ui/quds_mail_ui.dart';
import 'package:quds_office_studio/studio_mail_bulk_status.dart';
import 'package:quds_office_studio/studio_mail_credentials.dart';
import 'package:quds_office_studio/studio_mail_draft_store.dart';
import 'package:quds_office_studio/studio_mail_ews.dart';
import 'package:quds_office_studio/studio_mail_journal_strings.dart';
import 'package:quds_office_studio/studio_mail_message_loader.dart';
import 'package:quds_office_studio/studio_mail_native.dart';
import 'package:quds_office_studio/studio_mail_strings.dart';
import 'package:quds_office_studio/studio_mail_workspace_strings.dart';
import 'package:quds_office_studio/studio_strings.dart';

import 'support/mail_flag_journal.dart';

const _strings = StudioStrings(StudioLanguage.en);
const _success = MailSuccess<MailUnit>(MailUnit.value);
Finder _key(String value) => find.byKey(ValueKey(value));
MailMessageList _list(WidgetTester tester) =>
    tester.widget(find.byType(MailMessageList));
StudioMailBulkStatus _status(WidgetTester tester) =>
    tester.widget(find.byType(StudioMailBulkStatus));
Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

final class _Incoming extends mail.ImapClient {
  @override
  Future<void> abort() async {}
}

final class _Outgoing extends mail.SmtpClient {
  _Outgoing() : super('test.invalid');
  @override
  Future<void> abort() async {}
}

final class _ImapClient extends Fake implements mail.MailClient {
  _ImapClient(this.harness);
  final _Harness harness;
  final _incoming = _Incoming();
  final _outgoing = _Outgoing();
  mail.Mailbox? selected;
  @override
  mail.Mailbox? get selectedMailbox => selected;
  @override
  mail.ImapClient get lowLevelIncomingMailClient => _incoming;
  @override
  mail.SmtpClient get lowLevelOutgoingMailClient => _outgoing;
  @override
  Future<void> connect({
    Duration timeout = const Duration(seconds: 20),
  }) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> sendMessage(
    mail.MimeMessage message, {
    mail.MailAddress? from,
    bool appendToSent = true,
    bool supportUnicode = false,
    mail.Mailbox? sentMailbox,
    bool use8BitEncoding = false,
    List<mail.MailAddress>? recipients,
  }) async {
    harness.sends++;
    throw StateError('A status observation must never submit mail.');
  }

  @override
  Future<List<mail.Mailbox>> listMailboxes({
    List<mail.MailboxFlag>? order,
  }) async => [
    mail.Mailbox(
      encodedName: 'INBOX',
      encodedPath: 'INBOX',
      pathSeparator: '/',
      flags: [mail.MailboxFlag.inbox],
    )..uidValidity = 71,
  ];
  @override
  Future<mail.Mailbox> selectMailbox(
    mail.Mailbox mailbox, {
    bool enableCondStore = false,
    mail.QResyncParameters? qresync,
  }) async => selected = mailbox;
}

final class _Credentials extends Fake implements StudioMailCredentialStore {
  @override
  Future<StudioMailCredentials?> load() async => null;
  @override
  Future<bool> save(StudioMailCredentials credentials) async => true;
  @override
  Future<bool> clear() async => true;
}

final class _ImapBrowser
    implements
        StudioMailMessageLoader,
        StudioMailMailboxBrowser,
        StudioMailMailboxRecords,
        StudioMailMessageActions,
        StudioMailBulkMessageActions,
        MailFlagObserver {
  _ImapBrowser(this.harness) {
    harness.liveAccount = account;
  }
  final _Harness harness;
  @override
  final account = MailAccountId(
    'imap-live-connection',
    profile: MailProfileId('ephemeral', hostId: 'native-test'),
  );
  final observations = Map<mail.MimeMessage, MailHeaderRecord>.identity();
  @override
  Future<StudioMailHeaderPage> fetchHeaders(
    mail.Mailbox mailbox, {
    MailCursor? cursor,
    int limit = 50,
  }) async {
    harness.headerReads++;
    final messages = [
      for (var uid = 1; uid <= 3; uid++)
        mail.MimeMessage.fromEnvelope(
          mail.Envelope(
            subject: 'Frozen subject $uid',
            from: [mail.MailAddress('Writer', 'writer@example.test')],
          ),
          uid: uid,
          flags: [mail.MessageFlags.seen],
        ),
    ];
    for (final message in messages) {
      observations[message] = MailHeaderRecord(
        id: MailMessageId('message-${message.uid}'),
        remote: MailImapIdentity(
          mailbox: MailMailboxId(mailbox.path, account: account),
          uidValidity: mailbox.uidValidity!,
          uid: message.uid!,
        ),
        envelope: MailEnvelope(subject: message.decodeSubject()!),
        flags: const MailMessageFlags(isRead: true),
      );
    }
    return StudioMailHeaderPage(messages: messages);
  }

  @override
  MailHeaderRecord observedHeader(
    mail.Mailbox mailbox,
    mail.MimeMessage header,
  ) => observations[header]!;
  @override
  MailImapIdentity bulkIdentity(
    mail.Mailbox mailbox,
    mail.MimeMessage header,
  ) => observedHeader(mailbox, header).remote as MailImapIdentity;
  @override
  Future<MailResult<MailUnit>> applyBulkFlag(
    MailOperation operation,
    MailOperationLease lease,
  ) => harness.record(operation);
  @override
  Future<Uint8List> fetch(mail.Mailbox mailbox, mail.MimeMessage header) async {
    harness.bodyReads++;
    return Uint8List.fromList(
      utf8.encode(
        'Subject: Frozen subject ${header.uid}\r\n\r\nSynthetic body.',
      ),
    );
  }

  @override
  Future<MailMessage> fetchMessage(
    mail.Mailbox mailbox,
    mail.MimeMessage header,
  ) async {
    final record = observedHeader(mailbox, header);
    return MailMessage(
      raw: MailBytes(await fetch(mailbox, header)),
      envelope: record.envelope,
      body: const MailBody(plainText: 'Synthetic body.'),
      localId: record.id,
      remoteIdentity: record.remote,
    );
  }

  @override
  Future<void> markRead(mail.Mailbox mailbox, mail.MimeMessage header) async {}
  @override
  Future<void> setRead(
    mail.Mailbox mailbox,
    mail.MimeMessage header, {
    required bool read,
  }) async =>
      throw StateError('Explicit flags must use the durable bulk path.');
  @override
  Future<void> setFlagged(
    mail.Mailbox mailbox,
    mail.MimeMessage header, {
    required bool flagged,
  }) async =>
      throw StateError('Explicit flags must use the durable bulk path.');
  @override
  void cancel() {}
  @override
  void dispose() {}

  @override
  Future<MailResult<MailFlagObservation>> observeFlags(
    MailRemoteIdentity identity, {
    required MailOperationLease lease,
  }) => harness.observe(identity, lease);
}

class _Provider extends Fake
    implements MailProvider, MailFlagObserver, MailSubmissionProvider {
  _Provider(this.harness, this.account) {
    harness.liveAccount = account;
  }
  final _Harness harness;
  @override
  final MailAccountId account;
  List<MailHeaderRecord> get headers => [
    for (var i = 1; i <= 3; i++)
      MailHeaderRecord(
        id: MailMessageId('message-$i'),
        remote: MailOpaqueIdentity(
          account: account,
          provider: harness.kind,
          value: 'remote-$i',
        ),
        envelope: MailEnvelope(subject: 'Frozen subject $i'),
        flags: const MailMessageFlags(isRead: true),
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
    MailMailbox(
      id: MailMailboxId('inbox', account: account),
      displayName: 'Inbox',
    ),
  ]);
  @override
  Future<MailResult<MailHeaderPage>> fetchHeaders(
    MailMailboxId mailbox, {
    MailCursor? cursor,
    required int limit,
    required MailOperationLease lease,
  }) async {
    harness.headerReads++;
    return MailSuccess(MailHeaderPage(messages: headers));
  }

  @override
  Future<MailResult<MailMessage>> fetchMessage(
    MailRemoteIdentity identity, {
    required MailReadBudget budget,
    required MailOperationLease lease,
  }) async {
    harness.bodyReads++;
    final record = headers.firstWhere((header) => header.remote == identity);
    return MailSuccess(
      MailMessage(
        raw: MailBytes(
          Uint8List.fromList(
            utf8.encode(
              'Subject: ${record.envelope.subject}\r\n\r\nSynthetic body.',
            ),
          ),
        ),
        envelope: record.envelope,
        body: const MailBody(plainText: 'Synthetic body.'),
        localId: record.id,
        remoteIdentity: record.remote,
      ),
    );
  }

  @override
  Future<MailResult<MailUnit>> apply(
    MailOperation operation,
    MailOperationLease lease,
  ) => harness.record(operation);

  @override
  Future<MailResult<MailFlagObservation>> observeFlags(
    MailRemoteIdentity identity, {
    required MailOperationLease lease,
  }) => harness.observe(identity, lease);

  @override
  Future<MailSubmissionResult> submit(
    MailPreparedMessage message, {
    required String attemptId,
    required MailOperationLease lease,
  }) async {
    harness.sends++;
    throw StateError('A status observation must never submit mail.');
  }
}

final class _EwsProvider extends _Provider implements MailEwsProvider {
  _EwsProvider(_Harness harness, MailEwsConfiguration configuration)
    : super(harness, configuration.account);
}

final class _CloudProvider extends _Provider implements MailCloudProvider {
  _CloudProvider(_Harness harness, MailCloudConfiguration configuration)
    : super(harness, configuration.account);
  @override
  void dispose() {}
}

final class _Tokens extends Fake implements MailCloudTokenSource {
  @override
  void dispose() {}
}

final class _Harness {
  _Harness(this.kind);
  final MailProviderKind kind;
  TestMailFlagJournal? _fixture;
  TestMailFlagJournal get fixture => _fixture!;
  final commands = <MailOperation>[];
  final atDispatch = <MailStoredFlagBatch>[];
  final flagObservations = <(MailRemoteIdentity, MailOperationLease)>[];
  MailAccountId? liveAccount;
  int headerReads = 0;
  int bodyReads = 0;
  int sends = 0;
  Future<MailResult<MailUnit>> Function(MailOperation)? respond;
  Future<MailResult<MailFlagObservation>> Function(
    MailRemoteIdentity,
    MailOperationLease,
  )?
  observeRespond;
  Future<StudioMailDraftStore> openStore(
    StudioMailDraftAccount identity,
  ) async {
    _fixture = await TestMailFlagJournal.create(identity: identity);
    return fixture.owner;
  }

  Future<MailResult<MailUnit>> record(MailOperation operation) async {
    commands.add(operation);
    final id = operation.id.substring(0, operation.id.lastIndexOf(':'));
    final snapshot = await fixture.store.load(id);
    if (snapshot == null) {
      throw StateError('Provider reached before durable intent.');
    }
    atDispatch.add(snapshot);
    return respond == null ? _success : await respond!(operation);
  }

  Future<MailResult<MailFlagObservation>> observe(
    MailRemoteIdentity identity,
    MailOperationLease lease,
  ) async {
    expectSync(identity.account, liveAccount);
    expectSync(lease.account, liveAccount);
    lease.checkCurrent();
    flagObservations.add((identity, lease));
    return observeRespond?.call(identity, lease) ??
        MailSuccess(
          MailFlagObservation.present(
            identity: identity,
            flags: const MailMessageFlags(isRead: true, isFlagged: true),
          ),
        );
  }

  Widget dialog() {
    if (kind == MailProviderKind.imap) {
      final client = _ImapClient(this);
      final browser = _ImapBrowser(this);
      return StudioMailDialog(
        strings: _strings,
        credentialStore: _Credentials(),
        clientFactory: (_) => client,
        messageLoaderFactory: (_) => browser,
        draftStoreFactory: openStore,
      );
    }
    if (kind == MailProviderKind.ews) {
      return StudioMailEwsDialog(
        strings: _strings,
        draftStoreFactory: openStore,
        providerFactory: (configuration, credentials) =>
            _EwsProvider(this, configuration),
      );
    }
    return StudioMailEwsDialog.cloud(
      strings: _strings,
      service: kind == MailProviderKind.gmail
          ? MailCloudService.gmail
          : MailCloudService.microsoft365,
      initialClientId: 'synthetic-desktop-client',
      draftStoreFactory: openStore,
      cloudAuthorizer:
          ({
            required configuration,
            required account,
            required openBrowser,
            required lease,
            log,
          }) async => MailSuccess(_Tokens()),
      cloudProviderFactory:
          ({required configuration, required tokenSource, log}) =>
              _CloudProvider(this, configuration),
    );
  }

  Future<void> dispose() async => _fixture?.dispose();
}

Future<void> _until(WidgetTester tester, bool Function() predicate) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 30));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    if (predicate()) {
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      return;
    }
  }
  fail('The synthetic host did not settle.');
}

Future<void> _show(WidgetTester tester, _Harness harness) async {
  tester.view
    ..physicalSize = const Size(1400, 1000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() => settleMailJournal(tester, harness.dispose));
  await tester.pumpWidget(MaterialApp(home: harness.dialog()));
  await tester.pump(const Duration(milliseconds: 350));
  if (harness.kind == MailProviderKind.imap) {
    await tester.enterText(
      _field(_strings.emailAddress),
      'reader@example.test',
    );
    await tester.enterText(_field(_strings.password), 'synthetic-password');
    await tester.tap(
      find.widgetWithText(SwitchListTile, _strings.manualServers),
    );
    await tester.pump();
    await tester.enterText(_field(_strings.imapHost), 'imap.example.test');
    await tester.enterText(_field(_strings.smtpHost), 'smtp.example.test');
    await tester.ensureVisible(find.text(_strings.connect));
    await tester.tap(find.text(_strings.connect));
  } else if (harness.kind == MailProviderKind.ews) {
    await tester.enterText(
      _key('ews-endpoint'),
      'https://mail.example.test/EWS/Exchange.asmx',
    );
    await tester.enterText(_key('ews-mailbox'), 'reader@example.test');
    await tester.enterText(_key('ews-login'), 'reader');
    await tester.enterText(_key('ews-password'), 'synthetic-password');
    await tester.tap(_key('ews-connect'));
  } else {
    await tester.enterText(_key('cloud-mailbox'), 'reader@example.test');
    await tester.tap(_key('cloud-connect'));
  }
  await _until(
    tester,
    () =>
        harness._fixture != null &&
        find.byType(MailMessageList).evaluate().length == 1 &&
        !_list(tester).busy,
  );
  expect(_key('studio-mail-open-activity'), findsOneWidget);
}

void _bulk(WidgetTester tester) {
  final list = _list(tester);
  list.onBulkAction!(
    MailBulkFlagAction.flag,
    list.items.map((item) => item.id).toList(),
  );
}

Future<MailStoredFlagBatch> _historicalUncertainty(
  WidgetTester tester,
  _Harness harness,
) async {
  final fixture = harness.fixture;
  final source = fixture.source('retired-connection');
  final mailbox = MailMailboxId('Archive/2025', account: source);
  final plan = MailBulkFlagPlan(
    id: 'historical-${harness.kind.name}',
    mailbox: mailbox,
    provider: harness.kind,
    action: MailBulkFlagAction.flag,
    messages: [
      for (var index = 0; index < 2; index++)
        if (harness.kind == MailProviderKind.imap)
          MailImapIdentity(mailbox: mailbox, uidValidity: 191, uid: 501 + index)
        else
          MailOpaqueIdentity(
            account: source,
            provider: harness.kind,
            value: 'historical-item-${501 + index}',
          ),
    ],
  );
  final session = MailAccountSession(source);
  var dispatched = 0;
  late MailStoredFlagBatch saved;
  try {
    await settleMailJournal(tester, () async {
      final report = await MailBulkFlagCoordinator().run(
        plan: plan,
        lease: session.begin(),
        isScopeCurrent: () => true,
        journal: fixture.bind(
          plan,
          subjects: ['Historical uncertain message', 'Never attempted'],
        ),
        apply: (_, _) async {
          dispatched++;
          return const MailBulkFlagAttempt.uncertain(
            MailProblem(
              MailProblemCode.providerFailure,
              mutationMayHaveOccurred: true,
            ),
          );
        },
      );
      expectSync(report.persistenceProblem, isNull);
      expectSync(report.uncertainCount, 1);
      expectSync(report.unattemptedCount, 1);
      saved = (await fixture.store.load(plan.id))!;
    });
  } finally {
    session.dispose();
  }
  expect(dispatched, 1);
  expect(saved.summary.complete, isTrue);
  expect(saved.summary.unresolvedCount, 1);
  expect(saved.resolutions, isEmpty);
  return saved;
}

Future<void> _openActivity(
  WidgetTester tester,
  MailStoredFlagBatch batch,
) async {
  await tester.tap(_key('studio-mail-open-activity'));
  await _until(
    tester,
    () =>
        _key(
          'studio-mail-activity-${batch.summary.id}',
        ).evaluate().isNotEmpty &&
        find.byType(LinearProgressIndicator).evaluate().isEmpty,
  );
  await tester.tap(_key('studio-mail-activity-${batch.summary.id}'));
  await _until(
    tester,
    () =>
        _key('studio-mail-activity-check').evaluate().isNotEmpty &&
        find.byType(LinearProgressIndicator).evaluate().isEmpty,
  );
  expect(find.text(_strings.mailActivityCheck), findsOneWidget);
}

Future<void> _checkActivity(WidgetTester tester) async {
  await tester.ensureVisible(_key('studio-mail-activity-check'));
  await tester.tap(_key('studio-mail-activity-check'));
}

void _expectHistoricalTarget(_Harness harness) {
  final observed = harness.flagObservations.single.$1;
  expect(observed.account, harness.liveAccount);
  // The frozen batch came from a retired connection; the check must be
  // re-targeted to the live one. (Since 45f0e503 EWS/Gmail/Graph live
  // accounts reuse the stable store identity, so they may equal
  // fixture.account; IMAP still uses a per-connection id.)
  expect(observed.account, isNot(harness.fixture.source('retired-connection')));
  expect(observed.provider, harness.kind);
  if (observed case MailImapIdentity(
    :final mailbox,
    :final uidValidity,
    :final uid,
  )) {
    expect(mailbox.value, 'Archive/2025');
    expect(uidValidity, 191);
    expect(uid, 501);
  } else {
    expect((observed as MailOpaqueIdentity).value, 'historical-item-501');
  }
}

void main() {
  for (final kind in [
    MailProviderKind.imap,
    MailProviderKind.ews,
    MailProviderKind.gmail,
    MailProviderKind.graph,
  ]) {
    testWidgets(
      '${kind.name} connected activity checks frozen history without replay and persists the separate observation',
      (tester) async {
        final harness = _Harness(kind);
        await _show(tester, harness);
        final historical = await _historicalUncertainty(tester, harness);
        final headerReads = harness.headerReads;
        expect(_list(tester).bulkActionsEnabled, isTrue);
        await _openActivity(tester, historical);
        expect(harness.flagObservations, isEmpty);
        expect(harness.commands, isEmpty);
        expect(harness.bodyReads, 0);
        expect(harness.sends, 0);
        expect(harness.headerReads, headerReads);
        expect(_status(tester).report.uncertainCount, 1);
        expect(_status(tester).historical, isTrue);

        await _checkActivity(tester);
        await _until(
          tester,
          () =>
              _key(
                'studio-mail-activity-observation-0',
              ).evaluate().isNotEmpty &&
              find.byType(LinearProgressIndicator).evaluate().isEmpty,
        );
        _expectHistoricalTarget(harness);
        expect(_key('studio-mail-activity-check'), findsNothing);
        expect(find.text('1 checked · 0 still to check'), findsOneWidget);
        expect(
          find.text(
            _strings.mailActivityObserved(
              MailFlagResolutionKind.matches,
              MailBulkFlagAction.flag,
            ),
          ),
          findsOneWidget,
        );
        expect(_status(tester).report.confirmedCount, 0);
        expect(_status(tester).report.uncertainCount, 1);
        expect(_status(tester).report.unattemptedCount, 1);
        expect(harness.commands, isEmpty);
        expect(harness.bodyReads, 0);
        expect(harness.sends, 0);
        expect(harness.headerReads, headerReads);

        await tester.tap(_key('studio-mail-activity-close'));
        await _until(
          tester,
          () => _key('studio-mail-activity-dialog').evaluate().isEmpty,
        );
        expect(_list(tester).bulkActionsEnabled, isFalse);
        expect(
          find.text(_strings.mailWorkspaceRefreshRequired),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await settleMailJournal(tester, harness.fixture.reopen);
        final saved = (await tester.runAsync(
          () => harness.fixture.store.load(historical.summary.id),
        ))!;
        expect(
          saved.summary.revision,
          greaterThan(historical.summary.revision),
        );
        expect(saved.summary.uncertainCount, 1);
        expect(saved.summary.reconciledCount, 1);
        expect(saved.summary.unresolvedCount, 0);
        expect(saved.report.confirmedCount, 0);
        expect(saved.report.uncertainCount, 1);
        expect(saved.report.unattemptedCount, 1);
        expect(
          saved.report.items.first.problem!.mutationMayHaveOccurred,
          isTrue,
        );
        expect(saved.report.plan.messages, historical.report.plan.messages);
        expect(saved.resolutions.single.index, 0);
        expect(saved.resolutions.single.kind, MailFlagResolutionKind.matches);
        expect(saved.resolutions.single.checkedAt, harness.fixture.now);
        expect(harness.flagObservations, hasLength(1));
        expect(harness.commands, isEmpty);
        expect(harness.sends, 0);
      },
    );

    for (final retireHost in [false, true]) {
      testWidgets(
        '${kind.name} ${retireHost ? 'retiring the host' : 'closing activity'} cancels a pending check and rejects its late observation',
        (tester) async {
          final harness = _Harness(kind);
          final response = Completer<MailResult<MailFlagObservation>>();
          harness.observeRespond = (_, _) => response.future;
          await _show(tester, harness);
          final historical = await _historicalUncertainty(tester, harness);
          final headerReads = harness.headerReads;
          await _openActivity(tester, historical);
          expect(harness.flagObservations, isEmpty);
          await _checkActivity(tester);
          await _until(tester, () => harness.flagObservations.length == 1);
          _expectHistoricalTarget(harness);
          if (retireHost) {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          } else {
            await tester.tap(_key('studio-mail-activity-close'));
          }
          await _until(
            tester,
            () => !harness.flagObservations.single.$2.isCurrent,
          );
          // The non-cooperative provider is still pending. Cancellation must
          // release the store queue without waiting for its reply.
          if (retireHost) {
            await settleMailJournal(tester, harness.fixture.owner.close);
          } else {
            await settleMailJournal(tester, () async {
              final saved = (await harness.fixture.store.load(
                historical.summary.id,
              ))!;
              expectSync(saved.resolutions, isEmpty);
              expectSync(saved.summary.unresolvedCount, 1);
            });
          }
          response.complete(
            MailSuccess(
              MailFlagObservation.present(
                identity: harness.flagObservations.single.$1,
                flags: const MailMessageFlags(isFlagged: true),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          if (!retireHost) {
            await _openActivity(tester, historical);
            expect(_key('studio-mail-activity-observation-0'), findsNothing);
            expect(find.text('0 checked · 1 still to check'), findsOneWidget);
            expect(_status(tester).report.uncertainCount, 1);
          }
          expect(harness.flagObservations, hasLength(1));
          expect(harness.commands, isEmpty);
          expect(harness.bodyReads, 0);
          expect(harness.sends, 0);
          expect(harness.headerReads, headerReads);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await settleMailJournal(tester, harness.fixture.reopen);
          final saved = (await tester.runAsync(
            () => harness.fixture.store.load(historical.summary.id),
          ))!;
          expect(saved.resolutions, isEmpty);
          expect(saved.summary.uncertainCount, 1);
          expect(saved.summary.unresolvedCount, 1);
          expect(saved.report.unattemptedCount, 1);
          expect(harness.flagObservations, hasLength(1));
          expect(harness.commands, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      '${kind.name} actual host journals bulk and single flags before provider dispatch',
      (tester) async {
        final harness = _Harness(kind);
        await _show(tester, harness);
        _bulk(tester);
        await _until(
          tester,
          () => harness.commands.length == 3 && !_list(tester).busy,
        );
        expect(_status(tester).report.confirmedCount, 3);
        expect(harness.atDispatch, hasLength(3));
        for (var i = 0; i < 3; i++) {
          final saved = harness.atDispatch[i];
          expect(saved.summary.complete, isFalse);
          expect(saved.summary.mailbox.account, harness.fixture.account);
          expect(saved.summary.uncertainCount, 1);
          expect(saved.summary.confirmedCount, i);
          expect(saved.summary.unattemptedCount, 2 - i);
        }
        final firstId = _list(tester).items.first.id;
        _list(tester).onOpen(firstId);
        await _until(
          tester,
          () =>
              find.byType(MailMessageView).evaluate().length == 1 &&
              !_list(tester).busy,
        );
        final unflag = find.byWidgetPredicate(
          (widget) =>
              widget is IconButton && widget.tooltip == _strings.ewsUnflag,
        );
        await tester.ensureVisible(unflag);
        await tester.tap(unflag);
        await _until(
          tester,
          () => harness.commands.length == 4 && !_list(tester).busy,
        );
        expect(harness.commands.last, isA<MailSetFlagged>());
        expect((harness.commands.last as MailSetFlagged).flagged, isFalse);
        expect(harness.atDispatch.last.summary.totalCount, 1);
        expect(harness.atDispatch.last.summary.uncertainCount, 1);
        await tester.tap(_key('studio-mail-open-activity'));
        await _until(
          tester,
          () =>
              _key('studio-mail-activity-dialog').evaluate().isNotEmpty &&
              find.byType(LinearProgressIndicator).evaluate().isEmpty,
        );
        expect(
          find.descendant(
            of: _key('studio-mail-activity-dialog'),
            matching: find.byType(ListTile),
          ),
          findsNWidgets(2),
        );
        expect(harness.commands, hasLength(4));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await settleMailJournal(tester, harness.fixture.reopen);
        final page = (await tester.runAsync(
          () => harness.fixture.store.list(),
        ))!;
        expect(page.batches, hasLength(2));
        expect(page.batches.map((batch) => batch.confirmedCount).toSet(), {
          1,
          3,
        });
        expect(harness.commands, hasLength(4));
      },
    );

    testWidgets(
      '${kind.name} actual host stops before dispatch when intent cannot commit',
      (tester) async {
        final harness = _Harness(kind);
        await _show(tester, harness);
        harness.fixture.failWrites = true;
        _bulk(tester);
        await _until(
          tester,
          () =>
              find.byType(StudioMailBulkStatus).evaluate().isNotEmpty &&
              _status(tester).report.persistenceProblem != null &&
              !_list(tester).busy,
        );
        expect(harness.commands, isEmpty);
        expect(_status(tester).report.unattemptedCount, 3);
        expect(_list(tester).bulkActionsEnabled, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await settleMailJournal(tester, harness.fixture.reopen);
        expect(
          (await tester.runAsync(() => harness.fixture.store.list()))!.batches,
          isEmpty,
        );
      },
    );

    testWidgets(
      '${kind.name} retiring the actual host waits for its durable late acknowledgement',
      (tester) async {
        final harness = _Harness(kind);
        final response = Completer<MailResult<MailUnit>>();
        harness.respond = (_) => response.future;
        await _show(tester, harness);
        _bulk(tester);
        await _until(tester, () => harness.atDispatch.length == 1);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        response.complete(_success);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 20));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
        }
        await settleMailJournal(tester, harness.fixture.reopen);
        final page = (await tester.runAsync(
          () => harness.fixture.store.list(),
        ))!;
        expect(page.batches, hasLength(1));
        final saved = (await tester.runAsync(
          () => harness.fixture.store.load(page.batches.single.id),
        ))!;
        expect(saved.report.confirmedCount, 1);
        expect(saved.report.uncertainCount, 0);
        expect(saved.report.unattemptedCount, 2);
        expect(harness.commands, hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );
  }
}

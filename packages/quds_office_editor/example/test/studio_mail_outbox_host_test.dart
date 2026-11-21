import 'dart:convert';
import 'dart:typed_data';

import 'package:enough_mail/enough_mail.dart' as mail;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quds_mail_core/quds_mail_core.dart';
import 'package:quds_mail_mime/quds_mail_mime.dart';
import 'package:quds_mail_store/quds_mail_store.dart';
import 'package:quds_mail_transport/quds_mail_transport.dart';
import 'package:quds_office_editor/quds_office_editor.dart';
import 'package:quds_office_studio/studio_mail_compose.dart';
import 'package:quds_office_studio/studio_mail_credentials.dart';
import 'package:quds_office_studio/studio_mail_draft_store.dart';
import 'package:quds_office_studio/studio_mail_drafts_dialog.dart';
import 'package:quds_office_studio/studio_mail_drafts_strings.dart';
import 'package:quds_office_studio/studio_mail_ews.dart';
import 'package:quds_office_studio/studio_mail_message_loader.dart';
import 'package:quds_office_studio/studio_mail_native.dart';
import 'package:quds_office_studio/studio_mail_outbox_dialog.dart';
import 'package:quds_office_studio/studio_mail_outbox_strings.dart';
import 'package:quds_office_studio/studio_mail_strings.dart';
import 'package:quds_office_studio/studio_strings.dart';

import 'support/mail_outbox_store.dart';

const _strings = StudioStrings(StudioLanguage.en);
const _sender = 'reader@example.test';
const _ewsEndpoint = 'https://mail.example.test/EWS/Exchange.asmx';

StudioMailDraftAccount _identity({bool ews = false}) => StudioMailDraftAccount(
  provider: ews ? 'ews' : 'imap',
  endpoint: ews ? _ewsEndpoint : 'imaps://imap.example.test:993',
  login: ews ? jsonEncode(['', _sender]) : _sender,
  sender: _sender,
);

final class _Credentials implements StudioMailCredentialStore {
  @override
  Future<StudioMailCredentials?> load() async => null;
  @override
  Future<bool> save(StudioMailCredentials credentials) async => true;
  @override
  Future<bool> clear() async => true;
}

final class _Loader implements StudioMailMessageLoader {
  @override
  Future<Uint8List> fetch(mail.Mailbox mailbox, mail.MimeMessage header) =>
      throw StateError('The empty fixture has no message to read.');
  @override
  Future<void> markRead(mail.Mailbox mailbox, mail.MimeMessage header) async {}
  @override
  void cancel() {}
  @override
  void dispose() {}
}

final class _Client extends Fake implements mail.MailClient {
  final inbox = mail.Mailbox(
    encodedName: 'INBOX',
    encodedPath: 'INBOX',
    flags: <mail.MailboxFlag>[],
    pathSeparator: '/',
    uidValidity: 41,
  );
  final sent = <mail.MimeMessage>[];
  final recipientLists = <List<String>>[];
  final senders = <String?>[];
  final appendRequests = <bool>[];
  Future<void> Function()? onSend;

  @override
  mail.Mailbox get selectedMailbox => inbox;
  @override
  Future<void> connect({
    Duration timeout = const Duration(seconds: 20),
  }) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<List<mail.Mailbox>> listMailboxes({
    List<mail.MailboxFlag>? order,
  }) async => [inbox];
  @override
  Future<List<mail.MimeMessage>> fetchMessages({
    mail.Mailbox? mailbox,
    int count = 20,
    int page = 1,
    mail.FetchPreference fetchPreference =
        mail.FetchPreference.fullWhenWithinSize,
  }) async => [];
  @override
  Future<mail.Mailbox> selectMailbox(
    mail.Mailbox mailbox, {
    bool enableCondStore = false,
    mail.QResyncParameters? qresync,
  }) async => mailbox;
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
    sent.add(message);
    recipientLists.add([
      for (final address in recipients ?? <mail.MailAddress>[]) address.email,
    ]);
    senders.add(from?.email);
    appendRequests.add(appendToSent);
    await onSend?.call();
  }
}

final class _EwsProvider extends Fake implements MailEwsProvider {
  _EwsProvider(this.configuration);
  final MailEwsConfiguration configuration;
  final submissions = <MailPreparedMessage>[];
  final attempts = <String>[];
  Future<void> Function()? onSubmit;

  @override
  MailAccountId get account => configuration.account;
  MailMailboxId get inbox => MailMailboxId('inbox', account: account);

  @override
  Future<MailResult<MailCapabilities>> capabilities(
    MailOperationLease lease,
  ) async => MailSuccess(
    MailCapabilities(const [
      MailCapability.mail,
      MailCapability.folders,
      MailCapability.send,
    ]),
  );
  @override
  Future<MailResult<List<MailMailbox>>> listMailboxes(
    MailOperationLease lease,
  ) async => MailSuccess([MailMailbox(id: inbox, displayName: 'Inbox')]);
  @override
  Future<MailResult<MailHeaderPage>> fetchHeaders(
    MailMailboxId mailbox, {
    MailCursor? cursor,
    required int limit,
    required MailOperationLease lease,
  }) async => MailSuccess(MailHeaderPage(messages: const []));
  @override
  Future<MailSubmissionResult> submit(
    MailPreparedMessage message, {
    required String attemptId,
    required MailOperationLease lease,
  }) async {
    expectSync(message.account, account);
    expectSync(lease.isCurrent, isTrue);
    submissions.add(message);
    attempts.add(attemptId);
    await onSubmit?.call();
    return MailSubmissionResult(
      attemptId: attemptId,
      outcome: MailSubmissionOutcome.accepted,
    );
  }
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);
Finder _action(String action, MailOutboxEntry entry) =>
    find.byKey(ValueKey('studio-mail-outbox-$action-${entry.id}'));
Finder get _openOutbox => find.byKey(const ValueKey('studio-mail-open-outbox'));
Finder get _queue => find.byKey(const ValueKey('studio-mail-queue'));
Finder _outboxIcon(String tooltip) => find.descendant(
  of: find.byType(StudioMailOutboxDialog),
  matching: find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.tooltip == tooltip,
  ),
);

Future<void> _press(WidgetTester tester, Finder control) async {
  await tester.ensureVisible(control);
  await _pump(tester);
  await tester.tap(control);
  await _pump(tester);
}

Future<void> _pump(WidgetTester tester) => pumpOutboxWidgets(tester);

Future<SqliteOutboxFixture> _fixture(
  WidgetTester tester, {
  bool ews = false,
}) async {
  final fixture = await awaitOutboxOperation(
    tester,
    SqliteOutboxFixture.create(_identity(ews: ews)),
  );
  addTearDown(() => awaitOutboxOperation(tester, fixture.close()));
  await tester.binding.setSurfaceSize(const Size(1440, 1050));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  return fixture;
}

Future<void> _mountHost(WidgetTester tester, Widget host) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showDialog<void>(context: context, builder: (_) => host),
            child: const Text('Open host fixture'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open host fixture'));
  await _pump(tester);
}

Future<void> _native(
  WidgetTester tester,
  SqliteOutboxFixture fixture,
  _Client client,
) async {
  await _mountHost(
    tester,
    StudioMailDialog(
      strings: _strings,
      clientFactory: (_) => client,
      messageLoaderFactory: (_) => _Loader(),
      credentialStore: _Credentials(),
      draftStoreFactory: fixture.open,
    ),
  );
  await tester.enterText(_field(_strings.emailAddress), _sender);
  await tester.enterText(_field(_strings.password), 'session-fixture');
  await tester.tap(find.widgetWithText(SwitchListTile, _strings.manualServers));
  await _pump(tester);
  await tester.enterText(_field(_strings.imapHost), 'imap.example.test');
  await tester.enterText(_field(_strings.smtpHost), 'smtp.example.test');
  await tester.ensureVisible(
    find.widgetWithText(FilledButton, _strings.connect),
  );
  await tester.tap(find.widgetWithText(FilledButton, _strings.connect));
  await _pump(tester);
  expect(_openOutbox, findsOneWidget);
}

Future<_EwsProvider> _ews(
  WidgetTester tester,
  SqliteOutboxFixture fixture,
) async {
  late _EwsProvider provider;
  await _mountHost(
    tester,
    StudioMailEwsDialog(
      strings: _strings,
      providerFactory: (configuration, credentials) =>
          provider = _EwsProvider(configuration),
      draftStoreFactory: fixture.open,
    ),
  );
  await tester.enterText(
    find.byKey(const ValueKey('ews-endpoint')),
    _ewsEndpoint,
  );
  await tester.enterText(find.byKey(const ValueKey('ews-mailbox')), _sender);
  await tester.enterText(find.byKey(const ValueKey('ews-login')), _sender);
  await tester.enterText(
    find.byKey(const ValueKey('ews-password')),
    'session-fixture',
  );
  await tester.ensureVisible(find.byKey(const ValueKey('ews-connect')));
  await tester.tap(find.byKey(const ValueKey('ews-connect')));
  await _pump(tester);
  expect(_openOutbox, findsOneWidget);
  return provider;
}

Future<void> _compose(
  WidgetTester tester, {
  bool ews = false,
  String subject = 'Queued from host',
}) async {
  await tester.tap(
    ews
        ? find.byTooltip(_strings.compose)
        : find.widgetWithText(TextButton, _strings.compose),
  );
  await _pump(tester);
  await tester.enterText(_field(_strings.to), 'to@example.test');
  if (_field(_strings.mailCc).evaluate().isEmpty) {
    await tester.tap(find.text(_strings.mailCopyRecipients));
    await _pump(tester);
  }
  await tester.enterText(_field(_strings.mailCc), 'copy@example.test');
  await tester.enterText(_field(_strings.mailBcc), 'hidden@example.test');
  await tester.enterText(_field(_strings.subject), subject);
  tester
      .widget<QudsWordEditor>(find.byType(QudsWordEditor))
      .controller
      .insertText('Written in the composer.');
  await tester.pump();
}

Future<(MailOutboxEntry, StudioMailDraft, StudioMailDraft)> _seedManagedOutbox(
  WidgetTester tester,
  SqliteOutboxFixture fixture,
) async {
  final seed = await awaitOutboxOperation(tester, fixture.openLoaded());
  const sibling = StudioMailDraft(
    to: 'sibling@example.test',
    bcc: 'sibling-hidden@example.test',
    subject: 'Keep the previous selected draft',
    body: 'This unrelated unfinished message must survive.',
  );
  await awaitOutboxOperation(
    tester,
    seed.save(sibling, submissionUncertain: true),
  );
  final original = StudioMailDraft(
    to: 'queued@example.test',
    cc: 'queued-copy@example.test',
    bcc: 'queued-hidden@example.test',
    subject: 'Original queued message مرحبًا',
    body: 'Frozen message <safe> & unchanged.',
    attachments: StudioMailAttachments.from([
      StudioMailAttachment(
        name: 'résumé.bin',
        bytes: Uint8List.fromList([0, 10, 13, 128, 255]),
      ),
    ]),
  );
  await awaitOutboxOperation(tester, seed.createDraft(original));
  final queued = await awaitOutboxOperation(
    tester,
    seed.enqueueOutbox(original, _sender),
  );
  await awaitOutboxOperation(tester, seed.close());
  return (queued, original, sibling);
}

void main() {
  for (final ews in [false, true]) {
    testWidgets(
      '${ews ? 'EWS' : 'IMAP'} edits queued copy into the correct draft and explicitly requeues new MIME',
      (tester) async {
        final fixture = await _fixture(tester, ews: ews);
        final (originalEntry, original, sibling) = await _seedManagedOutbox(
          tester,
          fixture,
        );
        final client = _Client();
        final provider = ews ? await _ews(tester, fixture) : null;
        if (!ews) await _native(tester, fixture, client);
        final store = fixture.adapters.last;
        expect(store.selectedDraftId, SqliteStudioMailDraftStore.draftId);
        final oldEpoch = store.selectionEpoch;
        await _press(tester, _openOutbox);
        await _press(tester, _action('edit', originalEntry));
        expect(find.text(_strings.mailOutboxEditExplanation), findsOneWidget);
        expect(find.byType(StudioMailComposeDialog), findsNothing);
        await _press(
          tester,
          find.byKey(const ValueKey('studio-mail-outbox-confirm')),
        );
        expect(find.byType(StudioMailOutboxDialog), findsNothing);
        final composer = tester.widget<StudioMailComposeDialog>(
          find.byType(StudioMailComposeDialog),
        );
        expect(composer.initialDraft!.subject, original.subject);
        expect(composer.initialDraft!.body, original.body);
        expect(composer.initialDraft!.to, original.to);
        expect(composer.initialDraft!.cc, original.cc);
        expect(composer.initialDraft!.bcc, original.bcc);
        expect(
          composer.initialDraft!.attachments.items.single.content.bytes,
          original.attachments.items.single.content.bytes,
        );
        expect(composer.previousSubmissionUncertain, isFalse);
        final editedId = store.selectedDraftId;
        expect(editedId, isNot(SqliteStudioMailDraftStore.draftId));
        expect(editedId, isNot(originalEntry.prepared.draftId));
        expect(store.selectionEpoch, greaterThan(oldEpoch));
        expect(client.sent, isEmpty);
        expect(provider?.submissions ?? [], isEmpty);
        final retired = (await awaitOutboxOperation(
          tester,
          store.loadOutbox(),
        )).single;
        expect(retired.state, MailOutboxState.cancelled);
        expect(retired.prepared.wire.bytes, originalEntry.prepared.wire.bytes);
        final beforeQueue = await awaitOutboxOperation(
          tester,
          store.listDrafts(),
        );
        expect(beforeQueue.drafts, hasLength(2));
        final kept = beforeQueue.drafts.singleWhere(
          (entry) => entry.id == SqliteStudioMailDraftStore.draftId,
        );
        expect(kept.subject, sibling.subject);
        expect(kept.submissionUncertain, isTrue);

        await tester.enterText(
          _field(_strings.subject),
          'Explicitly edited message',
        );
        await _press(tester, _queue);
        expect(find.byType(StudioMailComposeDialog), findsNothing);
        final entries = await awaitOutboxOperation(tester, store.loadOutbox());
        expect(entries, hasLength(2));
        final edited = entries.singleWhere(
          (entry) => entry.id != originalEntry.id,
        );
        expect(edited.state, MailOutboxState.queued);
        expect(edited.attemptNumber, 0);
        expect(edited.prepared.draftId, editedId);
        expect(
          edited.prepared.wireHash,
          isNot(originalEntry.prepared.wireHash),
        );
        final originalMessage = const QudsMimeCodec()
            .parse(originalEntry.prepared.wire.bytes)
            .message!;
        final newMessage = const QudsMimeCodec()
            .parse(edited.prepared.wire.bytes)
            .message!;
        expect(newMessage.envelope.messageId, isNotNull);
        expect(
          newMessage.envelope.messageId,
          isNot(originalMessage.envelope.messageId),
        );
        expect(newMessage.envelope.subject, 'Explicitly edited message');
        expect(
          newMessage.attachments.single.content.bytes,
          original.attachments.items.single.content.bytes,
        );
        expect(
          edited.prepared.envelope.recipients,
          original.recipients.envelope,
        );
        final remaining = await awaitOutboxOperation(
          tester,
          store.listDrafts(),
        );
        expect(remaining.drafts.single.id, SqliteStudioMailDraftStore.draftId);
        expect(remaining.drafts.single.subject, sibling.subject);
        expect(remaining.drafts.single.submissionUncertain, isTrue);
        await _press(tester, _openOutbox);
        expect(client.sent, isEmpty);
        expect(provider?.submissions ?? [], isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${ews ? 'EWS' : 'IMAP'} failed edit keeps original queue and prior selected draft',
      (tester) async {
        final fixture = await _fixture(tester, ews: ews);
        final (originalEntry, _, sibling) = await _seedManagedOutbox(
          tester,
          fixture,
        );
        final client = _Client();
        final provider = ews ? await _ews(tester, fixture) : null;
        if (!ews) await _native(tester, fixture, client);
        final store = fixture.adapters.last;
        final selectedId = store.selectedDraftId;
        final originalEpoch = store.selectionEpoch;
        await _press(tester, _openOutbox);
        await _press(tester, _action('edit', originalEntry));
        fixture.failNextCheckpoint = MailStoreCheckpoint.afterDraftBlobs;
        await _press(
          tester,
          find.byKey(const ValueKey('studio-mail-outbox-confirm')),
        );
        expect(find.byType(StudioMailOutboxDialog), findsOneWidget);
        expect(find.text(_strings.mailOutboxFailed), findsOneWidget);
        expect(store.selectedDraftId, selectedId);
        expect(store.selectionEpoch, originalEpoch);
        expect(
          (await awaitOutboxOperation(tester, store.loadOutbox())).single.state,
          MailOutboxState.queued,
        );
        expect(
          (await awaitOutboxOperation(
            tester,
            store.listDrafts(),
          )).drafts.single.id,
          selectedId,
        );
        await _press(tester, _outboxIcon(_strings.close));
        await _press(
          tester,
          ews
              ? find.byTooltip(_strings.compose)
              : find.widgetWithText(TextButton, _strings.compose),
        );
        final composer = tester.widget<StudioMailComposeDialog>(
          find.byType(StudioMailComposeDialog),
        );
        expect(composer.initialDraft!.subject, sibling.subject);
        expect(composer.initialDraft!.body, sibling.body);
        expect(composer.initialDraft!.bcc, sibling.bcc);
        expect(composer.previousSubmissionUncertain, isTrue);
        expect(client.sent, isEmpty);
        expect(provider?.submissions ?? [], isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${ews ? 'EWS' : 'IMAP'} keeps independent drafts when creating, resuming and queueing',
      (tester) async {
        final fixture = await _fixture(tester, ews: ews);
        final seed = await awaitOutboxOperation(tester, fixture.openLoaded());
        final legacy = StudioMailDraft(
          to: 'first@example.test',
          bcc: 'first-hidden@example.test',
          subject: 'First retained draft',
          body: 'Keep this unfinished message.',
          attachments: StudioMailAttachments.from([
            StudioMailAttachment(
              name: 'first.txt',
              bytes: Uint8List.fromList(utf8.encode('first attachment')),
            ),
          ]),
        );
        await awaitOutboxOperation(
          tester,
          seed.save(legacy, submissionUncertain: true),
        );
        await awaitOutboxOperation(tester, seed.close());
        final client = _Client();
        final provider = ews ? await _ews(tester, fixture) : null;
        if (!ews) await _native(tester, fixture, client);
        final store = fixture.adapters.last;
        final openDrafts = find.byKey(
          const ValueKey('studio-mail-open-drafts'),
        );
        await _press(tester, openDrafts);
        expect(find.byType(StudioMailDraftsDialog), findsOneWidget);
        expect(find.text('First retained draft'), findsOneWidget);
        expect(find.text(_strings.mailDraftUncertain), findsOneWidget);
        await _press(
          tester,
          find.byKey(const ValueKey('studio-mail-new-draft')),
        );
        expect(find.byType(StudioMailComposeDialog), findsOneWidget);
        expect(
          tester.widget<TextField>(_field(_strings.subject)).controller!.text,
          isEmpty,
        );
        await tester.enterText(_field(_strings.to), 'second@example.test');
        await tester.enterText(_field(_strings.subject), 'Second draft');
        tester
            .widget<QudsWordEditor>(find.byType(QudsWordEditor))
            .controller
            .insertText('Independent second body.');
        await _press(tester, find.text(_strings.mailDraftSaveClose));
        final page = await awaitOutboxOperation(tester, store.listDrafts());
        expect(page.drafts, hasLength(2));
        final first = page.drafts.singleWhere(
          (entry) => entry.subject == 'First retained draft',
        );
        final second = page.drafts.singleWhere(
          (entry) => entry.subject == 'Second draft',
        );
        expect(first.id, SqliteStudioMailDraftStore.draftId);
        expect(first.submissionUncertain, isTrue);
        expect(first.attachmentCount, 1);
        expect(second.id, isNot(first.id));
        expect(second.submissionUncertain, isFalse);
        await _press(tester, openDrafts);
        await _press(tester, find.text('First retained draft'));
        final composer = tester.widget<StudioMailComposeDialog>(
          find.byType(StudioMailComposeDialog),
        );
        expect(composer.previousSubmissionUncertain, isTrue);
        expect(
          composer.initialDraft!.attachments.items.single.name,
          'first.txt',
        );
        expect(composer.initialDraft!.bcc, 'first-hidden@example.test');
        await _press(tester, find.text(_strings.mailDraftSaveClose));
        await _press(tester, openDrafts);
        await _press(tester, find.text('Second draft'));
        await _press(tester, _queue);
        expect(find.byType(StudioMailComposeDialog), findsNothing);
        final remaining = await awaitOutboxOperation(
          tester,
          store.listDrafts(),
        );
        expect(remaining.drafts.single.id, first.id);
        expect(remaining.drafts.single.submissionUncertain, isTrue);
        final queued = (await awaitOutboxOperation(
          tester,
          store.loadOutbox(),
        )).single;
        expect(queued.prepared.draftId, second.id);
        expect(queued.priorSubmissionUncertain, isFalse);
        expect(client.sent, isEmpty);
        expect(provider?.submissions ?? [], isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'native queue freezes attachments and envelope across explicit retry',
    (tester) async {
      final fixture = await _fixture(tester);
      final seed = await awaitOutboxOperation(tester, fixture.openLoaded());
      final attachment = Uint8List.fromList([0, 10, 13, 128, 255]);
      await awaitOutboxOperation(
        tester,
        seed.save(
          StudioMailDraft(
            to: 'to@example.test',
            cc: 'copy@example.test',
            bcc: 'hidden@example.test',
            subject: 'Original draft',
            body: 'Original body. ',
            attachments: StudioMailAttachments.from([
              StudioMailAttachment(name: 'résumé.bin', bytes: attachment),
            ]),
          ),
          submissionUncertain: false,
        ),
      );
      await awaitOutboxOperation(tester, seed.close());
      final client = _Client();
      await _native(tester, fixture, client);
      final store = fixture.adapters.last;
      await _compose(tester);
      await tester.ensureVisible(_queue);
      await _press(tester, _queue);
      await _pump(tester);
      expect(find.byType(StudioMailComposeDialog), findsNothing);
      expect(client.sent, isEmpty);
      expect(await awaitOutboxOperation(tester, store.load()), isNull);
      final frozen = (await awaitOutboxOperation(
        tester,
        store.loadOutbox(),
      )).single;
      expect(frozen.state, MailOutboxState.queued);
      expect(frozen.prepared.envelope.recipients, [
        'to@example.test',
        'copy@example.test',
        'hidden@example.test',
      ]);
      final wire = ascii.decode(frozen.prepared.wire.bytes);
      expect(wire, isNot(contains('Bcc:')));
      final parsed = const QudsMimeCodec()
          .parse(frozen.prepared.wire.bytes)
          .message!;
      expect(parsed.attachments.single.content.bytes, attachment);
      expect(parsed.attachments.single.displayName, 'résumé.bin');
      await tester.tap(_openOutbox);
      await _pump(tester);
      await tester.tap(_outboxIcon(_strings.refresh));
      await _pump(tester);
      expect(client.sent, isEmpty);
      await tester.tap(_outboxIcon(_strings.close));
      await _pump(tester);
      await _compose(tester, subject: 'A later independent draft');
      await _press(tester, find.text(_strings.mailDraftSaveClose));
      await _pump(tester);
      expect(
        (await awaitOutboxOperation(tester, store.load()))!.draft.subject,
        'A later independent draft',
      );
      await tester.tap(_openOutbox);
      await _pump(tester);
      expect(client.sent, isEmpty);
      client.onSend = () async =>
          throw StateError('Ambiguous network completion');
      await tester.tap(_action('send', frozen));
      await _pump(tester);
      expect(client.sent, hasLength(1));
      expect(
        (await awaitOutboxOperation(tester, store.loadOutbox())).single.state,
        MailOutboxState.uncertain,
      );
      client.onSend = null;
      await tester.tap(_action('send', frozen));
      await _pump(tester);
      final confirm = find.byKey(const ValueKey('studio-mail-outbox-confirm'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.tap(
        find.byKey(const ValueKey('studio-mail-outbox-acknowledge')),
      );
      await tester.pump();
      await tester.tap(confirm);
      await _pump(tester);
      expect(client.sent, hasLength(2));
      expect(
        client.sent.map((message) => message.renderMessage()),
        everyElement(wire),
      );
      expect(
        client.recipientLists,
        everyElement([
          'to@example.test',
          'copy@example.test',
          'hidden@example.test',
        ]),
      );
      expect(client.senders, everyElement(_sender));
      expect(client.appendRequests, everyElement(isFalse));
      expect(
        (await awaitOutboxOperation(tester, store.loadOutbox())).single.state,
        MailOutboxState.submitted,
      );
      expect(
        (await awaitOutboxOperation(tester, store.load()))!.draft.subject,
        'A later independent draft',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('native Send persists the frozen attempt before invoking SMTP', (
    tester,
  ) async {
    final fixture = await _fixture(tester);
    final client = _Client();
    await _native(tester, fixture, client);
    final store = fixture.adapters.single;
    var observedDurableAttempt = false;
    client.onSend = () async {
      final entry = (await store.loadOutbox()).single;
      expectSync(entry.state, MailOutboxState.submitting);
      expectSync(entry.attemptNumber, 1);
      expectSync(await store.load(), isNull);
      expectSync(
        client.sent.single.renderMessage(),
        ascii.decode(entry.prepared.wire.bytes),
      );
      observedDurableAttempt = true;
    };
    await _compose(tester, subject: 'Immediate durable send');
    await _press(tester, find.widgetWithText(FilledButton, _strings.send));
    await _pump(tester);
    expect(observedDurableAttempt, isTrue);
    expect(client.sent, hasLength(1));
    expect(
      (await awaitOutboxOperation(tester, store.loadOutbox())).single.state,
      MailOutboxState.submitted,
    );
    expect(await awaitOutboxOperation(tester, store.load()), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'queue storage failure retains the editable and saved native draft',
    (tester) async {
      final fixture = await _fixture(tester);
      final client = _Client();
      await _native(tester, fixture, client);
      final store = fixture.adapters.single;
      await _compose(tester, subject: 'Retain on queue failure');
      fixture.failNextCheckpoint = MailStoreCheckpoint.afterOutboxWrite;
      await _press(tester, _queue);
      await _pump(tester);
      expect(find.byType(StudioMailComposeDialog), findsOneWidget);
      expect(find.text(_strings.mailQueueFailed), findsOneWidget);
      expect(client.sent, isEmpty);
      expect(await awaitOutboxOperation(tester, store.loadOutbox()), isEmpty);
      final retained = (await awaitOutboxOperation(
        tester,
        store.load(),
      ))!.draft;
      expect(retained.subject, 'Retain on queue failure');
      expect(retained.bcc, 'hidden@example.test');
      expect(retained.body, contains('Written in the composer.'));
      await _press(tester, _queue);
      await _pump(tester);
      expect(find.byType(StudioMailComposeDialog), findsNothing);
      expect(
        (await awaitOutboxOperation(tester, store.loadOutbox())).single.state,
        MailOutboxState.queued,
      );
      expect(await awaitOutboxOperation(tester, store.load()), isNull);
      expect(client.sent, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS reopens a stable queue and rebinds only its provider account',
    (tester) async {
      final fixture = await _fixture(tester, ews: true);
      final firstProvider = await _ews(tester, fixture);
      final firstStore = fixture.adapters.single;
      await _compose(tester, ews: true, subject: 'Survive Exchange reconnect');
      await _press(tester, _queue);
      await _pump(tester);
      expect(firstProvider.submissions, isEmpty);
      expect(await awaitOutboxOperation(tester, firstStore.load()), isNull);
      final frozen = (await awaitOutboxOperation(
        tester,
        firstStore.loadOutbox(),
      )).single;
      expect(frozen.prepared.account, fixture.identity.account);
      // Since 45f0e503 EWS/Gmail/Graph derive the live account id from the
      // stable account settings, so it may equal the durable identity; the
      // connection is distinguished by its provider instance and session.
      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(tester);
      final secondProvider = await _ews(tester, fixture);
      final secondStore = fixture.adapters.last;
      expect(secondProvider, isNot(same(firstProvider)));
      expect(secondProvider.submissions, isEmpty);
      expect(
        (await awaitOutboxOperation(
          tester,
          secondStore.loadOutbox(),
        )).single.prepared.wire.bytes,
        frozen.prepared.wire.bytes,
      );
      await tester.tap(_openOutbox);
      await _pump(tester);
      expect(find.byType(StudioMailOutboxDialog), findsOneWidget);
      expect(secondProvider.submissions, isEmpty);
      secondProvider.onSubmit = () async {
        expectSync(
          (await secondStore.loadOutbox()).single.state,
          MailOutboxState.submitting,
        );
      };
      await tester.tap(_action('send', frozen));
      await _pump(tester);
      expect(firstProvider.submissions, isEmpty);
      final submitted = secondProvider.submissions.single;
      expect(submitted.account, secondProvider.account);
      expect(submitted.draftId, frozen.prepared.draftId);
      expect(submitted.draftRevision, frozen.prepared.draftRevision);
      expect(submitted.wire.bytes, frozen.prepared.wire.bytes);
      expect(submitted.wireHash, frozen.prepared.wireHash);
      expect(submitted.envelope.sender, frozen.prepared.envelope.sender);
      expect(
        submitted.envelope.recipients,
        frozen.prepared.envelope.recipients,
      );
      expect(
        (await awaitOutboxOperation(
          tester,
          secondStore.loadOutbox(),
        )).single.state,
        MailOutboxState.submitted,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'EWS immediate Send uses the durable attempt and live session identity',
    (tester) async {
      final fixture = await _fixture(tester, ews: true);
      final provider = await _ews(tester, fixture);
      final store = fixture.adapters.single;
      var observedDurableAttempt = false;
      provider.onSubmit = () async {
        final entry = (await store.loadOutbox()).single;
        expectSync(entry.state, MailOutboxState.submitting);
        expectSync(entry.prepared.account, fixture.identity.account);
        expectSync(provider.submissions.single.account, provider.account);
        expectSync(
          provider.submissions.single.wire.bytes,
          entry.prepared.wire.bytes,
        );
        expectSync(await store.load(), isNull);
        observedDurableAttempt = true;
      };
      await _compose(tester, ews: true, subject: 'Immediate Exchange send');
      await _press(tester, find.widgetWithText(FilledButton, _strings.send));
      await _pump(tester);
      expect(observedDurableAttempt, isTrue);
      expect(provider.submissions, hasLength(1));
      expect(
        (await awaitOutboxOperation(tester, store.loadOutbox())).single.state,
        MailOutboxState.submitted,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quds_mail_core/quds_mail_core.dart';
import 'package:quds_mail_mime/quds_mail_mime.dart';
import 'package:quds_mail_transport/quds_mail_transport.dart';
import 'package:quds_office_editor/quds_office_editor.dart';
import 'package:quds_office_studio/studio_mail_cloud.dart';
import 'package:quds_office_studio/studio_mail_compose.dart';
import 'package:quds_office_studio/studio_mail_draft_store.dart';
import 'package:quds_office_studio/studio_mail_outbox_dialog.dart';
import 'package:quds_office_studio/studio_mail_outbox_strings.dart';
import 'package:quds_office_studio/studio_mail_strings.dart';
import 'package:quds_office_studio/studio_strings.dart';

import 'support/mail_outbox_store.dart';
import 'support/mail_local_accounts.dart';

const _strings = StudioStrings(StudioLanguage.en);
const _sender = 'reader@example.test';

StudioMailDraftAccount _identity(MailCloudService service) =>
    StudioMailDraftAccount(
      provider: service == MailCloudService.gmail ? 'gmail' : 'graph',
      endpoint: service == MailCloudService.gmail
          ? 'https://gmail.googleapis.com/gmail/v1'
          : 'https://graph.microsoft.com/v1.0',
      login: service == MailCloudService.gmail
          ? _sender
          : jsonEncode(['common', _sender]),
      sender: _sender,
    );

final class _Tokens extends Fake implements MailCloudTokenSource {
  int disposals = 0;

  @override
  void dispose() => disposals++;
}

final class _Provider extends Fake implements MailCloudProvider {
  _Provider(this.configuration);

  final MailCloudConfiguration configuration;
  final submissions = <MailPreparedMessage>[];
  final attempts = <String>[];
  final leases = <MailOperationLease>[];
  int disposals = 0;
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
  }) async {
    expectSync(mailbox.account, account);
    expectSync(lease.account, account);
    expectSync(lease.isCurrent, isTrue);
    return MailSuccess(MailHeaderPage(messages: const []));
  }

  @override
  Future<MailSubmissionResult> submit(
    MailPreparedMessage message, {
    required String attemptId,
    required MailOperationLease lease,
  }) async {
    expectSync(message.account, account);
    expectSync(lease.account, account);
    expectSync(lease.isCurrent, isTrue);
    submissions.add(message);
    attempts.add(attemptId);
    leases.add(lease);
    await onSubmit?.call();
    return MailSubmissionResult(
      attemptId: attemptId,
      outcome: MailSubmissionOutcome.accepted,
    );
  }

  @override
  void dispose() => disposals++;
}

final class _CloudHarness {
  final providers = <_Provider>[];
  final tokens = <_Tokens>[];

  Future<MailResult<MailCloudTokenSource>> authorize({
    required MailOAuthConfiguration configuration,
    required MailAccountId account,
    required Future<bool> Function(Uri) openBrowser,
    required MailOperationLease lease,
    MailCloudLogSink? log,
  }) async {
    expectSync(lease.account, account);
    expectSync(lease.isCurrent, isTrue);
    expectSync(configuration.tenant, 'common');
    final token = _Tokens();
    tokens.add(token);
    return MailSuccess(token);
  }

  MailCloudProvider create({
    required MailCloudConfiguration configuration,
    required MailCloudTokenSource tokenSource,
    MailCloudLogSink? log,
  }) {
    expectSync(tokenSource, same(tokens.last));
    final provider = _Provider(configuration);
    providers.add(provider);
    return provider;
  }
}

Finder _key(String value) => find.byKey(ValueKey(value));
Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);
Finder get _openOutbox => _key('studio-mail-open-outbox');
Finder get _queue => _key('studio-mail-queue');
Finder _outboxTooltip(String tooltip) => find.descendant(
  of: find.byType(StudioMailOutboxDialog),
  matching: find.byTooltip(tooltip),
);
Finder _sendQueued(MailOutboxEntry entry) =>
    _key('studio-mail-outbox-send-${entry.id}');

Future<void> _press(WidgetTester tester, Finder control) async {
  await tester.ensureVisible(control);
  await pumpOutboxWidgets(tester);
  await tester.tap(control);
  await pumpOutboxWidgets(tester);
}

Future<void> _settleRealIo(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

Future<SqliteOutboxFixture> _fixture(
  WidgetTester tester,
  MailCloudService service,
) async {
  final fixture = await awaitOutboxOperation(
    tester,
    SqliteOutboxFixture.create(_identity(service)),
  );
  addTearDown(() => awaitOutboxOperation(tester, fixture.close()));
  await tester.binding.setSurfaceSize(const Size(1440, 1050));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  return fixture;
}

Future<_Provider> _mountCloud(
  WidgetTester tester,
  SqliteOutboxFixture fixture,
  _CloudHarness harness,
  MailCloudService service, {
  MemoryMailLocalAccounts? localAccounts,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => StudioMailCloudDialog(
                strings: _strings,
                service: service,
                authorizer: harness.authorize,
                providerFactory: harness.create,
                openBrowser: (_) async => true,
                initialClientId: 'controlled-desktop-client',
                draftStoreFactory: fixture.open,
                localAccountStore: localAccounts,
              ),
            ),
            child: const Text('Open cloud outbox fixture'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open cloud outbox fixture'));
  await pumpOutboxWidgets(tester);
  await tester.enterText(_key('cloud-mailbox'), _sender);
  await tester.ensureVisible(_key('cloud-connect'));
  await tester.pump();
  await tester.tap(_key('cloud-connect'));
  await pumpOutboxWidgets(tester);
  expect(_openOutbox, findsOneWidget);
  expect(harness.providers.last.configuration.service, service);
  expect(harness.providers.last.configuration.mailboxAddress, _sender);
  return harness.providers.last;
}

Future<void> _compose(WidgetTester tester, String subject) async {
  await tester.tap(find.byTooltip(_strings.compose));
  await pumpOutboxWidgets(tester);
  await tester.enterText(_field(_strings.to), 'to@example.test');
  await tester.tap(find.text(_strings.mailCopyRecipients));
  await pumpOutboxWidgets(tester);
  await tester.enterText(_field(_strings.mailCc), 'copy@example.test');
  await tester.enterText(_field(_strings.mailBcc), 'hidden@example.test');
  await tester.enterText(_field(_strings.subject), subject);
  tester
      .widget<QudsWordEditor>(find.byType(QudsWordEditor))
      .controller
      .insertText('Cloud body مرحبا <safe> & unchanged.');
  await tester.pump();
}

void _sameFrozenContent(
  MailPreparedMessage actual,
  MailPreparedMessage frozen,
) {
  expectSync(actual.draftId, frozen.draftId);
  expectSync(actual.draftRevision, frozen.draftRevision);
  expectSync(actual.wire.bytes, frozen.wire.bytes);
  expectSync(actual.wireHash, frozen.wireHash);
  expectSync(actual.envelope.sender, frozen.envelope.sender);
  expectSync(actual.envelope.recipients, frozen.envelope.recipients);
}

void main() {
  for (final service in MailCloudService.values) {
    testWidgets(
      '${service.name} registers offline draft identity and opens without another authorization',
      (tester) async {
        final fixture = await _fixture(tester, service);
        final seed = await awaitOutboxOperation(tester, fixture.openLoaded());
        await awaitOutboxOperation(
          tester,
          seed.save(
            const StudioMailDraft(
              to: 'reader@example.test',
              subject: 'Offline cloud draft',
              body: 'Keep cloud work',
            ),
            submissionUncertain: false,
          ),
        );
        await awaitOutboxOperation(tester, seed.close());
        final directory = MemoryMailLocalAccounts();
        final harness = _CloudHarness();
        final provider = await _mountCloud(
          tester,
          fixture,
          harness,
          service,
          localAccounts: directory,
        );
        expect(directory.remembered.single.account, fixture.identity.account);
        await _press(tester, find.byTooltip(_strings.disconnect));
        // Since 4d435f81 disconnect first retires the cached mailbox view's
        // real SQLite session; the directory opens once that release lands.
        await _settleRealIo(tester);
        await _press(tester, _key('studio-mail-known-drafts'));
        await _press(
          tester,
          _key('studio-mail-local-account-${fixture.identity.account.value}'),
        );
        await _press(tester, find.text('Offline cloud draft'));
        final composer = tester.widget<StudioMailComposeDialog>(
          find.byType(StudioMailComposeDialog),
        );
        expect(composer.canSend, isFalse);
        expect(composer.onQueueDraft, isNull);
        expect(harness.tokens, hasLength(1));
        expect(harness.providers, hasLength(1));
        expect(provider.submissions, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final service in [
    MailCloudService.gmail,
    MailCloudService.microsoft365,
  ]) {
    testWidgets(
      '${service.name} edits a queued copy without sending or replacing sibling drafts',
      (tester) async {
        final fixture = await _fixture(tester, service);
        final seed = await awaitOutboxOperation(tester, fixture.openLoaded());
        const sibling = StudioMailDraft(
          to: 'sibling@example.test',
          bcc: 'sibling-hidden@example.test',
          subject: 'Keep this cloud draft',
          body: 'Unfinished sibling body.',
        );
        await awaitOutboxOperation(
          tester,
          seed.save(sibling, submissionUncertain: true),
        );
        final original = StudioMailDraft(
          to: 'queued@example.test',
          cc: 'queued-copy@example.test',
          bcc: 'queued-hidden@example.test',
          subject: '${service.name} original frozen message',
          body: 'Frozen cloud body مرحبا <safe> & unchanged.',
          attachments: StudioMailAttachments.from([
            StudioMailAttachment(
              name: 'cloud.bin',
              bytes: Uint8List.fromList([0, 10, 128, 255]),
            ),
          ]),
        );
        await awaitOutboxOperation(tester, seed.createDraft(original));
        final frozen = await awaitOutboxOperation(
          tester,
          seed.enqueueOutbox(original, _sender),
        );
        await awaitOutboxOperation(tester, seed.close());
        final harness = _CloudHarness();
        final provider = await _mountCloud(tester, fixture, harness, service);
        final store = fixture.adapters.last;
        final originalEpoch = store.selectionEpoch;
        expect(store.selectedDraftId, SqliteStudioMailDraftStore.draftId);
        await _press(tester, _openOutbox);
        await _press(tester, _key('studio-mail-outbox-edit-${frozen.id}'));
        expect(find.text(_strings.mailOutboxEditExplanation), findsOneWidget);
        await _press(tester, _key('studio-mail-outbox-confirm'));
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
        expect(store.selectionEpoch, greaterThan(originalEpoch));
        final editedId = store.selectedDraftId;
        expect(editedId, isNot(SqliteStudioMailDraftStore.draftId));
        expect(editedId, isNot(frozen.prepared.draftId));
        final retired = (await awaitOutboxOperation(
          tester,
          store.loadOutbox(),
        )).single;
        expect(retired.state, MailOutboxState.cancelled);
        expect(retired.prepared.wire.bytes, frozen.prepared.wire.bytes);
        expect(provider.submissions, isEmpty);
        final page = await awaitOutboxOperation(tester, store.listDrafts());
        expect(page.drafts, hasLength(2));
        final kept = page.drafts.singleWhere(
          (entry) => entry.id == SqliteStudioMailDraftStore.draftId,
        );
        expect(kept.subject, sibling.subject);
        expect(kept.submissionUncertain, isTrue);
        await tester.enterText(
          _field(_strings.subject),
          '${service.name} explicitly edited',
        );
        await _press(tester, _queue);
        expect(find.byType(StudioMailComposeDialog), findsNothing);
        final entries = await awaitOutboxOperation(tester, store.loadOutbox());
        expect(entries, hasLength(2));
        final edited = entries.singleWhere((entry) => entry.id != frozen.id);
        expect(edited.state, MailOutboxState.queued);
        expect(edited.attemptNumber, 0);
        expect(edited.prepared.draftId, editedId);
        expect(edited.prepared.wireHash, isNot(frozen.prepared.wireHash));
        final beforeMessage = const QudsMimeCodec()
            .parse(frozen.prepared.wire.bytes)
            .message!;
        final afterMessage = const QudsMimeCodec()
            .parse(edited.prepared.wire.bytes)
            .message!;
        expect(afterMessage.envelope.messageId, isNotNull);
        expect(
          afterMessage.envelope.messageId,
          isNot(beforeMessage.envelope.messageId),
        );
        expect(
          afterMessage.envelope.subject,
          '${service.name} explicitly edited',
        );
        expect(
          afterMessage.attachments.single.content.bytes,
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
        expect(provider.submissions, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpOutboxWidgets(tester);
      },
    );

    testWidgets(
      '${service.name} queued message survives reconnect and sends only explicitly',
      (tester) async {
        final fixture = await _fixture(tester, service);
        final harness = _CloudHarness();
        final firstProvider = await _mountCloud(
          tester,
          fixture,
          harness,
          service,
        );
        final firstStore = fixture.adapters.single;
        expect(firstStore.account, _identity(service).account);
        await _compose(tester, '${service.name} frozen before reconnect');
        await tester.ensureVisible(_queue);
        await tester.pump();
        await tester.tap(_queue);
        await pumpOutboxWidgets(tester);
        expect(find.byType(StudioMailComposeDialog), findsNothing);
        expect(firstProvider.submissions, isEmpty);
        expect(await awaitOutboxOperation(tester, firstStore.load()), isNull);
        final frozen = (await awaitOutboxOperation(
          tester,
          firstStore.loadOutbox(),
        )).single;
        expect(frozen.state, MailOutboxState.queued);
        expect(frozen.prepared.account, fixture.identity.account);
        // Since 45f0e503 EWS/Gmail/Graph derive the live account id from the
        // stable account settings, so it may equal the durable identity; the
        // connection is distinguished by its provider instance and session.
        expect(frozen.prepared.envelope.sender, _sender);
        expect(frozen.prepared.envelope.recipients, [
          'to@example.test',
          'copy@example.test',
          'hidden@example.test',
        ]);
        expect(
          ascii.decode(frozen.prepared.wire.bytes),
          isNot(contains('hidden@example.test')),
        );

        await tester.tap(_openOutbox);
        await pumpOutboxWidgets(tester);
        expect(find.byType(StudioMailOutboxDialog), findsOneWidget);
        await tester.tap(_outboxTooltip(_strings.refresh));
        await pumpOutboxWidgets(tester);
        expect(firstProvider.submissions, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpOutboxWidgets(tester);
        expect(firstProvider.disposals, 1);
        expect(harness.tokens.first.disposals, 1);

        final secondProvider = await _mountCloud(
          tester,
          fixture,
          harness,
          service,
        );
        final secondStore = fixture.adapters.last;
        expect(secondStore.account, fixture.identity.account);
        expect(secondProvider, isNot(same(firstProvider)));
        expect(secondProvider.submissions, isEmpty);
        final reopened = (await awaitOutboxOperation(
          tester,
          secondStore.loadOutbox(),
        )).single;
        expect(reopened.id, frozen.id);
        expect(reopened.prepared.account, fixture.identity.account);
        _sameFrozenContent(reopened.prepared, frozen.prepared);
        await tester.tap(_openOutbox);
        await pumpOutboxWidgets(tester);
        expect(secondProvider.submissions, isEmpty);
        await tester.tap(_outboxTooltip(_strings.close));
        await pumpOutboxWidgets(tester);
        await tester.tap(_openOutbox);
        await pumpOutboxWidgets(tester);
        expect(secondProvider.submissions, isEmpty);

        var durableBeforeProvider = false;
        secondProvider.onSubmit = () async {
          final attempt = (await secondStore.loadOutbox()).single;
          expectSync(attempt.state, MailOutboxState.submitting);
          expectSync(attempt.attemptId, secondProvider.attempts.single);
          expectSync(attempt.prepared.account, fixture.identity.account);
          _sameFrozenContent(attempt.prepared, frozen.prepared);
          durableBeforeProvider = true;
        };
        await tester.tap(_sendQueued(frozen));
        await pumpOutboxWidgets(tester);
        expect(durableBeforeProvider, isTrue);
        expect(firstProvider.submissions, isEmpty);
        final submitted = secondProvider.submissions.single;
        expect(submitted.account, secondProvider.account);
        _sameFrozenContent(submitted, frozen.prepared);
        final committed = (await awaitOutboxOperation(
          tester,
          secondStore.loadOutbox(),
        )).single;
        expect(committed.state, MailOutboxState.submitted);
        expect(committed.prepared.account, fixture.identity.account);
        expect(committed.attemptId, secondProvider.attempts.single);
        await tester.tap(_outboxTooltip(_strings.close));
        await pumpOutboxWidgets(tester);
        await tester.tap(_openOutbox);
        await pumpOutboxWidgets(tester);
        expect(secondProvider.submissions, hasLength(1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpOutboxWidgets(tester);
      },
    );

    testWidgets(
      '${service.name} immediate Send persists before invoking the live provider',
      (tester) async {
        final fixture = await _fixture(tester, service);
        final harness = _CloudHarness();
        final provider = await _mountCloud(tester, fixture, harness, service);
        final store = fixture.adapters.single;
        var durableBeforeProvider = false;
        provider.onSubmit = () async {
          final attempt = (await store.loadOutbox()).single;
          expectSync(attempt.state, MailOutboxState.submitting);
          expectSync(attempt.attemptNumber, 1);
          expectSync(attempt.attemptId, provider.attempts.single);
          expectSync(attempt.prepared.account, fixture.identity.account);
          final submitted = provider.submissions.single;
          expectSync(submitted.account, provider.account);
          _sameFrozenContent(submitted, attempt.prepared);
          expectSync(await store.load(), isNull);
          durableBeforeProvider = true;
        };
        await _compose(tester, '${service.name} immediate durable send');
        final send = find.widgetWithText(FilledButton, _strings.send);
        await tester.ensureVisible(send);
        await tester.pump();
        await tester.tap(send);
        await pumpOutboxWidgets(tester);
        expect(durableBeforeProvider, isTrue);
        expect(find.byType(StudioMailComposeDialog), findsNothing);
        expect(provider.submissions, hasLength(1));
        final committed = (await awaitOutboxOperation(
          tester,
          store.loadOutbox(),
        )).single;
        expect(committed.state, MailOutboxState.submitted);
        expect(committed.prepared.account, fixture.identity.account);
        expect(committed.prepared.envelope.recipients, [
          'to@example.test',
          'copy@example.test',
          'hidden@example.test',
        ]);
        expect(await awaitOutboxOperation(tester, store.load()), isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpOutboxWidgets(tester);
      },
    );
  }
}

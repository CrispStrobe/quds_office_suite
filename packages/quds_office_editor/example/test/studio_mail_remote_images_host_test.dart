import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:enough_mail/enough_mail.dart' as mail;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:quds_mail_core/quds_mail_core.dart';
import 'package:quds_mail_ui/quds_mail_ui.dart';
import 'package:quds_office_studio/studio_mail_credentials.dart';
import 'package:quds_office_studio/studio_mail_message_loader.dart';
import 'package:quds_office_studio/studio_mail_native.dart';
import 'package:quds_office_studio/studio_mail_remote_images.dart';
import 'package:quds_office_studio/studio_strings.dart';

import 'support/mail_draft_store.dart';

const _strings = StudioStrings(StudioLanguage.en);
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGMwaDjwHwAExAJwNooHGQAAAABJRU5ErkJggg==',
);

final class _Incoming extends mail.ImapClient {
  @override
  Future<void> abort() async {}
}

final class _Outgoing extends mail.SmtpClient {
  _Outgoing() : super('fixture.invalid');
  @override
  Future<void> abort() async {}
}

final class _MailClient extends Fake implements mail.MailClient {
  final _incoming = _Incoming();
  final _outgoing = _Outgoing();
  mail.Mailbox? _selected;
  @override
  mail.Mailbox? get selectedMailbox => _selected;
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
  Future<List<mail.Mailbox>> listMailboxes({
    List<mail.MailboxFlag>? order,
  }) async => [
    mail.Mailbox(
      encodedName: 'Inbox',
      encodedPath: 'Inbox',
      pathSeparator: '/',
      flags: [mail.MailboxFlag.inbox],
    )..uidValidity = 91,
  ];
  @override
  Future<mail.Mailbox> selectMailbox(
    mail.Mailbox mailbox, {
    bool enableCondStore = false,
    mail.QResyncParameters? qresync,
  }) async => _selected = mailbox;
}

final class _Browser
    implements StudioMailMessageLoader, StudioMailMailboxBrowser {
  @override
  Future<StudioMailHeaderPage> fetchHeaders(
    mail.Mailbox mailbox, {
    MailCursor? cursor,
    int limit = 50,
  }) async => StudioMailHeaderPage(
    messages: [
      for (var uid = 1; uid <= 2; uid++)
        mail.MimeMessage.fromEnvelope(
          mail.Envelope(
            subject: 'Message $uid',
            from: [mail.MailAddress('Writer', 'writer@example.test')],
          ),
          uid: uid,
          flags: [mail.MessageFlags.seen],
        ),
    ],
  );
  @override
  Future<Uint8List> fetch(
    mail.Mailbox mailbox,
    mail.MimeMessage header,
  ) async => Uint8List.fromList(
    utf8.encode(
      'From: writer@example.test\r\nSubject: Message ${header.uid}\r\n'
      'Content-Type: multipart/alternative; boundary=fixture\r\n\r\n'
      '--fixture\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nPlain message.\r\n'
      '--fixture\r\nContent-Type: text/html; charset=utf-8\r\n\r\n'
      '<p>Message ${header.uid}</p><img src="https://images.invalid/${header.uid}">'
      '<script src="https://active.invalid/script"></script>\r\n--fixture--\r\n',
    ),
  );
  @override
  Future<void> markRead(mail.Mailbox mailbox, mail.MimeMessage header) async {}
  @override
  void cancel() {}
  @override
  void dispose() {}
}

final class _Credentials extends Fake implements StudioMailCredentialStore {
  @override
  Future<StudioMailCredentials?> load() async => null;
  @override
  Future<bool> save(StudioMailCredentials credentials) async => true;
  @override
  Future<bool> clear() async => true;
}

final class _ImageClient extends http.BaseClient {
  final pending = Completer<http.StreamedResponse>();
  final requests = <http.BaseRequest>[];
  bool closed = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    return pending.future;
  }

  @override
  void close() => closed = true;
  void complete() => pending.complete(
    http.StreamedResponse(
      Stream.value(_png),
      200,
      headers: {'content-type': 'image/png'},
    ),
  );
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);
final _images = find.byKey(const ValueKey('studio-mail-show-images'));
Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

void main() {
  testWidgets(
    'retired image loads cannot block or finish a newer reader action',
    (tester) async {
      final clients = <_ImageClient>[];
      final mailClient = _MailClient();
      final browser = _Browser();
      final drafts = MemoryStudioMailDrafts();
      tester.view
        ..physicalSize = const Size(1400, 1000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: StudioMailDialog(
            strings: _strings,
            credentialStore: _Credentials(),
            clientFactory: (_) => mailClient,
            messageLoaderFactory: (_) => browser,
            draftStoreFactory: drafts.open,
            remoteImageLoaderFactory: () => StudioMailRemoteImageLoader(
              clientFactory: () {
                final client = _ImageClient();
                clients.add(client);
                return client;
              },
            ),
          ),
        ),
      );
      await _pump(tester);
      await tester.enterText(
        _field(_strings.emailAddress),
        'reader@example.test',
      );
      await tester.enterText(_field(_strings.password), 'fixture-password');
      await tester.tap(
        find.widgetWithText(SwitchListTile, _strings.manualServers),
      );
      await tester.pump();
      await tester.enterText(_field(_strings.imapHost), 'imap.example.test');
      await tester.enterText(_field(_strings.smtpHost), 'smtp.example.test');
      await tester.ensureVisible(find.text(_strings.connect));
      await tester.tap(find.text(_strings.connect));
      await _pump(tester);
      tester
          .widget<MailMessageList>(find.byType(MailMessageList))
          .onOpen('imap-message-91:1');
      await _pump(tester);
      expect(clients, isEmpty);
      final firstReader = tester
          .widget<MailMessageView>(find.byType(MailMessageView))
          .controller;
      firstReader.setPreferHtml(false);
      await _pump(tester);
      expect(tester.widget<IconButton>(_images).onPressed, isNull);
      firstReader.setPreferHtml(true);
      await _pump(tester);
      expect(tester.widget<IconButton>(_images).onPressed, isNotNull);
      await tester.tap(_images);
      await _pump(tester);
      expect(clients, hasLength(1));
      expect(
        clients.first.requests.single.url.toString(),
        'https://images.invalid/1',
      );

      tester
          .widget<MailMessageList>(find.byType(MailMessageList))
          .onOpen('imap-message-91:2');
      await _pump(tester);
      expect(clients.first.closed, isTrue);
      // Since ca5be882 every new reader opens in plain text; switch this one
      // to HTML as the first reader was, so its remote images can be offered.
      final secondReader = tester
          .widget<MailMessageView>(find.byType(MailMessageView))
          .controller;
      expect(secondReader, isNot(same(firstReader)));
      secondReader.setPreferHtml(true);
      await _pump(tester);
      expect(tester.widget<IconButton>(_images).onPressed, isNotNull);
      await tester.tap(_images);
      await _pump(tester);
      expect(clients, hasLength(2));
      clients.first.complete();
      await _pump(tester);
      expect(tester.widget<IconButton>(_images).onPressed, isNull);
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: _images, matching: find.byType(Icon)),
            )
            .icon,
        Icons.hourglass_top,
      );
      final reader = tester
          .widget<MailMessageView>(find.byType(MailMessageView))
          .controller;
      expect(reader.presentation.images, isEmpty);
      clients.last.complete();
      await _pump(tester);
      expect(
        reader.presentation.images.single.attachment.partPath,
        'remote:https://images.invalid/2',
      );
      expect(reader.presentation.blockedResourceCount, greaterThan(0));
      expect(clients.expand((client) => client.requests), hasLength(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(tester);
    },
  );
}

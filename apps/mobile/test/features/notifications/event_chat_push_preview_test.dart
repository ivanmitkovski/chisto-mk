import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_notifications/src/data/event_chat_push_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localizedForMessageType returns voice label for AUDIO', () {
    expect(
      EventChatPushPreview.localizedForMessageType('AUDIO', null),
      'Voice message',
    );
  });

  test('localizedForMessageType uses Macedonian labels', () {
    final AppLocalizations mk = lookupAppLocalizations(const Locale('mk'));
    expect(
      EventChatPushPreview.localizedForMessageType('AUDIO', mk),
      mk.eventChatPushPreviewVoice,
    );
    expect(
      EventChatPushPreview.localizedForMessageType('IMAGE', mk),
      mk.eventChatPushPreviewPhoto,
    );
  });

  test('localizedForMessageType uses English labels', () {
    final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
    expect(
      EventChatPushPreview.localizedForMessageType('AUDIO', en),
      en.eventChatPushPreviewVoice,
    );
  });

  test('resolveMessageBody uses messagePreview first', () {
    expect(
      EventChatPushPreview.resolveMessageBody(<String, dynamic>{
        'messagePreview': 'Hi',
        'messageType': 'TEXT',
      }),
      'Hi',
    );
  });

  test('resolveNotificationBody strips empty sender suffix', () {
    final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
    expect(
      EventChatPushPreview.resolveNotificationBody(<String, dynamic>{
        'type': 'EVENT_CHAT',
        'messageType': 'AUDIO',
        'senderName': 'Alex',
        'body': 'Alex: ',
      }, strings: en),
      'Alex: ${en.eventChatPushPreviewVoice}',
    );
  });
}

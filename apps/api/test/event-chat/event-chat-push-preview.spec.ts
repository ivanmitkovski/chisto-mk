/// <reference types="jest" />
import { EventChatMessageType } from '../../src/prisma-client';
import { buildEventChatPushPreview } from '../../src/event-chat/event-chat-push-preview';

describe('buildEventChatPushPreview', () => {
  const base = {
    messageType: EventChatMessageType.TEXT,
    locationLabel: null,
    attachments: [],
    body: '',
  };

  it('returns plaintext body when present', () => {
    expect(
      buildEventChatPushPreview(
        { ...base, messageType: EventChatMessageType.TEXT },
        '  hello  ',
      ),
    ).toBe('hello');
  });

  it('returns Voice message for AUDIO without body', () => {
    expect(
      buildEventChatPushPreview(
        { ...base, messageType: EventChatMessageType.AUDIO },
        '',
      ),
    ).toBe('Voice message');
  });

  it('returns Photo for IMAGE', () => {
    expect(
      buildEventChatPushPreview(
        { ...base, messageType: EventChatMessageType.IMAGE },
        '',
      ),
    ).toBe('Photo');
  });

  it('returns Video for VIDEO', () => {
    expect(
      buildEventChatPushPreview(
        { ...base, messageType: EventChatMessageType.VIDEO },
        '',
      ),
    ).toBe('Video');
  });

  it('returns file name for FILE when available', () => {
    expect(
      buildEventChatPushPreview(
        {
          ...base,
          messageType: EventChatMessageType.FILE,
          attachments: [{ fileName: 'report.pdf' } as never],
        },
        '',
      ),
    ).toBe('report.pdf');
  });

  it('returns location label for LOCATION', () => {
    expect(
      buildEventChatPushPreview(
        {
          ...base,
          messageType: EventChatMessageType.LOCATION,
          locationLabel: 'City Park',
        },
        '',
      ),
    ).toBe('City Park');
  });
});

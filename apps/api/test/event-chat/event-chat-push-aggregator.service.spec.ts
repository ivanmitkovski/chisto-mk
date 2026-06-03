import { EventChatMessageType, NotificationType } from '../../src/prisma-client';
import { NotificationDispatcherService } from '../../src/notifications/services/notification-dispatcher.service';
import { EventChatPushAggregatorService } from '../../src/event-chat/services/event-chat-push-aggregator.service';

describe('EventChatPushAggregatorService', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('flushes a single message after the coalesce window', async () => {
    const dispatchToUser = jest.fn().mockResolvedValue(undefined);
    const dispatcher = { dispatchToUser } as unknown as NotificationDispatcherService;
    const aggregator = new EventChatPushAggregatorService(
      { get: jest.fn().mockReturnValue('100') } as never,
      dispatcher,
    );

    aggregator.enqueue({
      recipientUserId: 'u2',
      eventId: 'evt1',
      eventTitle: 'Beach cleanup',
      senderDisplayName: 'Alex',
      senderUserId: 'sender-1',
      messagePreview: 'Hey',
      messageId: 'm1',
      messageType: EventChatMessageType.TEXT,
    });

    expect(dispatchToUser).not.toHaveBeenCalled();
    await jest.runAllTimersAsync();
    expect(dispatchToUser).toHaveBeenCalledTimes(1);
    expect(dispatchToUser).toHaveBeenCalledWith(
      'u2',
      expect.objectContaining({
        type: NotificationType.EVENT_CHAT,
        body: 'Alex: Hey',
        data: expect.objectContaining({ messageCount: 1, eventId: 'evt1' }),
      }),
    );
  });

  it('coalesces a burst into one push with messageCount', async () => {
    const dispatchToUser = jest.fn().mockResolvedValue(undefined);
    const dispatcher = { dispatchToUser } as unknown as NotificationDispatcherService;
    const aggregator = new EventChatPushAggregatorService(
      { get: jest.fn().mockReturnValue('100') } as never,
      dispatcher,
    );

    aggregator.enqueue({
      recipientUserId: 'u2',
      eventId: 'evt1',
      eventTitle: 'Beach cleanup',
      senderDisplayName: 'Alex',
      senderUserId: 'sender-1',
      messagePreview: 'One',
      messageId: 'm1',
      messageType: EventChatMessageType.TEXT,
    });
    aggregator.enqueue({
      recipientUserId: 'u2',
      eventId: 'evt1',
      eventTitle: 'Beach cleanup',
      senderDisplayName: 'Alex',
      senderUserId: 'sender-1',
      messagePreview: 'Two',
      messageId: 'm2',
      messageType: EventChatMessageType.TEXT,
    });
    aggregator.enqueue({
      recipientUserId: 'u2',
      eventId: 'evt1',
      eventTitle: 'Beach cleanup',
      senderDisplayName: 'Alex',
      senderUserId: 'sender-1',
      messagePreview: 'Three',
      messageId: 'm3',
      messageType: EventChatMessageType.TEXT,
    });

    await jest.runAllTimersAsync();
    expect(dispatchToUser).toHaveBeenCalledTimes(1);
    expect(dispatchToUser).toHaveBeenCalledWith(
      'u2',
      expect.objectContaining({
        body: 'Alex: Three (+2)',
        data: expect.objectContaining({ messageCount: 3, messageId: 'm3' }),
      }),
    );
  });
});

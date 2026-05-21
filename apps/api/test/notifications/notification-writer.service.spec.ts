import { NotificationType } from '../../src/prisma-client';
import { PrismaService } from '../../src/prisma/prisma.service';
import { FeatureFlagsService } from '../../src/feature-flags/feature-flags.service';
import { NotificationPreferencesService } from '../../src/notifications/notification-preferences.service';
import { NotificationWriterService } from '../../src/notifications/notification-writer.service';

describe('NotificationWriterService', () => {
  const userId = 'user-1';
  const groupKey = 'event-chat:evt-1';

  let prisma: {
    userNotification: {
      findFirst: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
    };
  };
  let writer: NotificationWriterService;

  beforeEach(() => {
    prisma = {
      userNotification: {
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
    };
    const featureFlags = {
      isNotificationsInboxEnabled: jest.fn().mockResolvedValue(true),
    };
    const preferences = {
      isTypeMuted: jest.fn().mockResolvedValue(false),
    };
    writer = new NotificationWriterService(
      prisma as unknown as PrismaService,
      featureFlags as unknown as FeatureFlagsService,
      preferences as unknown as NotificationPreferencesService,
    );
  });

  it('upserts unread EVENT_CHAT rows by groupKey', async () => {
    prisma.userNotification.findFirst.mockResolvedValue({
      id: 'n-existing',
      data: { messageCount: 1, eventId: 'evt-1' },
    });
    prisma.userNotification.update.mockResolvedValue({ id: 'n-existing' });

    const result = await writer.createNotification({
      userId,
      title: 'Event',
      body: 'Alex: second',
      type: NotificationType.EVENT_CHAT,
      threadKey: `${groupKey}:msg-2`,
      groupKey,
      data: {
        messageCount: 1,
        messageId: 'msg-2',
        eventId: 'evt-1',
        actorUserId: 'sender-1',
      },
    });

    expect(result).toEqual({ id: 'n-existing', updated: true });
    expect(prisma.userNotification.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'n-existing' },
        data: expect.objectContaining({
          body: 'Alex: second',
          data: expect.objectContaining({ messageCount: 2 }),
        }),
      }),
    );
    expect(prisma.userNotification.create).not.toHaveBeenCalled();
  });

  it('creates a new EVENT_CHAT row when no unread group exists', async () => {
    prisma.userNotification.findFirst.mockResolvedValue(null);
    prisma.userNotification.create.mockResolvedValue({ id: 'n-new' });

    const result = await writer.createNotification({
      userId,
      title: 'Event',
      body: 'Alex: hi',
      type: NotificationType.EVENT_CHAT,
      threadKey: `${groupKey}:msg-1`,
      groupKey,
      data: { messageCount: 1, messageId: 'msg-1', eventId: 'evt-1' },
    });

    expect(result).toEqual({ id: 'n-new', updated: false });
    expect(prisma.userNotification.create).toHaveBeenCalled();
    expect(prisma.userNotification.update).not.toHaveBeenCalled();
  });

  it('creates a new EVENT_CHAT row after the previous group was read', async () => {
    prisma.userNotification.findFirst.mockResolvedValue(null);
    prisma.userNotification.create.mockResolvedValue({ id: 'n-new-2' });

    const result = await writer.createNotification({
      userId,
      title: 'Event',
      body: 'Alex: again',
      type: NotificationType.EVENT_CHAT,
      threadKey: `${groupKey}:msg-9`,
      groupKey,
      data: { messageId: 'msg-9', eventId: 'evt-1' },
    });

    expect(result).toEqual({ id: 'n-new-2', updated: false });
    expect(prisma.userNotification.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ isRead: false, groupKey }),
      }),
    );
  });

  it('dedupes duplicate threadKey within the window for non-chat types', async () => {
    prisma.userNotification.findFirst.mockResolvedValue({ id: 'n-existing' });

    const result = await writer.createNotification({
      userId,
      title: 'Site',
      body: 'Update',
      type: NotificationType.UPVOTE,
      threadKey: 'UPVOTE:site:s1',
      data: { siteId: 's1' },
    });

    expect(result).toBeNull();
    expect(prisma.userNotification.create).not.toHaveBeenCalled();
  });
});

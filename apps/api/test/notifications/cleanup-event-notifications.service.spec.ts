/// <reference types="jest" />

import { NotificationType } from '../../src/prisma-client';
import { CleanupEventNotificationsService } from '../../src/notifications/services/cleanup-event-notifications.service';

describe('CleanupEventNotificationsService', () => {
  let prisma: {
    user: { findMany: jest.Mock };
    userDeviceToken: { findMany: jest.Mock };
    cleanupEvent: { findUnique: jest.Mock };
  };
  let dispatcher: { dispatchToUser: jest.Mock };
  let moderationEmailNotifier: { notify: jest.Mock };
  let service: CleanupEventNotificationsService;

  beforeEach(() => {
    prisma = {
      user: {
        findMany: jest.fn().mockResolvedValue([{ id: 's1' }, { id: 's2' }]),
      },
      userDeviceToken: { findMany: jest.fn().mockResolvedValue([]) },
      cleanupEvent: {
        findUnique: jest.fn().mockResolvedValue({
          scheduledAt: new Date('2026-06-10T09:00:00.000Z'),
          endAt: new Date('2026-06-10T12:00:00.000Z'),
          category: 'GENERAL_CLEANUP',
          scale: 'MEDIUM',
          organizer: { firstName: 'Ivan', lastName: 'M' },
          site: { address: 'Park' },
        }),
      },
    };
    dispatcher = {
      dispatchToUser: jest.fn().mockResolvedValue(undefined),
    };
    moderationEmailNotifier = { notify: jest.fn() };
    service = new CleanupEventNotificationsService(
      prisma as never,
      dispatcher as never,
      moderationEmailNotifier as never,
    );
  });

  it('notifyStaffPendingReview queries staff with take 200 and dispatches per user', async () => {
    await service.notifyStaffPendingReview({
      eventId: 'e1',
      siteId: 'site-1',
      title: 'River cleanup',
    });

    expect(prisma.user.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        take: 200,
      }),
    );
    expect(dispatcher.dispatchToUser).toHaveBeenCalledTimes(2);
    expect(dispatcher.dispatchToUser).toHaveBeenCalledWith(
      's1',
      expect.objectContaining({
        type: NotificationType.CLEANUP_EVENT,
        data: expect.objectContaining({ kind: 'pending_review', eventId: 'e1' }),
      }),
    );
  });
});

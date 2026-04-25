/// <reference types="jest" />

import { NotificationType } from '../../src/prisma-client';
import { CleanupEventNotificationsService } from '../../src/notifications/cleanup-event-notifications.service';

describe('CleanupEventNotificationsService', () => {
  let prisma: { user: { findMany: jest.Mock } };
  let dispatcher: { dispatchToUser: jest.Mock };
  let service: CleanupEventNotificationsService;

  beforeEach(() => {
    prisma = {
      user: {
        findMany: jest.fn().mockResolvedValue([{ id: 's1' }, { id: 's2' }]),
      },
    };
    dispatcher = {
      dispatchToUser: jest.fn().mockResolvedValue(undefined),
    };
    service = new CleanupEventNotificationsService(prisma as never, dispatcher as never);
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

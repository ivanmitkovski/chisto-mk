/// <reference types="jest" />

import { NotificationType } from '../../src/prisma-client';
import { EmailDeliveryOutboxService } from '../../src/email/email-delivery-outbox.service';

describe('EmailDeliveryOutboxService.enqueue', () => {
  const importantEvent = {
    type: NotificationType.CLEANUP_EVENT,
    title: 'Done',
    body: 'Points awarded',
    data: { pointsAwarded: 50, eventId: 'e1', eventTitle: 'Park day' },
  };

  const nonImportantEvent = {
    type: NotificationType.SYSTEM,
    title: 'Report received',
    body: 'Thanks',
    data: { kind: 'report_received', reportNumber: '#1', reportId: 'r1', siteId: 's1' },
  };

  function createService() {
    const prisma = {
      emailOutbox: {
        create: jest.fn().mockResolvedValue({ id: 'outbox-1' }),
      },
    };
    const emailService = {} as never;
    const service = new EmailDeliveryOutboxService(prisma as never, emailService);
    return { service, prisma };
  }

  it('creates an outbox row for important notification events', async () => {
    const { service, prisma } = createService();

    await service.enqueue('user-1', 'notif-1', importantEvent);

    expect(prisma.emailOutbox.create).toHaveBeenCalledTimes(1);
    expect(prisma.emailOutbox.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: 'user-1',
          templateId: 'event_completed_award',
          idempotencyKey: 'notif-1:email',
        }),
      }),
    );
  });

  it('skips outbox creation for non-important notification events', async () => {
    const { service, prisma } = createService();

    await service.enqueue('user-1', 'notif-2', nonImportantEvent);

    expect(prisma.emailOutbox.create).not.toHaveBeenCalled();
  });
});

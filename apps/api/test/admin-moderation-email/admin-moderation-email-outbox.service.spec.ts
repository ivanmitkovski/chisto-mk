/// <reference types="jest" />

import { Prisma } from '../../src/prisma-client';
import { AdminModerationCategory } from '../../src/prisma-client';
import { AdminModerationEmailOutboxService } from '../../src/admin-moderation-email/services/admin-moderation-email-outbox.service';

describe('AdminModerationEmailOutboxService.enqueueMany', () => {
  it('inserts rows with idempotency keys and skips duplicates', async () => {
    const create = jest
      .fn()
      .mockResolvedValueOnce({ id: '1' })
      .mockRejectedValueOnce(
        new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
          code: 'P2002',
          clientVersion: 'test',
        }),
      );
    const prisma = { adminEmailOutbox: { create } };
    const service = new AdminModerationEmailOutboxService(
      prisma as never,
      {} as never,
      {} as never,
      {} as never,
    );

    const inserted = await service.enqueueMany([
      {
        recipientUserId: 'u1',
        recipientEmail: 'a@b.c',
        category: AdminModerationCategory.NEW_REPORT,
        resourceId: 'r1',
        payload: { firstName: 'A', deepLinkPath: '/x', emailContext: {} },
      },
      {
        recipientUserId: 'u1',
        recipientEmail: 'a@b.c',
        category: AdminModerationCategory.NEW_REPORT,
        resourceId: 'r1',
        payload: { firstName: 'A', deepLinkPath: '/x', emailContext: {} },
      },
    ]);

    expect(inserted).toBe(1);
    expect(create).toHaveBeenCalledTimes(2);
    expect(create.mock.calls[0][0].data.idempotencyKey).toBe('NEW_REPORT:r1:u1');
  });
});

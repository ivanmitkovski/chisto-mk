/// <reference types="jest" />
import { NotFoundException } from '@nestjs/common';
import { UgcSubjectVisibilityService } from '../../src/moderation/services/ugc-subject-visibility.service';

describe('UgcSubjectVisibilityService', () => {
  const siteId = 'site-1';

  function makeService(prisma: unknown) {
    return new UgcSubjectVisibilityService(prisma as never);
  }

  it('site_comment hide cascades subtree and reconciles the counter', async () => {
    const prisma = {
      siteComment: {
        findUnique: jest.fn().mockResolvedValue({ id: 'root', siteId }),
        findMany: jest
          .fn()
          .mockResolvedValueOnce([{ id: 'child' }])
          .mockResolvedValueOnce([]),
        updateMany: jest.fn().mockResolvedValue({ count: 2 }),
        count: jest.fn().mockResolvedValue(0),
      },
      site: {
        update: jest.fn().mockResolvedValue({}),
      },
    };
    const svc = makeService(prisma);

    await svc.applySubjectVisibility('site_comment', 'root', true);

    expect(prisma.siteComment.updateMany).toHaveBeenCalledWith({
      where: { id: { in: ['root', 'child'] }, siteId },
      data: { isDeleted: true },
    });
    expect(prisma.site.update).toHaveBeenCalledWith({
      where: { id: siteId },
      data: { commentsCount: 0 },
    });
  });

  it('site_comment hide throws when comment is missing', async () => {
    const prisma = {
      siteComment: {
        findUnique: jest.fn().mockResolvedValue(null),
      },
    };
    const svc = makeService(prisma);

    await expect(
      svc.applySubjectVisibility('site_comment', 'missing', true),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('event_chat_message hide sets deletedAt', async () => {
    const prisma = {
      eventChatMessage: {
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
    };
    const svc = makeService(prisma);

    await svc.applySubjectVisibility('event_chat_message', 'msg-1', true);

    expect(prisma.eventChatMessage.updateMany).toHaveBeenCalledWith({
      where: { id: 'msg-1' },
      data: { deletedAt: expect.any(Date) },
    });
  });
});

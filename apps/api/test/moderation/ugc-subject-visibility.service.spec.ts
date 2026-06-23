/// <reference types="jest" />
import { NotFoundException } from '@nestjs/common';
import { UgcSubjectVisibilityService } from '../../src/moderation/services/ugc-subject-visibility.service';

describe('UgcSubjectVisibilityService', () => {
  const siteId = 'site-1';

  function makeService(prisma: unknown, sessionRevocation?: { revokeAllForUser: jest.Mock }) {
    const revocation = sessionRevocation ?? { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
    return {
      svc: new UgcSubjectVisibilityService(prisma as never, revocation as never),
      sessionRevocation: revocation,
    };
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
    const { svc } = makeService(prisma);

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
    const { svc } = makeService(prisma);

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
    const { svc } = makeService(prisma);

    await svc.applySubjectVisibility('event_chat_message', 'msg-1', true);

    expect(prisma.eventChatMessage.updateMany).toHaveBeenCalledWith({
      where: { id: 'msg-1' },
      data: { deletedAt: expect.any(Date) },
    });
  });

  it('user hide suspends account and revokes sessions', async () => {
    const revokeAllForUser = jest.fn().mockResolvedValue(undefined);
    const prisma = {
      user: {
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
    };
    const { svc, sessionRevocation } = makeService(prisma, { revokeAllForUser });

    await svc.applySubjectVisibility('user', 'user-1', true);

    expect(prisma.user.updateMany).toHaveBeenCalledWith({
      where: { id: 'user-1' },
      data: { status: 'SUSPENDED' },
    });
    expect(sessionRevocation.revokeAllForUser).toHaveBeenCalledWith('user-1', 'status_changed');
  });
});

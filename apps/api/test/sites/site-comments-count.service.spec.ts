/// <reference types="jest" />
import { SiteCommentsCountService } from '../../src/sites/services/site-comments-count.service';
import { ModerationService } from '../../src/moderation/services/moderation.service';

describe('SiteCommentsCountService', () => {
  const siteId = 'site-1';

  function makeService(prisma: unknown, moderation: Partial<ModerationService> = {}) {
    return new SiteCommentsCountService(
      prisma as never,
      {
        blockedUserIdsFor: jest.fn().mockResolvedValue([]),
        ...moderation,
      } as never,
    );
  }

  it('reconcileGlobal sets Site.commentsCount from non-deleted rows', async () => {
    const prisma = {
      siteComment: {
        count: jest.fn().mockResolvedValue(3),
      },
      site: {
        update: jest.fn().mockResolvedValue({}),
      },
    };
    const svc = makeService(prisma);

    const count = await svc.reconcileGlobal(siteId);

    expect(count).toBe(3);
    expect(prisma.siteComment.count).toHaveBeenCalledWith({
      where: { siteId, isDeleted: false },
    });
    expect(prisma.site.update).toHaveBeenCalledWith({
      where: { id: siteId },
      data: { commentsCount: 3 },
    });
  });

  it('countVisible excludes blocked authors for authed viewer', async () => {
    const prisma = {
      siteComment: {
        count: jest.fn().mockResolvedValue(1),
      },
    };
    const svc = makeService(prisma, {
      blockedUserIdsFor: jest.fn().mockResolvedValue(['blocked-u']),
    });

    await svc.countVisible(siteId, {
      userId: 'viewer',
      email: 'v@test.mk',
      phoneNumber: '+38970000001',
      role: 'USER' as never,
    });

    expect(prisma.siteComment.count).toHaveBeenCalledWith({
      where: {
        siteId,
        isDeleted: false,
        authorId: { notIn: ['blocked-u'] },
      },
    });
  });

  it('countVisibleBatch returns zero for sites with no visible comments', async () => {
    const prisma = {
      siteComment: {
        groupBy: jest.fn().mockResolvedValue([]),
      },
    };
    const svc = makeService(prisma);

    const out = await svc.countVisibleBatch(['site-a', 'site-b'], {
      userId: 'viewer',
      email: 'v@test.mk',
      phoneNumber: '+38970000001',
      role: 'USER' as never,
    });

    expect(out.get('site-a')).toBe(0);
    expect(out.get('site-b')).toBe(0);
  });

});

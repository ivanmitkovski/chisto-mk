/// <reference types="jest" />
import { NewsPostsAdminQueryService } from '../../src/news/services/news-posts-admin-query.service';

describe('NewsPostsAdminQueryService', () => {
  it('applies filters to status groupBy counts', async () => {
    const prisma = {
      newsPost: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
        groupBy: jest.fn().mockResolvedValue([{ status: 'DRAFT', _count: { _all: 3 } }]),
      },
    };
    const signedUrls = { signMany: jest.fn().mockResolvedValue(new Map()) };
    const svc = new NewsPostsAdminQueryService(prisma as never, signedUrls as never);

    const result = await svc.list({ status: 'draft' });

    expect(prisma.newsPost.groupBy).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ status: 'DRAFT' }),
      }),
    );
    expect(result.countsByStatus.draft).toBe(3);
  });
});

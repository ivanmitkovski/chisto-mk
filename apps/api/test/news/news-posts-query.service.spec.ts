/// <reference types="jest" />
import { NewsPostsQueryService } from '../../src/news/services/news-posts-query.service';

describe('NewsPostsQueryService', () => {
  it('returns db total for listPublished', async () => {
    const prisma = {
      newsPost: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(42),
      },
    };
    const signedUrls = { signMany: jest.fn().mockResolvedValue(new Map()) };
    const svc = new NewsPostsQueryService(prisma as never, signedUrls as never);

    const result = await svc.listPublished('en', 10, 0);

    expect(result.total).toBe(42);
    expect(prisma.newsPost.count).toHaveBeenCalled();
  });
});

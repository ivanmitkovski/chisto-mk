/// <reference types="jest" />
import { NewsRevisionsService } from '../../src/news/services/news-revisions.service';

describe('NewsRevisionsService', () => {
  it('prunes revisions beyond the cap', async () => {
    const create = jest.fn().mockResolvedValue({ id: 'rev-new' });
    const findUnique = jest.fn().mockResolvedValue({
      id: 'post-1',
      slug: 'slug',
      category: 'RELEASE',
      featured: false,
      scheduledAt: null,
      translations: {
        en: { title: 'T', excerpt: 'E', body: [] },
        mk: { title: '', excerpt: '', body: [] },
        sq: { title: '', excerpt: '', body: [] },
      },
    });
    const findMany = jest.fn().mockResolvedValue([{ id: 'old-1' }, { id: 'old-2' }]);
    const deleteMany = jest.fn().mockResolvedValue({ count: 2 });

    const prisma = {
      newsPost: { findUnique },
      newsPostRevision: { create, findMany, deleteMany },
    };

    const svc = new NewsRevisionsService(prisma as never);
    await svc.createRevision('post-1');

    expect(deleteMany).toHaveBeenCalledWith({
      where: { id: { in: ['old-1', 'old-2'] } },
    });
  });
});

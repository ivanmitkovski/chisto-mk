import { PersonalRetriever } from '../../../src/sites/feed/candidates/personal.retriever';

describe('PersonalRetriever', () => {
  it('returns empty when no followed reporters exist', async () => {
    const findMany = jest.fn();
    const prisma = { site: { findMany } } as never;
    const userStateRepo = {
      getState: jest.fn().mockResolvedValue({
        hiddenSiteIds: new Set<string>(),
        mutedCategoryIds: new Set<string>(),
        followReporterIds: new Set<string>(),
        seenSiteIds: new Map<string, number>(),
      }),
    } as never;
    const svc = new PersonalRetriever(prisma, userStateRepo);
    const out = await svc.retrieve({ userId: 'u1' });
    expect(out).toHaveLength(0);
    expect(findMany).not.toHaveBeenCalled();
  });
});

/// <reference types="jest" />
import { SiteStatus } from '../../src/prisma-client';
import { FeedTrainerWorker } from '../../src/workers/feed-trainer.worker';

function makeSite(i: number) {
  return {
    id: `site_${i}`,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    upvotesCount: 2,
    commentsCount: 1,
    savesCount: 1,
    sharesCount: 0,
    status: SiteStatus.REPORTED,
  };
}

describe('FeedTrainerWorker', () => {
  it('refreshSiteFeatureSnapshots uses one INSERT per chunk (not per site)', async () => {
    const executeRaw = jest.fn().mockResolvedValue(1);
    const sites = Array.from({ length: 450 }, (_, i) => makeSite(i));
    const prisma = {
      site: { findMany: jest.fn().mockResolvedValue(sites) },
      $executeRaw: executeRaw,
    };
    const worker = new FeedTrainerWorker(prisma as never);
    const n = await worker.refreshSiteFeatureSnapshots(5000);
    expect(n).toBe(450);
    expect(executeRaw).toHaveBeenCalledTimes(3);
  });

  it('refreshSiteFeatureSnapshots does not execute when no sites', async () => {
    const executeRaw = jest.fn();
    const prisma = {
      site: { findMany: jest.fn().mockResolvedValue([]) },
      $executeRaw: executeRaw,
    };
    const worker = new FeedTrainerWorker(prisma as never);
    const n = await worker.refreshSiteFeatureSnapshots(100);
    expect(n).toBe(0);
    expect(executeRaw).not.toHaveBeenCalled();
  });
});

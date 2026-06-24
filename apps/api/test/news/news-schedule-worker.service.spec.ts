/// <reference types="jest" />
import { NewsScheduleWorkerService } from '../../src/news/services/news-schedule-worker.service';

describe('NewsScheduleWorkerService', () => {
  it('publishes due scheduled posts and revalidates', async () => {
    const duePost = {
      id: 'p1',
      slug: 'due-post',
      scheduledAt: new Date(Date.now() - 1000),
    };
    const prisma = {
      newsPost: {
        findMany: jest.fn().mockResolvedValue([duePost]),
        update: jest.fn().mockResolvedValue({}),
      },
    };
    const revalidate = { triggerLandingRevalidate: jest.fn().mockResolvedValue(undefined) };
    const audit = { log: jest.fn().mockResolvedValue(undefined) };
    const worker = new NewsScheduleWorkerService(
      prisma as never,
      revalidate as never,
      audit as never,
    );
    (worker as unknown as { isLeader: boolean }).isLeader = true;

    await worker.runTick();

    expect(prisma.newsPost.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'p1' },
        data: expect.objectContaining({ status: 'PUBLISHED' }),
      }),
    );
    expect(revalidate.triggerLandingRevalidate).toHaveBeenCalled();
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'news.post.scheduled_publish' }),
    );
  });
});

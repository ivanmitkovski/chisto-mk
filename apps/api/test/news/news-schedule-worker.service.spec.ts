/// <reference types="jest" />
import { BadRequestException } from '@nestjs/common';
import { NewsScheduleWorkerService } from '../../src/news/services/news-schedule-worker.service';

describe('NewsScheduleWorkerService', () => {
  it('publishes due scheduled posts via lifecycle and revalidates', async () => {
    const duePost = {
      id: 'p1',
      slug: 'due-post',
      scheduledAt: new Date(Date.now() - 1000),
    };
    const prisma = {
      newsPost: {
        findMany: jest.fn().mockResolvedValue([duePost]),
      },
    };
    const lifecycle = { publish: jest.fn().mockResolvedValue({}) };
    const revalidate = { triggerLandingRevalidate: jest.fn().mockResolvedValue(undefined) };
    const worker = new NewsScheduleWorkerService(
      prisma as never,
      lifecycle as never,
      revalidate as never,
    );
    (worker as unknown as { isLeader: boolean }).isLeader = true;

    await worker.runTick();

    expect(lifecycle.publish).toHaveBeenCalledWith('p1');
    expect(revalidate.triggerLandingRevalidate).toHaveBeenCalled();
  });

  it('reverts failed scheduled publish to DRAFT when validation fails', async () => {
    const duePost = {
      id: 'p1',
      slug: 'due-post',
      scheduledAt: new Date(Date.now() - 1000),
    };
    const update = jest.fn().mockResolvedValue({});
    const prisma = {
      newsPost: {
        findMany: jest.fn().mockResolvedValue([duePost]),
        update,
      },
    };
    const lifecycle = {
      publish: jest.fn().mockRejectedValue(
        new BadRequestException({ code: 'NEWS_COVER_REQUIRED', message: 'validation failed' }),
      ),
    };
    const revalidate = { triggerLandingRevalidate: jest.fn().mockResolvedValue(undefined) };
    const worker = new NewsScheduleWorkerService(
      prisma as never,
      lifecycle as never,
      revalidate as never,
    );
    (worker as unknown as { isLeader: boolean }).isLeader = true;

    await worker.runTick();

    expect(lifecycle.publish).toHaveBeenCalledWith('p1');
    expect(update).toHaveBeenCalledWith({
      where: { id: 'p1' },
      data: { status: 'DRAFT', scheduledAt: null },
    });
    expect(revalidate.triggerLandingRevalidate).toHaveBeenCalled();
  });

  it('keeps scheduled status on transient publish failures', async () => {
    const duePost = {
      id: 'p1',
      slug: 'due-post',
      scheduledAt: new Date(Date.now() - 1000),
    };
    const update = jest.fn().mockResolvedValue({});
    const prisma = {
      newsPost: {
        findMany: jest.fn().mockResolvedValue([duePost]),
        update,
      },
    };
    const lifecycle = {
      publish: jest.fn().mockRejectedValue(new Error('database unavailable')),
    };
    const revalidate = { triggerLandingRevalidate: jest.fn().mockResolvedValue(undefined) };
    const worker = new NewsScheduleWorkerService(
      prisma as never,
      lifecycle as never,
      revalidate as never,
    );
    (worker as unknown as { isLeader: boolean }).isLeader = true;

    await worker.runTick();

    expect(update).not.toHaveBeenCalled();
  });
});

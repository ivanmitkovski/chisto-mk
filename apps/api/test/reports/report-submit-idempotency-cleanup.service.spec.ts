import { ReportSubmitIdempotencyCleanupService } from '../../src/reports/report-submit-idempotency-cleanup.service';

describe('ReportSubmitIdempotencyCleanupService', () => {
  const prisma = {
    reportSubmitIdempotency: {
      deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
    },
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('deletes rows older than retention', async () => {
    prisma.reportSubmitIdempotency.deleteMany.mockResolvedValue({ count: 3 });
    const service = new ReportSubmitIdempotencyCleanupService(prisma as never);
    const now = new Date('2026-05-20T12:00:00.000Z');
    jest.useFakeTimers({ now });

    await service.runOnce();

    expect(prisma.reportSubmitIdempotency.deleteMany).toHaveBeenCalledWith({
      where: {
        createdAt: {
          lt: new Date(now.getTime() - 45 * 86_400_000),
        },
      },
    });

    jest.useRealTimers();
  });

  it('onModuleDestroy clears the interval started by onModuleInit', () => {
    jest.useFakeTimers();
    const service = new ReportSubmitIdempotencyCleanupService(prisma as never);
    service.onModuleInit();
    service.onModuleDestroy();
    jest.advanceTimersByTime(86_400_000);
    expect(prisma.reportSubmitIdempotency.deleteMany).toHaveBeenCalledTimes(1);
    jest.useRealTimers();
  });
});

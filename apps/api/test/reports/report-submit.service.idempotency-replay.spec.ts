/// <reference types="jest" />
/**
 * Product contract: replaying the same idempotency key returns the same public response
 * shape as the original submit, reconstructed from the report + points ledger (no second create).
 * If create path later reads the ledger for points on first response too, update this test.
 */
import { ReportSubmitService } from '../../src/reports/report-submit.service';
import { ReportCapacityService } from '../../src/reports/report-capacity.service';
import { Role } from '../../src/prisma-client';

describe('ReportSubmitService idempotency replay', () => {
  const user = {
    userId: 'user-1',
    email: 'u@x.com',
    roles: [Role.USER],
  };

  const dto = {
    latitude: 41.9973,
    longitude: 21.428,
    title: 'Test report title here',
    description: 'Desc',
    mediaUrls: [] as string[],
    category: 'OTHER' as const,
    severity: 3,
    address: 'Addr',
    cleanupEffort: null as null,
  };

  it('two submits with the same key return deep-equal responses; create and emit once', async () => {
    let findIdemCall = 0;
    const prisma: any = {
      reportSubmitIdempotency: {
        findUnique: jest.fn().mockImplementation(() => {
          findIdemCall += 1;
          if (findIdemCall === 1) {
            return Promise.resolve(null);
          }
          return Promise.resolve({ reportId: 'rep-1' });
        }),
        create: jest.fn().mockResolvedValue({}),
      },
      site: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'site-1',
            latitude: 41.9973,
            longitude: 21.428,
            reports: [
              {
                id: 'older',
                createdAt: new Date('2020-01-01'),
                reporterId: 'other',
              },
            ],
          },
        ]),
        updateMany: jest.fn().mockResolvedValue({ count: 0 }),
        create: jest.fn(),
      },
      report: {
        create: jest.fn().mockResolvedValue({
          id: 'rep-1',
          siteId: 'site-1',
          createdAt: new Date('2024-06-01'),
          reportNumber: 42,
        }),
        findUnique: jest.fn().mockImplementation(() =>
          Promise.resolve({
            id: 'rep-1',
            siteId: 'site-1',
            reporterId: 'user-1',
            createdAt: new Date('2024-06-01'),
            reportNumber: 42,
          }),
        ),
      },
      reportCoReporter: {
        upsert: jest.fn().mockResolvedValue({}),
      },
      adminNotification: {
        create: jest.fn().mockResolvedValue({
          id: 'n1',
          title: 't',
        }),
      },
      pointTransaction: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      $transaction: jest.fn(),
    };

    prisma.$transaction.mockImplementation(async (cb: (tx: unknown) => Promise<unknown>) => cb(prisma));

    const reportsUploadService = {
      assertReportMediaUrlsFromOurBucket: jest.fn(),
    };
    const reportsOwnerEventsService = { emit: jest.fn(), emitToReportInterestedParties: jest.fn() };
    const postCreateEvents = { emit: jest.fn() };

    const reportCapacity = {
      spendWithinTransaction: jest.fn().mockResolvedValue(undefined),
    };
    const nearbySiteResolver = {
      resolveEarliestReportAnchor: jest.fn().mockResolvedValue({
        id: 'older',
        createdAt: new Date('2020-01-01'),
        reporterId: 'other',
        siteId: 'site-1',
      }),
    };

    const svc = new ReportSubmitService(
      prisma as never,
      postCreateEvents as never,
      reportsOwnerEventsService as never,
      reportCapacity as unknown as ReportCapacityService,
      reportsUploadService as never,
      nearbySiteResolver as never,
    );

    const key = 'idem-key-abc1234567';
    const first = await svc.createWithLocation(user as never, dto as never, key, 'en');
    const second = await svc.createWithLocation(user as never, dto as never, key, 'en');

    expect(second).toEqual(first);
    expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    expect(prisma.report.create).toHaveBeenCalledTimes(1);
    expect(postCreateEvents.emit).toHaveBeenCalledTimes(1);
    expect(reportsOwnerEventsService.emit).toHaveBeenCalledTimes(1);
    expect(reportsOwnerEventsService.emit).toHaveBeenCalledWith(
      'user-1',
      'rep-1',
      'report_submit_queued',
      expect.objectContaining({
        kind: 'submit_queued',
        idempotencyKey: key,
      }),
    );
  });
});

/// <reference types="jest" />
import { ReportSubmitIdempotencyService } from '../../src/reports/report-submit-idempotency.service';
import { ReportSubmitMediaAppendService } from '../../src/reports/report-submit-media-append.service';
import { ReportSubmitService } from '../../src/reports/report-submit.service';
import { ReportCapacityService } from '../../src/reports/report-capacity.service';
import { Role } from '../../src/prisma-client';

describe('ReportSubmitService nearby site', () => {
  const user = {
    userId: 'user-b',
    email: 'b@x.com',
    roles: [Role.USER],
  };

  const dto = {
    latitude: 41.9973,
    longitude: 21.428,
    title: 'Second report at same location',
    description: 'Desc',
    mediaUrls: [] as string[],
    category: 'OTHER' as const,
    severity: 3,
    address: null as null,
    cleanupEffort: null as null,
  };

  it('does not create co-reporter rows when attaching to an existing nearby site', async () => {
    const prisma: any = {
      reportSubmitIdempotency: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({}),
      },
      site: {
        updateMany: jest.fn().mockResolvedValue({ count: 0 }),
        create: jest.fn(),
      },
      report: {
        create: jest.fn().mockResolvedValue({
          id: 'rep-b',
          siteId: 'site-1',
          createdAt: new Date('2026-05-30T12:00:00.000Z'),
          reportNumber: 99,
        }),
      },
      reportCoReporter: {
        upsert: jest.fn(),
      },
      adminNotification: {
        create: jest.fn().mockResolvedValue({ id: 'n1', title: 't' }),
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
        id: 'rep-a',
        createdAt: new Date('2026-05-30T11:00:00.000Z'),
        reporterId: 'user-a',
        siteId: 'site-1',
      }),
    };

    const idempotency = new ReportSubmitIdempotencyService(prisma as never);
    const mediaAppend = new ReportSubmitMediaAppendService(
      prisma as never,
      reportsUploadService as never,
      reportsOwnerEventsService as never,
    );
    const svc = new ReportSubmitService(
      prisma as never,
      postCreateEvents as never,
      reportsOwnerEventsService as never,
      reportCapacity as unknown as ReportCapacityService,
      reportsUploadService as never,
      nearbySiteResolver as never,
      idempotency,
      mediaAppend,
      { emit: jest.fn() } as never,
      { recordSiteCreated: jest.fn(), emitHistoryAppended: jest.fn() } as never,
      { recordReportSubmitted: jest.fn() } as never,
    );

    await svc.createWithLocation(user as never, dto as never, undefined, 'en');

    expect(prisma.report.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        siteId: 'site-1',
        reporterId: 'user-b',
        potentialDuplicateOfId: 'rep-a',
      }),
    });
    expect(prisma.reportCoReporter.upsert).not.toHaveBeenCalled();
  });
});

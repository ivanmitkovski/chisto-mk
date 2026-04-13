/// <reference types="jest" />
import { ReportsService } from '../../src/reports/reports.service';
import { Role } from '../../src/prisma-client';

describe('ReportsService mergeDuplicateReports', () => {
  it('does not append child media to primary; hard-deletes children; deletes duplicate media from storage', async () => {
    const moderator = { userId: 'mod-1', role: Role.ADMIN };
    const primaryId = 'primary-1';
    const childId = 'child-1';
    const childMedia = ['https://test-bucket.s3.eu-central-1.amazonaws.com/reports/u1/a.jpg'];

    const txReportUpdate = jest.fn();
    const txReportDeleteMany = jest.fn().mockResolvedValue({ count: 1 });
    const txReportUpdateMany = jest.fn().mockResolvedValue({ count: 0 });
    const txReportCoReporterUpsert = jest.fn();
    const txReportCount = jest.fn().mockResolvedValue(2);

    const mergePayload = {
      id: primaryId,
      siteId: 'site-1',
      status: 'NEW' as const,
      reporterId: 'user-a',
      mediaUrls: ['https://test-bucket.s3.eu-central-1.amazonaws.com/reports/u-a/orig.jpg'],
      coReporters: [] as { userId: string }[],
      potentialDuplicates: [
        {
          id: childId,
          reporterId: 'user-b',
          createdAt: new Date('2026-01-02T00:00:00.000Z'),
          mediaUrls: childMedia,
          coReporters: [] as { userId: string; createdAt: Date }[],
        },
      ],
    };

    let findUniqueCalls = 0;
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockImplementation(() => {
          findUniqueCalls += 1;
          if (findUniqueCalls === 1) {
            return Promise.resolve({ id: primaryId, potentialDuplicateOfId: null });
          }
          return Promise.resolve(mergePayload);
        }),
        findUniqueOrThrow: jest.fn().mockResolvedValue({
          status: 'APPROVED',
          reporterId: 'user-a',
          coReporters: [
            {
              userId: 'user-b',
              reportedAt: new Date('2026-01-02T00:00:00.000Z'),
              user: { firstName: 'B', lastName: 'User' },
            },
          ],
        }),
      },
      $transaction: jest.fn(async (cb: (tx: unknown) => Promise<unknown>) => {
        const tx = {
          report: {
            update: txReportUpdate,
            updateMany: txReportUpdateMany,
            deleteMany: txReportDeleteMany,
            count: txReportCount,
          },
          reportCoReporter: {
            upsert: txReportCoReporterUpsert,
          },
          site: {
            findUnique: jest.fn(),
            update: jest.fn(),
          },
        };
        return cb(tx);
      }),
    };

    const reportsUploadService = {
      signUrls: jest.fn(),
      deleteReportMediaUrls: jest.fn().mockResolvedValue(1),
      tryExtractReportMediaObjectKeyFromUrl: jest.fn(),
    };

    const service = new ReportsService(
      prisma as never,
      { log: jest.fn() } as never,
      reportsUploadService as never,
      { emitReportStatusUpdated: jest.fn() } as never,
      { emitNotificationCreated: jest.fn() } as never,
      { emitSiteUpdated: jest.fn() } as never,
      { emit: jest.fn() } as never,
      { emit: jest.fn() } as never,
    );

    const result = await service.mergeDuplicateReports(
      primaryId,
      { childReportIds: [childId], reason: 'test' },
      moderator as never,
    );

    expect(txReportUpdate).toHaveBeenCalledWith({
      where: { id: primaryId },
      data: expect.not.objectContaining({
        mediaUrls: expect.anything(),
      }),
    });
    expect(txReportDeleteMany).toHaveBeenCalledWith({
      where: { id: { in: [childId] } },
    });
    expect(reportsUploadService.deleteReportMediaUrls).toHaveBeenCalledWith(childMedia);
    expect(result.reporterCount).toBe(2);
    expect(result.coReporters).toHaveLength(1);
    expect(result.coReporters[0].userId).toBe('user-b');
    expect(result.mergedMediaCount).toBe(1);
    expect(txReportCoReporterUpsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: expect.objectContaining({
          reportId: primaryId,
          userId: 'user-b',
          reportedAt: mergePayload.potentialDuplicates[0].createdAt,
        }),
      }),
    );
  });

  it('is idempotent when child reports were already removed (no duplicate co-reporter rows on retry)', async () => {
    const moderator = { userId: 'mod-1', role: Role.ADMIN };
    const primaryId = 'primary-1';
    const childId = 'child-1';

    let findCall = 0;
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockImplementation(() => {
          findCall += 1;
          if (findCall === 1) {
            return Promise.resolve({ id: primaryId, potentialDuplicateOfId: null });
          }
          return Promise.resolve({
            id: primaryId,
            siteId: 'site-1',
            status: 'APPROVED',
            reporterId: 'user-a',
            mediaUrls: [],
            coReporters: [],
            potentialDuplicates: [],
          });
        }),
        findUniqueOrThrow: jest.fn().mockResolvedValue({
          status: 'APPROVED',
          reporterId: 'user-a',
          coReporters: [],
        }),
        count: jest.fn().mockResolvedValue(0),
      },
      $transaction: jest.fn(),
    };

    const reportsUploadService = {
      signUrls: jest.fn(),
      deleteReportMediaUrls: jest.fn(),
      tryExtractReportMediaObjectKeyFromUrl: jest.fn(),
    };

    const service = new ReportsService(
      prisma as never,
      { log: jest.fn() } as never,
      reportsUploadService as never,
      { emitReportStatusUpdated: jest.fn() } as never,
      { emitNotificationCreated: jest.fn() } as never,
      { emitSiteUpdated: jest.fn() } as never,
      { emit: jest.fn() } as never,
      { emit: jest.fn() } as never,
    );

    const result = await service.mergeDuplicateReports(
      primaryId,
      { childReportIds: [childId] },
      moderator as never,
    );

    expect(result.mergedChildCount).toBe(0);
    expect(result.primaryReportId).toBe(primaryId);
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(reportsUploadService.deleteReportMediaUrls).not.toHaveBeenCalled();
  });
});
